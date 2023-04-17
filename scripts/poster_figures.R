# create stacked bar charts for poster

library(here)
library(tidyverse)
library(DO.utils)

poster_dir <- here::here("graphics/poster")
citedby_data <- here::here("data/citedby/DO_citedby-2023_Apr.csv")

# get manual & cited by counts
collect_df <- readr::read_csv(
  here::here("data/citedby/analysis/citedby_source_count.csv")
) %>%
  dplyr::mutate(
    source = dplyr::if_else(source == "ncbi_col", "MyNCBI", "cited by")
  ) %>%
  dplyr::count(source, wt = n)

# add search count
search_res <- readr::read_csv(
  here::here("data/lit_search/src_comparison.csv")
)
collect_df <- collect_df %>%
  tibble::add_row(source = "search", n = max(search_res$id))


# create record collection plots
collect_colors <- c("#9B5E52", "#8C58B0", "#92BC72")
g_collect <- list(
  record_collection = collect_df %>%
    tibble::add_row(source = "total", n = sum(collect_df$n)) %>%
    ggplot() +
    geom_col(
      aes(x = source, y = n, fill = source),
      color = "black", size = 2, width = 0.8
    ) +
    scale_fill_manual(values = c(collect_colors, "white")) +
    theme_void(),
  record_total = collect_df %>%
    ggplot() +
    geom_col(
      aes(x = 1, y = n, fill = source),
      color = "black", size = 2, width = 0.8
    ) +
    scale_fill_manual(values = collect_colors) +
    theme_void()
)

g_collect$record_pie <- g_collect$record_total +
  coord_polar("y", start = 0)

purrr::map2(
  g_collect,
  names(g_collect),
  ~ ggsave(
    path = poster_dir,
    filename = paste0(.y, ".svg"),
    plot = .x,
    device = "svg",
    width = 8,
    units = "cm",
    dpi = 1200
  )
)

collect_df %>%
  tibble::add_row(source = "total", n = sum(collect_df$n))


# standard used counts updated into 2023 (to get full count of 2022)
g_cb <- DO.utils::plot_citedby(citedby_data, out_dir = NULL) +
  scale_fill_manual(
    values = rev(hues::iwanthue(6)),
    name = "Type",
    limits = c("Article", "Clinical Trial", "Conference", "Book", "Review",
               "Other")
    ) +
  scale_x_continuous(limits = c(2004, 2023), expand = c(0, 0)) +
  theme(
    text = element_text(size = 24),
    legend.position = "bottom"
  )

ggsave(
  path = poster_dir,
  filename = "citedby.svg",
  plot = g_cb,
  device = "svg",
  width = 23.015,
  height = 17,
  units = "cm",
  dpi = 600
)


# estimate of manual vs automated cited by use counts 2023
cb <- readr::read_csv(
  citedby_data,
  col_types = readr::cols(
    pub_date = readr::col_date(),
    added_dt = readr::col_datetime(),
    .default = readr::col_character()
  )
) %>%
  dplyr::mutate(
    Year = lubridate::year(.data$pub_date),
    pub_type = DO.utils:::clean_pub_type(.data$pub_type),
    From = factor(
      dplyr::if_else(
        stringr::str_detect(source, "ncbi"),
        "Old method alone",
        "Added with DO.utils"
      ),
      levels = c("Added with DO.utils", "Old method alone")
    )
  )

g_cb_diff <- ggplot(data = cb) +
  geom_bar(aes(x = Year, fill = From), width = 0.8, position = "stack") +
  scale_fill_manual(
    name = NULL,
    values = c(unname(DO_colors["sat_light"]), "#304558"),
    guide = guide_legend(reverse = TRUE)
  ) +
  labs(y = NULL) +
  theme_DO(base_size = 24) +
  scale_x_continuous(limits = c(2004, 2023), expand = c(0, 0)) +
  theme(legend.position = "bottom")

ggsave(
  path = poster_dir,
  filename = "citedby-improvement.svg",
  plot = g_cb_diff,
  device = "svg",
  width = 23.015,
  height = 17,
  units = "cm",
  dpi = 600
)

# Evaluation results figure
eval_plot <- function(x, facet = NULL, ...) {
  g_colors <- hues::iwanthue(dplyr::n_distinct(x[[1]]))
  g <- ggplot(
    x,
    aes(x = 1, y = pct, fill = reorder(.data[[names(x)[1]]], pct))
  ) +
    geom_col(color = "black", size = 2, width = 0.8) +
    geom_text(
      aes(label = pct),
      position = position_stack(vjust = 0.5),
      size = 24
    ) +
    scale_fill_manual(values = g_colors) +
    theme_void(base_size = 24)

  if (!is.null(facet)) {
    g <- g + facet_wrap({{ facet }})
  }

  g
}


research_area <- readr::read_csv(
  here::here("data/poster/research_area.csv")
)%>%
  dplyr::select(!dplyr::matches("_orig|group")) %>%
  dplyr::filter(., if_any(1, .fns = ~ !is.na(.x))) %>%
  dplyr::group_by(area) %>%
  dplyr::mutate(pct = round(n / sum(n) * 100, 0)) %>%
  dplyr::ungroup() %>%
  dplyr::arrange(area, dplyr::desc(pct))

# area pct
research_area %>%
  dplyr::count(area, wt = n) %>%
  dplyr::mutate(pct = round(n / sum(n) * 100, 0))

g_research <- eval_plot(research_area, facet = "area")

ggsave(
  path = poster_dir,
  filename = "research_area.svg",
  plot = g_research,
  device = "svg",
  height = 7.6194,
  units = "cm",
  dpi = 600
)



# EXTRA -------------------------------------------------------------------

eval_dir <- here::here("data/poster")
eval_files <- list.files(eval_dir)

eval_res <- purrr::map(
  eval_files,
  function(.x) {
    df <- readr::read_csv(file.path(eval_dir, .x)) %>%
      dplyr::select(!dplyr::matches("_orig|group")) %>%
      dplyr::filter(., if_any(1, .fns = ~ !is.na(.x))) %>%
      dplyr::arrange(dplyr::across())
    if ("n" %in% names(df)) {
      df <- dplyr::mutate(df, pct = round(n / sum(n) * 100, 0))
    }
    df
  }
) %>%
  purrr::set_names(tools::file_path_sans_ext(eval_files))

purrr::map2(
  g_eval,
  names(g_eval),
  ~ ggsave(
    path = poster_dir,
    filename = paste0(.y, ".svg"),
    plot = .x,
    device = "svg",
    width = 8,
    units = "cm",
    dpi = 1200
  )
)

# as pie charts
g_eval_pie <- purrr::map(g_eval, ~ .x + coord_polar("y", start = 0))

purrr::map2(
  g_eval_pie,
  names(g_eval_pie),
  ~ ggsave(
    path = poster_dir,
    filename = paste0(.y, "_pie.svg"),
    plot = .x,
    device = "svg",
    width = 8,
    units = "cm",
    dpi = 1200
  )
)

rev_time <- readr::read_csv(
  here::here("data/citedby/analysis/review_time_summary.csv")
) %>%
  dplyr::select(1, mean = Mean)
