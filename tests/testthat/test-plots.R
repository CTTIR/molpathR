# Tests for R/plots.R
# Plot builders return ggplot objects; cover grouping arms and error guards.

test_that("mp_plot_variant_landscape returns ggplot", {
  db <- mp_example_db(n_patients = 10, seed = 1)
  p <- mp_plot_variant_landscape(db, top_n = 5)
  expect_s3_class(p, "ggplot")
})

test_that("mp_plot_variant_landscape accepts explicit gene list", {
  db <- mp_example_db(n_patients = 10, seed = 1)
  p <- mp_plot_variant_landscape(db, genes = c("TP53", "KRAS"))
  expect_s3_class(p, "ggplot")
})

test_that("mp_plot_variant_landscape errors on non-db and empty variants", {
  expect_error(mp_plot_variant_landscape(list()), "molpath_db")
  db <- new_molpath_db()
  expect_error(mp_plot_variant_landscape(db), "No variants")
})

test_that("mp_plot_mutation_spectrum returns ggplot", {
  db <- mp_example_db(n_patients = 10, seed = 1)
  p <- mp_plot_mutation_spectrum(db)
  expect_s3_class(p, "ggplot")
})

test_that("mp_plot_mutation_spectrum parses from variant string when no allele cols", {
  db <- new_molpath_db(
    variants = tibble::tibble(
      sample_id = c("S1", "S2"),
      gene = c("TP53", "KRAS"),
      variant = c("c.123A>T", "c.456C>G"),
      classification = c("VUS", "VUS"),
      vaf = c(0.3, 0.4)
    )
  )
  p <- mp_plot_mutation_spectrum(db)
  expect_s3_class(p, "ggplot")
})

test_that("mp_plot_mutation_spectrum errors on non-db and unparseable", {
  expect_error(mp_plot_mutation_spectrum(list()), "molpath_db")
  db <- new_molpath_db(
    variants = tibble::tibble(sample_id = "S1", gene = "TP53",
                              variant = "fusion", classification = "VUS",
                              vaf = 0.3)
  )
  expect_error(mp_plot_mutation_spectrum(db), "No SNVs")
})

test_that("mp_plot_survival returns ggplot for os and pfs", {
  db <- mp_example_db(n_patients = 20, seed = 1)
  expect_s3_class(mp_plot_survival(db, type = "os"), "ggplot")
  expect_s3_class(mp_plot_survival(db, type = "pfs"), "ggplot")
})

test_that("mp_plot_survival with grouping by diagnosis returns ggplot", {
  db <- mp_example_db(n_patients = 30, seed = 1)
  p <- mp_plot_survival(db, group_by = "diagnosis", type = "os")
  expect_s3_class(p, "ggplot")
})

test_that("mp_plot_survival with gene grouping returns ggplot", {
  db <- mp_example_db(n_patients = 30, seed = 1)
  p <- mp_plot_survival(db, group_by = "TP53", type = "os")
  expect_s3_class(p, "ggplot")
})

test_that("mp_plot_survival errors on non-db and empty survival", {
  expect_error(mp_plot_survival(list()), "molpath_db")
  db <- new_molpath_db()
  expect_error(mp_plot_survival(db), "No survival data")
})

test_that("mp_plot_cohort_overview returns list of ggplots", {
  db <- mp_example_db(n_patients = 10, seed = 1)
  plots <- mp_plot_cohort_overview(db)
  expect_named(plots, c("diagnosis", "age", "sample_types", "top_genes"))
  expect_s3_class(plots$diagnosis, "ggplot")
  expect_s3_class(plots$age, "ggplot")
  expect_s3_class(plots$top_genes, "ggplot")
})

test_that("mp_plot_cohort_overview errors on non-db", {
  expect_error(mp_plot_cohort_overview(list()), "molpath_db")
})

test_that("mp_plot_vaf_distribution returns ggplot, with and without gene", {
  db <- mp_example_db(n_patients = 10, seed = 1)
  expect_s3_class(mp_plot_vaf_distribution(db), "ggplot")
  expect_s3_class(mp_plot_vaf_distribution(db, gene = c("TP53", "KRAS")), "ggplot")
})

test_that("mp_plot_vaf_distribution errors on non-db and empty", {
  expect_error(mp_plot_vaf_distribution(list()), "molpath_db")
  db <- new_molpath_db()
  expect_error(mp_plot_vaf_distribution(db), "No variants")
})

test_that("mp_plot_timeline returns ggplot", {
  db <- mp_example_db(n_patients = 10, seed = 1)
  pid <- db$patients$patient_id[1]
  p <- mp_plot_timeline(db, pid)
  expect_s3_class(p, "ggplot")
})

test_that("mp_plot_timeline errors on non-db and patient with no events", {
  expect_error(mp_plot_timeline(list(), "x"), "molpath_db")
  db <- mp_example_db(n_patients = 5, seed = 1)
  suppressWarnings(
    expect_error(mp_plot_timeline(db, "NONEXISTENT"), "No timeline events")
  )
})
