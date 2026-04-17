# Read a PDF pathology report

Extract structured information from a pathology PDF report using
[`pdftools::pdf_text()`](https://docs.ropensci.org/pdftools//reference/pdftools.html)
and regex-based section parsing.

## Usage

``` r
mp_read_pdf_report(path, template = "generic")
```

## Arguments

- path:

  Character scalar. Path to the `.pdf` file.

- template:

  Character scalar. Template name controlling which regex patterns are
  applied. Currently `"generic"` (default) is supported.

## Value

A `molpath_parsed` object whose `data` slot is a
[tibble](https://tibble.tidyverse.org/reference/tibble.html) with
columns `section` and `content` extracted from the report (Patient,
Sample, Findings, Interpretation, Recommendations).

## Examples

``` r
# \donttest{
pdf_file <- system.file("extdata", "report.pdf", package = "molpathR")
if (nzchar(pdf_file)) {
  result <- mp_read_pdf_report(pdf_file)
  print(result)
}
# }
```
