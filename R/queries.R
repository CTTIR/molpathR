# queries.R
# Query functions for molpath_db objects
# ----------------------------------------

#' Filter patients in a molpath_db
#'
#' Uses tidy evaluation to filter the patients table.
#'
#' @param db A `molpath_db` object.
#' @param ... Filter expressions passed to [dplyr::filter()].
#'
#' @return A tibble of matching patients.
#' @export
#'
#' @examples
#' db <- mp_example_db(n_patients = 20, seed = 1)
#' mp_query_patients(db, diagnosis == "Melanoma")
#' mp_query_patients(db, age > 60, sex == "F")
mp_query_patients <- function(db, ...) {
  if (!inherits(db, "molpath_db")) {
    rlang::abort("`db` must be a molpath_db object.")
  }
  dplyr::filter(db$patients, ...)
}

#' Filter variants in a molpath_db
#'
#' Filter the variants table by gene, classification, VAF range, or variant
#' type.
#'
#' @param db A `molpath_db` object.
#' @param genes Character vector of gene symbols to include. `NULL` means all.
#' @param classification Character vector of classifications to include.
#'   `NULL` means all.
#' @param min_vaf Minimum variant allele frequency (inclusive). `NULL` for no
#'   lower bound.
#' @param max_vaf Maximum variant allele frequency (inclusive). `NULL` for no
#'   upper bound.
#' @param variant_type Character vector of variant types to include (e.g.,
#'   `"SNV"`, `"Indel"`, `"CNV"`, `"Fusion"`). `NULL` means all.
#'
#' @return A tibble of matching variants.
#' @export
#'
#' @examples
#' db <- mp_example_db(n_patients = 20, seed = 1)
#' mp_query_variants(db, genes = c("TP53", "KRAS"))
#' mp_query_variants(db, classification = "Pathogenic", min_vaf = 0.1)
mp_query_variants <- function(db,
                              genes = NULL,
                              classification = NULL,
                              min_vaf = NULL,
                              max_vaf = NULL,
                              variant_type = NULL) {
  if (!inherits(db, "molpath_db")) {
    rlang::abort("`db` must be a molpath_db object.")
  }
  result <- db$variants

  if (!is.null(genes)) {
    result <- dplyr::filter(result, .data$gene %in% genes)
  }
  if (!is.null(classification)) {
    result <- dplyr::filter(result, .data$classification %in% classification)
  }
  if (!is.null(min_vaf)) {
    result <- dplyr::filter(result, .data$vaf >= min_vaf)
  }

  if (!is.null(max_vaf)) {
    result <- dplyr::filter(result, .data$vaf <= max_vaf)
  }
  if (!is.null(variant_type)) {
    if ("variant_type" %in% names(result)) {
      result <- dplyr::filter(result, .data$variant_type %in% variant_type)
    }
  }
  result
}

#' Filter samples in a molpath_db
#'
#' Uses tidy evaluation to filter the samples table.
#'
#' @param db A `molpath_db` object.
#' @param ... Filter expressions passed to [dplyr::filter()].
#'
#' @return A tibble of matching samples.
#' @export
#'
#' @examples
#' db <- mp_example_db(n_patients = 20, seed = 1)
#' mp_query_samples(db, sample_type == "FFPE")
mp_query_samples <- function(db, ...) {
  if (!inherits(db, "molpath_db")) {
    rlang::abort("`db` must be a molpath_db object.")
  }
  dplyr::filter(db$samples, ...)
}

#' Get all data for a single patient
#'
#' Returns a named list containing all data layers for the given patient,
#' including samples, variants (via sample linkage), reports, clinical data,
#' and survival data.
#'
#' @param db A `molpath_db` object.
#' @param patient_id A single patient ID string.
#'
#' @return A named list with elements: `patient`, `samples`, `variants`,
#'   `reports`, `clinical`, `survival`.
#' @export
#'
#' @examples
#' db <- mp_example_db(n_patients = 20, seed = 1)
#' pat <- mp_get_patient(db, db$patients$patient_id[1])
#' pat$samples
mp_get_patient <- function(db, patient_id) {
  if (!inherits(db, "molpath_db")) {
    rlang::abort("`db` must be a molpath_db object.")
  }
  if (length(patient_id) != 1L) {
    rlang::abort("`patient_id` must be a single value.")
  }

  patient <- dplyr::filter(db$patients, .data$patient_id == !!patient_id)
  if (nrow(patient) == 0L) {
    cli::cli_warn("Patient {.val {patient_id}} not found in database.")
    return(list(
      patient  = patient,
      samples  = db$samples[0L, ],
      variants = db$variants[0L, ],
      reports  = db$reports[0L, ],
      clinical = db$clinical[0L, ],
      survival = db$survival[0L, ]
    ))
  }

  samples <- dplyr::filter(db$samples, .data$patient_id == !!patient_id)
  sample_ids <- samples$sample_id

  variants <- dplyr::filter(db$variants, .data$sample_id %in% sample_ids)
  reports  <- dplyr::filter(db$reports, .data$sample_id %in% sample_ids)
  clinical <- dplyr::filter(db$clinical, .data$patient_id == !!patient_id)
  surv     <- dplyr::filter(db$survival, .data$patient_id == !!patient_id)

  list(
    patient  = patient,
    samples  = samples,
    variants = variants,
    reports  = reports,
    clinical = clinical,
    survival = surv
  )
}

#' Cohort-level summary of a molpath_db
#'
#' Computes summary statistics across all layers of the database.
#'
#' @param db A `molpath_db` object.
#'
#' @return An S3 object of class `molpath_summary` (a named list) containing
#'   `n_patients`, `n_samples`, `n_variants`, `n_reports`, `n_clinical`,
#'   `diagnosis_distribution`, `variant_gene_counts`, `classification_distribution`,
#'   `sample_type_distribution`, `date_range`, and `completeness`.
#' @export
#'
#' @examples
#' db <- mp_example_db(n_patients = 20, seed = 1)
#' mp_summary(db)
mp_summary <- function(db) {
  if (!inherits(db, "molpath_db")) {
    rlang::abort("`db` must be a molpath_db object.")
  }

  pids <- db$patients$patient_id
  pids_with_variants <- if (nrow(db$variants) > 0L && nrow(db$samples) > 0L) {
    sids_with_vars <- unique(db$variants$sample_id)
    unique(db$samples$patient_id[db$samples$sample_id %in% sids_with_vars])
  } else {
    character()
  }
  pids_with_survival <- unique(db$survival$patient_id)

  n_pat <- nrow(db$patients)
  completeness <- c(
    patients_with_samples  = if (n_pat > 0) mean(pids %in% unique(db$samples$patient_id)) else NA_real_,
    patients_with_variants = if (n_pat > 0) mean(pids %in% pids_with_variants) else NA_real_,
    patients_with_survival = if (n_pat > 0) mean(pids %in% pids_with_survival) else NA_real_,
    patients_with_clinical = if (n_pat > 0) mean(pids %in% unique(db$clinical$patient_id)) else NA_real_
  )

  # Gene counts top 20
  gene_counts <- if (nrow(db$variants) > 0L) {
    gc <- sort(table(db$variants$gene), decreasing = TRUE)
    utils::head(gc, 20L)
  } else {
    table(character())
  }

  date_range <- if (nrow(db$samples) > 0L && "date" %in% names(db$samples)) {
    range(db$samples$date, na.rm = TRUE)
  } else {
    c(NA, NA)
  }

  result <- list(
    n_patients                = n_pat,
    n_samples                 = nrow(db$samples),
    n_variants                = nrow(db$variants),
    n_reports                 = nrow(db$reports),
    n_clinical                = nrow(db$clinical),
    diagnosis_distribution    = if (n_pat > 0) table(db$patients$diagnosis) else table(character()),
    variant_gene_counts       = gene_counts,
    classification_distribution = if (nrow(db$variants) > 0) table(db$variants$classification) else table(character()),
    sample_type_distribution  = if (nrow(db$samples) > 0) table(db$samples$sample_type) else table(character()),
    date_range                = date_range,
    completeness              = completeness
  )
  structure(result, class = "molpath_summary")
}

#' @export
print.molpath_summary <- function(x, ...) {
  cli::cli_h1("molpathR Database Summary")

  cli::cli_h2("Record counts")
  cli::cli_ul(c(
    "Patients: {.val {x$n_patients}}",
    "Samples: {.val {x$n_samples}}",
    "Variants: {.val {x$n_variants}}",
    "Reports: {.val {x$n_reports}}",
    "Clinical: {.val {x$n_clinical}}"
  ))

  if (length(x$diagnosis_distribution) > 0L) {
    cli::cli_h2("Diagnoses")
    for (nm in names(x$diagnosis_distribution)) {
      cli::cli_li("{nm}: {.val {x$diagnosis_distribution[[nm]]}}")
    }
  }

  if (length(x$variant_gene_counts) > 0L) {
    cli::cli_h2("Top mutated genes")
    top <- utils::head(x$variant_gene_counts, 10L)
    for (nm in names(top)) {
      cli::cli_li("{nm}: {.val {top[[nm]]}}")
    }
  }

  if (!all(is.na(x$completeness))) {
    cli::cli_h2("Completeness")
    for (nm in names(x$completeness)) {
      pct <- round(x$completeness[[nm]] * 100, 1)
      cli::cli_li("{nm}: {.val {pct}}%")
    }
  }

  invisible(x)
}

#' Free-text search across a molpath_db
#'
#' Searches all text fields across all tables for the given term
#' (case-insensitive).
#'
#' @param db A `molpath_db` object.
#' @param term A single search string.
#'
#' @return A named list of tibbles, one per table, containing rows that match
#'   the search term. Empty tibbles are omitted.
#' @export
#'
#' @examples
#' db <- mp_example_db(n_patients = 20, seed = 1)
#' mp_search(db, "TP53")
mp_search <- function(db, term) {
  if (!inherits(db, "molpath_db")) {
    rlang::abort("`db` must be a molpath_db object.")
  }
  if (!is.character(term) || length(term) != 1L) {
    rlang::abort("`term` must be a single character string.")
  }

  search_table <- function(tbl) {
    if (nrow(tbl) == 0L) return(tbl[0L, ])
    char_cols <- names(tbl)[vapply(tbl, is.character, logical(1L))]
    if (length(char_cols) == 0L) return(tbl[0L, ])
    matches <- rep(FALSE, nrow(tbl))
    for (col in char_cols) {
      matches <- matches | stringr::str_detect(
        tbl[[col]],
        stringr::fixed(term, ignore_case = TRUE)
      )
    }
    matches[is.na(matches)] <- FALSE
    tbl[matches, ]
  }

  results <- list(
    patients = search_table(db$patients),
    samples  = search_table(db$samples),
    variants = search_table(db$variants),
    reports  = search_table(db$reports),
    clinical = search_table(db$clinical),
    survival = search_table(db$survival)
  )

  # Drop empty

  results <- results[vapply(results, nrow, integer(1L)) > 0L]

  n_total <- sum(vapply(results, nrow, integer(1L)))
  cli::cli_alert_info("Found {.val {n_total}} matching record{?s} across {.val {length(results)}} table{?s}.")

  results
}
