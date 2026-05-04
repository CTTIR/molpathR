test_that("new_molpath_db creates valid empty object", {
  db <- new_molpath_db()
  expect_s3_class(db, "molpath_db")
  expect_equal(nrow(db$patients), 0L)
  expect_equal(nrow(db$samples), 0L)
  expect_equal(nrow(db$variants), 0L)
  expect_true(tibble::is_tibble(db$patients))
  expect_true(is.list(db$metadata))
})

test_that("new_molpath_db stores metadata", {
  db <- new_molpath_db()
  expect_true("creation_date" %in% names(db$metadata))
  expect_true("source_files" %in% names(db$metadata))
})

test_that("validate_molpath_db returns db invisibly for valid db", {
  db <- new_molpath_db()
  result <- validate_molpath_db(db)
  expect_s3_class(result, "molpath_db")
})

test_that("print.molpath_db runs without error", {
  db <- new_molpath_db()
  # cli output goes to message connection, not stdout
  expect_no_error(print(db))
})

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

test_that("print.molpath_parsed runs without error", {
  p <- new_molpath_parsed(
    data = tibble::tibble(a = 1),
    source_type = "test",
    source_file = "f.csv"
  )
  # cli output goes to message connection, not stdout
  expect_no_error(print(p))
})
