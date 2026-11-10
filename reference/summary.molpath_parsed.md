# Summarise a molpath_parsed object

Prints a detailed summary of a parsed data source, including column
types, missing value counts, and a preview of distinct values.

## Usage

``` r
# S3 method for class 'molpath_parsed'
summary(object, ...)
```

## Arguments

- object:

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
summary(parsed)
#> 
#> ── molpath_parsed Summary ──────────────────────────────────────────────────────
#> ℹ Source type: "survival"
#> ℹ Source file: example.csv
#> ℹ Parsed: "2026-11-10 00:03:40"
#> ℹ Dimensions: 1 row x 2 columns
#> 
#> ── Column Details ──
#> 
#> ℹ patient_id: <character>, 1 unique, 0 NA
#> ℹ os_months: <numeric>, 1 unique, 0 NA
```
