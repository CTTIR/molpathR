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
description, classification, evidence level, therapeutic implications
and an explicit VAF proportion when supplied. VAF must be between 0 and
1, inclusive; percentages or other units are not inferred.

## Examples

``` r
files <- mp_example_files(file.path(tempdir(), "molpathR-example"))
result <- mp_read_xml_report(files$xml[1], provider = "molecular_health")
#> ℹ Reading XML report: SAM-2024-0001_report.xml (provider: molecular_health)
#> ✔ Parsed 7 variant(s) from XML report
result
#> 
#> ── molpath_parsed ──────────────────────────────────────────────────────────────
#> ℹ Source type: "xml_report"
#> ℹ Source file: /tmp/Rtmp811Chj/molpathR-example/xml/SAM-2024-0001_report.xml
#> ℹ Parsed: "2026-11-10 08:10:21"
#> ℹ Data: 7 rows x 10 columns
#> ℹ Columns: patient_id, patient_name, sample_id, sample_type, gene, variant, classification, vaf, evidence, and therapeutic
#> ℹ Completeness: "60%"
result$data
#> # A tibble: 7 × 10
#>   patient_id    patient_name sample_id  sample_type gene  variant classification
#>   <chr>         <chr>        <chr>      <chr>       <chr> <chr>   <chr>         
#> 1 PAT-2024-0001 NA           SAM-2024-… NA          BRCA1 p.A170… Pathogenic    
#> 2 PAT-2024-0001 NA           SAM-2024-… NA          TP53  p.Y220C Likely benign 
#> 3 PAT-2024-0001 NA           SAM-2024-… NA          ERBB2 p.T798M VUS           
#> 4 PAT-2024-0001 NA           SAM-2024-… NA          ERBB2 p.V842I Likely pathog…
#> 5 PAT-2024-0001 NA           SAM-2024-… NA          ERBB2 p.G309A Benign        
#> 6 PAT-2024-0001 NA           SAM-2024-… NA          TP53  p.H179R VUS           
#> 7 PAT-2024-0001 NA           SAM-2024-… NA          PTEN  p.K267… VUS           
#> # ℹ 3 more variables: vaf <dbl>, evidence <chr>, therapeutic <chr>
```
