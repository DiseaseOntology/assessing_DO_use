# Downloads the Alliance's latest "All disease associations" file and summarizes
# the entities annotated with DO terms by MOD and data type

library(DO.utils)
library(here)
library(tidyverse)
library(hues)


# SET file outputs --------------------------------------------------------
data_dir <- here::here("data", "alliance")

full_file <- file.path(data_dir, "disease_counts-full_by_obj.csv")
disobj_file <- file.path(data_dir, "disease_counts-disobj_by_obj.csv")
disease_file <- file.path(data_dir, "disease_counts-disease_by_obj.csv")
uniq_file <- file.path(data_dir, "disease_counts-unique_diseases.csv")

plot_file <- here::here("graphics", "alliance_disobj_plot.png")


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



# Plot - Disease-Object ---------------------------------------------------
disobj_long <- disobj_record %>%
  tidyr::pivot_longer(
    cols = dplyr::ends_with("_n"),
    names_to = c("Type", ".value"),
    names_sep = "\\."
  ) %>%
  dplyr::mutate(
    species = factor(
      species,
      levels = c("Saccharomyces cerevisiae", "Caenorhabditis elegans",
                 "Drosophila melanogaster", "Danio rerio",
                 "Mus musculus", "Rattus norvegicus", "Homo sapiens")
      )
  ) %>%
  dplyr::rename(n = "disease-object_n", Species = species)

colors <- hues::iwanthue(dplyr::n_distinct(disobj_long$Species))

g <- ggplot(disobj_long, aes(x = Type, y = n, fill = Species)) +
  geom_col() +
  scale_fill_manual(values = colors) +
  scale_y_continuous(
    name = "Unique Disease-Object Relationships",
    labels = ~ format(.x, big.mark = ",")
  ) +
  scale_x_discrete(name = "Object Type") +
  theme_classic() +
  theme(
    axis.text.x = element_text(size = 11),
    axis.text.y = element_text(size = 11),
    legend.text = element_text(size = 11),
    axis.title = element_text(size = 13),
    legend.title = element_blank()
  )

ggsave(
  plot = g,
  filename = plot_file,
  device = tools::file_ext(plot_file),
  width = 5,
  height = 3.75,
  units = "in",
  dpi = 600
)
