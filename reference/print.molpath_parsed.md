# Print a molpath_parsed object

Displays a compact summary of a parsed data source, including source
metadata and a preview of the data.

## Usage

``` r
# S3 method for class 'molpath_parsed'
print(x, ...)
```

## Arguments

- x:

  A `molpath_parsed` object.

- ...:

  Additional arguments (ignored).

## Value

The `molpath_parsed` object (invisibly).

## Examples

``` r
parsed <- new_molpath_parsed(
  data = tibble::tibble(patient_id = "P1", os_months = 12),
  source_type = "survival", source_file = "example.csv"
)
print(parsed)
#> 
#> ── molpath_parsed ──────────────────────────────────────────────────────────────
#> ℹ Source type: "survival"
#> ℹ Source file: example.csv
#> ℹ Parsed: "2026-11-10 00:03:40"
#> ℹ Data: 1 row x 2 columns
#> ℹ Columns: patient_id and os_months
#> ℹ Completeness: "100%"
```
