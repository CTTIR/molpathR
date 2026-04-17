# Read a FASTQ file

Parse a FASTQ file into a tidy tibble of sequencing reads.

## Usage

``` r
mp_read_fastq(path, n = NULL)
```

## Arguments

- path:

  Character scalar. Path to a `.fastq`, `.fq`, `.fastq.gz`, or `.fq.gz`
  file.

- n:

  Integer or `NULL`. If specified, only the first `n` records are
  returned.

## Value

A `molpath_parsed` object whose `data` slot is a
[tibble](https://tibble.tidyverse.org/reference/tibble.html) with
columns `read_id`, `sequence`, `quality`, and `seq_length`.

## Details

Tries
[`ShortRead::readFastq()`](https://rdrr.io/pkg/ShortRead/man/readFastq.html)
first. Falls back to a base-R text parser that reads 4-line FASTQ
records.

## Examples

``` r
# \donttest{
fq_file <- system.file("extdata", "example.fastq", package = "molpathR")
if (nzchar(fq_file)) {
  result <- mp_read_fastq(fq_file, n = 100)
  print(result)
}
# }
```
