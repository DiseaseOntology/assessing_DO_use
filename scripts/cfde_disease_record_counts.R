# Count CFDE Samples from each DCC with disease annotations

# To execute this script the data must be downloaded manually as follows:
# Set CFDE Summary Review (https://www.nih-cfde.org/) with the drop-down menus
# as follows:
#   Y-axis: “Sample Count”
#   X-axis: “CF Program”
#   Group by: “Disease”
# Save to "data/cfde/CFDE_data-program_sample_disease.csv" and run this script.

library(here)
library(tidyverse)
library(scales)
library(hues)

data_dir <- here::here("data/cfde")
cfde_input <- file.path(data_dir, "CFDE_data-program_sample_disease.csv")
cfde_summary_file <- file.path(data_dir, "cfde_disease_counts.csv")
cfde_plot <- here::here("graphics/cfde_disease.png")


cfde <- readr::read_csv(cfde_input)

cfde_tidy <- cfde %>%
  tidyr::pivot_longer(
    cols = -dcc,
    names_to = "disease",
    values_to = "sample_n"
  ) %>%
  dplyr::mutate(
    disease_status = dplyr::case_when(
      stringr::str_detect(disease, "obsolete") ~ "obsolete",
      disease == "Not Specified" ~ "absent",
      TRUE ~ "active"
    )
  )

# none when run (2022-11-09); not sure why obsolete diseases are even here
cfde_obsolete <- cfde_tidy %>%
  dplyr::filter(disease_status == "obsolete", sample_n > 0)

cfde_n <- cfde_tidy %>%
  dplyr::count(dcc, disease_status, wt = sample_n, name = "sample_n") %>%
  dplyr::group_by(dcc) %>%
  dplyr::mutate(
    sample_total = sum(sample_n),
    pct_total = round(sample_n / sample_total * 100, 1),
  ) %>%
  dplyr::ungroup() %>%
  dplyr::filter(disease_status == "active") %>%
  dplyr::select(-disease_status) %>%
  dplyr::arrange(dplyr::desc(sample_total), dplyr::desc(sample_n), dcc)

cfde_n %>%
  dplyr::mutate(
    dplyr::across(dplyr::starts_with("sample"), ~ format(.x, big.mark = ","))
  ) %>%
  dplyr::rename(
    DCC = dcc, "Disease Annotated Samples" = sample_n,
    "Total Samples" = sample_total, "Percent Disease Annotated" = pct_total
  ) %>%
readr::write_csv(cfde_summary_file)


g <- cfde_n %>%
  # exclude programs/DCCs without data from plot
  dplyr::filter(sample_total != 0) %>%
  dplyr::mutate(
    pct_total = paste0(pct_total, "%"),
    dcc = factor(dcc, levels = dcc),
    sample_diff = sample_total - sample_n
  ) %>%
  dplyr::select(-sample_total) %>%
  tidyr::pivot_longer(
    cols = c(sample_n, sample_diff),
    names_to = "type",
    names_prefix = "sample_",
    values_to = "count"
  ) %>%
  dplyr::mutate(`Disease Annotated` = type == "n") %>%
  ggplot(aes(x = dcc)) +
  geom_col(aes(y = count, fill = `Disease Annotated`)) +
  geom_text(
    aes(y = 0, label = pct_total),
    vjust = 1,
    nudge_y = -1000000,
    size = 3.5
  ) +
  scale_y_continuous(
    name = "Samples",
    labels = scales::label_number(suffix = "M", scale = 1e-6),
    expand = expansion(mult = c(0.06, 0.05))
  ) +
  scale_x_discrete(name = "CFDE Program") +
  scale_fill_manual(values = c("grey70", "grey30")) +
  theme_minimal() +
  theme(
    axis.text = element_text(size = 10),
    axis.text.x = element_text(angle = 45, hjust = 1),
    panel.grid.major.x = element_blank(),
    legend.position = "top",
    legend.text = element_text(size = 10),
    legend.box.spacing = unit(0, units = "points")
  )

ggsave(
  filename = cfde_plot,
  plot = g,
  device = "png",
  dpi = 600,
  width = 4.5,
  height = 3.5,
  bg = "white"
)
