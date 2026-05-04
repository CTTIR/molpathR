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
# \donttest{
clin_file <- system.file("extdata", "nexus_clinical.csv",
                         package = "molpathR")
if (nzchar(clin_file)) {
  result <- mp_read_nexus_clinical(clin_file)
  print(result)
}
# }
```
