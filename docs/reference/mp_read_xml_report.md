# Read an XML variant report

Parse a structured XML variant interpretation report (e.g. from
Molecular Health or similar providers) into a tidy tibble.

## Usage

``` r
mp_read_xml_report(path, provider = "molecular_health")
```

## Arguments

- path:

  Character scalar. Path to the `.xml` file.

- provider:

  Character scalar. Report provider template to apply. Currently
  supported: `"molecular_health"` (default).

## Value

A `molpath_parsed` object whose `data` slot is a
[tibble](https://tibble.tidyverse.org/reference/tibble.html) with one
row per variant and columns for patient info, sample info, gene, variant
description, classification, evidence level, and therapeutic
implications.

## Examples

``` r
# \donttest{
xml_file <- system.file("extdata", "report.xml", package = "molpathR")
if (nzchar(xml_file)) {
  result <- mp_read_xml_report(xml_file, provider = "molecular_health")
  print(result)
}
# }
```
