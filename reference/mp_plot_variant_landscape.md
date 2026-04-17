# Plot variant landscape (oncoplot)

Creates a tile plot showing variant classifications across samples and
genes.

## Usage

``` r
mp_plot_variant_landscape(db, genes = NULL, top_n = 20)
```

## Arguments

- db:

  A `molpath_db` object.

- genes:

  Character vector of genes to display. If `NULL`, the top `top_n` most
  frequently mutated genes are shown.

- top_n:

  Integer. Number of top genes to show when `genes` is `NULL`.

## Value

A [ggplot2::ggplot](https://ggplot2.tidyverse.org/reference/ggplot.html)
object.

## Examples

``` r
# \donttest{
db <- mp_example_db(n_patients = 20, seed = 1)
mp_plot_variant_landscape(db, top_n = 10)

# }
```
