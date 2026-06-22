# Tests for R/classes.R
# Constructors, validation guards, and S3 print/summary methods.

# ---- new_molpath_db ----------------------------------------------------------

test_that("new_molpath_db creates valid empty object", {
  db <- new_molpath_db()
  expect_s3_class(db, "molpath_db")
  expect_equal(nrow(db$patients), 0L)
  expect_equal(nrow(db$samples), 0L)
  expect_equal(nrow(db$variants), 0L)
  expect_true(tibble::is_tibble(db$patients))
  expect_true(is.list(db$metadata))
})

test_that("new_molpath_db stores metadata fields", {
  db <- new_molpath_db()
  expect_true(all(c("creation_date", "source_files", "parser_versions") %in%
                    names(db$metadata)))
})

# ---- validate_molpath_db -----------------------------------------------------

test_that("validate_molpath_db returns db invisibly for valid db", {
  db <- new_molpath_db()
  result <- validate_molpath_db(db)
  expect_s3_class(result, "molpath_db")
})

test_that("validate_molpath_db rejects non-molpath_db", {
  expect_error(validate_molpath_db(list()), class = "rlang_error")
})

test_that("validate_molpath_db errors on missing table", {
  db <- new_molpath_db()
  db$variants <- NULL
  expect_error(validate_molpath_db(db), "Missing required table")
})

test_that("validate_molpath_db errors when a table is not a tibble", {
  db <- new_molpath_db()
  db$variants <- data.frame()
  expect_error(validate_molpath_db(db), "must be a tibble")
})

test_that("validate_molpath_db errors on missing required column", {
  db <- new_molpath_db()
  db$patients <- tibble::tibble(patient_id = character())
  expect_error(validate_molpath_db(db), "missing required column")
})

test_that("validate_molpath_db errors on missing metadata field", {
  db <- new_molpath_db()
  db$metadata <- list(creation_date = Sys.time())
  expect_error(validate_molpath_db(db), "missing required field")
})

test_that("validate_molpath_db warns about orphan samples", {
  db <- new_molpath_db(
    patients = tibble::tibble(patient_id = "P1", age = 60L, sex = "M",
                              diagnosis = "Lung"),
    samples = tibble::tibble(sample_id = "S1", patient_id = "ORPHAN",
                             sample_type = "FFPE", date = as.Date("2024-01-01"),
                             source_file = "f")
  )
  expect_warning(validate_molpath_db(db), "not found in patients")
})

# ---- print/summary molpath_db ------------------------------------------------

test_that("print.molpath_db runs on empty and populated db", {
  expect_no_error(print(new_molpath_db()))
  db <- mp_example_db(n_patients = 5, seed = 1)
  expect_invisible(print(db))
})

test_that("summary.molpath_db runs on empty and populated db", {
  expect_no_error(summary(new_molpath_db()))
  db <- mp_example_db(n_patients = 5, seed = 1)
  res <- summary(db)
  expect_s3_class(res, "molpath_db")
})

# ---- new_molpath_parsed ------------------------------------------------------

test_that("new_molpath_parsed creates valid object", {
  p <- new_molpath_parsed(
    data = tibble::tibble(x = 1:3),
    source_type = "test",
    source_file = "test.csv"
  )
  expect_s3_class(p, "molpath_parsed")
  expect_equal(nrow(p$data), 3L)
  expect_equal(p$source_type, "test")
})

test_that("new_molpath_parsed coerces data.frame to tibble", {
  p <- new_molpath_parsed(data = data.frame(a = 1), source_type = "csv",
                          source_file = "f.csv")
  expect_true(tibble::is_tibble(p$data))
})

test_that("new_molpath_parsed validates argument types", {
  expect_error(new_molpath_parsed(data = 1, source_type = "x",
                                  source_file = "f"))
  expect_error(new_molpath_parsed(data = tibble::tibble(),
                                  source_type = c("a", "b"),
                                  source_file = "f"))
  expect_error(new_molpath_parsed(data = tibble::tibble(),
                                  source_type = "x",
                                  source_file = 1))
})

test_that("print.molpath_parsed runs without error", {
  p <- new_molpath_parsed(
    data = tibble::tibble(a = 1:2, b = c("x", NA)),
    source_type = "test", source_file = "f.csv"
  )
  expect_invisible(print(p))
  # empty data branch (no columns)
  expect_no_error(print(new_molpath_parsed(source_type = "t", source_file = "f")))
})

test_that("summary.molpath_parsed reports column details", {
  p <- new_molpath_parsed(
    data = tibble::tibble(a = 1:3, b = c("x", "y", NA)),
    source_type = "test", source_file = "f.csv"
  )
  res <- summary(p)
  expect_s3_class(res, "molpath_parsed")
  # empty-data branch
  expect_no_error(summary(new_molpath_parsed(source_type = "t",
                                             source_file = "f")))
})
