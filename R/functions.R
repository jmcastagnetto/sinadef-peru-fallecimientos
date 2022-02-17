library(tidyverse)
library(httr)
library(git2r, warn.conflicts = FALSE)

# "new" URL that is not been updated since 2022-02-12
# data_url <- "https://cloud.minsa.gob.pe/s/g9KdDRtek42X3pg/download"

# "old" URL that seems to be updated as of 2022-02-16
data_url <- "https://cloud.minsa.gob.pe/s/nqF2irNbFomCLaa/download"

detect_change <- function(url = data_url) {
  prev_length <- read_lines("prev_length.txt") %>% as.integer()
  res <- HEAD(url)
  curr_length <- res$headers$`content-length`
  write_file(curr_length, "prev_length.txt")
  data_changed <- (as.integer(curr_length) != prev_length)
  if(data_changed) {
    cat(">> Change detected\n")
  } else {
    cat(">> Data has not changed\n")
  }
  return(data_changed)
}


get_file <- function(url = data_url, has_changed) {
  if(has_changed) {
    cat(">> Downloading data\n")
    # format is now CSV
    download.file(url, destfile = "datos/fallecidos_sinadef.csv", method = "wget")
  } else {
    cat(">> No need to download data\n")
  }
  return("datos/fallecidos_sinadef.csv")
}

get_csv_file <- function(downloaded_data) {
  # archive_read(
  #   archive = downloaded_data,
  #   file = "TB_SINADEF.csv",
  #   mode = "r",
  #   format = "7zip"
  # )
  return("datos/fallecidos_sinadef.csv")
}

read_sinadef_raw <- function(csv_file) {
  csv_spec <- cols(
    .default = col_character(),
    EDAD = col_number(),
    AÑO = col_number(),
    MES = col_number(),
    FECHA = col_date()
  )
  vroom(
    csv_file,
    delim = "|",
    col_types = csv_spec,
    trim_ws = TRUE,
    na = c("", "SIN REGISTRO", "NA")
  ) %>%
    janitor::clean_names() %>%
    rename(año = ano)
  # %>%
  #   mutate(
  #     fecha = lubridate::dmy(fecha)
  #   )
}

fix_clean_data <- function(sinadef_raw) {
  estciv_mayores <- c("CASADO", "DIVORCIADO", "SEPARADO",
                      "VIUDO", "CONVIVIENT/CONCUBINA")
  edu_mayor3 <- c("INICIAL / PRE-ESCOLAR",
                  "PRIMARIA INCOMPLETA",
                  "PRIMARIA COMPLETA",
                  "SECUNDARIA INCOMPLETA",
                  "SECUNDARIA COMPLETA",
                  "SUPERIOR NO UNIV. INC.",
                  "SUPERIOR NO UNIV. COMP.",
                  "SUPERIOR UNIV. INC.",
                  "SUPERIOR UNIV. COMP.")

  covid19_regex <- "(CORONAVIRUS|COVID|SARS COV|SARS-COV|COBID|CORONA VI|CORONAB)"

  # para convertir a edades en años
  s2m <- 60
  m2h <- 60
  h2d <- 24
  d2y <- 365
  m2y <- 12

  sinadef_raw %>%
    separate(
      col = cod_number_ubigeo_domicilio,
      into = c("cod", "number", "dept", "prov", "dist", "domicilio"),
      sep = "-",
      convert = FALSE
    ) %>%
    mutate(
      ubigeo_reniec = glue::glue("{dept}{prov}{dist}"),
      # intento de corregir errores en la unidad de la edad
      tiempo_edad_orig = tiempo_edad,
      tiempo_edad = case_when(
        !is.na(edad) &
          edad >= 15 &
          tiempo_edad_orig != "AÑOS" &
          estado_civil %in% estciv_mayores ~ "AÑOS",
        !is.na(edad) &
          edad >= 3 &
          tiempo_edad_orig != "AÑOS" &
          nivel_de_instruccion %in% edu_mayor3 ~ "AÑOS",
        TRUE ~ tiempo_edad
      ),
      corregido_tiempo_edad = (tiempo_edad != tiempo_edad_orig),
      # años
      edad_años = case_when(
        tiempo_edad == "SEGUNDOS" ~ edad / (s2m * m2h * h2d * d2y),
        tiempo_edad == "MINUTOS" ~ edad / (m2h * h2d * d2y),
        tiempo_edad == "HORAS" ~ edad / (h2d * d2y),
        tiempo_edad == "DIAS" ~ edad / d2y,
        tiempo_edad == "MESES" ~ edad / m2y,
        TRUE ~ edad
      ),
      # age group
      grupo_edad = cut(edad_años,
                       breaks = c(0, 20, 40, 60, 80, 200),
                       labels = c(
                         "0-19",
                         "20-39",
                         "40-59",
                         "60-79",
                         "80+"
                       ),
                       include.lowest = TRUE,
                       right = FALSE,
                       ordered_result = TRUE),
      # calcular campos extra
      dia = lubridate::wday(fecha,
                            locale = "es_PE.UTF8",
                            label = TRUE, abbr = FALSE),
      semana = lubridate::week(fecha),
      semana_iso = lubridate::isoweek(fecha),
      semana_epi = lubridate::epiweek(fecha),
      año_epi = lubridate::epiyear(fecha),
      trimestre = lubridate::quarter(fecha),
      pais_en = str_trim(pais_domicilio) %>%
        str_squish() %>%
        str_to_title() %>%
        str_replace_all(" De ", " de ") %>%
        str_replace_all(" E ", " e ") %>%
        str_replace("Republica", "República") %>%
        str_replace("^Gran Bretaña$", "Reino Unido") %>%
        str_replace("^Reino Unido de Gran Bretaña e Irlanda Del Norte", "Reino Unido") %>%
        str_replace("^Estados Unidos de America$", "Estados Unidos") %>%
        countrycode::countryname(destination = "country.name.en"),
      iso3c = countrycode::countryname(pais_en, destination = "iso3c"),
      en_peru = (iso3c == "PER")
    ) %>%
    mutate(
      covid19_a = str_detect(debido_a_causa_a,
                             covid19_regex) %>%
        replace_na(FALSE),
      covid19_b = str_detect(debido_a_causa_b,
                             covid19_regex) %>%
        replace_na(FALSE),
      covid19_c = str_detect(debido_a_causa_c,
                             covid19_regex) %>%
        replace_na(FALSE),
      covid19_d = str_detect(debido_a_causa_d,
                             covid19_regex) %>%
        replace_na(FALSE),
      covid19_e = str_detect(debido_a_causa_e,
                             covid19_regex) %>%
        replace_na(FALSE),
      covid19_f = str_detect(debido_a_causa_f,
                             covid19_regex) %>%
        replace_na(FALSE)
    ) %>%
    rowwise() %>%
    mutate(
      covid19_causa = (covid19_a | covid19_b | covid19_c | covid19_d | covid19_e | covid19_f),
      covid19_n_causa = sum(covid19_a, covid19_b, covid19_c, covid19_d, covid19_e, covid19_f, na.rm = TRUE)
    )
}

save_csv <- function(data, filename) {
  vroom_write(
    data,
    delim = ",",
    file = filename,
    num_threads = 4
  )
}

save_rds <- function(data, filename) {
  saveRDS(data, filename)
}

mk_causes <- function(sinadef_raw) {
  bind_rows(
    sinadef_raw %>% select(codigo_ciex = causa_a_cie_x,
                           causa = debido_a_causa_a),
    sinadef_raw %>% select(codigo_ciex = causa_b_cie_x,
                           causa = debido_a_causa_b),
    sinadef_raw %>% select(codigo_ciex = causa_c_cie_x,
                           causa = debido_a_causa_c),
    sinadef_raw %>% select(codigo_ciex = causa_d_cie_x,
                           causa = debido_a_causa_d),
    sinadef_raw %>% select(codigo_ciex = causa_e_cie_x,
                           causa = debido_a_causa_e),
    sinadef_raw %>% select(codigo_ciex = causa_f_cie_x,
                           causa = debido_a_causa_f)
  ) %>%
    arrange(codigo_ciex, causa) %>%
    group_by(codigo_ciex, causa) %>%
    tally() %>%
    mutate(
      causa = str_trim(causa) %>% str_squish()
    )
}

build_readme <- function(dummy) {
  rmarkdown::render(
    input = "README.Rmd",
    output_format = "md_document",
    output_file = "README.md"
  )
}

commit_push <- function(dummy, msg) {
  commit(message = msg, all = TRUE)
  push()
}
