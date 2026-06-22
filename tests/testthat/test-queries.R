# Tests for R/queries.R
# Filtering, dispatch arms, empty/missing returns, guards and S3 print.

# ---- mp_query_patients -------------------------------------------------------

test_that("mp_query_patients filters correctly", {
  db <- mp_example_db(n_patients = 20, seed = 1)
  result <- mp_query_patients(db, sex == "F")
  expect_true(all(result$sex == "F"))
  expect_true(nrow(result) > 0L)
  expect_true(nrow(result) < nrow(db$patients))
})

test_that("mp_query_patients errors on non-db", {
  expect_error(mp_query_patients(list()), "molpath_db")
})

# ---- mp_query_variants -------------------------------------------------------

test_that("mp_query_variants filters by gene", {
  db <- mp_example_db(n_patients = 20, seed = 1)
  result <- mp_query_variants(db, genes = "TP53")
  expect_true(all(result$gene == "TP53"))
})

test_that("mp_query_variants filters by VAF bounds", {
  db <- mp_example_db(n_patients = 20, seed = 1)
  result <- mp_query_variants(db, min_vaf = 0.3, max_vaf = 0.6)
  expect_true(all(result$vaf >= 0.3 & result$vaf <= 0.6))
})

test_that("mp_query_variants filters by classification and variant_type", {
  db <- mp_example_db(n_patients = 20, seed = 1)
  result <- mp_query_variants(db, classification = "Pathogenic",
                              variant_type = "SNV")
  expect_true(all(result$classification == "Pathogenic"))
  expect_true(all(result$variant_type == "SNV"))
})

test_that("mp_query_variants classification/variant_type actually filter (regression)", {
  # Regression for a data-mask name collision where the column name shadowed
  # the argument, making classification/variant_type filters no-ops.
  db <- mp_example_db(n_patients = 20, seed = 1)
  r_class <- mp_query_variants(db, classification = "Pathogenic")
  expect_true(nrow(r_class) < nrow(db$variants))
  expect_setequal(unique(r_class$classification), "Pathogenic")

  r_type <- mp_query_variants(db, variant_type = "Fusion")
  expect_true(nrow(r_type) < nrow(db$variants))
  expect_setequal(unique(r_type$variant_type), "Fusion")
})

test_that("mp_query_variants with all NULL returns all variants", {
  db <- mp_example_db(n_patients = 10, seed = 1)
  result <- mp_query_variants(db)
  expect_equal(nrow(result), nrow(db$variants))
})

test_that("mp_query_variants errors on non-db", {
  expect_error(mp_query_variants(list()), "molpath_db")
})

# ---- mp_query_samples --------------------------------------------------------

test_that("mp_query_samples works", {
  db <- mp_example_db(n_patients = 10, seed = 1)
  result <- mp_query_samples(db, sample_type == "FFPE")
  expect_true(all(result$sample_type == "FFPE"))
})

test_that("mp_query_samples errors on non-db", {
  expect_error(mp_query_samples(list()), "molpath_db")
})

# ---- mp_get_patient ----------------------------------------------------------

test_that("mp_get_patient returns all layers", {
  db <- mp_example_db(n_patients = 10, seed = 1)
  pid <- db$patients$patient_id[1]
  pat <- mp_get_patient(db, pid)
  expect_named(pat, c("patient", "samples", "variants", "reports",
                      "clinical", "survival"))
  expect_equal(nrow(pat$patient), 1L)
  expect_true(all(pat$samples$patient_id == pid))
})

test_that("mp_get_patient warns and returns empty layers for missing patient", {
  db <- mp_example_db(n_patients = 5, seed = 1)
  expect_warning(pat <- mp_get_patient(db, "NONEXISTENT"), "not found")
  expect_equal(nrow(pat$patient), 0L)
  expect_equal(nrow(pat$samples), 0L)
})

test_that("mp_get_patient errors on non-scalar id and non-db", {
  db <- mp_example_db(n_patients = 5, seed = 1)
  expect_error(mp_get_patient(db, c("a", "b")), "single value")
  expect_error(mp_get_patient(list(), "x"), "molpath_db")
})

# ---- mp_summary --------------------------------------------------------------

test_that("mp_summary returns molpath_summary with expected fields", {
  db <- mp_example_db(n_patients = 10, seed = 1)
  s <- mp_summary(db)
  expect_s3_class(s, "molpath_summary")
  expect_equal(s$n_patients, 10L)
  expect_true(all(c("completeness", "variant_gene_counts",
                    "diagnosis_distribution") %in% names(s)))
})

test_that("mp_summary handles empty db", {
  s <- mp_summary(new_molpath_db())
  expect_equal(s$n_patients, 0L)
  expect_true(all(is.na(s$completeness)))
})

test_that("mp_summary errors on non-db", {
  expect_error(mp_summary(list()), "molpath_db")
})

test_that("print.molpath_summary runs on populated and empty summaries", {
  db <- mp_example_db(n_patients = 10, seed = 1)
  expect_invisible(print(mp_summary(db)))
  expect_no_error(print(mp_summary(new_molpath_db())))
})

# ---- mp_search ---------------------------------------------------------------

test_that("mp_search finds matching records", {
  db <- mp_example_db(n_patients = 20, seed = 1)
  result <- mp_search(db, "TP53")
  expect_true(is.list(result))
  expect_true(length(result) > 0L)
  expect_true("variants" %in% names(result))
})

test_that("mp_search returns empty list when nothing matches", {
  db <- mp_example_db(n_patients = 5, seed = 1)
  result <- mp_search(db, "ZZZ-NO-MATCH-ZZZ")
  expect_length(result, 0L)
})

test_that("mp_search errors on bad inputs", {
  db <- mp_example_db(n_patients = 5, seed = 1)
  expect_error(mp_search(list(), "x"), "molpath_db")
  expect_error(mp_search(db, 1), "single character")
  expect_error(mp_search(db, c("a", "b")), "single character")
})
