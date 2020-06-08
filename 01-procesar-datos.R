library(tidyverse)

sinadef_raw <- read_csv2(
  "datos/fallecidos_sinadef-utf8.csv",
  skip = 2,
  col_types = cols(
    Nº = col_integer(),
    `TIPO SEGURO` = col_character(),
    SEXO = col_character(),
    EDAD = col_number(),
    `TIEMPO EDAD` = col_character(),
    `ESTADO CIVIL` = col_character(),
    `NIVEL DE INSTRUCCIÓN` = col_character(),
    `COD# UBIGEO DOMICILIO` = col_character(),
    `PAIS DOMICILIO` = col_character(),
    `DEPARTAMENTO DOMICILIO` = col_character(),
    `PROVINCIA DOMICILIO` = col_character(),
    `DISTRITO DOMICILIO` = col_character(),
    FECHA = col_date(format = "%d/%m/%Y"),
    AÑO = col_integer(),
    MES = col_integer(),
    `TIPO LUGAR` = col_character(),
    INSTITUCION = col_character(),
    `MUERTE VIOLENTA` = col_character(),
    NECROPSIA = col_character()
  ),
  na = c("", "SIN REGISTRO", "NA")
) %>%
  janitor::clean_names()

estciv_mayores <- c("CASADO", "DIVORCIADO", "SEPARADO",
                    "VIUDO", "CONVIVIENT/CONCUBINA")
edu_mayores <- c("INICIAL / PRE-ESCOLAR",
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
      tiempo_edad_orig != "AÑOS" &
        estado_civil %in% estciv_mayores ~ "AÑOS",
      tiempo_edad_orig != "AÑOS" &
        nivel_de_instruccion %in% edu_mayores ~ "AÑOS",
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
  mutate_at(
    vars(tipo_seguro, sexo,
         tiempo_edad, tiempo_edad_orig,
         estado_civil,
         nivel_de_instruccion,
         cod, number, dept, prov, dist, domicilio,
         pais_domicilio, departamento_domicilio,
         distrito_domicilio,
         pais_en, iso3c,
         tipo_lugar, institucion, muerte_violenta,
         necropsia),
    factor
  )

save(
  sinadef_raw,
  sinadef_df,
  file = "datos/sinadef-datos.Rdata"
)

