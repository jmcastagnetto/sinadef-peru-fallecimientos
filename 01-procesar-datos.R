library(tidyverse)
library(vroom)



# forma condesada
col_spec <- cols(
  .default = col_character(),
  Nº = col_double(),
  EDAD = col_double(),
  FECHA = col_date(format = ""),
  AÑO = col_number(),
  MES = col_number()
)

sinadef_raw <- vroom(
  "datos/fallecidos_sinadef-utf8.csv.gz",
  delim = ";",
  skip = 2,
  col_types = col_spec,
  col_select = 1:31, # columnas 32-35 no tienen contenidos
  trim_ws = TRUE,
  na = c("", "SIN REGISTRO", "NA")
) %>%
  janitor::clean_names()

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

sinadef_df <- sinadef_raw %>%
  rename(
    id = 1,
    anho = ano
  ) %>%
  separate(
    col = cod_number_ubigeo_domicilio,
    into = c("cod", "number", "dept", "prov", "dist", "domicilio"),
    sep = "-",
    convert = FALSE
  ) %>%
  mutate( # intento de corregir errores en la unidad de la edad
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
    # calcular campos extra
    dia = lubridate::day(fecha),
    semana = lubridate::week(fecha),
    semana_iso = lubridate::isoweek(fecha),
    pais_en = simplecountries::simple_country_name(pais_domicilio) %>%
      str_replace("gran bretaña", "UK") %>%
      str_replace("estados unidos de america", "USA"),
    iso3c = countrycode::countryname(pais_en, destination = "iso3c")
  ) %>%
#  mutate_if(
#    is.character,
#    str_remove_all,
#	pattern = "\0"
#  ) %>%
#  mutate_if(
#    is.character,
#    str_trim
#  ) %>%
#  mutate_if(
#    is.character,
#    str_squish
#  ) %>%
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

all_causes <- bind_rows(
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
  group_by(codigo_ciex, causa)

write_csv(
  all_causes,
  path = "datos/causas_reportadas_sinadef.csv"
)

write_csv(
  sinadef_df,
  path = "datos/fallecidos_sinadef_procesado.csv.gz"
)

save(
  sinadef_raw,
  sinadef_df,
  file = "datos/sinadef-datos.Rdata"
)

