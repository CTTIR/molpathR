# Launch the molpathR Shiny application

Starts an interactive Shiny application for exploring molecular
pathology data. If a `molpath_db` object is provided, the app launches
pre-loaded with that database. Otherwise, the user can upload data
through the app interface.

## Usage

``` r
mp_run_app(db = NULL, ...)
```

## Arguments

- db:

  Optional `molpath_db` object to pre-load into the application.

- ...:

  Additional arguments passed to
  [`shiny::runApp()`](https://rdrr.io/pkg/shiny/man/runApp.html).

## Value

This function does not return a value; it launches a Shiny app.

## Examples

``` r
if (FALSE) { # \dontrun{
# Launch with example data
db <- mp_example_db()
mp_run_app(db)

# Launch empty — upload data in browser
mp_run_app()
} # }
```
