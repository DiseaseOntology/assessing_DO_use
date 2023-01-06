# Estimate use of DO in RNA research over time

library(here)
library(tidyverse)
library(googlesheets4)


# Data locations ----------------------------------------------------------

citedby_gs <- "1soEnbGY2uVVDEC_xKOpjs9WQg-wQcLiXqmh_iJ-2qsM"

graphics_dir <- here::here("graphics/citedby")


# Quick RNA analysis ------------------------------------------------------

citedby_df <- googlesheets4::read_sheet(
  citedby_gs,
  sheet = "cited_by",
  col_types = "c"
) %>%
  dplyr::mutate(
    dplyr::across(dplyr::matches("_(dt|date)$"), readr::parse_guess),
    pub_yr = lubridate::year(pub_date),
    rna = stringr::str_detect(title, "RNA")
  )

# custom match function
str_detect_ci <- function(string, pattern) {
  stringr::str_detect(string, stringr::regex(pattern, ignore_case = TRUE))
}

rna <- citedby_df %>%
  dplyr::filter(stringr::str_detect(title, "RNA")) %>%
  dplyr::mutate(
    type = dplyr::case_when(
      # order does matter here --> trying to go from specific to general
      str_detect_ci(title, "(compet.*endo.*|ce.{0,2})RNA") ~ "ceRNA",
      str_detect_ci(title, "piwi.*RNA") ~ "piRNA",
      str_detect_ci(title, "circ(ular)?.*RNA") ~ "circRNA",
      str_detect_ci(title, "(small.?nucleolar.*|sno.{0,2})RNA") ~ "snoRNA",
      str_detect_ci(title, "(extracell.*|ex.{0,2})RNA") ~ "exRNA",
      str_detect_ci(title, "small(.?non.?coding.?)?.{0,2}RNA") ~ "small RNA",
      str_detect_ci(title, "mi(cro)?.{0,2}RNA") ~ "miRNA",
      str_detect_ci(title, "(long.?non.?coding.*|lnc.{0,2})RNA") ~ "lncRNA",
      str_detect_ci(title, "(non.?coding.*|nc.{0,2})RNA") ~ "ncRNA",
      str_detect_ci(title, "RNA([^ ]{0,2}i|.*interfer)") ~ "RNAi",
      str_detect_ci(title, "(expression.*)?m?RNA|RNA([^ ]{0,2}seq|.*expression)") ~ "RNA-seq",
      TRUE ~ NA_character_
    ),
    type_group = dplyr::case_when(
      type %in% c("miRNA", "piRNA", "small RNA", "snoRNA") ~ "small ncRNA",
      type %in% c("lncRNA", "circRNA") ~ "lncRNA",
      type == "ncRNA" ~ "unspecified ncRNA",
      TRUE ~ type
    ),
    use = dplyr::if_else(
      str_detect_ci(title, "database|db|:|tool"),
      "Resource",
      "Analysis"
    )
  ) %>%
  tidyr::replace_na(list(type = "unknown")) %>%
  # exclude uses of RNA
  dplyr::filter(!type %in% c("RNAi", "RNA-seq"))


# simple plot
g_rna <- ggplot(rna) +
  geom_bar(aes(x = pub_yr), width = 0.8) +
  labs(x = "Year", y = "Publications")

ggsave(
  plot = g_rna,
  filename = file.path(graphics_dir, "RNA_pubs_over_time.png"),
  device = "png",
  dpi = 600,
  width = 4,
  height = 3,
  bg = "white"
)


# plot by type
g_rna_type <- rna %>%
  # exclude uses of RNA
  dplyr::filter(!type %in% c("RNAi", "RNA-seq")) %>%
  dplyr::mutate(
    type = factor(
      type,
      levels = rev(c("miRNA", "lncRNA", "circRNA", "ncRNA", "exRNA", "ceRNA",
                     "small RNA", "snoRNA", "piRNA"))
    )
  ) %>%
  ggplot() +
  geom_bar(aes(x = pub_yr, fill = type), width = 0.8) +
  scale_fill_manual(name = "Type", values = hues::iwanthue(9)) +
  facet_wrap(~ type_group) +
  labs(x = "Year", y = "Publications")

ggsave(
  plot = g_rna_type,
  filename = file.path(graphics_dir, "RNA_pubs_over_time-by_type.png"),
  device = "png",
  dpi = 600,
  bg = "white"
)


# plot by resource/primary (estimated)

g_use <- rna %>%
  dplyr::mutate(

  ) %>%
  ggplot() +
  geom_bar(aes(x = pub_yr), width = 0.8) +
  facet_wrap(~ use) +
  labs(x = "Year", y = "Publications")

ggsave(
  plot = g_use,
  filename = file.path(graphics_dir, "RNA_pubs_over_time-by_pub_type.png"),
  device = "png",
  dpi = 600,
  bg = "white"
)
