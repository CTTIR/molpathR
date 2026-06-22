# Data Import Guide

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

## Overview

molpathR provides dedicated parsers for each molecular pathology data
source. All parsers return `molpath_parsed` objects that can be combined
into a unified database using
[`mp_build_db()`](https://cttir.github.io/molpathR/reference/mp_build_db.md).

## Available parsers

| Function | File types | Description |
|----|----|----|
| [`mp_read_vcf()`](https://cttir.github.io/molpathR/reference/mp_read_vcf.md) | .vcf, .vcf.gz | Variant Call Format files |
| [`mp_read_fastq()`](https://cttir.github.io/molpathR/reference/mp_read_fastq.md) | .fastq, .fq | FASTQ sequence files |
| [`mp_read_bam()`](https://cttir.github.io/molpathR/reference/mp_read_bam.md) | .bam | BAM alignment files |
| [`mp_read_xml_report()`](https://cttir.github.io/molpathR/reference/mp_read_xml_report.md) | .xml | XML variant interpretation reports |
| [`mp_read_pdf_report()`](https://cttir.github.io/molpathR/reference/mp_read_pdf_report.md) | .pdf | Pathology PDF reports |
| [`mp_read_nexus_pathology()`](https://cttir.github.io/molpathR/reference/mp_read_nexus_pathology.md) | .csv, .xml | Nexus Pathology exports |
| [`mp_read_nexus_clinical()`](https://cttir.github.io/molpathR/reference/mp_read_nexus_clinical.md) | .csv | Nexus clinical data exports |
| [`mp_read_survival()`](https://cttir.github.io/molpathR/reference/mp_read_survival.md) | .xlsx, .csv | Survival/outcome data |
| [`mp_read_auto()`](https://cttir.github.io/molpathR/reference/mp_read_auto.md) | any | Auto-detect and dispatch |

## Example: parsing VCF files

``` r

library(molpathR)

# Parse a single VCF file
parsed_vcf <- mp_read_vcf("path/to/variants.vcf")
parsed_vcf

# View the data
head(parsed_vcf$data)
```

## Building a database from multiple sources

``` r

# Parse several files
vcf1 <- mp_read_vcf("sample1.vcf")
vcf2 <- mp_read_vcf("sample2.vcf")
surv <- mp_read_survival("survival_data.xlsx")

# Build the database
db <- mp_build_db(vcf1, vcf2, surv)

# Validate integrity
mp_validate_db(db)

# Save for later use
mp_save_db(db, "my_database.rds")
```

## Auto-detection with mp_read_auto()

``` r

# Automatically detects file type and uses the correct parser
parsed <- mp_read_auto("unknown_file.vcf")
parsed$source_type
```

## Handling parse errors

All parsers use defensive parsing with informative error messages:

``` r

# Malformed files produce warnings, not crashes
result <- mp_read_vcf("possibly_broken.vcf")
```
