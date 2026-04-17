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
and any sample-level columns present in the file.

## Details

The function first attempts to use
[`VariantAnnotation::readVcf()`](https://rdrr.io/pkg/VariantAnnotation/man/readVcf-methods.html)
from Bioconductor. If the package is not installed it falls back to a
lightweight text parser that handles single- and multi-sample VCFs.

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
