# Plot mutation spectrum

Bar chart of SNV substitution types (C\>A, C\>G, C\>T, T\>A, T\>C,
T\>G).

## Usage

``` r
mp_plot_mutation_spectrum(db, sample_id = NULL)
```

## Arguments

- db:

  A `molpath_db` object.

- sample_id:

  Optional character vector of sample IDs to include. If `NULL`,
  aggregate across all samples.

## Value

A [ggplot2::ggplot](https://ggplot2.tidyverse.org/reference/ggplot.html)
object.

## Examples

``` r
# \donttest{
db <- mp_example_db(n_patients = 20, seed = 1)
mp_plot_mutation_spectrum(db)

# }
```
