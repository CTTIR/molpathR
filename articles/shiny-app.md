# Interactive Shiny Application

[![R-CMD-check](https://github.com/r-heller/molpathR/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/r-heller/molpathR/actions/workflows/R-CMD-check.yaml)
[![pkgdown](https://github.com/r-heller/molpathR/actions/workflows/pkgdown.yaml/badge.svg)](https://r-heller.github.io/molpathR/)
[![CRAN
status](https://www.r-pkg.org/badges/version/molpathR)](https://CRAN.R-project.org/package=molpathR)
[![Codecov test
coverage](https://codecov.io/gh/r-heller/molpathR/branch/main/graph/badge.svg)](https://app.codecov.io/gh/r-heller/molpathR?branch=main)
[![CRAN
downloads](https://cranlogs.r-pkg.org/badges/molpathR)](https://cran.r-project.org/package=molpathR)
[![CRAN downloads
total](https://cranlogs.r-pkg.org/badges/grand-total/molpathR)](https://cran.r-project.org/package=molpathR)
[![License:
MIT](https://img.shields.io/badge/license-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)

## Launching the app

``` r

library(molpathR)

# Launch with pre-loaded example data
db <- mp_example_db()
mp_run_app(db)

# Or launch empty and upload data in the browser
mp_run_app()
```

## Application tabs

### Tab 1: Database

The home tab lets you upload data files or load the example database. It
shows summary cards (number of patients, samples, variants, reports) and
a table of loaded data sources.

### Tab 2: Patients

A searchable, filterable master table of all patients. Click a row to
expand a detail panel showing that patient’s samples, variants, clinical
data, and survival information. Filters include diagnosis, sex, and age
range.

### Tab 3: Variants

Interactive variant table with gene, classification, and VAF filters.
Includes tabs for the variant landscape plot, mutation spectrum, and VAF
distribution. Clicking a variant selects its gene for survival
stratification.

### Tab 4: Reports

Browse all parsed reports with filters for report type, date range, and
patient. Click a row to view the full report text in a detail panel.

### Tab 5: Survival

Interactive Kaplan-Meier curves with options for overall or
progression-free survival. Stratify by diagnosis, sex, or any gene
mutation status. Displays log-rank p-values and median survival
statistics. Gene selection from the Variants tab automatically
propagates here.

### Tab 6: Export

Select which data layers to export (patients, samples, variants,
reports, clinical, survival). Choose from CSV, TSV, Excel, or RDS
formats. Preview the data before downloading.

## Cross-tab interactivity

- Selecting a patient in Tab 2 filters Tabs 3-5 to that patient
- Selecting a gene/variant in Tab 3 pre-fills the survival
  stratification gene

## Deployment

``` r

# Deploy to shinyapps.io
rsconnect::deployApp(
  appDir = system.file("shiny", "molpathR", package = "molpathR"),
  appName = "molpathR"
)
```
