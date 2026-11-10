# Print a molpath_db object

Displays a human-readable summary of a `molpath_db`, including table
dimensions, date ranges, and data completeness.

## Usage

``` r
# S3 method for class 'molpath_db'
print(x, ...)
```

## Arguments

- x:

  A `molpath_db` object.

- ...:

  Additional arguments (ignored).

## Value

The `molpath_db` object (invisibly).

## Examples

``` r
db <- mp_example_db(n_patients = 10, seed = 1)
print(db)
#> 
#> ── molpath_db ──────────────────────────────────────────────────────────────────
#> ℹ patients: 10 records x 5 columns
#> ℹ samples: 24 records x 5 columns
#> ℹ variants: 2042 records x 10 columns
#> ℹ reports: 24 records x 5 columns
#> ℹ clinical: 40 records x 5 columns
#> ℹ survival: 10 records x 5 columns
#> ℹ Sample date range: 2021-08-02 to 2025-10-19
#> ℹ Overall completeness: "93.3%"
#> ℹ Created: "2026-11-10 08:10:23"
#> ℹ Source files: 0
```
