# Conducts literature searches for papers referring to the Human Disease
# Ontology by one of various identifiers.

# Setup -------------------------------------------------------------------

library(here)
library(tidyverse)
library(europepmc)
library(rentrez)
library(DO.utils)


# Define Output Location & Searches ---------------------------------------
data_dir <- here::here("data/lit_search")

search_terms <- c(
  ns_id = 'doid',
  full_name = '"human disease ontology"',
  generic_name = '"disease ontology"',
  lynn_custom = '"disease ontology" NOT IDO',
  website = '"disease-ontology.org"',
  ncbo = 'bioportal.bioontology.org/ontologies/doid',
  embl_ols = 'ebi.ac.uk/ols/ontologies/doid',
  iri = 'purl.obolibrary.org/obo/doid.owl',
  iri_no_ext = 'purl.obolibrary.org/obo/doid' ,
  ontobee = 'ontobee.org/ontology/doid',
  github = 'github.com/diseaseontology/humandiseaseontology',
  do_wiki = 'do-wiki.nubic.northwestern.edu/do-wiki/index.php/main_page',
  sourceforge = 'sourceforge.net/p/diseaseontology',
  wikipedia = 'en.wikipedia.org/wiki/disease_ontology'
)



# Support -----------------------------------------------------------------
if (!dir.exists(data_dir)) {
  dir.create(data_dir, recursive = TRUE)
}

# make functions safe --> to keep code running if errors
search_pm_safely <- purrr::safely(DO.utils::search_pubmed)
search_pmc_safely <- purrr::safely(DO.utils::search_pmc)
search_epmc_safely <- purrr::safely(europepmc::epmc_search)

search_blank <- tibble::tibble(
  name = names(search_terms),
  term = search_terms
)


# Explore Europe PMC hit counts (+/- synonyms) ----------------------------
epmc_n <- search_blank %>%
  dplyr::mutate(
    hits_no_synonym = purrr::map_dbl(
      term,
      ~ europepmc::epmc_hits(.x, synonym = FALSE)
    )
  )

# NOTE: europepmc::epmc_hits() doesn't use synonyms, despite what documentation
#   says. epmc_search() does and has ~ 11 more hits for `ns_id` search on
#   2022-10-22. It's sort of surprising that any of these searches would have
#   'synonyms'... not sure what they are or where they are from.


# GET Europe PMC search results -------------------------------------------
# Using with synonyms to match web results
epmc_res <- purrr::map(
  search_terms,
  ~ search_epmc_safely(.x, limit = 10000, synonym = TRUE)
) %>%
  purrr::set_names(names(search_terms)) %>%
  purrr::transpose() %>%
  purrr::simplify_all()

epmc_df <- dplyr::bind_rows(epmc_res$result, .id = "search_id")

# save results
save(epmc_res, file = file.path(data_dir, "epmc_search_raw.RData"))
readr::write_csv(epmc_df, file.path(data_dir, "epmc_search_results.csv"))


# GET PubMed search results -----------------------------------------------
# pubmed splits URLs replacing / with AND (probably close to the same in essence)
pm_res <- purrr::map(
  search_terms,
  ~ search_pm_safely(.x, retmax = 10000)
) %>%
  purrr::set_names(names(search_terms)) %>%
  purrr::transpose() %>%
  purrr::simplify_all()

pm_df <- pm_res$result %>%
  purrr::map(DO.utils::extract_pmid) %>%
  unlist() %>%
  tibble::tibble(
    search_id = names(.),
    pmid = .
  ) %>%
  dplyr::mutate(search_id = stringr::str_remove(search_id, "[0-9]+$"))

# save results
save(pm_res, file = file.path(data_dir, "pubmed_search_raw.RData"))
readr::write_csv(pm_df, file.path(data_dir, "pubmed_search_results.csv"))


# GET PMC search results --------------------------------------------------
pmc_res <- purrr::map(
  search_terms,
  ~ search_pmc_safely(.x, retmax = 10000, pmid = TRUE)
) %>%
  purrr::set_names(names(search_terms)) %>%
  purrr::transpose() %>%
  purrr::simplify_all()

pmc_df <- purrr::map2_dfr(
  .x = pmc_res$result,
  .y = names(pmc_res$result),
  function(res, nm) {
    missing_val <-
      if (rlang::is_empty(res$ids)) {
        NULL
      } else {
        tibble::tibble(
          pmcid = res$ids,
          pmid = as.numeric(suppressWarnings(DO.utils::extract_pmid(res))),
          search_id = nm
        )
      }
  }
) %>%
  dplyr::select(search_id, pmid, pmcid)

# save results
save(pmc_res, file = file.path(data_dir, "pmc_search_raw.RData"))
readr::write_csv(pmc_df, file.path(data_dir, "pmc_search_results.csv"))


# Count Results -----------------------------------------------------------
search_n <- dplyr::bind_rows(
  pm = dplyr::count(pm_df, search_id),
  pmc = dplyr::count(pmc_df, search_id),
  epmc = dplyr::count(epmc_df, search_id),
  .id = "db"
) %>%
  tidyr::pivot_wider(
    names_from = db,
    values_from = n
  ) %>%
  dplyr::left_join(search_blank, by = c("search_id" = "name"))

readr::write_csv(search_n, file.path(data_dir, "search_res_n.csv"), na = "0")


# Identify overlap in searches --------------------------------------------
epmc_pm_match <- DO.utils::match_citations(epmc_df, pm_df)
epmc_pmc_match <- DO.utils::match_citations(epmc_df, pmc_df)

# Actual searches performed -----------------------------------------------
actual_search <- tibble::tibble(
  search_id = names(search_terms),
  search_term = unlist(search_terms),
  pm = purrr::map_chr(pm_res$result, ~.x$QueryTranslation),
  pmc = purrr::map_chr(pmc_res$result, ~.x$QueryTranslation)
)

readr::write_csv(actual_search, file.path(data_dir, "actual_search_terms.csv"))
