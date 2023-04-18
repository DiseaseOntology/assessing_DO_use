# Script Descriptions

The scripts below were used in the case study to assess use of the Human Disease Ontology in the publication:

> J. Allen Baron, Lynn M Schriml, _Assessing resource use: a case study with the Human Disease Ontology_, Database, Volume 2023, 2023, baad007. PMID:36856688, https://doi.org/10.1093/database/baad007.

Scripts are found in the `scripts/` directory and listed below under the section of the case study they apply to, with a brief description. Later in this document a description of what each script accomplished and its file inputs and outputs are given.


## Obtain Use Records

1. [citedby_full_procedure.R](scripts/citedby_full_procedure.R): used to obtain "cited by" and MyNCBI collection records.
2. [pub_searches.R](scripts/pub_searches.R): used to obtain and analyze search records.

## Curating Use Information

No scripts were used in curation. Instead, open the [DO_uses-published_2022](https://docs.google.com/spreadsheets/d/1soEnbGY2uVVDEC_xKOpjs9WQg-wQcLiXqmh_iJ-2qsM/edit?usp=share_link) Google Sheet to review curated information.

## Evaluate Use

[citedby_RNA.R](scripts/citedby_RNA.R)
[citedby_analysis.R](scripts/citedby_analysis.R)
[citedby_manual_count_plot.R](scripts/citedby_manual_count_plot.R)
[compare_citedby_search.R](scripts/compare_citedby_search.R)


## Detailed Description of Scripts Used in Publication

1. citedby_full_procedure.R
	- **Purpose:** Obtain publication records from PubMed and Scopus that cite one or more of the official DO publications (referred to as "cited by"), load DO's MyNCBI collection, merge all of the records from these sources together, and append results to existing [DO_uses-published_2022](https://docs.google.com/spreadsheets/d/1soEnbGY2uVVDEC_xKOpjs9WQg-wQcLiXqmh_iJ-2qsM/edit?usp=share_link) Google Sheet.
	- **Input:**
		1. data/citedby/collection.txt: 2022-11-17 download of [DO's MyNCBI collection](https://www.ncbi.nlm.nih.gov/sites/myncbi/lynn.schriml.1/collections/49204559/public/).
	- **Output:**
		1. data/citedby/do_cb_pm_summary_by_id.rda: full, untidied PubMed "cited by" results, obtained 2022-11-10.
		2. data/citedby/do_cb_scop_by_id.rda: full, untidied Scopus "cited by" results, obtained 2022-11-10.
		3. data/citedby/do_collection_pm_summary.rda: full, untidied MyNCBI collection publication summary results from PubMed, obtained 2022-11-10.
		4. data/citedby/do_collection_pmc_summary.rda: full, untidied MyNCBI collection publication summary results from PubMed Central (PMC), obtained 2022-11-10.
		5. data/citedby/DO_citedby.csv: merged and tidied citations from all sources.

2. pub_searches.R
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
		- Tidied search results
			6. Europe PMC: data/lit_search/epmc_search_results.csv
			7. PubMed: data/lit_search/pubmed_search_results.csv
			8. PMC:	data/lit_search/pmc_search_results.csv
		
			data/lit_search/search_res_n.csv
			data/lit_search/actual_search_terms.csv
			graphics/lit_search/epmc_search_overlap.png
			graphics/lit_search/epmc_search_overlap-min10.png
			graphics/lit_search/pmc_search_overlap.png
			graphics/lit_search/pm_search_overlap.png
			data/lit_search/src_comparison.csv
			graphics/lit_search/search_src_overlap-venn.png
			graphics/lit_search/search_src_overlap-upset.png
			graphics/lit_search/total_hits-graph.png
			graphics/lit_search/total_hits-legend.png
			graphics/lit_search/total_hits-complete.png



citedby_RNA.R
	- **Purpose:** 
	- **Input:**
	- **Output:**
    1. graphics/citedby/RNA_pubs_over_time.png
    2. graphics/citedby/RNA_pubs_over_time-by_type.png
    3. graphics/citedby/RNA_pubs_over_time-by_pub_type.png

citedby_analysis.R
	- **Purpose:** 
	- **Input:**
	  1. data/citedby/DO_citedby.csv
	- **Output:**
data/citedby/analysis/time_to_review.csv
data/citedby/analysis/MyNCBI_collection_cites-mid2021.csv
data/citedby/analysis/citedby_source_count.csv
data/citedby/analysis/review_time_summary.csv
data/citedby/analysis/status_uses_count.csv
data/citedby/analysis/use_type_count.csv
data/citedby/analysis/tool_roles_count.csv
data/citedby/analysis/research_area_count.csv
data/citedby/analysis/disease_count.csv
data/citedby/analysis/use_case_count.csv

graphics/citedby/analysis/DO_cited_by_count.png
graphics/citedby/analysis/citedy_source_overlap-venn.png


citedby_manual_count_plot.R
	- **Purpose:** 
	- **Input:**
	  1. data/citedby/counts/citedby_counts-manual.csv
	- **Output:**
    2. data/citedby/counts/citedby_counts-manual_smry.csv
    3. graphics/citedby/citedby_manual_comparison_2021.png
    4. graphics/citedby/citedby_manual_comparison_2022.png

compare_citedby_search.R
	- **Purpose:** 
	- **Input:**
	  1. data/citedby/DO_citedby.csv
	- **Output:**

data/lit_search/src_comparison.csv
data/lit_search/epmc_search_results.csv
data/cb_search_compare/citedby_search_comparison.csv
data/cb_search_compare/search_uniq.csv
graphics/cb_search_compare/citedby_search_comparison.png
graphics/cb_search_compare/search_unique_pub_type.png





## Additional Scripts in this Repository

Three additional scripts in this repository were used to evaluate the impact of the DO _outside_ of published literature but these impact measures, specific to the DO, are not included in the publication.

1. [alliance_disease_record_counts.R](scripts/alliance_disease_record_counts.R): count of disease records in databases belonging to the [Alliance of Genome Resources](https://www.alliancegenome.org/).
2. [bioconductor_stats.R](scripts/bioconductor_stats.R): unique IP download statistics for DO-dependent R packages 'DOSE' and 'DO.db'.
3. [cfde_disease_record_counts.R](scripts/cfde_disease_record_counts.R): count of disease records in databases belonging to the [Common Fund Data Ecosystem](https://app.nih-cfde.org/) (CFDE).


### Details
1. 
data/alliance/disease_counts-full_by_obj.csv
data/alliance/disease_counts-disobj_by_obj.csv
data/alliance/disease_counts-disease_by_obj.csv
data/alliance/disease_counts-unique_diseases.csv
graphics/alliance_disobj_plot.png
graphics/alliance_full_record_plot.png

2. 
data/bioc_DO_stats.csv
data/bioc_DO_stats-1yr-distinctIP.csv
graphics/bioc_DO_stats-distinctIP.png
graphics/bioc_DO_stats-1yr-distinctIP.png

3. 
  - **Input:** data/cfde/CFDE_data-program_sample_disease.csv
  - **Output:**
    1. data/cfde/cfde_disease_counts.csv
    2. graphics/cfde_disease.png
