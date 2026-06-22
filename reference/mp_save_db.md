# Save a molpath_db to disk

Validates the database and saves it as a compressed RDS file. The file
path is returned invisibly for use in pipelines.

## Usage

``` r
mp_save_db(db, path)
```

## Arguments

- db:

  A `molpath_db` object to save.

- path:

  Character string giving the file path to save to. Should typically end
  in `.rds`.

## Value

The file `path`, returned invisibly.

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
#> ✔ Database saved to /tmp/Rtmp6xchjv/file21d721e11463.rds (38.3 KB).
unlink(tmp)
# }
```
