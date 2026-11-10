# Automatically read a molecular pathology file

Detect the file type from its extension and/or content, then dispatch to
the appropriate parser.

## Usage

``` r
mp_read_auto(path, source_name = NULL)
```

## Arguments

- path:

  Character scalar. Path to the file.

- source_name:

  Optional original filename for an extensionless upload. Dispatch uses
  its basename, and the result retains that basename as source identity.
  A disposable copy is removed after reading.

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
files <- mp_example_files(file.path(tempdir(), "molpathR-example"))
mp_read_auto(files$vcf[1])
#> ℹ Auto-detected file type: "vcf"
#> 
#> ── molpath_parsed ──────────────────────────────────────────────────────────────
#> ℹ Source type: "vcf"
#> ℹ Source file: /tmp/Rtmp811Chj/molpathR-example/vcf/SAM-2024-0001.vcf
#> ℹ Parsed: "2026-11-10 08:10:09"
#> ℹ Data: 8 rows x 10 columns
#> ℹ Columns: chrom, pos, id, ref, alt, qual, filter, info, format, and SAM-2024-0001
#> ℹ Completeness: "100%"
mp_read_auto(files$survival)
#> ℹ Auto-detected file type: "tabular"
#> ℹ Reading survival data: survival.csv
#> ✔ Parsed 30 patient record(s) with survival data
#> 
#> ── molpath_parsed ──────────────────────────────────────────────────────────────
#> ℹ Source type: "survival"
#> ℹ Source file: /tmp/Rtmp811Chj/molpathR-example/survival.csv
#> ℹ Parsed: "2026-11-10 08:10:09"
#> ℹ Data: 30 rows x 5 columns
#> ℹ Columns: patient_id, os_months, os_status, pfs_months, and pfs_status
#> ℹ Completeness: "100%"
```
