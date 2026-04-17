# Create a synthetic molecular pathology database

Generates a realistic but entirely synthetic `molpath_db` object
containing patients, samples, variants, reports, clinical data, and
survival data. The data set is designed to mirror the structure of a
real-world molecular pathology database with plausible clinical
correlations, including diagnosis-specific mutation profiles, TNM
staging, and survival outcomes.

## Usage

``` r
mp_example_db(n_patients = 150, seed = 42)
```

## Arguments

- n_patients:

  Integer. Number of patients to generate. Default `150`.

- seed:

  Integer. Random seed for reproducibility. Default `42`.

## Value

A `molpath_db` object (S3 list) containing:

- patients:

  A `tibble` with columns patient_id, age, sex, diagnosis,
  diagnosis_date.

- samples:

  A `tibble` with columns sample_id, patient_id, sample_type, date,
  source_file.

- variants:

  A `tibble` with columns sample_id, gene, variant, variant_type,
  classification, vaf, chromosome, position, ref_allele, alt_allele.

- reports:

  A `tibble` with columns sample_id, report_type, report_date,
  summary_text, source_file.

- clinical:

  A `tibble` with columns patient_id, parameter, value, date, source.

- survival:

  A `tibble` with columns patient_id, os_months, os_status, pfs_months,
  pfs_status.

## Examples

``` r
db <- mp_example_db()
db$patients
#> # A tibble: 150 × 5
#>    patient_id      age sex   diagnosis            diagnosis_date
#>    <chr>         <int> <chr> <chr>                <date>        
#>  1 PAT-2024-0001    78 M     Colorectal carcinoma 2021-04-10    
#>  2 PAT-2024-0002    55 F     Lung adenocarcinoma  2023-10-17    
#>  3 PAT-2024-0003    66 F     Breast carcinoma     2022-08-26    
#>  4 PAT-2024-0004    69 F     Breast carcinoma     2024-05-20    
#>  5 PAT-2024-0005    66 M     Colorectal carcinoma 2022-05-19    
#>  6 PAT-2024-0006    60 M     Lung adenocarcinoma  2021-10-08    
#>  7 PAT-2024-0007    80 F     Lung adenocarcinoma  2022-06-20    
#>  8 PAT-2024-0008    60 M     Breast carcinoma     2022-06-12    
#>  9 PAT-2024-0009    85 M     Melanoma             2023-10-24    
#> 10 PAT-2024-0010    61 F     Breast carcinoma     2023-04-04    
#> # ℹ 140 more rows
nrow(db$variants)
#> [1] 2361

# Smaller data set for quick tests
db_small <- mp_example_db(n_patients = 20, seed = 123)
```
