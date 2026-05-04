test_that("mp_query_patients filters correctly", {
  db <- mp_example_db(n_patients = 20, seed = 1)
  result <- mp_query_patients(db, sex == "F")
  expect_true(all(result$sex == "F"))
  expect_true(nrow(result) > 0L)
  expect_true(nrow(result) < nrow(db$patients))
})

test_that("mp_query_variants filters by gene", {
  db <- mp_example_db(n_patients = 20, seed = 1)
  result <- mp_query_variants(db, genes = "TP53")
  expect_true(all(result$gene == "TP53"))
})

test_that("mp_query_variants filters by VAF", {
  db <- mp_example_db(n_patients = 20, seed = 1)
  result <- mp_query_variants(db, min_vaf = 0.3)
  expect_true(all(result$vaf >= 0.3))
})

test_that("mp_get_patient returns all layers", {
  db <- mp_example_db(n_patients = 10, seed = 1)
  pid <- db$patients$patient_id[1]
  pat <- mp_get_patient(db, pid)
  expect_true(is.list(pat))
  expect_equal(nrow(pat$patient), 1L)
  expect_true(all(pat$samples$patient_id == pid))
})

test_that("mp_get_patient warns for missing patient", {
  db <- mp_example_db(n_patients = 5, seed = 1)
  expect_warning(mp_get_patient(db, "NONEXISTENT"))
})

test_that("mp_summary returns molpath_summary", {
  db <- mp_example_db(n_patients = 10, seed = 1)
  s <- mp_summary(db)
  expect_s3_class(s, "molpath_summary")
  expect_equal(s$n_patients, 10L)
})

test_that("mp_search finds matching records", {
  db <- mp_example_db(n_patients = 20, seed = 1)
  result <- mp_search(db, "TP53")
  expect_true(is.list(result))
  expect_true(length(result) > 0L)
})

test_that("mp_query_samples works", {
  db <- mp_example_db(n_patients = 10, seed = 1)
  result <- mp_query_samples(db, sample_type == "FFPE")
  expect_true(all(result$sample_type == "FFPE"))
})
