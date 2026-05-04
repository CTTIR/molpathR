test_that("mp_example_db returns valid molpath_db", {
  db <- mp_example_db(n_patients = 10, seed = 1)
  expect_s3_class(db, "molpath_db")
  expect_equal(nrow(db$patients), 10L)
  expect_true(nrow(db$samples) > 0L)
  expect_true(nrow(db$variants) > 0L)
  expect_true(nrow(db$survival) > 0L)
})

test_that("mp_example_db is reproducible with seed", {
  db1 <- mp_example_db(n_patients = 5, seed = 99)
  db2 <- mp_example_db(n_patients = 5, seed = 99)
  expect_identical(db1$patients, db2$patients)
  expect_identical(db1$variants, db2$variants)
})

test_that("mp_example_db has correct column names", {
  db <- mp_example_db(n_patients = 5, seed = 1)
  expect_true("patient_id" %in% names(db$patients))
  expect_true("sample_id" %in% names(db$samples))
  expect_true("gene" %in% names(db$variants))
  expect_true("os_months" %in% names(db$survival))
})

test_that("mp_example_db links are consistent", {
  db <- mp_example_db(n_patients = 10, seed = 1)
  # All sample patient_ids should exist in patients
  expect_true(all(db$samples$patient_id %in% db$patients$patient_id))
  # All variant sample_ids should exist in samples
  expect_true(all(db$variants$sample_id %in% db$samples$sample_id))
  # All survival patient_ids should exist in patients
  expect_true(all(db$survival$patient_id %in% db$patients$patient_id))
})
