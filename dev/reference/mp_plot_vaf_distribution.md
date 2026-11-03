# Plot variant allele frequency distribution

Histogram or density plot of variant allele frequencies (VAF),
optionally filtered by gene.

## Usage

``` r
mp_plot_vaf_distribution(db, gene = NULL)
```

## Arguments

- db:

  A `molpath_db` object.

- gene:

  Optional character vector of gene symbols to include.

## Value

A [ggplot2::ggplot](https://ggplot2.tidyverse.org/reference/ggplot.html)
object.

## Examples

``` r
# \donttest{
db <- mp_example_db(n_patients = 20, seed = 1)
mp_plot_vaf_distribution(db)

mp_plot_vaf_distribution(db, gene = "TP53")

# }
```
