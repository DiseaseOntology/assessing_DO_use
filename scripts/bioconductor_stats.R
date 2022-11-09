# Get Bioconductor package stats

library(here)
library(tidyverse)
library(DO.utils)
library(lubridate)


# SET pkg names & types (both required) -----------------------------------
pkg_nm <- c("DOSE", "DO.db")
pkg_type <- c("software", "annotation")


# SET yrs desired for stats --------------------------------------------
yrs <- 2011:2022


# SET save dirs & filenames ------------------------------------------------
data_dir <- here::here("data")
plot_dir <- here::here("graphics")
stats_all_file <- file.path(data_dir, "bioc_DO_stats.csv")
stats_1y_file <- file.path(data_dir, "bioc_DO_stats-1yr-distinctIP.csv")
plot_all_file <- file.path(plot_dir, "bioc_DO_stats-distinctIP.png")
plot_1y_file <- file.path(plot_dir, "bioc_DO_stats-1yr-distinctIP.png")



# Create output dirs if they don't exist ----------------------------------
if (!dir.exists(data_dir)) {
  dir.create(data_dir, recursive = TRUE)
}

if (!dir.exists(plot_dir)) {
  dir.create(plot_dir, recursive = TRUE)
}


# Get & save stats of bioconductor pkgs using DO --------------------------

do_bioc <- purrr::map(
  as.character(yrs),
  ~ DO.utils::get_bioc_pkg_stats(
    pkg_nm,
    pkg_type,
    yr = .x,
    delay_rng = 1:2
  )
) %>%
  dplyr::bind_rows() %>%
  dplyr::filter(Month != "all") %>%
  dplyr::arrange(pkg, Year)

# save stats info
readr::write_csv(do_bioc, stats_all_file)


# Plot stats --------------------------------------------------------------

do_bioc_tidy <- do_bioc %>%
  # drop data from incomplete months (current month onward)
  dplyr::filter(
    !(
      Year == lubridate::year(lubridate::today()) &
        match(Month, month.abb) >= lubridate::month(lubridate::today())
    )
  ) %>%
  dplyr::mutate(
    date = lubridate::ym(paste(Year, Month, sep = "-")),
  ) %>%
  tidyr::pivot_longer(
    cols = dplyr::starts_with("Nb"),
    names_to = "metric",
    names_prefix = "Nb_of_",
    values_to = "count"
  )

# plot all time (just for viewing)
ggplot(do_bioc_tidy, aes(x = date, y = count, color = pkg)) +
  geom_line() +
  geom_smooth(method = "loess", formula = "y ~ x", size = 0.4) +
  scale_x_date(date_labels = "%Y-%b") +
  facet_wrap(~ metric) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))


# plot all time (distinct IP only) & save
do_bioc_ip <- dplyr::filter(do_bioc_tidy, metric == "distinct_IPs")

g_all <- ggplot(do_bioc_ip, aes(x = date, y = count, color = pkg)) +
  geom_line() +
  scale_x_date(name = "Year", date_labels = "%Y") +
  scale_y_continuous(
    name = "Downloads / Month",
    labels = ~ format(.x, big.mark = ",")
  ) +
  theme_classic() +
  theme(
    axis.text.x = element_text(size = 12),
    axis.text.y = element_text(size = 12),
    legend.text = element_text(size = 12),
    axis.title = element_text(size = 14),
    legend.title = element_blank()
  )

ggsave(
  filename = plot_all_file,
  plot = g_all,
  device = tools::file_ext(plot_all_file),
  width = 5,
  height = 3.75,
  dpi = 600
)

# Examine distinct IP download stats over the last yr ----------------------
# NOTE: Does not include current month

# limit to distinct IPs over last year
do_bioc_ip_1y <- do_bioc_ip %>%
  dplyr::filter(
    date >= (max(date) - 340),
    metric == "distinct_IPs"
  ) %>%
  dplyr::select(!metric)


# save last yr (12 month) results
readr::write_csv(
  dplyr::rename(do_bioc_ip_1y, distinctIP_downloads = count),
  stats_1y_file
)


# plot & save
sorted_dates <- unique(do_bioc_ip_1y$date) %>%
  sort()
month_breaks <- sorted_dates[1:length(sorted_dates) %% 2 == 1]

g_1y <- ggplot(do_bioc_ip_1y, aes(x = date, y = count, color = pkg)) +
  geom_line() +
  scale_x_date(
    name = "Year",
    breaks = month_breaks,
    date_labels = "%b\n%Y"
  ) +
  scale_y_continuous(
    name = "Downloads / Month",
    labels = ~ format(.x, big.mark = ",")
  ) +
  expand_limits(y = 0) +
  theme_classic() +
  theme(
    axis.text.x = element_text(size = 10),
    axis.text.y = element_text(size = 10),
    legend.text = element_text(size = 10),
    axis.title = element_text(size = 12),
    legend.title = element_blank()
  )

ggsave(
  filename = plot_1y_file,
  plot = g_1y,
  device = tools::file_ext(plot_1y_file),
  width = 4,
  height = 3,
  dpi = 600
)
