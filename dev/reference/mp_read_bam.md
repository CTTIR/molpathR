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
# \donttest{
bam_file <- system.file("extdata", "example.bam", package = "molpathR")
if (nzchar(bam_file)) {
  result <- mp_read_bam(bam_file)
  print(result)
}
# }
```
