# Tests for R/example_data.R
# Synthetic db generation, reproducibility, links, and example file writing.

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

test_that("mp_example_db has expected columns", {
  db <- mp_example_db(n_patients = 5, seed = 1)
  expect_true(all(c("patient_id", "age", "sex", "diagnosis") %in%
                    names(db$patients)))
  expect_true(all(c("sample_id", "patient_id", "sample_type") %in%
                    names(db$samples)))
  expect_true(all(c("gene", "variant", "variant_type", "vaf",
                    "ref_allele", "alt_allele") %in% names(db$variants)))
  expect_true(all(c("os_months", "os_status", "pfs_months", "pfs_status") %in%
                    names(db$survival)))
})

test_that("mp_example_db links are referentially consistent", {
  db <- mp_example_db(n_patients = 10, seed = 1)
  expect_true(all(db$samples$patient_id %in% db$patients$patient_id))
  expect_true(all(db$variants$sample_id %in% db$samples$sample_id))
  expect_true(all(db$survival$patient_id %in% db$patients$patient_id))
  expect_true(all(db$clinical$patient_id %in% db$patients$patient_id))
})

test_that("mp_example_db produces in-range VAFs and survival values", {
  db <- mp_example_db(n_patients = 20, seed = 7)
  expect_true(all(db$variants$vaf >= 0.01 & db$variants$vaf <= 0.95))
  expect_true(all(db$survival$os_months >= 6 & db$survival$os_months <= 60))
  expect_true(all(db$survival$os_status %in% c(0L, 1L)))
})

test_that("mp_example_db forces known hotspots for melanoma (BRAF V600E)", {
  db <- mp_example_db(n_patients = 60, seed = 1)
  mel_pat <- db$patients$patient_id[db$patients$diagnosis == "Melanoma"]
  mel_samp <- db$samples$sample_id[db$samples$patient_id %in% mel_pat]
  braf <- db$variants[db$variants$sample_id %in% mel_samp &
                        db$variants$gene == "BRAF", ]
  expect_true(any(braf$variant == "p.V600E"))
})

# ---- mp_example_files --------------------------------------------------------

test_that("mp_example_files writes all expected files", {
  dir <- withr::local_tempdir()
  files <- mp_example_files(dir = dir, seed = 1)
  expect_named(files, c("vcf", "xml", "pdf", "survival", "fastq"))
  expect_length(files$vcf, 5L)
  expect_length(files$xml, 5L)
  expect_true(all(file.exists(files$vcf)))
  expect_true(all(file.exists(files$xml)))
  expect_true(file.exists(files$survival))
  expect_true(file.exists(files$fastq))
})

test_that("mp_example_files output is parseable by the parsers", {
  dir <- withr::local_tempdir()
  files <- mp_example_files(dir = dir, seed = 2)
  vcf <- mp_read_vcf(files$vcf[1])
  expect_true(nrow(vcf$data) > 0L)
  surv <- mp_read_survival(files$survival)
  expect_true(nrow(surv$data) > 0L)
  expect_true("patient_id" %in% names(surv$data))
})

test_that("mp_example_files fastq has 100 four-line records", {
  dir <- withr::local_tempdir()
  files <- mp_example_files(dir = dir, seed = 3)
  lines <- readLines(files$fastq)
  expect_equal(length(lines), 400L)
  expect_true(startsWith(lines[1], "@SYNTH"))
})
