library(tidyverse)

col_spec <- cols(
  Nº = col_double(),
  `TIPO SEGURO` = col_character(),
  SEXO = col_character(),
  EDAD = col_double(),
  `TIEMPO EDAD` = col_character(),
  `ESTADO CIVIL` = col_character(),
  `NIVEL DE INSTRUCCIÓN` = col_character(),
  `COD# UBIGEO DOMICILIO` = col_character(),
  `PAIS DOMICILIO` = col_character(),
  `DEPARTAMENTO DOMICILIO` = col_character(),
  `PROVINCIA DOMICILIO` = col_character(),
  `DISTRITO DOMICILIO` = col_character(),
  FECHA = col_date(format = ""),
  AÑO = col_double(),
  MES = col_double(),
  `TIPO LUGAR` = col_character(),
  INSTITUCION = col_character(),
  `MUERTE VIOLENTA` = col_character(),
  NECROPSIA = col_character(),
  `DEBIDO A (CAUSA A)` = col_character(),
  `CAUSA A (CIE-X)` = col_character(),
  `DEBIDO A (CAUSA B)` = col_character(),
  `CAUSA B (CIE-X)` = col_character(),
  `DEBIDO A (CAUSA C)` = col_character(),
  `CAUSA C (CIE-X)` = col_character(),
  `DEBIDO A (CAUSA D)` = col_character(),
  `CAUSA D (CIE-X)` = col_character(),
  `DEBIDO A (CAUSA E)` = col_character(),
  `CAUSA E (CIE-X)` = col_character(),
  `DEBIDO A (CAUSA F)` = col_character(),
  `CAUSA F (CIE-X)` = col_character()
)

sinadef_raw <- read_csv2(
  "datos/fallecidos_sinadef-utf8.csv.gz",
  skip = 2,
  col_types = col_spec,
  na = c("", "SIN REGISTRO", "NA")
) %>%
  janitor::clean_names() %>%
  select(-c(32:35))

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
  mutate_if(
    is.character,
    str_trim
  ) %>%
  mutate_if(
    is.character,
    str_squish
  ) %>%
  mutate(
    covid19_a = str_detect(debido_a_causa_a,
                          "(CORONAVIRUS|COVID|SARS COV|SARS-COV)") %>%
      replace_na(FALSE),
    covid19_b = str_detect(debido_a_causa_b,
                          "(CORONAVIRUS|COVID|SARS COV|SARS-COV)") %>%
      replace_na(FALSE),
    covid19_c = str_detect(debido_a_causa_c,
                          "(CORONAVIRUS|COVID|SARS COV|SARS-COV)") %>%
      replace_na(FALSE),
    covid19_d = str_detect(debido_a_causa_d,
                          "(CORONAVIRUS|COVID|SARS COV|SARS-COV)") %>%
      replace_na(FALSE),
    covid19_e = str_detect(debido_a_causa_e,
                          "(CORONAVIRUS|COVID|SARS COV|SARS-COV)") %>%
      replace_na(FALSE),
    covid19_f = str_detect(debido_a_causa_f,
                          "(CORONAVIRUS|COVID|SARS COV|SARS-COV)") %>%
      replace_na(FALSE)
  ) %>%
  rowwise() %>%
  mutate(
    covid19_causa = (covid19_a | covid19_b | covid19_c | covid19_d | covid19_e | covid19_f),
    covid19_n_causa = sum(covid19_a, covid19_b, covid19_c, covid19_d, covid19_e, covid19_f, na.rm = TRUE)
  )

all_causes <- bind_rows(
  sinadef_raw %>% select(codigo_ciex = causa_a_cie_x, causa = debido_a_causa_a),
  sinadef_raw %>% select(codigo_ciex = causa_b_cie_x, causa = debido_a_causa_b),
  sinadef_raw %>% select(codigo_ciex = causa_c_cie_x, causa = debido_a_causa_c),
  sinadef_raw %>% select(codigo_ciex = causa_d_cie_x, causa = debido_a_causa_d),
  sinadef_raw %>% select(codigo_ciex = causa_e_cie_x, causa = debido_a_causa_e),
  sinadef_raw %>% select(codigo_ciex = causa_f_cie_x, causa = debido_a_causa_f)
) %>%
  arrange(codigo_ciex, causa) %>%
  distinct()

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

