# classes.R
# S3 class definitions for the molpathR package
# -----------------------------------------------

# ---- molpath_db class --------------------------------------------------------

#' Create a new molpath_db object
#'
#' Constructs a `molpath_db` object, which is a list of linked tibbles
#' representing the core data model for molecular pathology workflows.
#'
#' @param patients A tibble with columns `patient_id`, `age`, `sex`,
#'   `diagnosis`, and optionally others.
#' @param samples A tibble with columns `sample_id`, `patient_id`,
#'   `sample_type`, `date`, `source_file`, and optionally others.
#' @param variants A tibble with columns `sample_id`, `gene`, `variant`,
#'   `classification`, `vaf`, and optionally others.
#' @param reports A tibble with columns `sample_id`, `report_type`,
#'   `report_date`, `summary_text`, `source_file`, and optionally others.
#' @param clinical A tibble with columns `patient_id`, `parameter`, `value`,
#'   `date`, `source`, and optionally others.
#' @param survival A tibble with columns `patient_id`, `os_months`,
#'   `os_status`, `pfs_months`, `pfs_status`, and optionally others.
#' @param metadata A list containing `creation_date` (POSIXct),
#'   `source_files` (character vector), and `parser_versions` (named list).
#'
#' @return An S3 object of class `molpath_db`.
#' @export
#'
#' @examples
#' db <- new_molpath_db()
#' db
new_molpath_db <- function(patients = tibble::tibble(
                             patient_id = character(),
                             age = integer(),
                             sex = character(),
                             diagnosis = character()
                           ),
                           samples = tibble::tibble(
                             sample_id = character(),
                             patient_id = character(),
                             sample_type = character(),
                             date = as.Date(character()),
                             source_file = character()
                           ),
                           variants = tibble::tibble(
                             sample_id = character(),
                             gene = character(),
                             variant = character(),
                             classification = character(),
                             vaf = double()
                           ),
                           reports = tibble::tibble(
                             sample_id = character(),
                             report_type = character(),
                             report_date = as.Date(character()),
                             summary_text = character(),
                             source_file = character()
                           ),
                           clinical = tibble::tibble(
                             patient_id = character(),
                             parameter = character(),
                             value = character(),
                             date = as.Date(character()),
                             source = character()
                           ),
                           survival = tibble::tibble(
                             patient_id = character(),
                             os_months = double(),
                             os_status = integer(),
                             pfs_months = double(),
                             pfs_status = integer()
                           ),
                           metadata = list(
                             creation_date = Sys.time(),
                             source_files = character(),
                             parser_versions = list()
                           )) {
  obj <- list(
    patients  = patients,
    samples   = samples,
    variants  = variants,
    reports   = reports,
    clinical  = clinical,
    survival  = survival,
    metadata  = metadata
  )

  structure(obj, class = "molpath_db")
}


#' Validate a molpath_db object
#'
#' Checks that all required tables are present, that each is a tibble, and that
#' mandatory columns exist in each table. Validates referential integrity
#' between patient and sample identifiers across tables.
#'
#' @param x An object of class `molpath_db`.
#'
#' @return The validated `molpath_db` object (invisibly). Throws an error if
#'   validation fails.
#' @export
#'
#' @examples
#' db <- new_molpath_db()
#' validate_molpath_db(db)
validate_molpath_db <- function(x) {
  if (!inherits(x, "molpath_db")) {
    cli::cli_abort("{.arg x} must be a {.cls molpath_db} object.")
  }

  # Required table names

  table_names <- c("patients", "samples", "variants", "reports",
                   "clinical", "survival")

  for (tbl in table_names) {
    if (!tbl %in% names(x)) {
      cli::cli_abort("Missing required table {.val {tbl}} in molpath_db.")
    }
    if (!tibble::is_tibble(x[[tbl]])) {
      cli::cli_abort("Table {.val {tbl}} must be a tibble, not {.cls {class(x[[tbl]])[1]}}.")
    }
  }

  # Required columns per table
  required_cols <- list(
    patients  = c("patient_id", "age", "sex", "diagnosis"),
    samples   = c("sample_id", "patient_id", "sample_type", "date",
                   "source_file"),
    variants  = c("sample_id", "gene", "variant", "classification", "vaf"),
    reports   = c("sample_id", "report_type", "report_date", "summary_text",
                   "source_file"),
    clinical  = c("patient_id", "parameter", "value", "date", "source"),
    survival  = c("patient_id", "os_months", "os_status", "pfs_months",
                   "pfs_status")
  )

  for (tbl in names(required_cols)) {
    missing <- setdiff(required_cols[[tbl]], names(x[[tbl]]))
    if (length(missing) > 0L) {
      cli::cli_abort(
        "Table {.val {tbl}} is missing required column{?s}: {.field {missing}}."
      )
    }
  }

  # Validate metadata structure
  if (!"metadata" %in% names(x)) {
    cli::cli_abort("Missing {.val metadata} list in molpath_db.")
  }

  meta_fields <- c("creation_date", "source_files", "parser_versions")
  missing_meta <- setdiff(meta_fields, names(x$metadata))
  if (length(missing_meta) > 0L) {
    cli::cli_abort(
      "Metadata is missing required field{?s}: {.field {missing_meta}}."
    )
  }

  # Referential integrity: sample patient_ids should be in patients
  if (nrow(x$samples) > 0L && nrow(x$patients) > 0L) {
    orphan_samples <- setdiff(x$samples$patient_id, x$patients$patient_id)
    if (length(orphan_samples) > 0L) {
      cli::cli_warn(
        c("!" = "{length(orphan_samples)} sample patient_id{?s} not found in patients table.",
          "i" = "First orphan IDs: {.val {utils::head(orphan_samples, 5)}}.")
      )
    }
  }

  invisible(x)
}


#' Print a molpath_db object
#'
#' Displays a human-readable summary of a `molpath_db`, including table
#' dimensions, date ranges, and data completeness.
#'
#' @param x A `molpath_db` object.
#' @param ... Additional arguments (ignored).
#'
#' @return The `molpath_db` object (invisibly).
#' @export
print.molpath_db <- function(x, ...) {
  cli::cli_h1("molpath_db")

  table_names <- c("patients", "samples", "variants", "reports",
                    "clinical", "survival")

  for (tbl in table_names) {
    n <- nrow(x[[tbl]])
    ncols <- ncol(x[[tbl]])
    cli::cli_alert_info(
      "{.field {tbl}}: {.val {n}} record{?s} x {.val {ncols}} column{?s}"
    )
  }

  # Date range from samples
  if (nrow(x$samples) > 0L && "date" %in% names(x$samples)) {
    dates <- x$samples$date[!is.na(x$samples$date)]
    if (length(dates) > 0L) {
      cli::cli_alert_info(
        "Sample date range: {.val {min(dates)}} to {.val {max(dates)}}"
      )
    }
  }

  # Completeness: proportion of non-NA values across all tables
  total_cells <- 0L
  non_na_cells <- 0L
  for (tbl in table_names) {
    if (nrow(x[[tbl]]) > 0L) {
      mat <- as.data.frame(x[[tbl]])
      total_cells <- total_cells + length(unlist(mat))
      non_na_cells <- non_na_cells + sum(!is.na(unlist(mat)))
    }
  }
  if (total_cells > 0L) {
    pct <- round(non_na_cells / total_cells * 100, 1)
    cli::cli_alert_info("Overall completeness: {.val {pct}%}")
  }

  # Metadata
  cli::cli_alert_info(
    "Created: {.val {format(x$metadata$creation_date, '%Y-%m-%d %H:%M:%S')}}"
  )
  n_sources <- length(x$metadata$source_files)
  cli::cli_alert_info("Source files: {.val {n_sources}}")

  invisible(x)
}


#' Summarise a molpath_db object
#'
#' Prints a detailed summary of a `molpath_db`, including per-table
#' completeness, unique counts for key columns, and metadata.
#'
#' @param object A `molpath_db` object.
#' @param ... Additional arguments (ignored).
#'
#' @return The `molpath_db` object (invisibly).
#' @export
summary.molpath_db <- function(object, ...) {
  cli::cli_h1("molpath_db Summary")

  # Patients
  n_pat <- nrow(object$patients)
  cli::cli_h2("Patients ({n_pat})")
  if (n_pat > 0L) {
    cli::cli_alert_info(
      "Sex distribution: {.val {paste(names(table(object$patients$sex)),
      table(object$patients$sex), sep = '=', collapse = ', ')}}"
    )
    cli::cli_alert_info(
      "Unique diagnoses: {.val {length(unique(object$patients$diagnosis))}}"
    )
  }

  # Samples
  n_samp <- nrow(object$samples)
  cli::cli_h2("Samples ({n_samp})")
  if (n_samp > 0L) {
    cli::cli_alert_info(
      "Sample types: {.val {paste(unique(object$samples$sample_type), collapse = ', ')}}"
    )
    cli::cli_alert_info(
      "Patients with samples: {.val {length(unique(object$samples$patient_id))}}"
    )
  }

  # Variants
  n_var <- nrow(object$variants)
  cli::cli_h2("Variants ({n_var})")
  if (n_var > 0L) {
    cli::cli_alert_info(
      "Unique genes: {.val {length(unique(object$variants$gene))}}"
    )
    cli::cli_alert_info(
      "Classifications: {.val {paste(unique(object$variants$classification), collapse = ', ')}}"
    )
  }

  # Reports
  n_rep <- nrow(object$reports)
  cli::cli_h2("Reports ({n_rep})")
  if (n_rep > 0L) {
    cli::cli_alert_info(
      "Report types: {.val {paste(unique(object$reports$report_type), collapse = ', ')}}"
    )
  }

  # Clinical
  n_clin <- nrow(object$clinical)
  cli::cli_h2("Clinical ({n_clin})")
  if (n_clin > 0L) {
    cli::cli_alert_info(
      "Parameters: {.val {paste(unique(object$clinical$parameter), collapse = ', ')}}"
    )
  }

  # Survival
  n_surv <- nrow(object$survival)
  cli::cli_h2("Survival ({n_surv})")
  if (n_surv > 0L) {
    os_avail <- sum(!is.na(object$survival$os_months))
    pfs_avail <- sum(!is.na(object$survival$pfs_months))
    cli::cli_alert_info(
      "OS data available: {.val {os_avail}}/{.val {n_surv}}"
    )
    cli::cli_alert_info(
      "PFS data available: {.val {pfs_avail}}/{.val {n_surv}}"
    )
  }

  # Metadata
  cli::cli_h2("Metadata")
  cli::cli_alert_info(
    "Created: {.val {format(object$metadata$creation_date, '%Y-%m-%d %H:%M:%S')}}"
  )
  cli::cli_alert_info(
    "Source files: {.val {length(object$metadata$source_files)}}"
  )
  if (length(object$metadata$parser_versions) > 0L) {
    vers <- paste(
      names(object$metadata$parser_versions),
      object$metadata$parser_versions,
      sep = " = ", collapse = ", "
    )
    cli::cli_alert_info("Parser versions: {vers}")
  }

  invisible(object)
}


# ---- molpath_parsed class ----------------------------------------------------

#' Create a new molpath_parsed object
#'
#' Constructs a `molpath_parsed` object representing the result of parsing a
#' single data source. This serves as an intermediate representation before
#' data is integrated into a `molpath_db`.
#'
#' @param data A tibble (or data frame) containing the parsed data.
#' @param source_type A character string identifying the source type (e.g.,
#'   `"vcf"`, `"xml_report"`, `"pdf_report"`, `"excel"`, `"csv"`).
#' @param source_file A character string with the path to the source file.
#' @param parse_date A `POSIXct` timestamp of when the data was parsed.
#'   Defaults to the current time.
#'
#' @return An S3 object of class `molpath_parsed`.
#' @export
#'
#' @examples
#' parsed <- new_molpath_parsed(
#'   data = tibble::tibble(gene = "BRAF", variant = "V600E"),
#'   source_type = "vcf",
#'   source_file = "sample1.vcf"
#' )
#' parsed
new_molpath_parsed <- function(data = tibble::tibble(),
                               source_type = character(1L),
                               source_file = character(1L),
                               parse_date = Sys.time()) {
  if (!tibble::is_tibble(data) && !is.data.frame(data)) {
    cli::cli_abort("{.arg data} must be a tibble or data frame.")
  }

  if (!is.character(source_type) || length(source_type) != 1L) {
    cli::cli_abort("{.arg source_type} must be a single character string.")
  }

  if (!is.character(source_file) || length(source_file) != 1L) {
    cli::cli_abort("{.arg source_file} must be a single character string.")
  }

  # Coerce data frames to tibble

  if (!tibble::is_tibble(data)) {
    data <- tibble::as_tibble(data)
  }


  obj <- list(
    data        = data,
    source_type = source_type,
    source_file = source_file,
    parse_date  = parse_date
  )

  structure(obj, class = "molpath_parsed")
}


#' Print a molpath_parsed object
#'
#' Displays a compact summary of a parsed data source, including source
#' metadata and a preview of the data.
#'
#' @param x A `molpath_parsed` object.
#' @param ... Additional arguments (ignored).
#'
#' @return The `molpath_parsed` object (invisibly).
#' @export
print.molpath_parsed <- function(x, ...) {
  cli::cli_h1("molpath_parsed")
  cli::cli_alert_info("Source type: {.val {x$source_type}}")
  cli::cli_alert_info("Source file: {.file {x$source_file}}")
  cli::cli_alert_info(
    "Parsed: {.val {format(x$parse_date, '%Y-%m-%d %H:%M:%S')}}"
  )
  cli::cli_alert_info(
    "Data: {.val {nrow(x$data)}} row{?s} x {.val {ncol(x$data)}} column{?s}"
  )

  if (ncol(x$data) > 0L) {
    cli::cli_alert_info(
      "Columns: {.field {names(x$data)}}"
    )
  }

  # Completeness
  if (nrow(x$data) > 0L && ncol(x$data) > 0L) {
    total <- nrow(x$data) * ncol(x$data)
    non_na <- sum(!is.na(as.data.frame(x$data)))
    pct <- round(non_na / total * 100, 1)
    cli::cli_alert_info("Completeness: {.val {pct}%}")
  }

  invisible(x)
}


#' Summarise a molpath_parsed object
#'
#' Prints a detailed summary of a parsed data source, including column types,
#' missing value counts, and a preview of distinct values.
#'
#' @param object A `molpath_parsed` object.
#' @param ... Additional arguments (ignored).
#'
#' @return The `molpath_parsed` object (invisibly).
#' @export
summary.molpath_parsed <- function(object, ...) {

  cli::cli_h1("molpath_parsed Summary")
  cli::cli_alert_info("Source type: {.val {object$source_type}}")
  cli::cli_alert_info("Source file: {.file {object$source_file}}")
  cli::cli_alert_info(
    "Parsed: {.val {format(object$parse_date, '%Y-%m-%d %H:%M:%S')}}"
  )
  cli::cli_alert_info(
    "Dimensions: {.val {nrow(object$data)}} row{?s} x {.val {ncol(object$data)}} column{?s}"
  )

  if (ncol(object$data) > 0L && nrow(object$data) > 0L) {
    cli::cli_h2("Column Details")
    for (col_name in names(object$data)) {
      col <- object$data[[col_name]]
      col_class <- class(col)[1L]
      n_na <- sum(is.na(col))
      n_unique <- length(unique(col[!is.na(col)]))
      cli::cli_alert_info(
        "{.field {col_name}}: {.cls {col_class}}, {.val {n_unique}} unique, {.val {n_na}} NA"
      )
    }
  }

  invisible(object)
}
