# Filter samples in a molpath_db

Uses tidy evaluation to filter the samples table.

## Usage

``` r
mp_query_samples(db, ...)
```

## Arguments

- db:

  A `molpath_db` object.

- ...:

  Filter expressions passed to
  [`dplyr::filter()`](https://dplyr.tidyverse.org/reference/filter.html).

## Value

A tibble of matching samples.

## Examples

``` r
db <- mp_example_db(n_patients = 20, seed = 1)
mp_query_samples(db, sample_type == "FFPE")
#> # A tibble: 8 × 5
#>   sample_id     patient_id    sample_type date       source_file            
#>   <chr>         <chr>         <chr>       <date>     <chr>                  
#> 1 SAM-2024-0005 PAT-2024-0003 FFPE        2024-04-30 input/SAM-2024-0005.vcf
#> 2 SAM-2024-0011 PAT-2024-0006 FFPE        2024-09-08 input/SAM-2024-0011.vcf
#> 3 SAM-2023-0020 PAT-2024-0011 FFPE        2023-11-05 input/SAM-2023-0020.vcf
#> 4 SAM-2022-0025 PAT-2024-0014 FFPE        2022-08-30 input/SAM-2022-0025.vcf
#> 5 SAM-2022-0026 PAT-2024-0014 FFPE        2022-10-29 input/SAM-2022-0026.vcf
#> 6 SAM-2022-0027 PAT-2024-0014 FFPE        2022-11-22 input/SAM-2022-0027.vcf
#> 7 SAM-2022-0034 PAT-2024-0019 FFPE        2022-10-22 input/SAM-2022-0034.vcf
#> 8 SAM-2023-0035 PAT-2024-0019 FFPE        2023-04-21 input/SAM-2023-0035.vcf
```
