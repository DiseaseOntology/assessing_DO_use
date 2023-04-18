# Script Descriptions

The scripts below were used in the case study to assess use of the Human Disease Ontology in the publication:

> J. Allen Baron, Lynn M Schriml, _Assessing resource use: a case study with the Human Disease Ontology_, Database, Volume 2023, 2023, baad007. PMID:36856688, https://doi.org/10.1093/database/baad007.

Scripts are found in the `scripts/` directory and listed below under the section of the case study they apply to, with a brief description. Later in this document a description of what each script accomplished and its file inputs and outputs are given.

## Introduction

1. [citedby_manual_count_plot.R](scripts/citedby_manual_count_plot.R)

## Obtain Use Records

1. [citedby_full_procedure.R](scripts/citedby_full_procedure.R): used to obtain "cited by" and MyNCBI collection records.
2. [pub_searches.R](scripts/pub_searches.R): used to obtain and analyze search records.
  - NOTE: Also produced figures comparing different search phrases at Europe PMC (Fig. 3) and comparing searches across sources (Fig. 4) used in the "Obtaining Records" portion of the case study.


## Curating Use Information

No scripts were used in curation. Instead, refer to the [DO_uses-published_2022](https://docs.google.com/spreadsheets/d/1soEnbGY2uVVDEC_xKOpjs9WQg-wQcLiXqmh_iJ-2qsM/edit?usp=share_link) Google Sheet to review curated information.


## Evaluate Use

1. [citedby_analysis.R](scripts/citedby_analysis.R)
  - NOTE: The publications citing the DO by year figure produced by this script (Fig. 1) was used in the introduction of the publication.
2. [citedby_RNA.R](scripts/citedby_RNA.R)
3. [compare_citedby_search.R](scripts/compare_citedby_search.R)


# Detailed Script Descriptions

1. citedby_manual_count_plot.R
	- **Purpose:** Generate plots showing the total publications citing official Disease Ontology publications from various providers.
	- **Input:**
	  1. data/citedby/counts/citedby_counts-manual.csv
	- **Output:**
    2. data/citedby/counts/citedby_counts-manual_smry.csv
    3. graphics/citedby/citedby_manual_comparison_2021.png: **Figure 2**
    4. graphics/citedby/citedby_manual_comparison_2022.png

2. citedby_full_procedure.R
	- **Purpose:** Obtain publication records from PubMed and Scopus that cite one or more of the official DO publications (referred to as "cited by"), load DO's MyNCBI collection, merge all of the records from these sources together, and append results to existing [DO_uses-published_2022](https://docs.google.com/spreadsheets/d/1soEnbGY2uVVDEC_xKOpjs9WQg-wQcLiXqmh_iJ-2qsM/edit?usp=share_link) Google Sheet.
	- **Input:**
		1. data/citedby/collection.txt: 2022-11-17 download of [DO's MyNCBI collection](https://www.ncbi.nlm.nih.gov/sites/myncbi/lynn.schriml.1/collections/49204559/public/).
	- **Output:**
		1. data/citedby/do_cb_pm_summary_by_id.rda: full, untidied PubMed "cited by" results, obtained 2022-11-10.
		2. data/citedby/do_cb_scop_by_id.rda: full, untidied Scopus "cited by" results, obtained 2022-11-10.
		3. data/citedby/do_collection_pm_summary.rda: full, untidied MyNCBI collection publication summary results from PubMed, obtained 2022-11-10.
		4. data/citedby/do_collection_pmc_summary.rda: full, untidied MyNCBI collection publication summary results from PubMed Central (PMC), obtained 2022-11-10.
		5. data/citedby/DO_citedby.csv: merged and tidied citations from all sources.


3. pub_searches.R
	- **Purpose:** Obtain publication records via search against PubMed, PubMed Central (PMC), and Europe PMC databases that _may_ have used the DO.
	- **Input:** None
	- **Output:**
		- Raw search results, obtained 2022-11-09:
			1. Europe PMC: data/lit_search/epmc_search_raw.RData
			2. PubMed: data/lit_search/pubmed_search_raw.RData
			3. PMC: data/lit_search/pmc_search_raw.RData
		- Raw results for additional identifiers, obtained 2022-11-09:
			4. PubMed: data/lit_search/pm_search_raw-IDs.RData
			5. PMC: data/lit_search/pmc_search_raw-IDs.RData
		- Tidied search results:
			6. Europe PMC: data/lit_search/epmc_search_results.csv
			7. PubMed: data/lit_search/pubmed_search_results.csv
			8. PMC:	data/lit_search/pmc_search_results.csv
		- The actual searches that each service converted a search phrase to:
		  9. data/lit_search/actual_search_terms.csv
		- Summary data:
		  10. data/lit_search/search_res_n.csv
			11. data/lit_search/src_comparison.csv
    - Graphics produced
			12. graphics/lit_search/epmc_search_overlap.png
			13. graphics/lit_search/epmc_search_overlap-min10.png: **Figure 3**
			14. graphics/lit_search/pmc_search_overlap.png
			15. graphics/lit_search/pm_search_overlap.png
			16. graphics/lit_search/search_src_overlap-venn.png
			17. graphics/lit_search/search_src_overlap-upset.png
			18. graphics/lit_search/total_hits-graph.png
			19. graphics/lit_search/total_hits-legend.png
			20. graphics/lit_search/total_hits-complete.png: **Figure 4**


4. citedby_analysis.R
	- **Purpose:** Analysis of curated information as part of the "Evaluation" step of the workflow.
	- **Input:**
	  1. [DO_uses-published_2022](https://docs.google.com/spreadsheets/d/1soEnbGY2uVVDEC_xKOpjs9WQg-wQcLiXqmh_iJ-2qsM/edit?usp=share_link) Google Sheet
	  2. data/citedby/analysis/time_to_review.csv (has curation review time data)
	- **Output:**
	  - Summary counts and statistics:
      1. data/citedby/analysis/MyNCBI_collection_cites-mid2021.csv
      2. data/citedby/analysis/citedby_source_count.csv
      3. data/citedby/analysis/review_time_summary.csv
      4. data/citedby/analysis/status_uses_count.csv: **Table 2**
      5. data/citedby/analysis/use_type_count.csv: **Table 3**
      6. data/citedby/analysis/tool_roles_count.csv: **Supplementary Table 1**
      7. data/citedby/analysis/research_area_count.csv: **Supplementary Table 2**
      8. data/citedby/analysis/disease_count.csv: **Supplementary Table 3**
      9. data/citedby/analysis/use_case_count.csv: Count of resources added to "Use Case" page on disease-ontology.org.
    - Graphics
      10. graphics/citedby/analysis/DO_cited_by_count.png: **Figure 1**
      11. graphics/citedby/analysis/citedy_source_overlap-venn.png


3. citedby_RNA.R
	- **Purpose:** Estimate use of DO in RNA research over time.
	- **Input:** [DO_uses-published_2022](https://docs.google.com/spreadsheets/d/1soEnbGY2uVVDEC_xKOpjs9WQg-wQcLiXqmh_iJ-2qsM/edit?usp=share_link) Google Sheet
	- **Output:**
    1. graphics/citedby/RNA_pubs_over_time.png: **Figure 5**
    2. graphics/citedby/RNA_pubs_over_time-by_type.png: **Supplementary Figure 1**
    3. graphics/citedby/RNA_pubs_over_time-by_pub_type.png

compare_citedby_search.R
	- **Purpose:** Compare "cited by" (including MyNCBI collection) and search results.
	- **Input:**
	  1. data/citedby/DO_citedby.csv
	  2. data/lit_search/src_comparison.csv
	  3. data/lit_search/epmc_search_results.csv
	- **Output:**
    4. data/cb_search_compare/citedby_search_comparison.csv
    5. data/cb_search_compare/search_uniq.csv
    6. graphics/cb_search_compare/citedby_search_comparison.png
    7. graphics/cb_search_compare/search_unique_pub_type.png



## Additional Scripts in this Repository

Three additional scripts in this repository were used to evaluate the impact of the DO _outside_ of published literature but these impact measures, specific to the DO, are not included in the publication.

1. [alliance_disease_record_counts.R](scripts/alliance_disease_record_counts.R): count of disease records in databases belonging to the [Alliance of Genome Resources](https://www.alliancegenome.org/).
2. [bioconductor_stats.R](scripts/bioconductor_stats.R): unique IP download statistics for DO-dependent R packages 'DOSE' and 'DO.db'.
3. [cfde_disease_record_counts.R](scripts/cfde_disease_record_counts.R): count of disease records in databases belonging to the [Common Fund Data Ecosystem](https://app.nih-cfde.org/) (CFDE).
4. [poster_figures.R](scripts/poster_figures.R): code used to make figures for poster presented at the 2023 Biocuration conference hosted by the [International Society for Biocuration](https://www.biocuration.org/).


### Applicable I/O Files

1. alliance_disease_record_counts.R
  - data/alliance/disease_counts-full_by_obj.csv
  - data/alliance/disease_counts-disobj_by_obj.csv
  - data/alliance/disease_counts-disease_by_obj.csv
  - data/alliance/disease_counts-unique_diseases.csv
  - graphics/alliance_disobj_plot.png
  - graphics/alliance_full_record_plot.png

2. bioconductor_stats.R
  - data/bioc_DO_stats.csv
  - data/bioc_DO_stats-1yr-distinctIP.csv
  - graphics/bioc_DO_stats-distinctIP.png
  - graphics/bioc_DO_stats-1yr-distinctIP.png

3. cfde_disease_record_counts.R
  - data/cfde/CFDE_data-program_sample_disease.csv
  - data/cfde/cfde_disease_counts.csv
  - graphics/cfde_disease.png
