# Plot variant allele frequency distribution

Histogram of variant allele frequencies (VAF), optionally filtered by
gene. Bins are 0.05 wide and start at 0; the dashed line marks a VAF of
0.5. When `gene` selects several genes, each gene gets its own panel.

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
db <- mp_example_db(n_patients = 20, seed = 1)
mp_plot_vaf_distribution(db)

mp_plot_vaf_distribution(db, gene = "TP53")
```
