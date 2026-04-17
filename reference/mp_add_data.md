# Add parsed data to an existing molpath_db

Appends new data from one or more `molpath_parsed` objects to an
existing `molpath_db` database. Records are deduplicated after
appending.

## Usage

``` r
mp_add_data(db, parsed)
```

## Arguments

- db:

  A `molpath_db` object to update.

- parsed:

  A single `molpath_parsed` object or a list of `molpath_parsed` objects
  to add.

## Value

An updated `molpath_db` object with the new data merged in.

## Examples

``` r
# \donttest{
db <- mp_example_db(n_patients = 5, seed = 1)
new_data <- new_molpath_parsed(
  data = tibble::tibble(patient_id = "P99", os_months = 12,
    os_status = 1L, pfs_months = 6, pfs_status = 1L),
  source_type = "survival", source_file = "new.csv"
)
db <- mp_add_data(db, new_data)
#> 
#> ── Adding data to molpath database ──
#> 
#> ℹ Processing 1 parsed object.
#> ✔ Data added successfully.
#> ℹ Updated tables: 5 patients, 11 samples, 2011 variants, 11 reports, 20 clinical records, 6 survival records.
# }
```
