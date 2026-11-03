# Interactive Shiny Application

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
