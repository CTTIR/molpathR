# Summarise a molpath_db object

Prints a detailed summary of a `molpath_db`, including per-table
completeness, unique counts for key columns, and metadata.

## Usage

``` r
# S3 method for class 'molpath_db'
summary(object, ...)
```

## Arguments

- object:

  A `molpath_db` object.

- ...:

  Additional arguments (ignored).

## Value

The `molpath_db` object (invisibly).

## Examples

``` r
db <- mp_example_db(n_patients = 10, seed = 1)
summary(db)
#> 
#> ── molpath_db Summary ──────────────────────────────────────────────────────────
#> 
#> ── Patients (10) ──
#> 
#> ℹ Sex distribution: "F=2, M=8"
#> ℹ Unique diagnoses: 3
#> 
#> ── Samples (24) ──
#> 
#> ℹ Sample types: "Fresh frozen, Tumor tissue, FFPE, Liquid biopsy"
#> ℹ Patients with samples: 10
#> 
#> ── Variants (2042) ──
#> 
#> ℹ Unique genes: 20
#> ℹ Classifications: "Likely pathogenic, Pathogenic, Likely benign, VUS, Benign"
#> 
#> ── Reports (24) ──
#> 
#> ℹ Report types: "Clinical Report, Molecular Health XML, Pathology PDF"
#> 
#> ── Clinical (40) ──
#> 
#> ℹ Parameters: "TNM_M, PD-L1 TPS, TNM_N, MSI status, TNM_T, Ki-67, Grading"
#> 
#> ── Survival (10) ──
#> 
#> ℹ OS data available: 10/10
#> ℹ PFS data available: 10/10
#> 
#> ── Metadata ──
#> 
#> ℹ Created: "2026-11-10 19:27:07"
#> ℹ Source files: 0
```
