# Downloads the Alliance's latest "All disease associations" file and summarizes
# the entities annotated with DO terms by MOD and data type

library(DO.utils)
library(here)
library(readr)


# SET file outputs --------------------------------------------------------
data_dir <- here::here("data", "alliance")

full_file <- file.path(data_dir, "disease_counts-full_by_obj.csv")
disobj_file <- file.path(data_dir, "disease_counts-disobj_by_obj.csv")
disease_file <- file.path(data_dir, "disease_counts-disease_by_obj.csv")
uniq_file <- file.path(data_dir, "disease_counts-unique_diseases.csv")



# Ensure directory exists -------------------------------------------------
if (!dir.exists(data_dir)) {
  dir.create(data_dir, recursive = TRUE)
}


# Download & Load "All disease annotations" .tsv.gz -------------------
disease_tsv_file <- DO.utils::download_alliance_tsv(dest_dir = data_dir)
disease_df <- DO.utils::read_alliance(disease_tsv_file)


# Calculate Counts --------------------------------------------------------
full_record <- DO.utils::count_alliance_records(
  disease_df,
  record_lvl = "full_record"
)

disobj_record <- DO.utils::count_alliance_records(
  disease_df,
  record_lvl = "disease-object"
)

disease_record <- DO.utils::count_alliance_records(
  disease_df,
  record_lvl = "disease"
)

unique_disease <- DO.utils::count_alliance_records(
  disease_df,
  record_lvl = "disease",
  by_type = FALSE
)
# add total unique diseases across entire alliance
unique_alliance <- tibble::tibble(
  species = "Alliance",
  disease_n = dplyr::n_distinct(disease_df$DOID)
)
unique_disease <- dplyr::bind_rows(unique_disease, unique_alliance) %>%
  unique() %>%
  dplyr::arrange(disease_n)


# Save Counts & Version Info ----------------------------------------------
readr::write_csv(full_record, full_file, na = "0")
readr::write_csv(disobj_record, disobj_file, na = "0")
readr::write_csv(disease_record, disease_file, na = "0")
readr::write_csv(unique_disease, uniq_file, na = "0")

version_info <- disease_df %>%
  attributes() %>%
  .[c("Alliance_Database_Version", "Date_file_generated_UTC")] %>%
  unlist() %>%
  paste0(names(.), ": ", .)
readr::write_lines(version_info, file.path(data_dir, "version_info.txt"))
