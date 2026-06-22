# Tests for R/database.R
# Cover build/add/merge/validate/save/load including source-type dispatch,
# guard errors, NULL/empty handling, and metadata accumulation.

# Helper: build a molpath_parsed of a given source type
mk_parsed <- function(data, source_type, source_file = "x") {
  new_molpath_parsed(data = data, source_type = source_type,
                     source_file = source_file)
}

# ---- mp_build_db -------------------------------------------------------------

test_that("mp_build_db builds survival table from one parsed object", {
  p <- mk_parsed(
    tibble::tibble(patient_id = c("P1", "P2"), os_months = c(12, 24),
                   os_status = c(1L, 0L), pfs_months = c(6, 18),
                   pfs_status = c(1L, 0L)),
    "survival"
  )
  db <- mp_build_db(p)
  expect_s3_class(db, "molpath_db")
  expect_equal(nrow(db$survival), 2L)
  expect_equal(nrow(db$variants), 0L)
})

test_that("mp_build_db dispatches each source type to the correct table", {
  ps <- list(
    mk_parsed(tibble::tibble(sample_id = "S1", gene = "TP53", variant = "x",
                             classification = "VUS", vaf = 0.3), "vcf"),
    mk_parsed(tibble::tibble(sample_id = "S1", report_type = "PDF",
                             report_date = as.Date("2024-01-01"),
                             summary_text = "t", source_file = "f"), "pdf_report"),
    mk_parsed(tibble::tibble(patient_id = "P1", parameter = "Ki-67",
                             value = "20", date = as.Date("2024-01-01"),
                             source = "LIMS"), "nexus_clinical")
  )
  db <- mp_build_db(ps)
  expect_equal(nrow(db$variants), 1L)
  expect_equal(nrow(db$reports), 1L)
  expect_equal(nrow(db$clinical), 1L)
})

# A molpath_parsed whose data slot is a list of tables (as produced internally
# by the xml_report / nexus_pathology parsers for multi-table sources). The
# constructor enforces tibble/data.frame data, so build the object directly.
mk_parsed_list <- function(data, source_type, source_file = "x") {
  structure(
    list(data = data, source_type = source_type, source_file = source_file,
         parse_date = Sys.time()),
    class = "molpath_parsed"
  )
}

test_that("mp_build_db handles xml_report list with variants and reports", {
  p <- mk_parsed_list(
    list(
      variants = tibble::tibble(sample_id = "S1", gene = "BRAF",
                                variant = "p.V600E", classification = "Pathogenic",
                                vaf = 0.4),
      reports = tibble::tibble(sample_id = "S1", report_type = "XML",
                               report_date = as.Date("2024-01-01"),
                               summary_text = "t", source_file = "f")
    ),
    "xml_report"
  )
  db <- mp_build_db(p)
  expect_equal(nrow(db$variants), 1L)
  expect_equal(nrow(db$reports), 1L)
})

test_that("mp_build_db handles nexus_pathology list with patients and samples", {
  p <- mk_parsed_list(
    list(
      patients = tibble::tibble(patient_id = "P1", age = 60L, sex = "M",
                                diagnosis = "Lung"),
      samples = tibble::tibble(sample_id = "S1", patient_id = "P1",
                               sample_type = "FFPE", date = as.Date("2024-01-01"),
                               source_file = "f")
    ),
    "nexus_pathology"
  )
  db <- mp_build_db(p)
  expect_equal(nrow(db$patients), 1L)
  expect_equal(nrow(db$samples), 1L)
})

test_that("mp_build_db warns on unknown source type and skips data", {
  p <- mk_parsed(tibble::tibble(x = 1), "totally_unknown")
  expect_warning(db <- mp_build_db(p), class = "molpathR_unknown_source_type")
  expect_equal(nrow(db$variants), 0L)
})

test_that("mp_build_db errors with no input", {
  expect_error(mp_build_db(), class = "molpathR_no_input")
})

test_that("mp_build_db errors on non-parsed input", {
  expect_error(mp_build_db(42), class = "molpathR_invalid_input")
  expect_error(mp_build_db(list(42)), class = "molpathR_invalid_input")
})

test_that("mp_build_db deduplicates identical rows", {
  row <- tibble::tibble(sample_id = "S1", gene = "TP53", variant = "x",
                        classification = "VUS", vaf = 0.3)
  p1 <- mk_parsed(row, "vcf")
  p2 <- mk_parsed(row, "vcf")
  db <- mp_build_db(p1, p2)
  expect_equal(nrow(db$variants), 1L)
})

# ---- mp_add_data -------------------------------------------------------------

test_that("mp_add_data appends to an existing db", {
  db <- mp_example_db(n_patients = 5, seed = 1)
  n0 <- nrow(db$survival)
  p <- mk_parsed(
    tibble::tibble(patient_id = "NEWPAT", os_months = 12, os_status = 1L,
                   pfs_months = 6, pfs_status = 1L),
    "survival"
  )
  db2 <- mp_add_data(db, p)
  expect_s3_class(db2, "molpath_db")
  expect_equal(nrow(db2$survival), n0 + 1L)
  expect_true("last_updated" %in% names(db2$metadata))
})

test_that("mp_add_data accepts a list of parsed objects", {
  db <- mp_example_db(n_patients = 3, seed = 1)
  ps <- list(
    mk_parsed(tibble::tibble(patient_id = "A", os_months = 1, os_status = 1L,
                             pfs_months = 1, pfs_status = 1L), "survival"),
    mk_parsed(tibble::tibble(patient_id = "B", os_months = 2, os_status = 0L,
                             pfs_months = 1, pfs_status = 0L), "survival")
  )
  db2 <- mp_add_data(db, ps)
  expect_equal(nrow(db2$survival), nrow(db$survival) + 2L)
})

test_that("mp_add_data errors on bad db", {
  p <- mk_parsed(tibble::tibble(x = 1), "vcf")
  expect_error(mp_add_data(list(), p), class = "molpathR_invalid_db")
})

test_that("mp_add_data errors on bad parsed input", {
  db <- mp_example_db(n_patients = 3, seed = 1)
  expect_error(mp_add_data(db, 42), class = "molpathR_invalid_input")
  expect_error(mp_add_data(db, list(42)), class = "molpathR_invalid_input")
})

# ---- mp_merge_db -------------------------------------------------------------

test_that("mp_merge_db combines two databases", {
  db1 <- mp_example_db(n_patients = 5, seed = 1)
  db2 <- mp_example_db(n_patients = 5, seed = 2)
  merged <- mp_merge_db(db1, db2)
  expect_s3_class(merged, "molpath_db")
  expect_equal(nrow(merged$patients), nrow(db1$patients) + nrow(db2$patients))
})

test_that("mp_merge_db unions metadata source files", {
  db1 <- mp_build_db(mk_parsed(
    tibble::tibble(patient_id = "P1", os_months = 1, os_status = 1L,
                   pfs_months = 1, pfs_status = 1L), "survival", "fileA.csv"))
  db2 <- mp_build_db(mk_parsed(
    tibble::tibble(patient_id = "P2", os_months = 2, os_status = 0L,
                   pfs_months = 1, pfs_status = 0L), "survival", "fileB.csv"))
  merged <- mp_merge_db(db1, db2)
  srcs <- unlist(merged$metadata$source_files)
  expect_true(all(c("fileA.csv", "fileB.csv") %in% srcs))
})

test_that("mp_merge_db errors on bad inputs", {
  db <- mp_example_db(n_patients = 3, seed = 1)
  expect_error(mp_merge_db(list(), db), class = "molpathR_invalid_db")
  expect_error(mp_merge_db(db, list()), class = "molpathR_invalid_db")
})

# ---- mp_validate_db ----------------------------------------------------------

test_that("mp_validate_db reports clean example db as valid", {
  db <- mp_example_db(n_patients = 10, seed = 1)
  result <- mp_validate_db(db)
  expect_true(result$valid)
  expect_length(result$issues, 0L)
  expect_true("pct_with_variants" %in% names(result$completeness))
})

test_that("mp_validate_db flags orphan references", {
  db <- mp_example_db(n_patients = 5, seed = 1)
  db$variants$sample_id[1] <- "ORPHAN-SAMPLE"
  result <- mp_validate_db(db)
  expect_false(result$valid)
  expect_gt(length(result$issues), 0L)
})

test_that("mp_validate_db returns NA completeness for empty db", {
  db <- new_molpath_db()
  result <- mp_validate_db(db)
  expect_true(result$valid)
  expect_true(all(is.na(result$completeness)))
})

test_that("mp_validate_db errors on bad input", {
  expect_error(mp_validate_db(list()), class = "molpathR_invalid_db")
})

# ---- mp_save_db / mp_load_db -------------------------------------------------

test_that("mp_save_db and mp_load_db round-trip", {
  db <- mp_example_db(n_patients = 5, seed = 1)
  tmp <- withr::local_tempfile(fileext = ".rds")
  ret <- mp_save_db(db, tmp)
  expect_equal(ret, tmp)
  expect_true(file.exists(tmp))
  db2 <- mp_load_db(tmp)
  expect_s3_class(db2, "molpath_db")
  expect_equal(nrow(db2$patients), nrow(db$patients))
  expect_equal(nrow(db2$variants), nrow(db$variants))
})

test_that("mp_save_db creates output directory if needed", {
  db <- mp_example_db(n_patients = 3, seed = 1)
  base <- withr::local_tempdir()
  tmp <- file.path(base, "nested", "sub", "db.rds")
  mp_save_db(db, tmp)
  expect_true(file.exists(tmp))
})

test_that("mp_save_db warns when db has integrity issues", {
  db <- mp_example_db(n_patients = 5, seed = 1)
  db$variants$sample_id[1] <- "ORPHAN"
  tmp <- withr::local_tempfile(fileext = ".rds")
  expect_warning(mp_save_db(db, tmp), class = "molpathR_validation_warning")
})

test_that("mp_save_db errors on bad db or path", {
  db <- mp_example_db(n_patients = 3, seed = 1)
  expect_error(mp_save_db(list(), tempfile()), class = "molpathR_invalid_db")
  expect_error(mp_save_db(db, NA), class = "molpathR_invalid_path")
  expect_error(mp_save_db(db, c("a", "b")), class = "molpathR_invalid_path")
})

test_that("mp_load_db errors on missing file and bad path", {
  expect_error(mp_load_db(NA), class = "molpathR_invalid_path")
  expect_error(mp_load_db(tempfile(fileext = ".rds")),
               class = "molpathR_file_not_found")
})

test_that("mp_load_db errors when file is not a molpath_db", {
  tmp <- withr::local_tempfile(fileext = ".rds")
  saveRDS(list(a = 1), tmp)
  expect_error(mp_load_db(tmp), class = "molpathR_invalid_db")
})
