# DO search results

# Setup -------------------------------------------------------------------

library(here)
library(tidyverse)
library(europepmc)
library(rentrez)
library(DO.utils)

# make functions safe --> to keep code running if errors
search_pm_safely <- purrr::safely(DO.utils::search_pubmed)
search_pmc_safely <- purrr::safely(DO.utils::search_pmc)
search_epmc_safely <- purrr::safely(europepmc::epmc_search)


# Define Searches & Output Location ---------------------------------------

outdir <- "data/lit_search"
if (!dir.exists(outdir)) {
  dir.create(outdir, recursive = TRUE)
}

search_terms <- list(
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


# Explore Europe PMC hit counts (+/- synonyms) ----------------------------

search_blank <- tibble::tibble(
  name = names(search_terms),
  term = search_terms
)

epmc_n <- search_blank %>%
  dplyr::mutate(
    w_synonym = purrr::map_dbl(
      term,
      ~ europepmc::epmc_hits(.x, synonym = TRUE)
    ),
    wo_synonym = purrr::map_dbl(
      term,
      ~ europepmc::epmc_hits(.x, synonym = FALSE)
    )
  )

# NOTE: europepmc::epmc_hits doesn't accept synonym, despite what documentation
#   suggests.


# GET Europe PMC search results -------------------------------------------

# without synonyms
epmc_res <- purrr::map(
  search_terms,
  ~ search_epmc_safely(.x, limit = 10000, synonym = FALSE)
) %>%
  purrr::set_names(names(search_terms)) %>%
  purrr::transpose() %>%
  purrr::simplify_all()

epmc_df <- dplyr::bind_rows(epmc_res$result, .id = "search_id")

# with synonyms -> on 2021-08-23 10 more results with ns_id  ("doid")
epmc_syn_res <- purrr::map(
  search_terms,
  ~ search_epmc_safely(.x, limit = 10000, synonym = TRUE)
) %>%
  purrr::set_names(names(search_terms)) %>%
  purrr::transpose() %>%
  purrr::simplify_all()

epmc_syn_df <- dplyr::bind_rows(epmc_syn_res$result, .id = "search_id")

epmc_diff <- dplyr::anti_join(epmc_syn_df, epmc_df)

# save results
save(epmc_res, epmc_syn_res, file = here::here(outdir, "epmc_res.RData"))
readr::write_csv(epmc_syn_df, here::here(outdir, "epmc_with_synonym-mult.csv"))


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
save(pm_res, file = here::here(outdir, "pubmed.RData"))
readr::write_csv(pm_df, here::here(outdir, "pubmed-mult.csv"))


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
          pmid = as.numeric(DO.utils::extract_pmid(res)),
          search_id = nm
        )
      }
  }
) %>%
  dplyr::select(search_id, pmid, pmcid)

# save results
save(pmc_res, file = here::here(outdir, "pmc.RData"))
readr::write_csv(pmc_df, here::here(outdir, "pmc-mult.csv"))


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
  )

readr::write_csv(search_n, here::here(outdir, "search_res_n.csv"), na = "0")


# FYI ---------------------------------------------------------------------

actual_search <- tibble::tibble(
  search_id = names(search_terms),
  search_term = unlist(search_terms),
  pm = purrr::map_chr(pm_res$result, ~.x$QueryTranslation),
  pmc = purrr::map_chr(pmc_res$result, ~.x$QueryTranslation)
)

readr::write_csv(actual_search, here::here(outdir, "actual_search_term.csv"))
