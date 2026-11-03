# Validate a molpath_db for referential integrity and completeness

Checks that all foreign key relationships in the database are satisfied
(e.g., every sample references an existing patient) and reports on data
completeness across tables.

## Usage

``` r
mp_validate_db(db)
```

## Arguments

- db:

  A `molpath_db` object to validate.

## Value

Invisibly, a list with three elements:

- valid:

  Logical. `TRUE` if no referential integrity issues were found.

- issues:

  Character vector of issue descriptions (empty if valid).

- completeness:

  Named numeric vector with percentages of patients having data in each
  table (e.g., `pct_with_variants`, `pct_with_survival`).

## Details

The following referential integrity checks are performed:

- All `patient_id` values in the samples table exist in patients.

- All `sample_id` values in the variants table exist in samples.

- All `sample_id` values in the reports table exist in samples.

- All `patient_id` values in the clinical table exist in patients.

- All `patient_id` values in the survival table exist in patients.

When called interactively, results are printed using `cli` formatting.

## Examples

``` r
# \donttest{
db <- mp_example_db(n_patients = 10, seed = 1)
validation <- mp_validate_db(db)
#> 
#> ── Validating molpath database ──
#> 
#> ✔ No referential integrity issues found.
#> 
#> ── Data completeness 
#>   • Patients with samples: 100%
#>   • Patients with variants: 100%
#>   • Patients with reports: 100%
#>   • Patients with clinical: 100%
#>   • Patients with survival: 100%
validation$valid
#> [1] TRUE
# }
```
