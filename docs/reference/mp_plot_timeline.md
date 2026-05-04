# Plot patient timeline

Displays a timeline of events for a single patient: sample collections,
report dates, and clinical measurements.

## Usage

``` r
mp_plot_timeline(db, patient_id)
```

## Arguments

- db:

  A `molpath_db` object.

- patient_id:

  A single patient ID.

## Value

A [ggplot2::ggplot](https://ggplot2.tidyverse.org/reference/ggplot.html)
object.

## Examples

``` r
# \donttest{
db <- mp_example_db(n_patients = 20, seed = 1)
pid <- db$patients$patient_id[1]
mp_plot_timeline(db, pid)

# }
```
