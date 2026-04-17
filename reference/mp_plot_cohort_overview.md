# Plot cohort overview

Returns a list of four ggplot objects summarising the database:
diagnosis distribution, age by sex, sample types, and top mutated genes.
Arrange with `patchwork` or `cowplot` as needed.

## Usage

``` r
mp_plot_cohort_overview(db)
```

## Arguments

- db:

  A `molpath_db` object.

## Value

A named list of four
[ggplot2::ggplot](https://ggplot2.tidyverse.org/reference/ggplot.html)
objects: `diagnosis`, `age`, `sample_types`, `top_genes`.

## Examples

``` r
# \donttest{
db <- mp_example_db(n_patients = 20, seed = 1)
plots <- mp_plot_cohort_overview(db)
plots$diagnosis

# }
```
