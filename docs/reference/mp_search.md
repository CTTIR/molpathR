# Free-text search across a molpath_db

Searches all text fields across all tables for the given term
(case-insensitive).

## Usage

``` r
mp_search(db, term)
```

## Arguments

- db:

  A `molpath_db` object.

- term:

  A single search string.

## Value

A named list of tibbles, one per table, containing rows that match the
search term. Empty tibbles are omitted.

## Examples

``` r
db <- mp_example_db(n_patients = 20, seed = 1)
mp_search(db, "TP53")
#> ℹ Found 275 matching records across 1 table.
#> $variants
#> # A tibble: 275 × 10
#>    sample_id gene  variant variant_type classification   vaf chromosome position
#>    <chr>     <chr> <chr>   <chr>        <chr>          <dbl> <chr>         <int>
#>  1 SAM-2024… TP53  p.R249S SNV          Benign         0.525 17           1.69e8
#>  2 SAM-2024… TP53  p.C176Y SNV          Likely benign  0.332 17           1.43e8
#>  3 SAM-2024… TP53  p.R282W SNV          VUS            0.227 17           9.18e7
#>  4 SAM-2024… TP53  c.211_… Indel        Pathogenic     0.277 17           8.10e7
#>  5 SAM-2024… TP53  p.C176Y SNV          Likely benign  0.316 17           1.65e8
#>  6 SAM-2024… TP53  p.R175H SNV          VUS            0.102 17           1.15e8
#>  7 SAM-2024… TP53  p.H179R SNV          VUS            0.401 17           8.89e6
#>  8 SAM-2024… TP53  p.V157F SNV          Likely benign  0.290 17           6.13e7
#>  9 SAM-2024… TP53  p.V157F SNV          Likely benign  0.557 17           2.31e7
#> 10 SAM-2024… TP53  p.R273H SNV          Pathogenic     0.488 17           1.86e8
#> # ℹ 265 more rows
#> # ℹ 2 more variables: ref_allele <chr>, alt_allele <chr>
#> 
```
