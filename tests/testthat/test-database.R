test_that("mp_save_db and mp_load_db round-trip", {
  db <- mp_example_db(n_patients = 5, seed = 1)
  tmp <- tempfile(fileext = ".rds")
  on.exit(unlink(tmp), add = TRUE)
  mp_save_db(db, tmp)
  expect_true(file.exists(tmp))
  db2 <- mp_load_db(tmp)
  expect_s3_class(db2, "molpath_db")
  expect_equal(nrow(db2$patients), nrow(db$patients))
  expect_equal(nrow(db2$variants), nrow(db$variants))
})

test_that("mp_validate_db works on example db", {
  db <- mp_example_db(n_patients = 10, seed = 1)
  result <- mp_validate_db(db)
  expect_true(is.list(result))
  expect_true("valid" %in% names(result))
  expect_true(result$valid)
})

test_that("mp_merge_db combines two databases", {
  db1 <- mp_example_db(n_patients = 5, seed = 1)
  db2 <- mp_example_db(n_patients = 5, seed = 2)
  merged <- mp_merge_db(db1, db2)
  expect_s3_class(merged, "molpath_db")
  expect_gte(nrow(merged$patients), nrow(db1$patients))
})
