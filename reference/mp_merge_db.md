# Merge two molpath_db objects

Combines all tables from two `molpath_db` objects into a single unified
database. Records are deduplicated after merging. Metadata source files
are combined as a union. Identical primary-key rows are deduplicated and
missing attributes may be filled from the other source. Conflicting
observed patient, sample or survival attributes require explicit
reconciliation and cause an error.

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
db1 <- mp_example_db(n_patients = 5, seed = 1)
db2 <- db1
db1$survival <- db1$survival[0, ]
db_combined <- mp_merge_db(db1, db2)
```
