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
# \donttest{
vcf_file <- system.file("extdata", "example.vcf", package = "molpathR")
if (nzchar(vcf_file)) {
  result <- mp_read_vcf(vcf_file)
  print(result)
}
# }
```
