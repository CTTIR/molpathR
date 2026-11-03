# Shared filter helper functions for the Shiny app
# These are used across multiple modules for consistent filtering

#' Get sample IDs for a given patient
#' @noRd
get_patient_sample_ids <- function(db, patient_id) {
  if (is.null(db) || length(patient_id) != 1L || is.na(patient_id)) return(character())
  matched <- !is.na(db$samples$patient_id) & !is.na(db$samples$sample_id) &
    db$samples$patient_id == patient_id
  db$samples$sample_id[matched]
}

# Build a candidate separately from the published session state.
app_import_files <- function(files, db = NULL) {
  if (!is.data.frame(files) || nrow(files) < 1L ||
      !all(c("name", "datapath") %in% names(files))) {
    cli::cli_abort("No uploaded files were supplied.")
  }
  names <- files$name
  if (anyNA(names) || any(!nzchar(names)) || any(basename(names) != names) ||
      any(grepl("[/\\\\]", names)) || any(names %in% c(".", ".."))) {
    cli::cli_abort("Uploaded filenames must be plain basenames.")
  }
  rds <- grepl("\\.rds$", names, ignore.case = TRUE)
  if (any(rds)) {
    if (nrow(files) != 1L) cli::cli_abort("Upload one database RDS by itself; it replaces the current database.")
    return(molpathR::mp_load_db(files$datapath[[1L]]))
  }
  if (anyDuplicated(names)) cli::cli_abort("Upload filenames must be unique within a batch.")
  parsed <- vector("list", nrow(files))
  for (i in seq_len(nrow(files))) {
    parsed[[i]] <- molpathR::mp_read_auto(files$datapath[[i]], source_name = names[[i]])
  }
  candidate <- if (is.null(db)) molpathR::mp_build_db(parsed) else {
    current <- db
    for (value in parsed) current <- molpathR::mp_add_data(current, value)
    current
  }
  molpathR::validate_molpath_db(candidate)
  candidate
}

app_export_layers <- function(db, layers, format, file) {
  all_layers <- c("patients", "samples", "variants", "reports", "clinical", "survival")
  molpathR::validate_molpath_db(db)
  if (!is.character(layers) || !length(layers) || anyNA(layers) ||
      anyDuplicated(layers) || !all(layers %in% all_layers)) {
    cli::cli_abort("Select valid data layers to export.")
  }
  if (!format %in% c("rds", "xlsx", "csv", "tsv")) cli::cli_abort("Unsupported export format.")
  flat <- if (format != "rds") stats::setNames(lapply(layers, function(layer) {
    app_flat_table(db[[layer]], layer)
  }), layers) else NULL
  if (format == "rds") {
    for (layer in setdiff(all_layers, layers)) db[[layer]] <- db[[layer]][0, ]
    molpathR::mp_save_db(db, file)
  } else if (format == "xlsx") {
    if (!requireNamespace("writexl", quietly = TRUE)) {
      cli::cli_abort("Excel export requires the optional writexl package. Choose CSV/TSV or install writexl.")
    }
    writexl::write_xlsx(flat, file)
  } else {
    stage <- tempfile("molpath-export-")
    dir.create(stage, mode = "0700")
    on.exit(unlink(stage, recursive = TRUE), add = TRUE)
    paths <- file.path(stage, paste0(layers, ".", format))
    for (i in seq_along(layers)) {
      utils::write.table(flat[[i]], paths[[i]],
        sep = if (format == "csv") "," else "\t", row.names = FALSE, quote = TRUE,
        qmethod = "double")
    }
    status <- utils::zip(file, paths, flags = "-j")
    if (!is.null(status) && status != 0L) cli::cli_abort("ZIP export failed. Check the zip executable or R_ZIPCMD.")
  }
  if (!file.exists(file) || is.na(file.info(file)$size) || file.info(file)$size <= 0) {
    cli::cli_abort("Export did not create a nonempty file.")
  }
  invisible(file)
}

# Expose a useful expected empty/input error in the plot region.
app_plot <- function(value) {
  tryCatch(value, error = function(e) {
    shiny::validate(shiny::need(FALSE, conditionMessage(e)))
  })
}

# Flat formats carry structured cells as JSON; native RDS retains R objects.
app_flat_table <- function(data, layer) {
  for (column in names(data)) {
    if (is.list(data[[column]]) && !inherits(data[[column]], "POSIXt")) {
      data[[column]] <- vapply(data[[column]], function(value) {
        tryCatch({
          app_json_value(value)
          as.character(jsonlite::toJSON(value, auto_unbox = TRUE,
          dataframe = "rows", null = "null", na = "null", digits = NA,
          POSIXt = "ISO8601", Date = "ISO8601"))
        }, error = function(e) {
          message <- paste0("Cannot export structured column ", layer, ".", column,
            " as JSON: ", conditionMessage(e), ". Use RDS to retain R objects.")
          cli::cli_abort("{message}", parent = e)
        })
      }, character(1))
    }
  }
  data
}

app_json_value <- function(value) {
  if (is.null(value)) return(invisible(NULL))
  if (is.function(value) || is.environment(value) || isS4(value) ||
      is.language(value) || is.complex(value) || is.raw(value) ||
      typeof(value) %in% c("externalptr", "weakref")) {
    cli::cli_abort("This R value has no supported JSON representation.")
  }
  if (is.object(value) && !inherits(value, c("data.frame", "Date", "POSIXt", "factor", "AsIs"))) {
    cli::cli_abort("Custom R classes require RDS export.")
  }
  if (is.numeric(value) && any(is.infinite(value))) {
    cli::cli_abort("Infinite values require RDS export.")
  }
  if (is.list(value) && !inherits(value, "POSIXt")) {
    nms <- names(value)
    if (!is.null(nms) && (anyNA(nms) || any(!nzchar(nms)) || anyDuplicated(nms))) {
      cli::cli_abort("JSON object names must be unique and nonempty.")
    }
    for (element in value) app_json_value(element)
  }
  invisible(NULL)
}

app_download <- function(value) {
  tryCatch(value, error = function(e) {
    shiny::showNotification(conditionMessage(e), type = "error", duration = NULL)
    rlang::cnd_signal(e)
  })
}
