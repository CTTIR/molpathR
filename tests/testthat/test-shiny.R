# Tests for R/shiny.R
# mp_run_app is interactive; cover guards and the db-passing path with a
# mocked shiny::runApp so the app never actually launches.

test_that("mp_run_app errors when db is not a molpath_db", {
  testthat::local_mocked_bindings(
    runApp = function(...) invisible(NULL),
    .package = "shiny"
  )
  expect_error(mp_run_app(db = list()), "molpath_db")
})

test_that("mp_run_app launches with NULL db (mocked runApp)", {
  called <- FALSE
  testthat::local_mocked_bindings(
    runApp = function(appDir, ...) {
      called <<- TRUE
      invisible(NULL)
    },
    .package = "shiny"
  )
  mp_run_app()
  expect_true(called)
})

test_that("mp_run_app stashes db then clears it on exit", {
  testthat::local_mocked_bindings(
    runApp = function(appDir, ...) {
      # while running, the db should be available in the internal env
      expect_s3_class(molpathR:::.molpathR_env$shiny_db, "molpath_db")
      invisible(NULL)
    },
    .package = "shiny"
  )
  db <- mp_example_db(n_patients = 3, seed = 1)
  mp_run_app(db)
  # cleared after return
  expect_null(molpathR:::.molpathR_env$shiny_db)
})
