# Cohort-level summary of a molpath_db

Computes summary statistics across all layers of the database.

## Usage

``` r
mp_summary(db)
```

## Arguments

- db:

  A `molpath_db` object.

## Value

An S3 object of class `molpath_summary` (a named list) containing
`n_patients`, `n_samples`, `n_variants`, `n_reports`, `n_clinical`,
`diagnosis_distribution`, `variant_gene_counts`,
`classification_distribution`, `sample_type_distribution`, `date_range`,
and `completeness`.

## Examples

``` r
db <- mp_example_db(n_patients = 20, seed = 1)
mp_summary(db)
#> 
#> ── molpathR Database Summary ───────────────────────────────────────────────────
#> 
#> ── Record counts ──
#> 
#> • Patients: 20
#> • Samples: 36
#> • Variants: 2015
#> • Reports: 36
#> • Clinical: 85
#> 
#> ── Diagnoses ──
#> 
#> • Breast carcinoma: 4
#> • Colorectal carcinoma: 3
#> • Lung adenocarcinoma: 8
#> • Melanoma: 5
#> 
#> ── Top mutated genes ──
#> 
#> • TP53: 275
#> • BRAF: 169
#> • EGFR: 161
#> • KRAS: 157
#> • PIK3CA: 136
#> • ERBB2: 97
#> • NRAS: 94
#> • CDKN2A: 92
#> • PTEN: 91
#> • STK11: 91
#> 
#> ── Completeness ──
#> 
#> • patients_with_samples: 100%
#> • patients_with_variants: 100%
#> • patients_with_survival: 100%
#> • patients_with_clinical: 100%
```
