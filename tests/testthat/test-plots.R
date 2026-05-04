test_that("mp_plot_variant_landscape returns ggplot", {
  db <- mp_example_db(n_patients = 10, seed = 1)
  p <- mp_plot_variant_landscape(db, top_n = 5)
  expect_s3_class(p, "ggplot")
})

test_that("mp_plot_mutation_spectrum returns ggplot", {
  db <- mp_example_db(n_patients = 10, seed = 1)
  skip_if(
    !all(c("ref_allele", "alt_allele") %in% names(db$variants)) &&
    !any(grepl("[ACGT]>[ACGT]", db$variants$variant)),
    "No parseable SNV alleles"
  )
  p <- mp_plot_mutation_spectrum(db)
  expect_s3_class(p, "ggplot")
})

test_that("mp_plot_survival returns ggplot", {
  db <- mp_example_db(n_patients = 20, seed = 1)
  p <- mp_plot_survival(db, type = "os")
  expect_s3_class(p, "ggplot")
})

test_that("mp_plot_survival with grouping returns ggplot", {
  db <- mp_example_db(n_patients = 20, seed = 1)
  p <- mp_plot_survival(db, group_by = "diagnosis", type = "os")
  expect_s3_class(p, "ggplot")
})

test_that("mp_plot_cohort_overview returns list of ggplots", {
  db <- mp_example_db(n_patients = 10, seed = 1)
  plots <- mp_plot_cohort_overview(db)
  expect_true(is.list(plots))
  expect_s3_class(plots$diagnosis, "ggplot")
  expect_s3_class(plots$age, "ggplot")
  expect_s3_class(plots$top_genes, "ggplot")
})

test_that("mp_plot_vaf_distribution returns ggplot", {
  db <- mp_example_db(n_patients = 10, seed = 1)
  p <- mp_plot_vaf_distribution(db)
  expect_s3_class(p, "ggplot")
})

test_that("mp_plot_timeline returns ggplot", {
  db <- mp_example_db(n_patients = 10, seed = 1)
  pid <- db$patients$patient_id[1]
  p <- mp_plot_timeline(db, pid)
  expect_s3_class(p, "ggplot")
})
