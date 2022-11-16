# compare search results with cited by results

library(here)
library(tidyverse)
library(DO.utils)
library(ggvenn)
library(googlesheets4)


# Files -------------------------------------------------------------------

# Input
citedby_file <- here::here("data/citedby/DO_citedby.csv")

search_dir <- here::here("data/lit_search")
search_file <- file.path(search_dir, "src_comparison.csv")
epmc_file <- file.path(search_dir, "epmc_search_results.csv")


# Output
## Data
data_dir <- here::here("data/cb_search_compare")
if (!dir.exists(data_dir)) {
  dir.create(data_dir, recursive = TRUE)
}

comparison_file <- file.path(data_dir, "citedby_search_comparison.csv")
search_uniq_file <- file.path(data_dir, "search_uniq.csv")

## Graphics
graphics_dir <- here::here("graphics/cb_search_compare")
if (!dir.exists(graphics_dir)) {
  dir.create(graphics_dir, recursive = TRUE)
}

comparison_plot <- file.path(graphics_dir, "citedby_search_comparison.png")
search_uniq_plot <- file.path(graphics_dir, "search_unique_pub_type.png")

## Google Sheet
uniq_review_gs <- "1GPY6WR_rsRH0EFtay0H8V2yOHE1Owp1LwG6SzXM8TLM"


# Data preparation ---------------------------------------------------------

epmc_df <- readr::read_csv(
  epmc_file,
  col_types = readr::cols(.default = "c")
) %>%
  dplyr::rename(epmc_id = id) %>%
  dplyr::select(-search_id) %>%
  unique()

search_df <- readr::read_csv(
  search_file,
  col_types = readr::cols(id = "i", .default = "c")
) %>%
  # collapse to unique records
  DO.utils::collapse_col(src:epmc_id) %>%
  # only DOI has multiple matches / ID (refs to preprints), remove all but first
  dplyr::mutate(doi = stringr::str_remove(doi, "\\|.*")) %>%
  dplyr::mutate(from = "search")

citedby_df <- readr::read_csv(
  citedby_file,
  col_types = readr::cols(added_dt = "T", pub_date = "D", .default = "c")
) %>%
  dplyr::mutate(from = "citedby") %>%
  DO.utils::match_citations(search_df, add_col = "id") %>%
  dplyr::select(id, dplyr::everything())



# Comparison --------------------------------------------------------------

cb_match <- citedby_df %>%
  dplyr::filter(!is.na(id))
cb_uniq <- citedby_df %>%
  dplyr::filter(is.na(id)) %>%
  dplyr::mutate(id = dplyr::row_number() + max(search_df$id))

compare_df <- dplyr::bind_rows(
    cb_match,
    cb_uniq,
    search_df
) %>%
  dplyr::select(id, from, doi:pmcid) %>%
  DO.utils::collapse_col(from:pmcid) %>%
  dplyr::mutate(
    from = dplyr::if_else(stringr::str_detect(from, "\\|"), "both", from)
  )

# save comparison (no publication details)
readr::write_csv(compare_df, comparison_file)



# plot comparison & save
compare_list <- list(
  "Cited By" = compare_df$id[compare_df$from %in% c("citedby", "both")],
  "Search" = compare_df$id[compare_df$from %in% c("search", "both")]
)

g_venn <- ggvenn::ggvenn(
  compare_list,
  fill_color = hues::iwanthue(2, random = TRUE),
  stroke_size = 0.5,
  set_name_size = 4,
  text_size = 4
)

ggsave(
  plot = g_venn,
  filename = comparison_plot,
  device = tools::file_ext(comparison_plot),
  dpi = 600,
  width = 4,
  height = 4
)

# Details - Search Unique -------------------------------------------------

search_uniq <- search_df %>%
  dplyr::filter(!id %in% cb_match$id) %>%
  dplyr::left_join(
    .,
    dplyr::select(epmc_df, !pmid:doi),
    by = "epmc_id"
  ) %>%
  dplyr::mutate(
    pub_type = dplyr::case_when(
      is.na(pubType) ~ "unknown",
      stringr::str_detect(pubType, "preprint") ~ "preprint",
      stringr::str_detect(pubType, "case") ~ "case report",
      stringr::str_detect(pubType, "clinic") ~ "clinical trial",
      stringr::str_detect(pubType, "journal article") ~ "journal article",
      stringr::str_detect(pubType, "abstract") ~ "abstract",
      stringr::str_detect(pubType, "editorial") ~ "editorial",
      stringr::str_detect(pubType, "meeting|congress") ~ "meeting",
      TRUE ~ "other"
    )
  )

# save details
readr::write_csv(search_uniq, search_uniq_file)


# plot & save
g_pub_type <- search_uniq %>%
  dplyr::count(pub_type, sort = TRUE) %>%
  dplyr::mutate(
    # order largest to smallest
    pub_type = factor(pub_type, levels = rev(pub_type)),
    pct = paste0(round( n / sum(n) * 100, 1), "%")
  ) %>%
  ggplot() +
  geom_col(aes(x = pub_type, y = n)) +
  geom_text(aes(x = pub_type, y = n + 20, label = pct), size = 3, hjust = 0) +
  labs(x = "Publication Type", y = "Total Publications") +
  scale_y_continuous(
    labels = scales::label_comma(),
    expand = expansion(mult = c(0.05, 0.15))
  ) +
  theme_minimal() +
  coord_flip()

ggsave(
  plot = g_pub_type,
  filename = search_uniq_plot,
  device = tools::file_ext(comparison_plot),
  dpi = 600,
  width = 4,
  height = 3
)


# save subset (50) of journal results for review to googlesheet, if time
uniq_review <- search_uniq %>%
  dplyr::filter(pub_type == "journal article") %>%
  dplyr::filter(dplyr::row_number() %in% sample.int(nrow(.), 50)) %>%
  dplyr::select(id, title, pmid:epmc_id, pub_type, firstPublicationDate) %>%
  dplyr::mutate(
    dplyr::across(
      pmid:doi,
      ~ build_hyperlink(
        .x,
        dplyr::recode(
          dplyr::cur_column(),
          pmid = "pubmed",
          pmcid = "pmc_article"
        ),
        as = "gs"
      )
    )
  )

cols_out <- c("review_notes", "cites_DO", "uses_DO", "conflated_with", "id", "title",
              "pmid", "pmcid","doi", "epmc_id", "pub_type",
              "firstPublicationDate")

uniq_review <- uniq_review %>%
  DO.utils::append_empty_col(col = cols_out, order = TRUE)

googlesheets4::write_sheet(uniq_review, uniq_review_gs, sheet = "for_review")
