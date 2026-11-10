# Visualization Guide

![molpathR logo](figures/logo.svg)![molpathR
logo](figures/logo-dark.svg)

[![R-CMD-check](https://github.com/CTTIR/molpathR/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/CTTIR/molpathR/actions/workflows/R-CMD-check.yaml)
[![pkgdown](https://github.com/CTTIR/molpathR/actions/workflows/pkgdown.yaml/badge.svg)](https://cttir.github.io/molpathR/)
[![CRAN
status](https://www.r-pkg.org/badges/version/molpathR)](https://CRAN.R-project.org/package=molpathR)
[![Codecov test
coverage](https://codecov.io/gh/CTTIR/molpathR/branch/main/graph/badge.svg)](https://app.codecov.io/gh/CTTIR/molpathR?branch=main)
[![CRAN
downloads](https://cranlogs.r-pkg.org/badges/molpathR)](https://cran.r-project.org/package=molpathR)
[![CRAN downloads
total](https://cranlogs.r-pkg.org/badges/grand-total/molpathR)](https://cran.r-project.org/package=molpathR)
[![License:
MIT](https://img.shields.io/badge/license-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)

## Overview

All molpathR plot functions return ggplot2 objects, so you can customize
them with standard ggplot2 syntax.

``` r

library(molpathR)
db <- mp_example_db(n_patients = 150, seed = 42)
```

## Variant landscape

``` r

mp_plot_variant_landscape(db, top_n = 10)
```

![Recorded variant classifications across synthetic patients for
selected genes.](visualization_files/figure-html/landscape-1.png)

## VAF distribution

``` r

mp_plot_vaf_distribution(db, gene = "TP53")
```

![Distribution of observed TP53 variant allele fractions in the
synthetic cohort.](visualization_files/figure-html/vaf-1.png)

## Survival analysis

``` r

# Overall survival by diagnosis
mp_plot_survival(db, group_by = "diagnosis", type = "os")
```

![Kaplan-Meier curves for synthetic patients grouped by
diagnosis.](visualization_files/figure-html/survival-1.png)

``` r

# Compare recorded TP53 variants with no recorded TP53 variant
mp_plot_survival(db, group_by = "TP53", type = "os")
```

![Kaplan-Meier curves comparing recorded TP53 variants with no recorded
TP53 variant; missing records are not a negative
assay.](visualization_files/figure-html/survival_gene-1.png)

The gene groups describe database records only. A patient with no
recorded variant is not established to be wild-type; assay coverage is
unavailable.

## Cohort overview

``` r

plots <- mp_plot_cohort_overview(db)
plots$diagnosis
```

![Synthetic patient counts by
diagnosis.](visualization_files/figure-html/cohort-1.png)

``` r

plots$top_genes
```

![Recorded synthetic variant counts for the most frequent
genes.](visualization_files/figure-html/cohort-2.png)

## Patient timeline

``` r

pid <- db$patients$patient_id[1]
mp_plot_timeline(db, pid)
```

![Dated sample, report and clinical records for one synthetic
patient.](visualization_files/figure-html/timeline-1.png)

## Customization

All plots can be customized with ggplot2:

``` r

library(ggplot2)
mp_plot_vaf_distribution(db) +
  labs(title = "Custom Title") +
  theme(plot.title = element_text(colour = "purple"))
```

![Distribution of synthetic variant allele fractions with a customized
title and styling.](visualization_files/figure-html/custom-1.png)
