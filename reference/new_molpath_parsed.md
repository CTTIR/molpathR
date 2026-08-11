# Create a new molpath_parsed object

Constructs a `molpath_parsed` object representing the result of parsing
a single data source. This serves as an intermediate representation
before data is integrated into a `molpath_db`.

## Usage

``` r
new_molpath_parsed(
  data = tibble::tibble(),
  source_type = character(1L),
  source_file = character(1L),
  parse_date = Sys.time()
)
```

## Arguments

- data:

  A tibble (or data frame) containing the parsed data.

- source_type:

  A character string identifying the source type (e.g., `"vcf"`,
  `"xml_report"`, `"pdf_report"`, `"excel"`, `"csv"`).

- source_file:

  A character string with the path to the source file.

- parse_date:

  A `POSIXct` timestamp of when the data was parsed. Defaults to the
  current time.

## Value

An S3 object of class `molpath_parsed`.

## Examples

``` r
parsed <- new_molpath_parsed(
  data = tibble::tibble(gene = "BRAF", variant = "V600E"),
  source_type = "vcf",
  source_file = "sample1.vcf"
)
parsed
#> 
#> ── molpath_parsed ──────────────────────────────────────────────────────────────
#> ℹ Source type: "vcf"
#> ℹ Source file: sample1.vcf
#> ℹ Parsed: "2026-08-11 14:39:24"
#> ℹ Data: 1 row x 2 columns
#> ℹ Columns: gene and variant
#> ℹ Completeness: "100%"
```
