# Create a new molpath_db object

Constructs a `molpath_db` object, which is a list of linked tibbles
representing the core data model for molecular pathology workflows.

## Usage

``` r
new_molpath_db(
  patients = tibble::tibble(patient_id = character(), age = integer(), sex = character(),
    diagnosis = character()),
  samples = tibble::tibble(sample_id = character(), patient_id = character(), sample_type
    = character(), date = as.Date(character()), source_file = character()),
  variants = tibble::tibble(sample_id = character(), gene = character(), variant =
    character(), classification = character(), vaf = double()),
  reports = tibble::tibble(sample_id = character(), report_type = character(),
    report_date = as.Date(character()), summary_text = character(), source_file =
    character()),
  clinical = tibble::tibble(patient_id = character(), parameter = character(), value =
    character(), date = as.Date(character()), source = character()),
  survival = tibble::tibble(patient_id = character(), os_months = double(), os_status =
    integer(), pfs_months = double(), pfs_status = integer()),
  metadata = list(creation_date = Sys.time(), source_files = character(), parser_versions
    = list())
)
```

## Arguments

- patients:

  A tibble with columns `patient_id`, `age`, `sex`, `diagnosis`, and
  optionally others.

- samples:

  A tibble with columns `sample_id`, `patient_id`, `sample_type`,
  `date`, `source_file`, and optionally others.

- variants:

  A tibble with columns `sample_id`, `gene`, `variant`,
  `classification`, `vaf`, and optionally others.

- reports:

  A tibble with columns `sample_id`, `report_type`, `report_date`,
  `summary_text`, `source_file`, and optionally others.

- clinical:

  A tibble with columns `patient_id`, `parameter`, `value`, `date`,
  `source`, and optionally others.

- survival:

  A tibble with columns `patient_id`, `os_months`, `os_status`,
  `pfs_months`, `pfs_status`, and optionally others.

- metadata:

  A list containing `creation_date` (POSIXct), `source_files` (character
  vector), and `parser_versions` (named list).

## Value

An S3 object of class `molpath_db`.

## Examples

``` r
db <- new_molpath_db()
db
#> 
#> ── molpath_db ──────────────────────────────────────────────────────────────────
#> ℹ patients: 0 records x 4 columns
#> ℹ samples: 0 records x 5 columns
#> ℹ variants: 0 records x 5 columns
#> ℹ reports: 0 records x 5 columns
#> ℹ clinical: 0 records x 5 columns
#> ℹ survival: 0 records x 5 columns
#> ℹ Created: "2026-06-22 08:59:24"
#> ℹ Source files: 0
```
