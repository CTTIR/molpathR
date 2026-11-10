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

Uses ShortRead when installed, streaming the first requested records
rather than sampling. Otherwise a strict 4-line text parser is used.
Invalid or incomplete records raise an error; backend parse errors are
not hidden.

## Examples

``` r
files <- mp_example_files(file.path(tempdir(), "molpathR-example"))
# \donttest{
# Loading the optional 'ShortRead' backend, when installed, can take
# several seconds.
result <- mp_read_fastq(files$fastq, n = 10)
#> Warning: replacing previous import ‘S4Arrays::makeNindexFromArrayViewport’ by ‘DelayedArray::makeNindexFromArrayViewport’ when loading ‘SummarizedExperiment’
result$data
#> # A tibble: 10 × 4
#>    read_id                                         sequence   quality seq_length
#>    <chr>                                           <chr>      <chr>        <int>
#>  1 SYNTH:1:FLOWCELL:1:1101:6757:7149 1:N:0:ATCACG  CGCCCTATT… )C:1*(…        150
#>  2 SYNTH:2:FLOWCELL:1:1101:9695:2728 1:N:0:ATCACG  GCAAAGAAG… /&.%;,…        150
#>  3 SYNTH:3:FLOWCELL:1:1101:5409:2532 1:N:0:ATCACG  CAGGATGTA… $CG.((…        150
#>  4 SYNTH:4:FLOWCELL:1:1101:4921:5932 1:N:0:ATCACG  GCACATCGA… BI#)0;…        150
#>  5 SYNTH:5:FLOWCELL:1:1101:9250:3922 1:N:0:ATCACG  CGTAGTTTC… 7;<!1;…        150
#>  6 SYNTH:6:FLOWCELL:1:1101:6719:1008 1:N:0:ATCACG  CGAATTATT… IE.HA=…        150
#>  7 SYNTH:7:FLOWCELL:1:1101:5513:7828 1:N:0:ATCACG  TCATGTCTT… %-$(<@…        150
#>  8 SYNTH:8:FLOWCELL:1:1101:9774:9287 1:N:0:ATCACG  CAGGCGCTA… )2:3!8…        150
#>  9 SYNTH:9:FLOWCELL:1:1101:2229:2507 1:N:0:ATCACG  TCCATTAGT… +F-C)I…        150
#> 10 SYNTH:10:FLOWCELL:1:1101:8415:1644 1:N:0:ATCACG CTACACCGA… -<.9!<…        150
# }
```
