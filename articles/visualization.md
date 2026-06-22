# Visualization Guide

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

![](visualization_files/figure-html/landscape-1.png)

## VAF distribution

``` r

mp_plot_vaf_distribution(db, gene = "TP53")
```

![](visualization_files/figure-html/vaf-1.png)

## Survival analysis

``` r

# Overall survival by diagnosis
mp_plot_survival(db, group_by = "diagnosis", type = "os")
```

![](visualization_files/figure-html/survival-1.png)

``` r

# Stratify by TP53 mutation status
mp_plot_survival(db, group_by = "TP53", type = "os")
```

![](visualization_files/figure-html/survival_gene-1.png)

## Cohort overview

``` r

plots <- mp_plot_cohort_overview(db)
plots$diagnosis
```

![](visualization_files/figure-html/cohort-1.png)

``` r

plots$top_genes
```

![](visualization_files/figure-html/cohort-2.png)

## Patient timeline

``` r

pid <- db$patients$patient_id[1]
mp_plot_timeline(db, pid)
```

![](visualization_files/figure-html/timeline-1.png)

## Customization

All plots can be customized with ggplot2:

``` r

library(ggplot2)
mp_plot_vaf_distribution(db) +
  labs(title = "Custom Title") +
  theme(plot.title = element_text(colour = "purple"))
```

![](visualization_files/figure-html/custom-1.png)
