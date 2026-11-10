# Read a BAM file

Parse a BAM (Binary Alignment Map) file into a tidy tibble.

## Usage

``` r
mp_read_bam(path, regions = NULL)
```

## Arguments

- path:

  Character scalar. Path to a `.bam` file.

- regions:

  Character scalar or `NULL`. An optional genomic region string such as
  `"chr1:1000-2000"` to restrict the query.

## Value

A `molpath_parsed` object whose `data` slot is a
[tibble](https://tibble.tidyverse.org/reference/tibble.html) with
columns `qname`, `flag`, `rname`, `pos`, `mapq`, `cigar`, `seq`, and
`qual`.

## Details

Uses
[`Rsamtools::scanBam()`](https://rdrr.io/pkg/Rsamtools/man/scanBam.html)
when installed. Otherwise it calls `samtools view`; if neither is
available an informative error is raised. Backend decoding errors are
reported rather than triggering another reader.

## Examples

``` r
# Building a BAM file requires the optional Bioconductor package Rsamtools.
if (requireNamespace("Rsamtools", quietly = TRUE)) {
  root <- tempfile("molpathR-bam-")
  dir.create(root)
  sam <- file.path(root, "tiny.sam")
  writeLines(c(
    "@HD\tVN:1.6\tSO:coordinate", "@SQ\tSN:chr1\tLN:1000",
    "q1\t0\tchr1\t11\t60\t4M\t*\t0\t0\tACGT\tIIII",
    "q2\t0\tchr1\t21\t40\t4M\t*\t0\t0\tTGCA\tJJJJ"
  ), sam)
  bam <- Rsamtools::asBam(sam, destination = file.path(root, "tiny"))
  mp_read_bam(bam)$data
  unlink(root, recursive = TRUE)
}
#> ℹ Reading BAM file: tiny.bam
#> ℹ Using Rsamtools backend
#> ✔ Parsed 2 alignment(s) via Rsamtools
```
