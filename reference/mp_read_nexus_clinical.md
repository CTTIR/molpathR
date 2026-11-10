# Read Nexus clinical data

Parse a clinical data export (CSV format) from a clinical information
system such as Nexus.

## Usage

``` r
mp_read_nexus_clinical(path_or_connection)
```

## Arguments

- path_or_connection:

  Character scalar. Path to the CSV file, or an open connection.

## Value

A `molpath_parsed` object whose `data` slot is a
[tibble](https://tibble.tidyverse.org/reference/tibble.html) with
columns `patient_id`, `parameter`, `value`, `unit`, `date`, and
`source`.

## Examples

``` r
clin_file <- tempfile(fileext = ".csv")
utils::write.csv(data.frame(
  patient_id = c("P1", "P1"), parameter = c("CEA", "LDH"),
  value = c("3.1", "210"), unit = c("ng/mL", "U/L"),
  date = c("2025-01-10", "2025-01-10")
), clin_file, row.names = FALSE)
result <- mp_read_nexus_clinical(clin_file)
#> ℹ Reading Nexus clinical export: file19b457530fff.csv
#> ✔ Parsed 2 clinical record(s)
result$data
#> # A tibble: 2 × 6
#>   patient_id parameter value unit  date       source
#>   <chr>      <chr>     <chr> <chr> <chr>      <chr> 
#> 1 P1         CEA       3.1   ng/mL 2025-01-10 NA    
#> 2 P1         LDH       210   U/L   2025-01-10 NA    
unlink(clin_file)
```
