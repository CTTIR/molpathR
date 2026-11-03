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
# \donttest{
nexus_file <- system.file("extdata", "nexus_pathology.csv",
                          package = "molpathR")
if (nzchar(nexus_file)) {
  result <- mp_read_nexus_pathology(nexus_file)
  print(result)
}
# }
```
