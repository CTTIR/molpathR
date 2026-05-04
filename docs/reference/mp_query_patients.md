# Filter patients in a molpath_db

Uses tidy evaluation to filter the patients table.

## Usage

``` r
mp_query_patients(db, ...)
```

## Arguments

- db:

  A `molpath_db` object.

- ...:

  Filter expressions passed to
  [`dplyr::filter()`](https://dplyr.tidyverse.org/reference/filter.html).

## Value

A tibble of matching patients.

## Examples

``` r
db <- mp_example_db(n_patients = 20, seed = 1)
mp_query_patients(db, diagnosis == "Melanoma")
#> # A tibble: 5 × 5
#>   patient_id      age sex   diagnosis diagnosis_date
#>   <chr>         <int> <chr> <chr>     <date>        
#> 1 PAT-2024-0001    54 F     Melanoma  2023-04-23    
#> 2 PAT-2024-0010    58 M     Melanoma  2021-09-09    
#> 3 PAT-2024-0016    61 M     Melanoma  2022-09-06    
#> 4 PAT-2024-0017    61 F     Melanoma  2024-03-14    
#> 5 PAT-2024-0020    69 M     Melanoma  2023-05-05    
mp_query_patients(db, age > 60, sex == "F")
#> # A tibble: 9 × 5
#>   patient_id      age sex   diagnosis            diagnosis_date
#>   <chr>         <int> <chr> <chr>                <date>        
#> 1 PAT-2024-0002    64 F     Lung adenocarcinoma  2022-04-10    
#> 2 PAT-2024-0004    81 F     Lung adenocarcinoma  2024-04-14    
#> 3 PAT-2024-0005    65 F     Breast carcinoma     2024-09-30    
#> 4 PAT-2024-0007    67 F     Colorectal carcinoma 2021-03-25    
#> 5 PAT-2024-0008    70 F     Breast carcinoma     2023-11-19    
#> 6 PAT-2024-0011    80 F     Lung adenocarcinoma  2023-01-03    
#> 7 PAT-2024-0017    61 F     Melanoma             2024-03-14    
#> 8 PAT-2024-0018    73 F     Lung adenocarcinoma  2021-11-25    
#> 9 PAT-2024-0019    71 F     Breast carcinoma     2022-05-02    
```
