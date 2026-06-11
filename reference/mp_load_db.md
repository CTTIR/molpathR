# Load a molpath_db from disk

Reads an RDS file, verifies it contains a valid `molpath_db` object, and
prints a summary of the loaded database.

## Usage

``` r
mp_load_db(path)
```

## Arguments

- path:

  Character string giving the file path to an RDS file containing a
  `molpath_db` object.

## Value

A `molpath_db` object.

## Examples

``` r
# \donttest{
db <- mp_example_db(n_patients = 5, seed = 1)
tmp <- tempfile(fileext = ".rds")
mp_save_db(db, tmp)
#> 
#> ── Saving molpath database ──
#> 
#> ── Validating molpath database ──
#> 
#> ✔ No referential integrity issues found.
#> 
#> ── Data completeness 
#> • Patients with samples: 100%
#> • Patients with variants: 100%
#> • Patients with reports: 100%
#> • Patients with clinical: 100%
#> • Patients with survival: 100%
#> ✔ Database saved to /tmp/Rtmp7GSRYF/file226b116e5d78.rds (38.3 KB).
db2 <- mp_load_db(tmp)
#> 
#> ── Loading molpath database ──
#> 
#> ✔ Database loaded from /tmp/Rtmp7GSRYF/file226b116e5d78.rds.
#> ℹ Contents: 5 patients, 11 samples, 2011 variants, 11 reports, 20 clinical records, 5 survival records.
unlink(tmp)
# }
```
