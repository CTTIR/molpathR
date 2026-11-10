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
files <- mp_example_files(file.path(tempdir(), "molpathR-example"))
result <- mp_read_survival(files$survival)
#> ℹ Reading survival data: survival.csv
#> ✔ Parsed 30 patient record(s) with survival data
head(result$data)
#> # A tibble: 6 × 5
#>   patient_id    os_months os_status pfs_months pfs_status
#>   <chr>             <dbl>     <int>      <dbl>      <int>
#> 1 PAT-2024-0001      40.4         0       31.2          1
#> 2 PAT-2024-0002      23.8         1       24.5          1
#> 3 PAT-2024-0003      19           0       36            1
#> 4 PAT-2024-0004      28.8         1       24.3          1
#> 5 PAT-2024-0005      30.6         1       36            0
#> 6 PAT-2024-0006      32           1       36            1
```
