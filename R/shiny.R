# shiny.R
# Launch function for the molpathR Shiny application
# ---------------------------------------------------

#' Launch the molpathR Shiny application
#'
#' Starts an interactive Shiny application for exploring molecular pathology
#' data. If a `molpath_db` object is provided, the app launches pre-loaded
#' with that database. Otherwise, the user can upload data through the app
#' interface.
#'
#' @param db Optional `molpath_db` object to pre-load into the application.
#' @param ... Additional arguments passed to [shiny::runApp()].
#'
#' @return This function does not return a value; it launches a Shiny app.
#' @export
#'
#' @examples
#' \dontrun{
#' # Launch with example data
#' db <- mp_example_db()
#' mp_run_app(db)
#'
#' # Launch empty — upload data in browser
#' mp_run_app()
#' }
mp_run_app <- function(db = NULL, ...) {
  app_dir <- system.file("shiny", "molpathR", package = "molpathR")
  if (app_dir == "") {
    rlang::abort("Could not find the Shiny app directory. Try reinstalling molpathR.")
  }

  # Pass db via options so the app can pick it up
  if (!is.null(db)) {
    if (!inherits(db, "molpath_db")) {
      rlang::abort("`db` must be a molpath_db object or NULL.")
    }
    .molpathR_env$shiny_db <- db
    on.exit(.molpathR_env$shiny_db <- NULL, add = TRUE)
  }

  shiny::runApp(app_dir, ...)
}

# Internal environment for passing data to Shiny
.molpathR_env <- new.env(parent = emptyenv())
