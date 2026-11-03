# Build a molpath_db from parsed data objects

Constructs a unified `molpath_db` database object from one or more
`molpath_parsed` objects. Each parsed object is categorized by its
`source_type` and merged into the appropriate database table. Raw
FASTQ/BAM reads remain available through their readers but cannot be
interpreted as variant calls by this function. Unknown gene annotations,
pathogenicity and patient links remain missing. Use
[`mp_validate_db()`](https://cttir.github.io/molpathR/dev/reference/mp_validate_db.md)
to assess incomplete links.

## Usage

``` r
mp_build_db(...)
```

## Arguments

- ...:

  One or more `molpath_parsed` objects, or lists of `molpath_parsed`
  objects. All objects are flattened and processed.

## Value

A `molpath_db` S3 object containing linked patients, samples, variants,
reports, clinical, survival, and metadata tables.

## Details

Source types map to database tables as follows:

- `"vcf"` – non-reference GT calls or explicitly normalized variants

- `"xml_report"` – variants and explicitly identified patients/samples

- `"pdf_report"` – reports

- `"nexus_pathology"` – patients and samples

- `"nexus_clinical"` – clinical

- `"survival"` – survival

## Examples

``` r
# \donttest{
# Build from a molpath_parsed object
surv_parsed <- new_molpath_parsed(
  data = tibble::tibble(
    patient_id = c("P1", "P2"),
    os_months = c(12, 24),
    os_status = c(1L, 0L),
    pfs_months = c(6, 18),
    pfs_status = c(1L, 0L)
  ),
  source_type = "survival",
  source_file = "test.csv"
)
db <- mp_build_db(surv_parsed)
# }
```
