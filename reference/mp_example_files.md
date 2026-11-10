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
files <- mp_example_files(file.path(tempdir(), "molpathR-example"))
str(files)
#> List of 5
#>  $ vcf     : chr [1:5] "/tmp/Rtmp811Chj/molpathR-example/vcf/SAM-2024-0001.vcf" "/tmp/Rtmp811Chj/molpathR-example/vcf/SAM-2024-0002.vcf" "/tmp/Rtmp811Chj/molpathR-example/vcf/SAM-2024-0003.vcf" "/tmp/Rtmp811Chj/molpathR-example/vcf/SAM-2024-0004.vcf" ...
#>  $ xml     : chr [1:5] "/tmp/Rtmp811Chj/molpathR-example/xml/SAM-2024-0001_report.xml" "/tmp/Rtmp811Chj/molpathR-example/xml/SAM-2024-0002_report.xml" "/tmp/Rtmp811Chj/molpathR-example/xml/SAM-2024-0003_report.xml" "/tmp/Rtmp811Chj/molpathR-example/xml/SAM-2024-0004_report.xml" ...
#>  $ pdf     : chr [1:5] "/tmp/Rtmp811Chj/molpathR-example/pdf/SAM-2024-0001_report.txt" "/tmp/Rtmp811Chj/molpathR-example/pdf/SAM-2024-0002_report.txt" "/tmp/Rtmp811Chj/molpathR-example/pdf/SAM-2024-0003_report.txt" "/tmp/Rtmp811Chj/molpathR-example/pdf/SAM-2024-0004_report.txt" ...
#>  $ survival: chr "/tmp/Rtmp811Chj/molpathR-example/survival.csv"
#>  $ fastq   : chr "/tmp/Rtmp811Chj/molpathR-example/ngs/sample.fastq"
readLines(files$vcf[1], n = 5)
#> [1] "##fileformat=VCFv4.2"                                               
#> [2] "##source=molpathR_synthetic_v0.1"                                   
#> [3] "##reference=GRCh38"                                                 
#> [4] "##INFO=<ID=DP,Number=1,Type=Integer,Description=\"Total Depth\">"   
#> [5] "##INFO=<ID=AF,Number=A,Type=Float,Description=\"Allele Frequency\">"
```
