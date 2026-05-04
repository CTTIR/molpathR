# database.R
# Database operation functions for the molpathR package
# Manages construction, modification, validation, and persistence of molpath_db objects

# ---- Internal helpers --------------------------------------------------------

#' Categorize a parsed object into target database tables
#'
#' @param parsed A `molpath_parsed` object.
#' @return A named list with keys matching molpath_db table slots, each
#'   containing a tibble (or NULL) extracted from the parsed object.
#' @noRd
.categorize_parsed <- function(parsed) {
  source_type <- parsed[["source_type"]]
  data <- parsed[["data"]]


  tables <- list(
    patients = NULL,
    samples = NULL,
    variants = NULL,
    reports = NULL,
    clinical = NULL,
    survival = NULL
  )


  if (source_type %in% c("vcf", "fastq", "bam")) {
    tables[["variants"]] <- data
  } else if (source_type == "xml_report") {
    if (is.list(data) && !inherits(data, "data.frame")) {
      tables[["variants"]] <- data[["variants"]]
      tables[["reports"]] <- data[["reports"]]
    } else {
      tables[["variants"]] <- data
    }
  } else if (source_type == "pdf_report") {
    tables[["reports"]] <- data
  } else if (source_type == "nexus_pathology") {
    if (is.list(data) && !inherits(data, "data.frame")) {
      tables[["patients"]] <- data[["patients"]]
      tables[["samples"]] <- data[["samples"]]
    } else {
      tables[["patients"]] <- data
    }
  } else if (source_type == "nexus_clinical") {
    tables[["clinical"]] <- data
  } else if (source_type == "survival") {
    tables[["survival"]] <- data
  } else {
    rlang::warn(
      c("Unknown source type encountered.",
        "i" = paste0("source_type '", source_type, "' is not recognized."),
        "i" = "Data will be skipped."),
      class = "molpathR_unknown_source_type"
    )
  }

  tables
}


#' Safely bind rows, handling NULL inputs
#'
#' @param existing A tibble or NULL.
#' @param new_data A tibble or NULL.
#' @return A tibble combining both inputs, or whichever is non-NULL, or an
#'   empty tibble if both are NULL.
#' @noRd
.safe_bind_rows <- function(existing, new_data) {
  if (is.null(existing) && is.null(new_data)) {
    return(tibble::tibble())
  }
  if (is.null(existing)) {
    return(tibble::as_tibble(new_data))
  }
  if (is.null(new_data)) {
    return(tibble::as_tibble(existing))
  }
  dplyr::bind_rows(existing, new_data)
}


#' Deduplicate a tibble by all columns
#'
#' @param tbl A tibble.
#' @return A deduplicated tibble.
#' @noRd
.dedup <- function(tbl) {
  if (nrow(tbl) == 0L) {
    return(tbl)
  }
  dplyr::distinct(tbl)
}


#' Ensure a table slot is a tibble (not NULL)
#'
#' @param x A tibble or NULL.
#' @return A tibble (empty if input was NULL).
#' @noRd
.ensure_tibble <- function(x) {
  if (is.null(x) || (is.data.frame(x) && nrow(x) == 0L)) {
    return(tibble::tibble())
  }
  tibble::as_tibble(x)
}


#' Flatten inputs to a list of molpath_parsed objects
#'
#' Handles dots containing individual `molpath_parsed` objects and/or lists
#' of them.
#'
#' @param ... Objects passed to `mp_build_db()`.
#' @return A flat list of `molpath_parsed` objects.
#' @noRd
.collect_parsed <- function(...) {
  inputs <- list(...)
  parsed_list <- list()

  for (item in inputs) {
    if (inherits(item, "molpath_parsed")) {
      parsed_list <- c(parsed_list, list(item))
    } else if (is.list(item)) {
      # A list of molpath_parsed objects
      for (sub_item in item) {
        if (inherits(sub_item, "molpath_parsed")) {
          parsed_list <- c(parsed_list, list(sub_item))
        } else {
          rlang::abort(
            c("Invalid input to `mp_build_db()`.",
              "x" = "All elements must be `molpath_parsed` objects.",
              "i" = paste0("Got class: ", paste(class(sub_item), collapse = "/"))),
            class = "molpathR_invalid_input"
          )
        }
      }
    } else {
      rlang::abort(
        c("Invalid input to `mp_build_db()`.",
          "x" = "All inputs must be `molpath_parsed` objects or lists of them.",
          "i" = paste0("Got class: ", paste(class(item), collapse = "/"))),
        class = "molpathR_invalid_input"
      )
    }
  }

  if (length(parsed_list) == 0L) {
    rlang::abort(
      c("No parsed objects provided.",
        "i" = "Supply one or more `molpath_parsed` objects to `mp_build_db()`."),
      class = "molpathR_no_input"
    )
  }

  parsed_list
}


#' Normalize parsed input for mp_add_data
#'
#' @param parsed A single `molpath_parsed` object or a list of them.
#' @return A flat list of `molpath_parsed` objects.
#' @noRd
.normalize_parsed_input <- function(parsed) {
  if (inherits(parsed, "molpath_parsed")) {
    return(list(parsed))
  }

  if (is.list(parsed)) {
    all_valid <- all(vapply(parsed, function(x) {
      inherits(x, "molpath_parsed")
    }, logical(1)))
    if (!all_valid) {
      rlang::abort(
        c("Invalid input.",
          "x" = "All elements must be `molpath_parsed` objects."),
        class = "molpathR_invalid_input"
      )
    }
    return(parsed)
  }

  rlang::abort(
    c("Invalid input.",
      "x" = "`parsed` must be a `molpath_parsed` object or a list of them.",
      "i" = paste0("Got class: ", paste(class(parsed), collapse = "/"))),
    class = "molpathR_invalid_input"
  )
}


# ---- Exported functions ------------------------------------------------------

#' Build a molpath_db from parsed data objects
#'
#' Constructs a unified `molpath_db` database object from one or more
#' `molpath_parsed` objects. Each parsed object is categorized by its
#' `source_type` and merged into the appropriate database table.
#'
#' Source types map to database tables as follows:
#' \itemize{
#'   \item `"vcf"`, `"fastq"`, `"bam"` -- variants
#'   \item `"xml_report"` -- variants and reports
#'   \item `"pdf_report"` -- reports
#'   \item `"nexus_pathology"` -- patients and samples
#'   \item `"nexus_clinical"` -- clinical
#'   \item `"survival"` -- survival
#' }
#'
#' @param ... One or more `molpath_parsed` objects, or lists of
#'   `molpath_parsed` objects. All objects are flattened and processed.
#'
#' @return A `molpath_db` S3 object containing linked patients, samples,
#'   variants, reports, clinical, survival, and metadata tables.
#'
#' @export
#' @examples
#' \donttest{
#' # Build from a molpath_parsed object
#' surv_parsed <- new_molpath_parsed(
#'   data = tibble::tibble(
#'     patient_id = c("P1", "P2"),
#'     os_months = c(12, 24),
#'     os_status = c(1L, 0L),
#'     pfs_months = c(6, 18),
#'     pfs_status = c(1L, 0L)
#'   ),
#'   source_type = "survival",
#'   source_file = "test.csv"
#' )
#' db <- mp_build_db(surv_parsed)
#' }
mp_build_db <- function(...) {
  parsed_list <- .collect_parsed(...)

  cli::cli_h2("Building molpath database")
  cli::cli_alert_info("Processing {length(parsed_list)} parsed object{?s}.")

  # Initialize empty tables
  patients <- tibble::tibble()
  samples <- tibble::tibble()
  variants <- tibble::tibble()
  reports <- tibble::tibble()
  clinical <- tibble::tibble()
  survival <- tibble::tibble()

  source_files <- character(0)
  parser_versions <- character(0)

  for (i in seq_along(parsed_list)) {
    parsed <- parsed_list[[i]]
    tables <- .categorize_parsed(parsed)

    patients <- .safe_bind_rows(patients, tables[["patients"]])
    samples <- .safe_bind_rows(samples, tables[["samples"]])
    variants <- .safe_bind_rows(variants, tables[["variants"]])
    reports <- .safe_bind_rows(reports, tables[["reports"]])
    clinical <- .safe_bind_rows(clinical, tables[["clinical"]])
    survival <- .safe_bind_rows(survival, tables[["survival"]])

    # Collect metadata from parsed objects
    if (!is.null(parsed[["source_file"]])) {
      source_files <- c(source_files, parsed[["source_file"]])
    }
    if (!is.null(parsed[["parser_version"]])) {
      parser_versions <- c(parser_versions, parsed[["parser_version"]])
    }
  }

  # Deduplicate all tables
  patients <- .dedup(patients)
  samples <- .dedup(samples)
  variants <- .dedup(variants)
  reports <- .dedup(reports)
  clinical <- .dedup(clinical)
  survival <- .dedup(survival)

  metadata <- tibble::tibble(
    creation_date = Sys.time(),
    source_files = list(unique(source_files)),
    parser_versions = list(unique(parser_versions))
  )

  db <- new_molpath_db(
    patients = patients,
    samples = samples,
    variants = variants,
    reports = reports,
    clinical = clinical,
    survival = survival,
    metadata = metadata
  )

  cli::cli_alert_success("Database built successfully.")
  cli::cli_alert_info(
    "Tables: {nrow(patients)} patient{?s}, {nrow(samples)} sample{?s}, \\
     {nrow(variants)} variant{?s}, {nrow(reports)} report{?s}, \\
     {nrow(clinical)} clinical record{?s}, {nrow(survival)} survival record{?s}."
  )

  db
}


#' Add parsed data to an existing molpath_db
#'
#' Appends new data from one or more `molpath_parsed` objects to an existing
#' `molpath_db` database. Records are deduplicated after appending.
#'
#' @param db A `molpath_db` object to update.
#' @param parsed A single `molpath_parsed` object or a list of
#'   `molpath_parsed` objects to add.
#'
#' @return An updated `molpath_db` object with the new data merged in.
#'
#' @export
#' @examples
#' \donttest{
#' db <- mp_example_db(n_patients = 5, seed = 1)
#' new_data <- new_molpath_parsed(
#'   data = tibble::tibble(patient_id = "P99", os_months = 12,
#'     os_status = 1L, pfs_months = 6, pfs_status = 1L),
#'   source_type = "survival", source_file = "new.csv"
#' )
#' db <- mp_add_data(db, new_data)
#' }
mp_add_data <- function(db, parsed) {
  if (!inherits(db, "molpath_db")) {
    rlang::abort(
      c("`db` must be a `molpath_db` object.",
        "i" = paste0("Got class: ", paste(class(db), collapse = "/"))),
      class = "molpathR_invalid_db"
    )
  }

  parsed_list <- .normalize_parsed_input(parsed)

  cli::cli_h2("Adding data to molpath database")
  cli::cli_alert_info("Processing {length(parsed_list)} parsed object{?s}.")

  patients <- .ensure_tibble(db[["patients"]])
  samples <- .ensure_tibble(db[["samples"]])
  variants <- .ensure_tibble(db[["variants"]])
  reports <- .ensure_tibble(db[["reports"]])
  clinical <- .ensure_tibble(db[["clinical"]])
  survival <- .ensure_tibble(db[["survival"]])

  source_files <- if (!is.null(db[["metadata"]][["source_files"]])) {
    unlist(db[["metadata"]][["source_files"]])
  } else {
    character(0)
  }

  parser_versions <- if (!is.null(db[["metadata"]][["parser_versions"]])) {
    unlist(db[["metadata"]][["parser_versions"]])
  } else {
    character(0)
  }

  for (parsed_obj in parsed_list) {
    tables <- .categorize_parsed(parsed_obj)

    patients <- .safe_bind_rows(patients, tables[["patients"]])
    samples <- .safe_bind_rows(samples, tables[["samples"]])
    variants <- .safe_bind_rows(variants, tables[["variants"]])
    reports <- .safe_bind_rows(reports, tables[["reports"]])
    clinical <- .safe_bind_rows(clinical, tables[["clinical"]])
    survival <- .safe_bind_rows(survival, tables[["survival"]])

    if (!is.null(parsed_obj[["source_file"]])) {
      source_files <- c(source_files, parsed_obj[["source_file"]])
    }
    if (!is.null(parsed_obj[["parser_version"]])) {
      parser_versions <- c(parser_versions, parsed_obj[["parser_version"]])
    }
  }

  # Deduplicate all tables
  patients <- .dedup(patients)
  samples <- .dedup(samples)
  variants <- .dedup(variants)
  reports <- .dedup(reports)
  clinical <- .dedup(clinical)
  survival <- .dedup(survival)

  metadata <- tibble::tibble(
    creation_date = db[["metadata"]][["creation_date"]],
    last_updated = Sys.time(),
    source_files = list(unique(source_files)),
    parser_versions = list(unique(parser_versions))
  )

  db <- new_molpath_db(
    patients = patients,
    samples = samples,
    variants = variants,
    reports = reports,
    clinical = clinical,
    survival = survival,
    metadata = metadata
  )

  cli::cli_alert_success("Data added successfully.")
  cli::cli_alert_info(
    "Updated tables: {nrow(patients)} patient{?s}, {nrow(samples)} sample{?s}, \\
     {nrow(variants)} variant{?s}, {nrow(reports)} report{?s}, \\
     {nrow(clinical)} clinical record{?s}, {nrow(survival)} survival record{?s}."
  )

  db
}


#' Merge two molpath_db objects
#'
#' Combines all tables from two `molpath_db` objects into a single unified
#' database. Records are deduplicated after merging. Metadata source files are
#' combined as a union.
#'
#' @param db1 A `molpath_db` object.
#' @param db2 A `molpath_db` object.
#'
#' @return A new `molpath_db` object containing merged data from both inputs.
#'
#' @export
#' @examples
#' \donttest{
#' db1 <- mp_example_db(n_patients = 5, seed = 1)
#' db2 <- mp_example_db(n_patients = 5, seed = 2)
#' db_combined <- mp_merge_db(db1, db2)
#' }
mp_merge_db <- function(db1, db2) {
  if (!inherits(db1, "molpath_db")) {
    rlang::abort(
      c("`db1` must be a `molpath_db` object.",
        "i" = paste0("Got class: ", paste(class(db1), collapse = "/"))),
      class = "molpathR_invalid_db"
    )
  }
  if (!inherits(db2, "molpath_db")) {
    rlang::abort(
      c("`db2` must be a `molpath_db` object.",
        "i" = paste0("Got class: ", paste(class(db2), collapse = "/"))),
      class = "molpathR_invalid_db"
    )
  }

  cli::cli_h2("Merging molpath databases")

  table_names <- c("patients", "samples", "variants", "reports",
                    "clinical", "survival")

  merged <- stats::setNames(
    lapply(table_names, function(nm) {
      .dedup(.safe_bind_rows(
        .ensure_tibble(db1[[nm]]),
        .ensure_tibble(db2[[nm]])
      ))
    }),
    table_names
  )

  # Merge metadata
  source_files_1 <- if (!is.null(db1[["metadata"]][["source_files"]])) {
    unlist(db1[["metadata"]][["source_files"]])
  } else {
    character(0)
  }
  source_files_2 <- if (!is.null(db2[["metadata"]][["source_files"]])) {
    unlist(db2[["metadata"]][["source_files"]])
  } else {
    character(0)
  }

  parser_versions_1 <- if (!is.null(db1[["metadata"]][["parser_versions"]])) {
    unlist(db1[["metadata"]][["parser_versions"]])
  } else {
    character(0)
  }
  parser_versions_2 <- if (!is.null(db2[["metadata"]][["parser_versions"]])) {
    unlist(db2[["metadata"]][["parser_versions"]])
  } else {
    character(0)
  }

  metadata <- tibble::tibble(
    creation_date = Sys.time(),
    source_files = list(unique(c(source_files_1, source_files_2))),
    parser_versions = list(unique(c(parser_versions_1, parser_versions_2)))
  )

  db <- new_molpath_db(
    patients = merged[["patients"]],
    samples = merged[["samples"]],
    variants = merged[["variants"]],
    reports = merged[["reports"]],
    clinical = merged[["clinical"]],
    survival = merged[["survival"]],
    metadata = metadata
  )

  cli::cli_alert_success("Databases merged successfully.")
  cli::cli_alert_info(
    "Merged tables: {nrow(merged[['patients']])} patient{?s}, \\
     {nrow(merged[['samples']])} sample{?s}, \\
     {nrow(merged[['variants']])} variant{?s}, \\
     {nrow(merged[['reports']])} report{?s}, \\
     {nrow(merged[['clinical']])} clinical record{?s}, \\
     {nrow(merged[['survival']])} survival record{?s}."
  )

  db
}


#' Validate a molpath_db for referential integrity and completeness
#'
#' Checks that all foreign key relationships in the database are satisfied
#' (e.g., every sample references an existing patient) and reports on data
#' completeness across tables.
#'
#' @param db A `molpath_db` object to validate.
#'
#' @return Invisibly, a list with three elements:
#' \describe{
#'   \item{valid}{Logical. `TRUE` if no referential integrity issues were found.}
#'   \item{issues}{Character vector of issue descriptions (empty if valid).}
#'   \item{completeness}{Named numeric vector with percentages of patients
#'     having data in each table (e.g., `pct_with_variants`,
#'     `pct_with_survival`).}
#' }
#'
#' @details
#' The following referential integrity checks are performed:
#' \itemize{
#'   \item All `patient_id` values in the samples table exist in patients.
#'   \item All `sample_id` values in the variants table exist in samples.
#'   \item All `sample_id` values in the reports table exist in samples.
#'   \item All `patient_id` values in the clinical table exist in patients.
#'   \item All `patient_id` values in the survival table exist in patients.
#' }
#'
#' When called interactively, results are printed using `cli` formatting.
#'
#' @export
#' @examples
#' \donttest{
#' db <- mp_example_db(n_patients = 10, seed = 1)
#' validation <- mp_validate_db(db)
#' validation$valid
#' }
mp_validate_db <- function(db) {
  if (!inherits(db, "molpath_db")) {
    rlang::abort(
      c("`db` must be a `molpath_db` object.",
        "i" = paste0("Got class: ", paste(class(db), collapse = "/"))),
      class = "molpathR_invalid_db"
    )
  }

  cli::cli_h2("Validating molpath database")

  issues <- character(0)

  patients <- .ensure_tibble(db[["patients"]])
  samples <- .ensure_tibble(db[["samples"]])
  variants <- .ensure_tibble(db[["variants"]])
  reports <- .ensure_tibble(db[["reports"]])
  clinical <- .ensure_tibble(db[["clinical"]])
  survival <- .ensure_tibble(db[["survival"]])

  patient_ids <- if ("patient_id" %in% names(patients)) {
    unique(patients[["patient_id"]])
  } else {
    character(0)
  }

  sample_ids <- if ("sample_id" %in% names(samples)) {
    unique(samples[["sample_id"]])
  } else {
    character(0)
  }

  # -- Referential integrity checks --


  # 1. samples.patient_id -> patients.patient_id
  if (nrow(samples) > 0L && "patient_id" %in% names(samples) &&
      length(patient_ids) > 0L) {
    orphan_sample_patients <- setdiff(
      unique(samples[["patient_id"]]),
      patient_ids
    )
    if (length(orphan_sample_patients) > 0L) {
      msg <- paste0(
        length(orphan_sample_patients),
        " sample(s) reference patient_id(s) not found in patients table: ",
        paste(utils::head(orphan_sample_patients, 5), collapse = ", "),
        if (length(orphan_sample_patients) > 5) ", ..." else ""
      )
      issues <- c(issues, msg)
      cli::cli_alert_warning(msg)
    }
  }

  # 2. variants.sample_id -> samples.sample_id
  if (nrow(variants) > 0L && "sample_id" %in% names(variants) &&
      length(sample_ids) > 0L) {
    orphan_variant_samples <- setdiff(
      unique(variants[["sample_id"]]),
      sample_ids
    )
    if (length(orphan_variant_samples) > 0L) {
      msg <- paste0(
        length(orphan_variant_samples),
        " variant(s) reference sample_id(s) not found in samples table: ",
        paste(utils::head(orphan_variant_samples, 5), collapse = ", "),
        if (length(orphan_variant_samples) > 5) ", ..." else ""
      )
      issues <- c(issues, msg)
      cli::cli_alert_warning(msg)
    }
  }

  # 3. reports.sample_id -> samples.sample_id
  if (nrow(reports) > 0L && "sample_id" %in% names(reports) &&
      length(sample_ids) > 0L) {
    orphan_report_samples <- setdiff(
      unique(reports[["sample_id"]]),
      sample_ids
    )
    if (length(orphan_report_samples) > 0L) {
      msg <- paste0(
        length(orphan_report_samples),
        " report(s) reference sample_id(s) not found in samples table: ",
        paste(utils::head(orphan_report_samples, 5), collapse = ", "),
        if (length(orphan_report_samples) > 5) ", ..." else ""
      )
      issues <- c(issues, msg)
      cli::cli_alert_warning(msg)
    }
  }

  # 4. clinical.patient_id -> patients.patient_id
  if (nrow(clinical) > 0L && "patient_id" %in% names(clinical) &&
      length(patient_ids) > 0L) {
    orphan_clinical_patients <- setdiff(
      unique(clinical[["patient_id"]]),
      patient_ids
    )
    if (length(orphan_clinical_patients) > 0L) {
      msg <- paste0(
        length(orphan_clinical_patients),
        " clinical record(s) reference patient_id(s) not found in patients table: ",
        paste(utils::head(orphan_clinical_patients, 5), collapse = ", "),
        if (length(orphan_clinical_patients) > 5) ", ..." else ""
      )
      issues <- c(issues, msg)
      cli::cli_alert_warning(msg)
    }
  }

  # 5. survival.patient_id -> patients.patient_id
  if (nrow(survival) > 0L && "patient_id" %in% names(survival) &&
      length(patient_ids) > 0L) {
    orphan_survival_patients <- setdiff(
      unique(survival[["patient_id"]]),
      patient_ids
    )
    if (length(orphan_survival_patients) > 0L) {
      msg <- paste0(
        length(orphan_survival_patients),
        " survival record(s) reference patient_id(s) not found in patients table: ",
        paste(utils::head(orphan_survival_patients, 5), collapse = ", "),
        if (length(orphan_survival_patients) > 5) ", ..." else ""
      )
      issues <- c(issues, msg)
      cli::cli_alert_warning(msg)
    }
  }

  # -- Completeness report --

  n_patients <- length(patient_ids)

  completeness <- if (n_patients > 0L) {
    # Patients with at least one variant (via samples)
    patients_with_variants <- if (
      nrow(variants) > 0L && "sample_id" %in% names(variants) &&
      nrow(samples) > 0L && "patient_id" %in% names(samples) &&
      "sample_id" %in% names(samples)
    ) {
      variant_sample_ids <- unique(variants[["sample_id"]])
      variant_patient_ids <- unique(
        samples[["patient_id"]][samples[["sample_id"]] %in% variant_sample_ids]
      )
      length(intersect(variant_patient_ids, patient_ids))
    } else {
      0L
    }

    # Patients with at least one report (via samples)
    patients_with_reports <- if (
      nrow(reports) > 0L && "sample_id" %in% names(reports) &&
      nrow(samples) > 0L && "patient_id" %in% names(samples) &&
      "sample_id" %in% names(samples)
    ) {
      report_sample_ids <- unique(reports[["sample_id"]])
      report_patient_ids <- unique(
        samples[["patient_id"]][samples[["sample_id"]] %in% report_sample_ids]
      )
      length(intersect(report_patient_ids, patient_ids))
    } else {
      0L
    }

    # Patients with clinical data
    patients_with_clinical <- if (
      nrow(clinical) > 0L && "patient_id" %in% names(clinical)
    ) {
      length(intersect(unique(clinical[["patient_id"]]), patient_ids))
    } else {
      0L
    }

    # Patients with survival data
    patients_with_survival <- if (
      nrow(survival) > 0L && "patient_id" %in% names(survival)
    ) {
      length(intersect(unique(survival[["patient_id"]]), patient_ids))
    } else {
      0L
    }

    # Patients with at least one sample
    patients_with_samples <- if (
      nrow(samples) > 0L && "patient_id" %in% names(samples)
    ) {
      length(intersect(unique(samples[["patient_id"]]), patient_ids))
    } else {
      0L
    }

    c(
      pct_with_samples = round(100 * patients_with_samples / n_patients, 1),
      pct_with_variants = round(100 * patients_with_variants / n_patients, 1),
      pct_with_reports = round(100 * patients_with_reports / n_patients, 1),
      pct_with_clinical = round(100 * patients_with_clinical / n_patients, 1),
      pct_with_survival = round(100 * patients_with_survival / n_patients, 1)
    )
  } else {
    c(
      pct_with_samples = NA_real_,
      pct_with_variants = NA_real_,
      pct_with_reports = NA_real_,
      pct_with_clinical = NA_real_,
      pct_with_survival = NA_real_
    )
  }

  valid <- length(issues) == 0L

  # -- Pretty output --

  if (valid) {
    cli::cli_alert_success("No referential integrity issues found.")
  } else {
    cli::cli_alert_danger(
      "{length(issues)} referential integrity issue{?s} found."
    )
  }

  cli::cli_h3("Data completeness")
  if (n_patients > 0L) {
    cli::cli_ul()
    cli::cli_li("Patients with samples:  {completeness[['pct_with_samples']]}%")
    cli::cli_li("Patients with variants: {completeness[['pct_with_variants']]}%")
    cli::cli_li("Patients with reports:  {completeness[['pct_with_reports']]}%")
    cli::cli_li("Patients with clinical: {completeness[['pct_with_clinical']]}%")
    cli::cli_li("Patients with survival: {completeness[['pct_with_survival']]}%")
    cli::cli_end()
  } else {
    cli::cli_alert_info("No patients in database; completeness cannot be calculated.")
  }

  result <- list(
    valid = valid,
    issues = issues,
    completeness = completeness
  )

  invisible(result)
}


#' Save a molpath_db to disk
#'
#' Validates the database and saves it as a compressed RDS file. The file
#' path is returned invisibly for use in pipelines.
#'
#' @param db A `molpath_db` object to save.
#' @param path Character string giving the file path to save to. Should
#'   typically end in `.rds`.
#'
#' @return The file `path`, returned invisibly.
#'
#' @export
#' @examples
#' \donttest{
#' db <- mp_example_db(n_patients = 5, seed = 1)
#' tmp <- tempfile(fileext = ".rds")
#' mp_save_db(db, tmp)
#' unlink(tmp)
#' }
mp_save_db <- function(db, path) {
  if (!inherits(db, "molpath_db")) {
    rlang::abort(
      c("`db` must be a `molpath_db` object.",
        "i" = paste0("Got class: ", paste(class(db), collapse = "/"))),
      class = "molpathR_invalid_db"
    )
  }
  if (!is.character(path) || length(path) != 1L || is.na(path)) {
    rlang::abort(
      c("`path` must be a single character string.",
        "i" = "Provide a file path ending in '.rds'."),
      class = "molpathR_invalid_path"
    )
  }

  cli::cli_h2("Saving molpath database")

  # Validate before saving
  validation <- mp_validate_db(db)
  if (!validation[["valid"]]) {
    rlang::warn(
      c("Database has referential integrity issues.",
        "i" = "Saving anyway, but consider fixing issues first.",
        "i" = paste(validation[["issues"]], collapse = "\n")),
      class = "molpathR_validation_warning"
    )
  }

  # Ensure output directory exists
  out_dir <- dirname(path)
  if (!dir.exists(out_dir)) {
    dir.create(out_dir, recursive = TRUE)
  }

  saveRDS(db, file = path, compress = "gzip")

  file_size <- file.info(path)[["size"]]
  file_size_fmt <- if (file_size < 1024) {
    paste0(file_size, " B")
  } else if (file_size < 1024^2) {
    paste0(round(file_size / 1024, 1), " KB")
  } else if (file_size < 1024^3) {
    paste0(round(file_size / 1024^2, 1), " MB")
  } else {
    paste0(round(file_size / 1024^3, 2), " GB")
  }

  cli::cli_alert_success("Database saved to {.file {path}} ({file_size_fmt}).")

  invisible(path)
}


#' Load a molpath_db from disk
#'
#' Reads an RDS file, verifies it contains a valid `molpath_db` object,
#' and prints a summary of the loaded database.
#'
#' @param path Character string giving the file path to an RDS file
#'   containing a `molpath_db` object.
#'
#' @return A `molpath_db` object.
#'
#' @export
#' @examples
#' \donttest{
#' db <- mp_example_db(n_patients = 5, seed = 1)
#' tmp <- tempfile(fileext = ".rds")
#' mp_save_db(db, tmp)
#' db2 <- mp_load_db(tmp)
#' unlink(tmp)
#' }
mp_load_db <- function(path) {
  if (!is.character(path) || length(path) != 1L || is.na(path)) {
    rlang::abort(
      c("`path` must be a single character string.",
        "i" = "Provide a path to an existing '.rds' file."),
      class = "molpathR_invalid_path"
    )
  }
  if (!file.exists(path)) {
    rlang::abort(
      c("File not found.",
        "x" = paste0("Path does not exist: ", path)),
      class = "molpathR_file_not_found"
    )
  }

  cli::cli_h2("Loading molpath database")

  db <- readRDS(path)

  if (!inherits(db, "molpath_db")) {
    rlang::abort(
      c("File does not contain a `molpath_db` object.",
        "i" = paste0("Got class: ", paste(class(db), collapse = "/")),
        "i" = "Use `mp_build_db()` to create a database from parsed objects."),
      class = "molpathR_invalid_db"
    )
  }

  cli::cli_alert_success("Database loaded from {.file {path}}.")

  patients <- .ensure_tibble(db[["patients"]])
  samples <- .ensure_tibble(db[["samples"]])
  variants <- .ensure_tibble(db[["variants"]])
  reports <- .ensure_tibble(db[["reports"]])
  clinical <- .ensure_tibble(db[["clinical"]])
  survival <- .ensure_tibble(db[["survival"]])

  cli::cli_alert_info(
    "Contents: {nrow(patients)} patient{?s}, {nrow(samples)} sample{?s}, \\
     {nrow(variants)} variant{?s}, {nrow(reports)} report{?s}, \\
     {nrow(clinical)} clinical record{?s}, {nrow(survival)} survival record{?s}."
  )

  db
}
