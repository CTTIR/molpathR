#' @keywords internal
"_PACKAGE"

## usethis namespace: start
#' @importFrom rlang .data .env %||%
## usethis namespace: end
NULL

# Declare imports that are used by the Shiny app in inst/ but not
# directly in R/ code.
# R CMD check requires that all Imports are referenced somewhere.
#' @importFrom DT datatable
#' @importFrom bslib bs_theme
#' @importFrom plotly ggplotly
#' @importFrom shinyWidgets pickerInput
#' @importFrom jsonlite toJSON
#' @importFrom tidyr pivot_longer
#' @importFrom methods as
NULL
