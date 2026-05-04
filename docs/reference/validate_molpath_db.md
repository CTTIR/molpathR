# Validate a molpath_db object

Checks that all required tables are present, that each is a tibble, and
that mandatory columns exist in each table. Validates referential
integrity between patient and sample identifiers across tables.

## Usage

``` r
validate_molpath_db(x)
```

## Arguments

- x:

  An object of class `molpath_db`.

## Value

The validated `molpath_db` object (invisibly). Throws an error if
validation fails.

## Examples

``` r
db <- new_molpath_db()
validate_molpath_db(db)
```
