# Write synthetic example files to a directory

Creates a set of realistic mock files that can be used to test the
molpathR import pipeline. Files include VCF, XML, text-based PDF-like
reports, a survival CSV, and a tiny FASTQ file.

## Usage

``` r
mp_example_files(
  dir = tempdir(),
  seed = 42,
  reference_date = as.Date("2025-01-01")
)
```

## Arguments

- dir:

  Character. Directory where files are written. Default
  [`tempdir()`](https://rdrr.io/r/base/tempfile.html).

- seed:

  Integer. Random seed for reproducibility. Default `42`. The caller's
  random-number state is restored, including on error.

- reference_date:

  Date. Fixed anchor for synthetic report dates; default 2025-01-01.
  File contents do not depend on the day they are generated.

## Value

A named list of file paths:

- vcf:

  Character vector of 5 VCF file paths.

- xml:

  Character vector of 5 XML report file paths.

- pdf:

  Character vector of 5 text-based mock PDF report paths.

- survival:

  Path to the survival CSV file.

- fastq:

  Path to the sample FASTQ file.

## Examples

``` r
# \donttest{
files <- mp_example_files()
readLines(files$vcf[1], n = 5)
#> [1] "##fileformat=VCFv4.2"                                               
#> [2] "##source=molpathR_synthetic_v0.1"                                   
#> [3] "##reference=GRCh38"                                                 
#> [4] "##INFO=<ID=DP,Number=1,Type=Integer,Description=\"Total Depth\">"   
#> [5] "##INFO=<ID=AF,Number=A,Type=Float,Description=\"Allele Frequency\">"
# }
```
