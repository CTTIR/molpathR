app_fixture <- function() {
  new_molpath_db(
    patients = tibble::tibble(patient_id = c("P1", "P2", "P3"), age = c(40L, 60L, NA_integer_),
      sex = c("F", "M", NA_character_), diagnosis = c("D1", "D2", NA_character_)),
    samples = tibble::tibble(sample_id = c("S1", "S2"), patient_id = c("P1", "P2"),
      sample_type = "FFPE", date = as.Date(c("2026-01-01", "2026-01-02")), source_file = "synthetic.csv"),
    variants = tibble::tibble(sample_id = c("S1", "S2"), gene = c("TP53", "KRAS"),
      variant = c("c.1C>A", "c.2C>T"), classification = c("Pathogenic", "VUS"),
      vaf = c(.1, .9), ref_allele = "C", alt_allele = c("A", "T")),
    survival = tibble::tibble(patient_id = c("P1", "P2", "P3"), os_months = c(1, 2, 3),
      os_status = c(1L, 0L, 1L), pfs_months = c(1, 2, 3), pfs_status = c(1L, 0L, 1L)))
}
app_modules <- function() {
  env <- new.env(parent = globalenv())
  path <- system.file("shiny", "molpathR", package = "molpathR")
  for (folder in c("helpers", "modules")) {
    for (file in list.files(file.path(path, folder), full.names = TRUE, pattern = "[.]R$")) {
      sys.source(file, envir = env)
    }
  }
  env
}

test_that("plot filters change observed values and mutation counts", {
  db <- app_fixture()
  expect_identical(mp_plot_vaf_distribution(db, "TP53")$data$gene, "TP53")
  expect_error(mp_plot_vaf_distribution(db, "ABSENT"), "No variants")
  counts <- mp_plot_mutation_spectrum(db, "S1")$data
  expect_equal(counts$count, c(1L, 0L, 0L, 0L, 0L, 0L))
  expect_error(mp_plot_mutation_spectrum(db, "ABSENT"), "No SNVs")
  expect_error(mp_query_variants(db, variant_type = "Fusion"), "no variant_type")
  expect_error(mp_query_variants(db, min_vaf = c(0, 1)), "one finite")
  expect_error(mp_query_variants(db, max_vaf = Inf), "one finite")
  expect_error(mp_query_variants(db, min_vaf = .8, max_vaf = .2), "must not exceed")
})

test_that("survival grouping describes records and exports actual analyzed rows", {
  db <- app_fixture()
  p <- mp_plot_survival(db, "TP53")
  rows <- attr(p, "molpath_survival_data")
  expect_equal(rows$patient_id, c("P1", "P2", "P3"))
  expect_equal(rows$group, c("TP53: recorded variant", rep("TP53: no recorded variant", 2)))
  expect_match(p$labels$subtitle, "does not establish")
  expect_error(mp_plot_survival(db, "ABSENT"), "negative assay status is unknown")
  expect_warning(q <- mp_plot_survival(db, "diagnosis"), "Omitting 1")
  expect_equal(attr(q, "molpath_survival_data")$patient_id, c("P1", "P2"))
  expect_equal(unname(attr(q, "molpath_survival_fit")$n), c(1, 1))
  db$survival$os_status[] <- 0L
  expect_no_error(mp_plot_survival(db, "TP53"))
})

test_that("variant table figures and CSV use the same current filter", {
  env <- app_modules(); db <- app_fixture()
  shared <- shiny::reactiveValues(db = db, selected_patient = NULL, selected_gene = NULL)
  calls <- list()
  plot <- function(db, ...) {
    calls[[length(calls) + 1L]] <<- db$variants$gene
    ggplot2::ggplot(db$variants, ggplot2::aes(x = vaf)) + ggplot2::geom_histogram(binwidth = .1)
  }
  local_mocked_bindings(mp_plot_variant_landscape = plot, mp_plot_mutation_spectrum = plot,
    mp_plot_vaf_distribution = plot, .package = "molpathR")
  shiny::testServer(env$mod_variants_server, args = list(shared = shared), {
    session$setInputs(gene_filter = "TP53", class_filter = c("Pathogenic", "VUS"),
      vaf_range = c(0, 1), include_missing = TRUE)
    expect_equal(filtered_variants()$gene, "TP53")
    invisible(output$vaf_plot); invisible(output$landscape_plot); invisible(output$spectrum_plot)
    expect_length(calls, 3L)
    expect_true(all(vapply(calls, identical, logical(1), "TP53")))
    csv <- read.csv(output$download_variants)
    expect_identical(csv$gene, "TP53")
    session$setInputs(gene_filter = character(), class_filter = character())
    expect_equal(nrow(filtered_variants()), 0L)
  })
})

test_that("patient selection clears on deselect, filter change and database replacement", {
  env <- app_modules(); db <- app_fixture()
  shared <- shiny::reactiveValues(db = db, selected_patient = NULL, selected_gene = NULL)
  shiny::testServer(env$mod_patients_server, args = list(shared = shared), {
    session$setInputs(diag_filter = c("D1", "D2"), sex_filter = c("M", "F"),
      age_range = c(0, 100), include_missing = TRUE)
    expect_equal(nrow(filtered_patients()), 3L)
    session$setInputs(patient_table_rows_selected = 1)
    expect_identical(shared$selected_patient, "P1")
    expect_no_error(output$patient_detail)
    session$setInputs(patient_table_rows_selected = integer())
    expect_null(shared$selected_patient)
    session$setInputs(patient_table_rows_selected = 1)
    session$setInputs(diag_filter = "D2")
    expect_null(shared$selected_patient)
    session$setInputs(patient_table_rows_selected = 1)
    expect_identical(shared$selected_patient, "P2")
    shared$db <- new_molpath_db(); session$flushReact()
    expect_null(shared$selected_patient)
    expect_null(shared$selected_gene)
  })
})

test_that("exports retain true format and isolated layer content", {
  env <- app_modules(); db <- app_fixture()
  path <- withr::local_tempfile(fileext = ".rds")
  env$app_export_layers(db, "patients", "rds", path)
  readback <- mp_load_db(path)
  expect_equal(readback$patients, db$patients)
  expect_equal(nrow(readback$variants), 0L)
  expect_error(env$app_export_layers(db, "../patients", "csv", path), "valid data layers")
  original <- base::requireNamespace
  local_mocked_bindings(requireNamespace = function(package, ...) {
    if (identical(package, "writexl")) FALSE else original(package, ...)
  }, .package = "base")
  excel <- withr::local_tempfile(fileext = ".xlsx")
  expect_error(env$app_export_layers(db, "patients", "xlsx", excel), "requires.*writexl")
  expect_false(file.exists(excel))
})

test_that("ZIP downloads contain only their own selected tables", {
  skip_if(Sys.which(Sys.getenv("R_ZIPCMD", "zip")) == "", "zip executable unavailable")
  env <- app_modules(); db <- app_fixture()
  one <- withr::local_tempfile(fileext = ".zip")
  two <- withr::local_tempfile(fileext = ".zip")
  env$app_export_layers(db, "patients", "csv", one)
  env$app_export_layers(db, "variants", "tsv", two)
  expect_identical(utils::unzip(one, list = TRUE)$Name, "patients.csv")
  expect_identical(utils::unzip(two, list = TRUE)$Name, "variants.tsv")
  stage <- withr::local_tempdir()
  utils::unzip(two, exdir = stage)
  expect_equal(read.delim(file.path(stage, "variants.tsv"))$gene, c("TP53", "KRAS"))
})

test_that("upload batches preserve original filename and publish no partial candidate", {
  env <- app_modules(); db <- app_fixture()
  root <- withr::local_tempdir()
  path <- file.path(root, "0")
  writeLines(c("patient_id,os_months,os_status,pfs_months,pfs_status", "P1,1,1,1,1"), path)
  files <- data.frame(name = "outcomes.csv", datapath = path)
  candidate <- env$app_import_files(files, new_molpath_db(patients = db$patients))
  expect_equal(candidate$survival$patient_id, "P1")
  expect_true("outcomes.csv" %in% candidate$metadata$source_files)
  expect_false(any(grepl("molpath-upload-", candidate$metadata$source_files)))
  broken <- file.path(root, "1"); writeLines("not a database", broken)
  batch <- rbind(files, data.frame(name = "bad.rds", datapath = broken))
  expect_error(env$app_import_files(batch, db), "one database RDS")
  before <- db
  expect_error(env$app_import_files(data.frame(name = "bad.rds", datapath = broken), db))
  expect_identical(db, before)
  expect_error(env$app_import_files(data.frame(name = "../escape.csv", datapath = path), db), "basenames")
})

test_that("launcher restores preexisting preload state on normal return and failure", {
  preload <- getFromNamespace(".molpathR_env", "molpathR")
  old <- preload$shiny_db
  withr::defer(preload$shiny_db <- old)
  preload$shiny_db <- app_fixture()
  prior <- preload$shiny_db
  local_mocked_bindings(runApp = function(...) {
    expect_null(molpathR:::.molpathR_env$shiny_db)
    cli::cli_abort("synthetic launch failure")
  }, .package = "shiny")
  expect_error(mp_run_app(), "synthetic launch failure")
  expect_identical(molpathR:::.molpathR_env$shiny_db, prior)
})

test_that("failed browser upload keeps prior database and selected identity", {
  env <- app_modules(); db <- app_fixture()
  shared <- shiny::reactiveValues(db = db, selected_patient = "P1", selected_gene = "TP53")
  root <- withr::local_tempdir()
  good <- file.path(root, "0"); bad <- file.path(root, "1")
  writeLines(c("patient_id,parameter,value,date", "P1,sodium,140,2026-01-01"), good)
  writeLines("unsupported content", bad)
  notifications <- character()
  local_mocked_bindings(showNotification = function(ui, ...) {
    notifications <<- c(notifications, as.character(ui))
  }, .package = "shiny")
  shiny::testServer(env$mod_database_server, args = list(shared = shared), {
    session$setInputs(file_upload = data.frame(name = c("clinical.csv", "broken.txt"),
      datapath = c(good, bad), size = file.info(c(good, bad))$size, type = "text/plain"))
    expect_identical(shared$db, db)
    expect_identical(shared$selected_patient, "P1")
    expect_identical(shared$selected_gene, "TP53")
    expect_true(any(grepl("current database retained", notifications)))
  })
})

test_that("available Excel download is a real workbook with selected sheet values", {
  skip_if_not_installed("writexl")
  env <- app_modules(); db <- app_fixture()
  file <- withr::local_tempfile(fileext = ".xlsx")
  env$app_export_layers(db, c("patients", "variants"), "xlsx", file)
  expect_equal(readxl::excel_sheets(file), c("patients", "variants"))
  expect_equal(readxl::read_xlsx(file, sheet = "variants")$vaf, c(.1, .9))
  expect_equal(readxl::read_xlsx(file, sheet = "patients")$patient_id, c("P1", "P2", "P3"))
})

test_that("report patient search is literal and missing dates remain explicitly available", {
  env <- app_modules(); db <- app_fixture()
  db$patients$patient_id[1] <- "[P1]"; db$samples$patient_id[1] <- "[P1]"
  db$survival$patient_id[1] <- "[P1]"
  db$reports <- tibble::tibble(sample_id = c("S1", "S2"), report_type = "Pathology",
    report_date = as.Date(c("2026-01-01", NA)), summary_text = c("first", "second"), source_file = "synthetic.xml")
  shared <- shiny::reactiveValues(db = db, selected_patient = NULL)
  shiny::testServer(env$mod_reports_server, args = list(shared = shared), {
    session$setInputs(report_type_filter = "Pathology", date_range = as.Date(c("2025-01-01", "2027-01-01")),
      include_missing = TRUE, patient_search = "[P1]")
    expect_equal(filtered_reports()$summary_text, "first")
    session$setInputs(patient_search = "")
    expect_equal(nrow(filtered_reports()), 2L)
    session$setInputs(report_table_rows_selected = 1)
    expect_equal(selected_report()$summary_text, "first")
    session$setInputs(include_missing = FALSE)
    expect_null(selected_report())
    expect_equal(nrow(filtered_reports()), 1L)
  })
})

test_that("variant deselection clears propagated survival gene but preserves manual edits", {
  env <- app_modules(); db <- app_fixture()
  shared <- shiny::reactiveValues(db = db, selected_patient = NULL, selected_gene = NULL)
  updates <- character()
  local_mocked_bindings(updateTextInput = function(session, inputId, value, ...) {
    if (identical(inputId, "gene_stratify")) updates <<- c(updates, value)
  }, .package = "shiny")
  server <- function(input, output, session) {
    env$mod_variants_server("variants", shared)
    env$mod_survival_server("survival", shared)
  }
  shiny::testServer(server, {
    session$setInputs(`variants-gene_filter` = c("TP53", "KRAS"),
      `variants-class_filter` = c("Pathogenic", "VUS"), `variants-vaf_range` = c(0, 1),
      `survival-gene_stratify` = "", `survival-group_var` = "none", `survival-surv_type` = "os")
    session$setInputs(`variants-variant_table_rows_selected` = 1)
    expect_identical(shared$selected_gene, "TP53")
    expect_identical(tail(updates, 1), "TP53")
    session$setInputs(`survival-gene_stratify` = "TP53")
    session$setInputs(`variants-variant_table_rows_selected` = integer())
    expect_null(shared$selected_gene)
    expect_identical(tail(updates, 1), "")
    session$setInputs(`variants-variant_table_rows_selected` = 2)
    session$setInputs(`survival-gene_stratify` = "MANUAL")
    before <- updates
    session$setInputs(`variants-variant_table_rows_selected` = integer())
    expect_null(shared$selected_gene)
    expect_identical(updates, before)
    shared$db <- new_molpath_db(); session$flushReact()
    expect_identical(tail(updates, 1), "")
  })
})

test_that("selected patients never acquire records with unknown linkage", {
  env <- app_modules(); db <- app_fixture()
  db$samples$patient_id[2] <- NA_character_
  db$variants$sample_id[2] <- NA_character_
  db$reports <- tibble::tibble(sample_id = c("S1", NA_character_), report_type = "Pathology",
    report_date = as.Date("2026-01-01"), summary_text = c("linked", "unknown"), source_file = "synthetic.pdf")
  expect_identical(env$get_patient_sample_ids(db, "P1"), "S1")
  shared <- shiny::reactiveValues(db = db, selected_patient = "P1", selected_gene = NULL)
  shiny::testServer(env$mod_variants_server, args = list(shared = shared), {
    session$setInputs(gene_filter = c("TP53", "KRAS"), class_filter = c("Pathogenic", "VUS"),
      vaf_range = c(0, 1), include_missing = TRUE)
    expect_identical(filtered_variants()$gene, "TP53")
  })
  shiny::testServer(env$mod_reports_server, args = list(shared = shared), {
    session$setInputs(report_type_filter = "Pathology", date_range = as.Date(c("2025-01-01", "2027-01-01")),
      patient_search = "", include_missing = TRUE)
    expect_identical(filtered_reports()$summary_text, "linked")
  })
})

test_that("imported PDF structured report cells survive flat-format export", {
  env <- app_modules(); root <- withr::local_tempdir()
  pdf <- file.path(root, "report.pdf")
  grDevices::pdf(pdf)
  tryCatch({
    graphics::plot.new()
    graphics::text(.5, .6, "Findings: synthetic evidence")
    graphics::text(.5, .4, "Recommendations: synthetic follow-up")
  }, finally = grDevices::dev.off())
  parsed <- mp_read_pdf_report(pdf)
  db <- mp_build_db(parsed)
  expect_true(is.list(db$reports$sections))
  if (Sys.which(Sys.getenv("R_ZIPCMD", "zip")) != "") {
    for (format in c("csv", "tsv")) {
      file <- file.path(root, paste0(format, ".zip"))
      expect_warning(env$app_export_layers(db, "reports", format, file), "incomplete referential")
      folder <- file.path(root, format); dir.create(folder); utils::unzip(file, exdir = folder)
      table <- utils::read.table(file.path(folder, paste0("reports.", format)),
        header = TRUE, sep = if (format == "csv") "," else "\t", check.names = FALSE)
      restored <- jsonlite::fromJSON(table$sections[[1L]])
      expect_equal(restored, as.data.frame(parsed$data))
    }
  }
  if (requireNamespace("writexl", quietly = TRUE)) {
    file <- file.path(root, "report.xlsx")
    expect_warning(env$app_export_layers(db, "reports", "xlsx", file), "incomplete referential")
    table <- readxl::read_xlsx(file)
    expect_equal(jsonlite::fromJSON(table$sections[[1L]]), as.data.frame(parsed$data))
  }
  bad <- app_fixture(); bad$patients$unserializable <- list(function() NULL, NULL, NULL)
  file <- file.path(root, "not-created.xlsx")
  expect_error(env$app_export_layers(bad, "patients", "xlsx", file), "patients.unserializable.*Use RDS")
  expect_false(file.exists(file))
})

test_that("preserved extra columns cannot shadow patient linkage variables", {
  db <- app_fixture()
  db$variants$sample_ids <- "S2"
  db$reports <- tibble::tibble(sample_id = c("S1", "S2"), report_type = "Pathology",
    report_date = as.Date("2026-01-01"), summary_text = c("first", "second"),
    source_file = "synthetic.xml", sample_ids = "S2")
  patient <- mp_get_patient(db, "P1")
  expect_identical(patient$variants$gene, "TP53")
  expect_identical(patient$reports$summary_text, "first")
})

test_that("summary date ranges remain unknown when imported sample dates are missing", {
  db <- app_fixture(); db$samples$date[] <- NA
  expect_no_warning(summary <- mp_summary(db))
  expect_s3_class(summary$date_range, "Date")
  expect_identical(summary$date_range, as.Date(c(NA_character_, NA_character_)))
})
