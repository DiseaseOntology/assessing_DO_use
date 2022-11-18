# Analysis of publications citing/using the Human Disease Ontology

# Setup -------------------------------------------------------------------
library(here)
library(tidyverse)
library(googlesheets4)
library(DO.utils)
library(hues)
library(ggvenn)



# SET output ---------------------------------------------------------
data_dir <- here::here("data/citedby/analysis")
graphics_dir <- here::here("graphics/citedby/analysis")


if (!dir.exists(data_dir)) {
  dir.create(data_dir, recursive = TRUE)
}

if (!dir.exists(graphics_dir)) {
  dir.create(graphics_dir, recursive = TRUE)
}



# Load Data ------------------------------------------------------------
# cited by Google Sheet
gs <- "1wG-d0wt-9YbwhQTaelxqRzbm4qnu11WDM2rv3THy5mY"
cb_sheet <- "cited_by"

cb_data <- googlesheets4::read_sheet(gs, sheet = cb_sheet, col_type = "c") %>%
  dplyr::mutate(
    dplyr::across(dplyr::matches("_(dt|date)$"), readr::parse_guess)
  )

# time to review file
review_time <- readr::read_csv(file.path(data_dir, "time_to_review.csv"))



# Plot cited by counts over time ------------------------------------------

g_cb <- DO.utils::plot_citedby(
  data_file = here::here("data/citedby/DO_citedby.csv"),
  out_dir = NULL,
  w = 8,
  h = 5.6
) +
  scale_fill_manual(
    name = "Type",
    values = hues::iwanthue(6),
    guide = ggplot2::guide_legend(reverse = TRUE)
  ) +
  theme_minimal() +
  labs(x = "Year", y = "Publications")

ggsave(
  plot = g_cb,
  filename = file.path(graphics_dir, "DO_cited_by_count.png"),
  width = 5,
  height = 3.5,
  dpi = 600
)



# MyNCBI collection - Uses not citing DO (< 2021-08) ----------------------

ncbi_cites <- cb_data %>%
  dplyr::filter(
    stringr::str_detect(source, "ncbi"),
    pub_date < as.Date("2021-08-01")
    ) %>%
  dplyr::mutate(cites_DO = !is.na(cites)) %>%
  dplyr::count(cites_DO) %>%
  dplyr::mutate(pct = round(n / sum(n) * 100, 1))

readr::write_csv(
  ncbi_cites,
  file.path(data_dir, "MyNCBI_collection_cites-mid2021.csv")
)


# "cited by" counts by source and overlap ---------------------------------

# counts
cb_src_count <- cb_data %>%
  dplyr::mutate(source = stringr::str_remove(source, "-[^ ;]+")) %>%
  DO.utils::count_delim(source, delim = "; ")

readr::write_csv(cb_src_count, file.path(data_dir, "citedby_source_count.csv"))

# overlap with venn diagram
cb_src <- cb_data %>%
  dplyr::mutate(
    id = dplyr::row_number(),
    source = stringr::str_remove(source, "-[^ ;]+")
  ) %>%
  DO.utils::lengthen_col(source, delim = "; ") %>%
  dplyr::select(id, source)

src <- unique(cb_src$source)
g_src_venn <- purrr::map(src, ~ cb_src$id[cb_src$source == .x]) %>%
  purrr::set_names(
    nm = dplyr::recode(
      src,
      ncbi_col = "MyNCBI collection",
      pubmed = "PubMed",
      scopus = "Scopus"
    )
  ) %>%
  ggvenn(
    fill_color = hues::iwanthue(3, random = TRUE),
    stroke_size = 0.5,
    set_name_size = 4,
    text_size = 4
  )

ggsave(
  plot = g_src_venn,
  filename = file.path(graphics_dir, "citedy_source_overlap-venn.png"),
  dpi = 600,
  width = 7,
  height = 7
)



# Analysis of time it takes for review/curation ---------------------------

time_anal <- review_time %>%
  dplyr::mutate(time_per_pub = time_min / pubs_reviewed) %>%
  dplyr::group_by(type) %>%
  dplyr::summarize(
      value = as.numeric(summary(time_per_pub)),
      output = c("Min.", "1st Qu.", "Median", "Mean", "3rd Qu.", "Max.")
  ) %>%
  dplyr::ungroup() %>%
  tidyr::pivot_wider(
    names_from = output,
    values_from = value
  )

readr::write_csv(time_anal, file.path(data_dir, "review_time_summary.csv"))



# Analysis: 2021-09 to 2022-09 --------------------------------------------

cb_tidy <- cb_data %>%
  dplyr::filter(
    pub_date > as.Date("2021-08-31"),
    pub_date < as.Date("2022-10-01")
  ) %>%
  dplyr::mutate(
    status = dplyr::case_when(
      !is.na(uses_DO) ~ "reviewed",
      stringr::str_detect(review_notes, "paywall") ~ "inaccessible",
      TRUE ~ "not reviewed"
    ),
    uses_DO = stringr::str_remove(uses_DO, ",.*"),
    source = stringr::str_replace_all(source, "(ncbi_col)-[^ ;]", "\\1"),
    cites_DO = stringr::str_detect(source, "pubmed|scopus")
  )

# save review status + use
status_use <- cb_tidy %>%
  dplyr::count(status, uses_DO) %>%
  dplyr::arrange(status, dplyr::desc(n))

readr::write_csv(status_use, file.path(data_dir, "status_uses_count.csv"))


# limit remaining analysis to publications that use DO only
cb_use <- cb_tidy %>%
  dplyr::filter(uses_DO %in% c("yes", "minor"))

use_type <- cb_use %>%
  DO.utils::count_delim(use_type, delim = "|", sort = TRUE)

readr::write_csv(use_type, file.path(data_dir, "use_type_count.csv"))


role <- cb_use %>%
  dplyr::filter(!stringr::str_detect(use_type, "review|anal")) %>%
  DO.utils::count_delim(tool_role, delim = "|") %>%
  dplyr::arrange(dplyr::desc(n))

readr::write_csv(role, file.path(data_dir, "tool_roles_count.csv"))


ra <- cb_use %>%
  DO.utils::count_delim(research_area, delim = "|") %>%
  dplyr::arrange(dplyr::desc(n), research_area)

readr::write_csv(ra, file.path(data_dir, "research_area_count.csv"))


disease <- cb_use %>%
  dplyr::count(disease) %>%
  dplyr::arrange(dplyr::desc(n), disease)

readr::write_csv(disease, file.path(data_dir, "disease_count.csv"))

# Summarize use cases (all time & within last year) -----------------------

use_case <- googlesheets4::read_sheet(
  gs,
  "DO_website_user_list",
  col_types = "c"
)

use_case_last_yr <- cb_tidy %>%
  dplyr::filter(!is.na(tool_ID))

use_case_counts <- use_case %>%
  dplyr::filter(added == "TRUE") %>%
  dplyr::mutate(
    added_recent = tool_ID %in% use_case_last_yr$tool_ID & !duplicated(tool_ID)
  ) %>%
  dplyr::group_by(type) %>%
  dplyr::summarize(
    Total = length(tool_ID),
    "Added in Last Year" = sum(added_recent)
  ) %>%
  dplyr::ungroup() %>%
  dplyr::mutate(type = stringr::str_to_title(type)) %>%
  dplyr::rename(Type = type) %>%
  tibble::add_row(
    Type = "Total",
    Total = sum(.$Total),
    `Added in Last Year` = sum(.$`Added in Last Year`)
  )

readr::write_csv(
  use_case_counts,
  file.path(data_dir, "use_case_count.csv")
)
