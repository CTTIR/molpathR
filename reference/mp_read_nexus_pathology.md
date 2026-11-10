# Read Nexus pathology data

Parse an export from a pathology information system (e.g. Nexus) in
either CSV or XML format.

## Usage

``` r
mp_read_nexus_pathology(path_or_connection)
```

## Arguments

- path_or_connection:

  Character scalar. Path to the CSV or XML export file, or an open
  connection.

## Value

A `molpath_parsed` object whose `data` slot is a
[tibble](https://tibble.tidyverse.org/reference/tibble.html) with
columns `patient_id`, `name`, `dob`, `sex`, `sample_id`, `sample_type`,
`diagnosis`, and `report_date`.

## Examples

``` r
nexus_file <- tempfile(fileext = ".csv")
utils::write.csv(data.frame(
  patient_id = c("P1", "P2"), sample_id = c("S1", "S2"),
  sex = c("F", "M"), diagnosis = c("NSCLC", "CRC"),
  report_date = c("2025-01-10", "2025-02-03")
), nexus_file, row.names = FALSE)
result <- mp_read_nexus_pathology(nexus_file)
#> ℹ Reading Nexus pathology export: file1a21339a56be.csv
#> ✔ Parsed 2 record(s) from Nexus pathology export
result$data
#> # A tibble: 2 × 9
#>   patient_id   age name  dob   sex   sample_id sample_type diagnosis report_date
#>   <chr>      <dbl> <chr> <chr> <chr> <chr>     <chr>       <chr>     <chr>      
#> 1 P1            NA NA    NA    F     S1        NA          NSCLC     2025-01-10 
#> 2 P2            NA NA    NA    M     S2        NA          CRC       2025-02-03 
unlink(nexus_file)
```
