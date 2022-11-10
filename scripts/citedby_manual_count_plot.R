# Generates plot showing total number of publications citing DO publications
# NOTE: Publications CAN be counted twice if they cite more than one article

library(here)
library(tidyverse)
library(lubridate)


# SPECIFY file paths ------------------------------------------------------
data_dir <- here::here("data/citedby/counts")
manual_file <- file.path(data_dir, "citedby_counts-manual.csv")
full_summary_file <- file.path(data_dir, "citedby_counts-manual_smry.csv")

graphics_dir <- here::here("graphics/citedby")
plot_2021 <- file.path(graphics_dir, "citedby_manual_comparison_2021.png")
plot_2022 <- file.path(graphics_dir, "citedby_manual_comparison_2022.png")

if (!dir.exists(graphics_dir)) {
  dir.create(graphics_dir, recursive = TRUE)
}


# Load manual count data --------------------------------------------------
cb_man <- readr::read_csv(
  manual_file,
  col_types = readr::cols(
    date = readr::col_date(),
    citedby_n = readr::col_integer(),
    .default = readr::col_character()
  )
)


# Summarize ---------------------------------------------------------------
cb_summary <- cb_man %>%
  dplyr::group_by(db, date) %>%
  dplyr::summarize(total = sum(citedby_n)) %>%
  dplyr::ungroup() %>%
  dplyr::arrange(date)

cb_summary_2021 <- dplyr::filter(cb_summary, lubridate::year(date) == 2021)
cb_summary_2022 <- dplyr::filter(cb_summary, lubridate::year(date) == 2022)



# Plot by year ------------------------------------------------------------
db_lvl <- c(pubmed = "PubMed", scopus = "Scopus", europepmc = "Europe PMC",
        icite = "iCite", semantic_scholar = "Semantic Scholar",
        scite = "scite.ai", aminer = "AMiner", lens = "Lens.org",
        google_scholar = "Google Scholar")

g_2021 <- cb_summary_2021 %>%
    dplyr::mutate(db = factor(dplyr::recode(db, !!!db_lvl), levels = db_lvl)) %>%
    ggplot() +
    geom_col(aes(x = db, y = total), fill = "grey", width = 0.8) +
    geom_text(aes(x = db, y = 50, label = db), angle = 90, hjust = 0) +
    labs(x = "Database", y = "Cited By Total (not unique)") +
    scale_y_continuous(expand = expansion(mult = 0.01)) +
    theme_minimal() +
    theme(axis.text.x = element_blank())

g_2022 <- cb_summary_2022 %>%
  dplyr::mutate(db = factor(dplyr::recode(db, !!!db_lvl), levels = db_lvl)) %>%
  ggplot() +
  geom_col(aes(x = db, y = total), fill = "grey", width = 0.8) +
  geom_text(aes(x = db, y = 50, label = db), angle = 90, hjust = 0) +
  labs(x = "Database", y = "Cited By Total (not unique)") +
  scale_y_continuous(expand = expansion(mult = 0.01)) +
  theme_minimal() +
  theme(axis.text.x = element_blank())

names(cb_man)

# Save --------------------------------------------------------------------
readr::write_csv(cb_summary, full_summary_file)

ggsave(
  g_2021,
  filename = plot_2021,
  device = tools::file_ext(plot_2021),
  width = 2.5,
  height = 2.5,
  dpi = 600
)

ggsave(
  g_2022,
  filename = plot_2022,
  device = tools::file_ext(plot_2022),
  width = 2,
  height = 3.45,
  dpi = 600
)
