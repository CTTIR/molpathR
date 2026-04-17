# Filter variants in a molpath_db

Filter the variants table by gene, classification, VAF range, or variant
type.

## Usage

``` r
mp_query_variants(
  db,
  genes = NULL,
  classification = NULL,
  min_vaf = NULL,
  max_vaf = NULL,
  variant_type = NULL
)
```

## Arguments

- db:

  A `molpath_db` object.

- genes:

  Character vector of gene symbols to include. `NULL` means all.

- classification:

  Character vector of classifications to include. `NULL` means all.

- min_vaf:

  Minimum variant allele frequency (inclusive). `NULL` for no lower
  bound.

- max_vaf:

  Maximum variant allele frequency (inclusive). `NULL` for no upper
  bound.

- variant_type:

  Character vector of variant types to include (e.g., `"SNV"`,
  `"Indel"`, `"CNV"`, `"Fusion"`). `NULL` means all.

## Value

A tibble of matching variants.

## Examples

``` r
db <- mp_example_db(n_patients = 20, seed = 1)
mp_query_variants(db, genes = c("TP53", "KRAS"))
#> # A tibble: 432 × 10
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
#>  9 SAM-2024… KRAS  p.G12C  SNV          Likely benign  0.372 12           1.22e8
#> 10 SAM-2024… KRAS  KRAS g… CNV          Likely pathog… 0.111 12           1.55e6
#> # ℹ 422 more rows
#> # ℹ 2 more variables: ref_allele <chr>, alt_allele <chr>
mp_query_variants(db, classification = "Pathogenic", min_vaf = 0.1)
#> # A tibble: 1,773 × 10
#>    sample_id gene  variant variant_type classification   vaf chromosome position
#>    <chr>     <chr> <chr>   <chr>        <chr>          <dbl> <chr>         <int>
#>  1 SAM-2024… BRAF  p.V600E SNV          Benign         0.498 7            2.32e7
#>  2 SAM-2024… BRAF  p.K601E SNV          Pathogenic     0.177 7            2.80e7
#>  3 SAM-2024… NRAS  p.Q61L  SNV          VUS            0.237 1            7.48e6
#>  4 SAM-2024… BRCA2 c.5946… SNV          VUS            0.257 13           1.68e8
#>  5 SAM-2024… NF1   c.731_… SNV          Likely benign  0.330 17           7.90e7
#>  6 SAM-2024… BRAF  c.2040… Indel        Pathogenic     0.308 7            6.79e7
#>  7 SAM-2024… BRAF  p.L597Q SNV          Benign         0.387 7            8.56e6
#>  8 SAM-2024… NRAS  p.Q61K  SNV          Likely benign  0.270 1            8.79e7
#>  9 SAM-2024… RB1   RB1 lo… CNV          VUS            0.223 13           8.17e7
#> 10 SAM-2024… NRAS  p.G12V  SNV          VUS            0.279 1            1.50e8
#> # ℹ 1,763 more rows
#> # ℹ 2 more variables: ref_allele <chr>, alt_allele <chr>
```
