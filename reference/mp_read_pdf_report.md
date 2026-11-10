# Read a PDF pathology report

Extract structured information from a pathology PDF report using
[`pdftools::pdf_text()`](https://docs.ropensci.org/pdftools//reference/pdftools.html)
and regex-based section parsing. Complete extracted pages and text are
retained in metadata even when section heuristics match only part of the
report. Database report summaries use that complete text. This does not
perform OCR or validate extraction accuracy against the PDF.

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
# Write a small text PDF to a temporary file and parse it.
pdf_file <- tempfile(fileext = ".pdf")
grDevices::pdf(pdf_file)
graphics::plot.new()
graphics::text(0.02, c(0.9, 0.8, 0.7, 0.6), adj = 0, labels = c(
  "Patient: P001", "Sample: S001",
  "Findings: KRAS G12D detected",
  "Interpretation: pathogenic variant"
))
grDevices::dev.off()
#> agg_record_19e259f1ea72 
#>                       2 
result <- mp_read_pdf_report(pdf_file)
#> ℹ Reading PDF report: file19e24d3c2b4e.pdf (template: generic)
#> ✔ Extracted 3 section(s) from PDF report
result$data
#> # A tibble: 3 × 2
#>   section        content                           
#>   <chr>          <chr>                             
#> 1 sample_info    Sample: S001                      
#> 2 findings       Findings: KRAS G12D detected      
#> 3 interpretation Interpretation: pathogenic variant
unlink(pdf_file)
```
