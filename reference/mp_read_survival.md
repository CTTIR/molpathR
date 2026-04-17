# Read survival / outcome data

Read a survival data file in Excel or CSV format and standardise the
column names to a canonical schema.

## Usage

``` r
mp_read_survival(path)
```

## Arguments

- path:

  Character scalar. Path to a `.xlsx`, `.xls`, or `.csv` file.

## Value

A `molpath_parsed` object whose `data` slot is a
[tibble](https://tibble.tidyverse.org/reference/tibble.html) with
columns `patient_id`, `os_months`, `os_status`, `pfs_months`, and
`pfs_status`.

## Examples

``` r
# \donttest{
surv_file <- system.file("extdata", "survival.csv", package = "molpathR")
if (nzchar(surv_file)) {
  result <- mp_read_survival(surv_file)
  print(result)
}
# }
```
