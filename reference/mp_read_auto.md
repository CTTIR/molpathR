# Automatically read a molecular pathology file

Detect the file type from its extension and/or content, then dispatch to
the appropriate parser.

## Usage

``` r
mp_read_auto(path)
```

## Arguments

- path:

  Character scalar. Path to the file.

## Value

A `molpath_parsed` object produced by the appropriate parser.

## Details

Extension mapping:

- `.vcf`, `.vcf.gz`:
  [`mp_read_vcf`](https://cttir.github.io/molpathR/reference/mp_read_vcf.md)

- `.fastq`, `.fq`, `.fastq.gz`, `.fq.gz`:
  [`mp_read_fastq`](https://cttir.github.io/molpathR/reference/mp_read_fastq.md)

- `.bam`:
  [`mp_read_bam`](https://cttir.github.io/molpathR/reference/mp_read_bam.md)

- `.xml`:
  [`mp_read_xml_report`](https://cttir.github.io/molpathR/reference/mp_read_xml_report.md)

- `.pdf`:
  [`mp_read_pdf_report`](https://cttir.github.io/molpathR/reference/mp_read_pdf_report.md)

- `.xlsx`, `.xls`, `.csv`: tries survival/clinical format detection

## Examples

``` r
# \donttest{
f <- system.file("extdata", "example.vcf", package = "molpathR")
if (nzchar(f)) {
  result <- mp_read_auto(f)
  print(result)
}
# }
```
