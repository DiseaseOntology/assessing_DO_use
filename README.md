# Assessing DO Use

[![DOI](https://zenodo.org/badge/523817284.svg)](https://zenodo.org/badge/latestdoi/523817284)

The code, data, and figures used or produced to assess use of the Human Disease Ontology (DO; [disease-ontology.org](https://disease-ontology.org/)) as part of the case study for the **resource use assessment workflow**, applicable to any public resource seeking to determine its use, as described in "Assessing Resource Use: A Case Study with the Human Disease Ontology" soon to be published in the journal DATABASE. This repository and the corresponding [DO_uses-published_2022](https://docs.google.com/spreadsheets/d/1soEnbGY2uVVDEC_xKOpjs9WQg-wQcLiXqmh_iJ-2qsM/edit?usp=share_link) Google Sheet used for curation should serve as a good example for any public resource wishing to implement this workflow.


# Reproducibility

All the data, figures and code for the publication can be found in the `data/`, `graphics/`, and `scripts/` folders of this repository on Github (https://github.com/allenbaron/assessing_DO_use) or the persistent, open-access repository Zenodo (DOI: [10.5281/zenodo.7467640](https://doi.org/10.5281/zenodo.7467640)). Re-executing the code requires R and a number of R packages, including the [DO.utils](https://github.com/allenbaron/DO.utils) package (DOI: [10.5281/zenodo.7467668](https://doi.org/10.5281/zenodo.7467668)), designed to support this workflow (as well as, analysis and improvement of the DO more specifically). The version of each R package has been tracked using the 'renv' R package.

The easiest way to get all dependencies and re-execute the code here is to download this repository from Github or Zenodo and R from [CRAN](https://cran.r-project.org/). Then, install the 'renv' package (within R, run `install.packages("renv")`) and  download all packages with versions matching those originally used to create this repository using 'renv' (within R, run `renv::restore()`).

The [DO_uses-published_2022](https://docs.google.com/spreadsheets/d/1soEnbGY2uVVDEC_xKOpjs9WQg-wQcLiXqmh_iJ-2qsM/edit?usp=share_link) Google Sheet used for curation as described in the publication remains in the same state used for code execution in this repository and is open for public viewing.


# Code Details

Details describing the purpose, input and output of each script in this repository can be found in the [script_descriptions.md](scripts_descriptions.md) file.
