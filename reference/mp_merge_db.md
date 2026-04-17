# Merge two molpath_db objects

Combines all tables from two `molpath_db` objects into a single unified
database. Records are deduplicated after merging. Metadata source files
are combined as a union.

## Usage

``` r
mp_merge_db(db1, db2)
```

## Arguments

- db1:

  A `molpath_db` object.

- db2:

  A `molpath_db` object.

## Value

A new `molpath_db` object containing merged data from both inputs.

## Examples

``` r
# \donttest{
db1 <- mp_example_db(n_patients = 5, seed = 1)
db2 <- mp_example_db(n_patients = 5, seed = 2)
db_combined <- mp_merge_db(db1, db2)
#> 
#> ── Merging molpath databases ──
#> 
#> ✔ Databases merged successfully.
#> ℹ Merged tables: 10 patients, 23 samples, 4018 variants, 23 reports, 39 clinical records, 10 survival records.
# }
```
