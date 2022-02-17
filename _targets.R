library(targets)
library(tarchetypes)
options(tidyverse.quiet = TRUE)
options(dplyr.summarise.inform = FALSE)
source("R/functions.R")

tar_option_set(
  packages = c("tidyverse", "vroom", "archive", "git2r", "httr")
)

list(
  tar_target(
    check_for_change,
    detect_change(data_url)
  ),
  tar_target(
    downloaded_data,
    get_file(data_url, check_for_change)
    #,
    #cue = tar_cue_age(  # downloaded data is older than 6 hours
    #  name = downloaded_data,
    #  age = as.difftime(6, units = "hours")
    #)
  ),
  # tar_target(
  #   csv_file,
  #   get_csv_file(downloaded_data),
  # ),
  tar_target(
    sinadef_raw,
    read_sinadef_raw(downloaded_data)
    #read_sinadef_raw(csv_file)
  ),
  tar_target(
    sinadef_proc,
    fix_clean_data(sinadef_raw)
  ),
  tar_target(
    generate_csv,
    save_csv(sinadef_proc, "datos/fallecidos_sinadef_procesado.csv.xz")
  ),
  tar_target(
    generate_raw_rds,
    save_rds(sinadef_raw, "datos/sinadef-raw.rds")
  ),
  tar_target(
    generate_proc_rds,
    save_rds(sinadef_proc, "datos/sinadef-procesado.rds")
  ),
  tar_target(
    all_causes,
    mk_causes(sinadef_raw)
  ),
  tar_target(
    save_all_causes,
    save_csv(all_causes, "datos/causas_reportadas_sinadef.csv")
  ),
  tar_target(
    update_readme,
    build_readme(sinadef_proc)
  )#,
  #tar_target(
  #  update_repo,
  #  commit_push(
  #    c(
  #      update_readme,
  #      sinadef_proc,
  #      save_all_causes,
  #      generate_proc_rds,
  #      generate_csv,
  #      generate_raw_rds,
  #    ),
  #    glue::glue("Datos actualizados al {Sys.time()}")
  #  )
  #)
)
