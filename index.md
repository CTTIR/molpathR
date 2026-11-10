# molpathR ![molpathR logo](reference/figures/logo-with-name.png)

**molpathR** is a unified molecular pathology data platform that ingests
heterogeneous clinical and genomic data sources (VCF, BAM, FASTQ, XML
reports, PDF reports, clinical information systems, survival data),
builds a queryable in-memory database from explicitly identified
records, and provides an interactive Shiny application for exploratory
cohort analysis. Raw FASTQ/BAM readers expose sequences and alignments
separately; they do not perform variant calling or clinical
interpretation. Unknown patient links and annotations remain unknown.
The package has not been qualified for diagnostic decision making.

## Installation

Use R 4.1 or later. On Windows and macOS, install the CRAN binaries from
R:

``` r

install.packages("pdftools", repos = "https://cloud.r-project.org")
```

For a source installation of `pdftools`, install its system library
first:

``` sh
# Debian or Ubuntu
sudo apt-get install libpoppler-cpp-dev
# macOS with Homebrew, only when building pdftools from source
brew install poppler
```

See the [pdftools installation
requirements](https://docs.ropensci.org/pdftools/) for other platforms.
These commands assume R and the platform’s R compilation toolchain are
already installed. Then install the development source:

``` r

install.packages("remotes", repos = "https://cloud.r-project.org")
remotes::install_github("cttir/molpathR")
```

## Quick example

``` r

library(molpathR)

# Load example database with synthetic data
db <- mp_example_db(n_patients = 50, seed = 42)
db
#> 
#> ── molpath_db ──────────────────────────────────────────────────────────────────
#> ℹ patients: 50 records x 5 columns
#> ℹ samples: 116 records x 5 columns
#> ℹ variants: 2151 records x 10 columns
#> ℹ reports: 116 records x 5 columns
#> ℹ clinical: 195 records x 5 columns
#> ℹ survival: 50 records x 5 columns
#> ℹ Sample date range: 2021-04-01 to 2025-06-26
#> ℹ Overall completeness: "93.7%"
#> ℹ Created: "2026-11-03 12:42:46"
#> ℹ Source files: 0

# Query pathogenic TP53 variants
tp53 <- mp_query_variants(db, genes = "TP53", classification = "Pathogenic")
head(tp53[, c("sample_id", "gene", "variant", "classification", "vaf")])
#> # A tibble: 6 × 5
#>   sample_id     gene  variant             classification   vaf
#>   <chr>         <chr> <chr>               <chr>          <dbl>
#> 1 SAM-2021-0010 TP53  TP53 deletion       Pathogenic     0.420
#> 2 SAM-2021-0011 TP53  TP53-UNKNOWN fusion Pathogenic     0.464
#> 3 SAM-2022-0013 TP53  TP53-UNKNOWN fusion Pathogenic     0.322
#> 4 SAM-2021-0017 TP53  TP53 loss           Pathogenic     0.214
#> 5 SAM-2022-0018 TP53  p.R282W             Pathogenic     0.250
#> 6 SAM-2023-0020 TP53  p.R248W             Pathogenic     0.213
```

``` r

# Survival analysis by diagnosis
mp_plot_survival(db, group_by = "diagnosis", type = "os")
```

![Kaplan-Meier curves by diagnosis for a synthetic cohort; time is
measured in months.](reference/figures/README-plot-1.png)

## Launch the Shiny app

``` r

mp_run_app(db)
```

## Features

- **Parsers** for VCF, raw FASTQ/BAM, XML reports, PDF text, clinical
  exports and survival data
- **Relational in-memory database** linking patients, samples, variants,
  reports, clinical, and survival data
- **Query engine** with tidy evaluation and free-text search
- **Exploratory plots**: variant landscapes, mutation spectra, survival
  curves, cohort overviews
- **Interactive Shiny application** with 6 tabs for clinical exploration

## Data integrity

`mp_validate_db(db)` reports incomplete patient/sample links, including
missing parent tables. The constructor rejects malformed schemas,
conflicting primary identities, impossible event codes and nonfinite
measures.
[`mp_save_db()`](https://cttir.github.io/molpathR/reference/mp_save_db.md)
verifies a staged file before replacement;
[`mp_load_db()`](https://cttir.github.io/molpathR/reference/mp_load_db.md)
validates its contents. Resolve reported linkage issues before
interpreting a cohort. Use one writer per saved file.

The [data import
guide](https://cttir.github.io/molpathR/articles/data-import.html)
contains a runnable synthetic pathology/clinical/survival import and
explains VCF and raw-read boundaries. Optional Bioconductor packages
provide BAM/FASTQ readers; strict text FASTQ and VCF paths are available
as documented.

## Citation

Run `citation("molpathR")` and record the package version (0.2.0) or
commit used. No Zenodo deposit has been published for this version. The
previously advertised draft DOI did not resolve during the maintenance
audit; use the repository citation until a public deposit is verified.

## Documentation

- [Getting
  Started](https://cttir.github.io/molpathR/articles/getting-started.html)
- [Data Import
  Guide](https://cttir.github.io/molpathR/articles/data-import.html)
- [Visualization
  Guide](https://cttir.github.io/molpathR/articles/visualization.html)
- [Shiny
  Application](https://cttir.github.io/molpathR/articles/shiny-app.html)

## License

MIT License. See
[LICENSE.md](https://cttir.github.io/molpathR/LICENSE.md) for details.

## Use of LLM tools

Where applicable, LLM tools were used for narrowly defined,
non-authorial tasks: copyediting, prose refinement, Markdown/LaTeX
formatting, boilerplate scaffolding (such as CI configurations and build
scripts), and code refactoring. Tools included [Chat
AI](https://kisski.gwdg.de/leistungen/2-02-llm-service/), the KISSKI
(GWDG) service, and self-hosted **Mistral Small (24B, Apache-2.0)**
served through a local **vLLM architecture** on an Ubuntu Linux
workstation with Intel processors and NVIDIA GPUs. Self-hosted use also
includes models that were further trained (fine-tuned) or weight-edited
in-house for specific tasks. All self-hosted models ran locally, with no
data sent to third parties.

All scientific claims, methodological choices, analyses, interpretations
and conclusions remain the authors’ own. Where applicable, LLM-generated
material must be reviewed and revised before inclusion, and references
must be verified against their DOI, arXiv ID or ISBN.

Local software setup: vLLM with Python/PyTorch, plus R and RStudio.

## Branding

Editable R artwork and regeneration instructions are in
[tools/branding](https://github.com/CTTIR/molpathR/blob/main/tools/branding/README.md).
