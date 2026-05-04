# Get all data for a single patient

Returns a named list containing all data layers for the given patient,
including samples, variants (via sample linkage), reports, clinical
data, and survival data.

## Usage

``` r
mp_get_patient(db, patient_id)
```

## Arguments

- db:

  A `molpath_db` object.

- patient_id:

  A single patient ID string.

## Value

A named list with elements: `patient`, `samples`, `variants`, `reports`,
`clinical`, `survival`.

## Examples

``` r
db <- mp_example_db(n_patients = 20, seed = 1)
pat <- mp_get_patient(db, db$patients$patient_id[1])
pat$samples
#> # A tibble: 2 × 5
#>   sample_id     patient_id    sample_type   date       source_file            
#>   <chr>         <chr>         <chr>         <date>     <chr>                  
#> 1 SAM-2024-0001 PAT-2024-0001 Liquid biopsy 2024-02-20 input/SAM-2024-0001.vcf
#> 2 SAM-2024-0002 PAT-2024-0001 Liquid biopsy 2024-04-02 input/SAM-2024-0002.vcf
```
