# Read a VCF file

Parse a Variant Call Format (VCF 4.x) file and return a tidy tibble of
variant calls.

## Usage

``` r
mp_read_vcf(path)
```

## Arguments

- path:

  Character scalar. Path to a `.vcf` or `.vcf.gz` file.

## Value

A `molpath_parsed` object whose `data` slot is a
[tibble](https://tibble.tidyverse.org/reference/tibble.html) with
columns `chrom`, `pos`, `id`, `ref`, `alt`, `qual`, `filter`, `info`,
and any sample-level columns present in the file, plus `format` when
declared. Sample names conflicting with these fixed output names are
rejected.

## Details

A validated text parser preserves original ID, INFO, FORMAT and sample
fields for single- and multi-sample VCFs, including gzip input.
Installing VariantAnnotation does not change the returned
representation. Header lines and declared sample names are retained in
the result metadata.

## Examples

``` r
files <- mp_example_files(file.path(tempdir(), "molpathR-example"))
result <- mp_read_vcf(files$vcf[1])
result
#> 
#> ── molpath_parsed ──────────────────────────────────────────────────────────────
#> ℹ Source type: "vcf"
#> ℹ Source file: /tmp/RtmphP3vAW/molpathR-example/vcf/SAM-2024-0001.vcf
#> ℹ Parsed: "2026-11-10 00:03:36"
#> ℹ Data: 8 rows x 10 columns
#> ℹ Columns: chrom, pos, id, ref, alt, qual, filter, info, format, and SAM-2024-0001
#> ℹ Completeness: "100%"
result$data
#> # A tibble: 8 × 10
#>   chrom       pos id    ref   alt    qual filter info     format `SAM-2024-0001`
#>   <chr>     <int> <chr> <chr> <chr> <dbl> <chr>  <chr>    <chr>  <chr>          
#> 1 chr3   76461934 .     A     G       138 PASS   DP=179;… GT     0/1            
#> 2 chr17 136786310 .     C     T       121 PASS   DP=454;… GT     0/1            
#> 3 chr7   24295576 .     T     C        33 PASS   DP=235;… GT     0/1            
#> 4 chr17  11812013 .     C     G       128 PASS   DP=82;A… GT     0/1            
#> 5 chr7   59916136 .     C     T       183 PASS   DP=158;… GT     1/1            
#> 6 chr12  40327002 .     G     T       143 PASS   DP=125;… GT     0/1            
#> 7 chr17  62039588 .     T     G        35 PASS   DP=84;A… GT     0/1            
#> 8 chr17 133018796 .     A     G       163 PASS   DP=269;… GT     0/1            
```
