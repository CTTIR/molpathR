# Validate a molpath_db object

Checks that all required tables are present, that each is a tibble, and
that mandatory columns, types, value ranges and primary identifiers are
valid. Incomplete cross-table links are reported as warnings; use
[`mp_validate_db()`](https://cttir.github.io/molpathR/dev/reference/mp_validate_db.md)
for a structured link report. Missing parent evidence is not fabricated.

## Usage

``` r
validate_molpath_db(x)
```

## Arguments

- x:

  An object of class `molpath_db`.

## Value

The original `molpath_db` object (invisibly). Structural or value
corruption raises an error. Incomplete links warn and remain unchanged.

## Examples

``` r
db <- new_molpath_db()
validate_molpath_db(db)
```
