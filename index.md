# molpathR

**molpathR** is a unified molecular pathology data platform that ingests
heterogeneous clinical and genomic data sources (VCF, BAM, FASTQ, XML
reports, PDF reports, clinical information systems, survival data),
builds a queryable in-memory database, and provides an interactive Shiny
application for clinical exploration and visualization.

## Installation

Install the development version from GitHub:

``` r

# install.packages("remotes")
remotes::install_github("r-heller/molpathR")
```

## Quick example

``` r

library(molpathR)

# Load example database with synthetic data
db <- mp_example_db(n_patients = 50, seed = 42)
db

# Query pathogenic TP53 variants
tp53 <- mp_query_variants(db, genes = "TP53", classification = "Pathogenic")
head(tp53[, c("sample_id", "gene", "variant", "classification", "vaf")])
```

``` r

# Survival analysis by diagnosis
mp_plot_survival(db, group_by = "diagnosis", type = "os")
```

## Launch the Shiny app

``` r

mp_run_app(db)
```

## Features

- **Parsers** for VCF, FASTQ, BAM, XML reports, PDF reports, clinical
  systems, and survival data
- **Relational in-memory database** linking patients, samples, variants,
  reports, clinical, and survival data
- **Query engine** with tidy evaluation and free-text search
- **Publication-ready plots**: variant landscapes, mutation spectra,
  survival curves, cohort overviews
- **Interactive Shiny application** with 6 tabs for clinical exploration

## Documentation

- [Getting
  Started](https://r-heller.github.io/molpathR/articles/getting-started.html)
- [Data Import
  Guide](https://r-heller.github.io/molpathR/articles/data-import.html)
- [Visualization
  Guide](https://r-heller.github.io/molpathR/articles/visualization.html)
- [Shiny
  Application](https://r-heller.github.io/molpathR/articles/shiny-app.html)

## License

MIT License. See
[LICENSE.md](https://r-heller.github.io/molpathR/LICENSE.md) for
details.
