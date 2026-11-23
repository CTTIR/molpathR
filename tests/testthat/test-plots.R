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

# ---- Legibility and colour regressions -----------------------------------------

test_that("variant landscape keys only classifications that are present", {
  db <- new_molpath_db(
    samples = tibble::tibble(sample_id = c("S1", "S2"), patient_id = c("P1", "P2"),
                             sample_type = "FFPE", date = as.Date(NA), source_file = NA_character_),
    variants = tibble::tibble(sample_id = c("S1", "S2"), gene = "TP53",
                              variant = c("p.R175H", "p.R248Q"),
                              classification = c("Pathogenic", "VUS"), vaf = c(0.3, 0.4))
  )
  p <- suppressWarnings(mp_plot_variant_landscape(db))
  expect_false("Unclassified" %in% levels(p$data$classification))
  db$variants$classification[2] <- "Odd label"
  p <- suppressWarnings(mp_plot_variant_landscape(db))
  expect_true("Unclassified" %in% levels(p$data$classification))
  expect_gte(p$theme$axis.text.x$size, 7)
})

test_that("survival groups use colour-blind-safe colours and mark censoring", {
  db <- mp_example_db(n_patients = 30, seed = 1)
  p <- mp_plot_survival(db, group_by = "diagnosis", type = "os")
  built <- ggplot2::ggplot_build(p)
  colours <- unique(built$data[[1]]$colour)
  expect_true(all(colours %in% molpathR:::mp_okabe_ito()))
  expect_false(any(c("#E41A1C", "#4DAF4A") %in% colours))
  geoms <- vapply(p$layers, function(l) class(l$geom)[1], character(1))
  expect_true("GeomPoint" %in% geoms)
  text_layer <- p$layers[[which(geoms == "GeomText")]]
  expect_equal(text_layer$data$x, 0)
})

test_that("survival gene note is dropped when stratification collapses", {
  db <- mp_example_db(n_patients = 20, seed = 1)
  expect_warning(p <- mp_plot_survival(db, group_by = "TP53"), "Only one group")
  expect_null(p$labels$subtitle)
})

test_that("cohort overview colours diagnoses outside the built-in palette", {
  db <- mp_example_db(n_patients = 10, seed = 1)
  db$patients$diagnosis[1] <- "Glioblastoma"
  built <- ggplot2::ggplot_build(mp_plot_cohort_overview(db)$diagnosis)
  expect_false(anyNA(built$data[[1]]$fill))
  expect_false(any(built$data[[1]]$fill %in% c("grey50", "#7F7F7F")))
  expect_match(mp_plot_cohort_overview(db)$age$labels$x, "years")
})

test_that("VAF histogram stays within [0, 1] and facets several genes", {
  db <- mp_example_db(n_patients = 10, seed = 1)
  db$variants$vaf[1] <- 0
  built <- ggplot2::ggplot_build(mp_plot_vaf_distribution(db))
  expect_gte(min(built$data[[1]]$xmin), 0)
  p <- mp_plot_vaf_distribution(db, gene = c("TP53", "KRAS"))
  expect_s3_class(p$facet, "FacetWrap")
})

test_that("timeline labels do not overlap and carry clinical values", {
  db <- mp_example_db(n_patients = 10, seed = 1)
  pid <- db$patients$patient_id[1]
  p <- mp_plot_timeline(db, pid)
  ev <- p$data
  expect_true(any(grepl(": ", ev$label[ev$type == "Clinical"])))
  span <- as.numeric(diff(range(ev$date)))
  for (lane in split(ev, list(ev$type, ev$y), drop = TRUE)) {
    lane <- lane[order(lane$date), ]
    if (nrow(lane) > 1L) {
      ends <- as.numeric(lane$date) + nchar(lane$label) * 0.0095 * span
      expect_true(all(utils::head(ends, -1L) < as.numeric(lane$date[-1L])))
    }
  }
})

test_that("timeline refuses patients whose events are all undated", {
  db <- mp_example_db(n_patients = 5, seed = 1)
  pid <- db$patients$patient_id[1]
  db$samples$date[db$samples$patient_id == pid] <- as.Date(NA)
  sids <- db$samples$sample_id[db$samples$patient_id == pid]
  db$reports$report_date[db$reports$sample_id %in% sids] <- as.Date(NA)
  db$clinical$date[db$clinical$patient_id == pid] <- as.Date(NA)
  expect_error(mp_plot_timeline(db, pid), "No dated timeline events")
})
