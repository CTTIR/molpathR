# == XML Report ===============================================================

#' Read an XML variant report
#'
#' Parse a structured XML variant interpretation report (e.g. from
#' Molecular Health or similar providers) into a tidy tibble.
#'
#' @param path Character scalar. Path to the \code{.xml} file.
#' @param provider Character scalar. Report provider template to apply.
#'   Currently supported: \code{"molecular_health"} (default).
#'
#' @return A \code{molpath_parsed} object whose \code{data} slot is a
#'   \link[tibble]{tibble} with one row per variant and columns for patient
#'   info, sample info, gene, variant description, classification, evidence
#'   level, therapeutic implications and an explicit VAF proportion when supplied.
#'   VAF must be between 0 and 1, inclusive; percentages or other units are not inferred.
#'
#' @examples
#' \donttest{
#' xml_file <- system.file("extdata", "report.xml", package = "molpathR")
#' if (nzchar(xml_file)) {
#'   result <- mp_read_xml_report(xml_file, provider = "molecular_health")
#'   print(result)
#' }
#' }
#'
#' @export
mp_read_xml_report <- function(path, provider = "molecular_health") {
  path <- normalizePath(path, mustWork = FALSE)
  if (!file.exists(path)) {
    cli::cli_abort("XML report not found: {.file {path}}")
  }

  cli::cli_alert_info("Reading XML report: {.file {basename(path)}} (provider: {provider})")

  doc <- tryCatch(
    xml2::read_xml(path),
    error = function(e) {
      cli::cli_abort(c(
        "Failed to parse XML: {.file {path}}",
        "x" = conditionMessage(e)
      ))
    }
  )

  tbl <- switch(provider,
    molecular_health = .parse_xml_molecular_health(doc, path),
    {
      cli::cli_warn("Unknown provider {.val {provider}}; attempting generic XML parse.")
      .parse_xml_generic(doc, path)
    }
  )

  cli::cli_alert_success("Parsed {nrow(tbl)} variant(s) from XML report")
  new_molpath_parsed(tbl, source_type = "xml_report", source_file = path)
}


#' Parse Molecular Health-style XML (internal)
#' @noRd
.parse_xml_molecular_health <- function(doc, path) {
  # Expected: VariantReport > Patient > Sample > Variant
  # Use xml2 to navigate; namespaces are stripped when not present
  ns <- xml2::xml_ns(doc)

  # Patient-level info

  patient_nodes <- xml2::xml_find_all(doc, ".//Patient")
  if (length(patient_nodes) == 0L) {
    patient_nodes <- xml2::xml_find_all(doc, ".//*[local-name()='Patient']")
  }

  rows <- list()
  idx <- 0L

  for (pnode in patient_nodes) {
    patient_id   <- .xml_text_or_na(pnode, "PatientID|PatientId|ID|Id|id")
    patient_name <- .xml_text_or_na(pnode, "Name|PatientName")

    sample_nodes <- xml2::xml_find_all(pnode, ".//Sample")
    if (length(sample_nodes) == 0L) {
      sample_nodes <- xml2::xml_find_all(pnode, ".//*[local-name()='Sample']")
    }
    # Patient-level variants may have an explicit SampleID, but the patient's
    # generic ID is not evidence of a sample identity.
    explicit_sample <- length(sample_nodes) > 0L
    if (!explicit_sample) sample_nodes <- list(pnode)

    for (snode in sample_nodes) {
      sample_id <- .xml_text_or_na(snode, if (explicit_sample) "SampleID|SampleId|ID|Id|id" else "SampleID|SampleId")
      sample_type <- .xml_text_or_na(snode, if (explicit_sample) "SampleType|Type" else "SampleType")

      variant_nodes <- xml2::xml_find_all(snode, ".//Variant")
      if (length(variant_nodes) == 0L) {
        variant_nodes <- xml2::xml_find_all(snode, ".//*[local-name()='Variant']")
      }

      for (vnode in variant_nodes) {
        idx <- idx + 1L
        rows[[idx]] <- tibble::tibble(
          patient_id     = patient_id,
          patient_name   = patient_name,
          sample_id      = sample_id,
          sample_type    = sample_type,
          gene           = .xml_text_or_na(vnode, "Gene|GeneName|GeneSymbol"),
          variant        = .xml_text_or_na(vnode, "Variant|VariantName|Description|HGVSc|HGVSp"),
          classification = .xml_text_or_na(vnode, "Classification|Pathogenicity|Significance"),
          vaf            = .mp_xml_vaf(vnode),
          evidence       = .xml_text_or_na(vnode, "Evidence|EvidenceLevel|Tier"),
          therapeutic    = .xml_text_or_na(vnode, "Therapeutic|TherapeuticImplication|Therapy|Drug")
        )
      }
    }
  }

  # If no structured Patient/Variant found, try flat Variant nodes at root
  if (length(rows) == 0L) {
    variant_nodes <- xml2::xml_find_all(doc, ".//Variant")
    if (length(variant_nodes) == 0L) {
      variant_nodes <- xml2::xml_find_all(doc, ".//*[local-name()='Variant']")
    }
    for (vnode in variant_nodes) {
      idx <- idx + 1L
      rows[[idx]] <- tibble::tibble(
        patient_id     = NA_character_,
        patient_name   = NA_character_,
        sample_id      = NA_character_,
        sample_type    = NA_character_,
        gene           = .xml_text_or_na(vnode, "Gene|GeneName|GeneSymbol"),
        variant        = .xml_text_or_na(vnode, "Variant|VariantName|Description|HGVSc|HGVSp"),
        classification = .xml_text_or_na(vnode, "Classification|Pathogenicity|Significance"),
        vaf            = .mp_xml_vaf(vnode),
        evidence       = .xml_text_or_na(vnode, "Evidence|EvidenceLevel|Tier"),
        therapeutic    = .xml_text_or_na(vnode, "Therapeutic|TherapeuticImplication|Therapy|Drug")
      )
    }
  }

  if (length(rows) == 0L) {
    cli::cli_warn("No Variant nodes found in XML report: {.file {path}}")
    return(tibble::tibble(
      patient_id = character(), patient_name = character(),
      sample_id = character(), sample_type = character(),
      gene = character(), variant = character(),
      classification = character(), vaf = double(), evidence = character(),
      therapeutic = character()
    ))
  }

  dplyr::bind_rows(rows)
}


# An explicit VAF is a proportion; do not silently convert percent-like values.
.mp_xml_vaf <- function(node) {
  text <- .xml_text_or_na(node, "VAF|VariantAlleleFrequency")
  value <- .mp_number(text, "XML VAF")
  if (!is.na(value) && value > 1) cli::cli_abort("XML VAF must be an explicit proportion between 0 and 1; units are not inferred.")
  value
}

#' Generic XML report parser (internal)
#' @noRd
.parse_xml_generic <- function(doc, path) {
  .parse_xml_molecular_health(doc, path)
}


#' Safely extract child text from an XML node by trying multiple names
#' @noRd
.xml_text_or_na <- function(node, name_pattern) {
  names_to_try <- strsplit(name_pattern, "\\|")[[1L]]
  for (nm in names_to_try) {
    child <- xml2::xml_find_first(node, paste0("./*[local-name()='", nm, "']"))
    if (!inherits(child, "xml_missing")) {
      txt <- xml2::xml_text(child, trim = TRUE)
      if (nzchar(txt)) return(txt)
    }
    # Also try as attribute
    attr_val <- xml2::xml_attr(node, nm)
    if (!is.na(attr_val) && nzchar(attr_val)) return(attr_val)
  }
  NA_character_
}


# == PDF Report ===============================================================

#' Read a PDF pathology report
#'
#' Extract structured information from a pathology PDF report using
#' \code{pdftools::pdf_text()} and regex-based section parsing. Complete extracted
#' pages and text are retained in metadata even when section heuristics match
#' only part of the report. Database report summaries use that complete text.
#' This does not perform OCR or validate extraction accuracy against the PDF.
#'
#' @param path Character scalar. Path to the \code{.pdf} file.
#' @param template Character scalar. Template name controlling which regex
#'   patterns are applied.
#'   Currently \code{"generic"} (default) is supported.
#'
#' @return A \code{molpath_parsed} object whose \code{data} slot is a
#'   \link[tibble]{tibble} with columns \code{section} and \code{content}
#'   extracted from the report (Patient, Sample, Findings, Interpretation,
#'   Recommendations).
#'
#' @examples
#' \donttest{
#' pdf_file <- system.file("extdata", "report.pdf", package = "molpathR")
#' if (nzchar(pdf_file)) {
#'   result <- mp_read_pdf_report(pdf_file)
#'   print(result)
#' }
#' }
#'
#' @export
mp_read_pdf_report <- function(path, template = "generic") {
  path <- normalizePath(path, mustWork = FALSE)
  if (!file.exists(path)) {
    cli::cli_abort("PDF report not found: {.file {path}}")
  }

  cli::cli_alert_info("Reading PDF report: {.file {basename(path)}} (template: {template})")

  pages <- tryCatch(
    pdftools::pdf_text(path),
    error = function(e) {
      cli::cli_abort(c(
        "Failed to read PDF: {.file {path}}",
        "x" = conditionMessage(e)
      ))
    }
  )

  full_text <- paste(pages, collapse = "\n")

  tbl <- switch(template,
    generic = .parse_pdf_generic(full_text),
    {
      cli::cli_warn("Unknown PDF template {.val {template}}; using generic parser.")
      .parse_pdf_generic(full_text)
    }
  )

  cli::cli_alert_success("Extracted {nrow(tbl)} section(s) from PDF report")
  new_molpath_parsed(tbl, source_type = "pdf_report", source_file = path,
    metadata = list(pdf_pages = pages, pdf_text = full_text))
}


#' Generic PDF section extractor (internal)
#' @noRd
.parse_pdf_generic <- function(text) {
  # Define section patterns (case-insensitive)
  section_patterns <- list(
    patient_info    = "(?i)(patient\\s*(info|information|details|data|demographics)[:\\s]*)(.+?)(?=\\n\\s*(?:sample|specimen|finding|result|interpretation|recommendation|conclusion|diagnosis)|$)",
    sample_info     = "(?i)(sample\\s*(info|information|details|data|type)?|specimen)[:\\s]*(.+?)(?=\\n\\s*(?:finding|result|interpretation|recommendation|conclusion|diagnosis|patient)|$)",
    findings        = "(?i)(findings?|results?|variants?\\s*detected|mutations?\\s*detected)[:\\s]*(.+?)(?=\\n\\s*(?:interpretation|recommendation|conclusion|diagnosis|patient|sample)|$)",
    interpretation  = "(?i)(interpretation|clinical\\s*significance|assessment)[:\\s]*(.+?)(?=\\n\\s*(?:recommendation|conclusion|diagnosis|patient|sample|finding)|$)",
    recommendations = "(?i)(recommendations?|suggested\\s*actions?|follow[- ]up)[:\\s]*(.+?)(?=\\n\\s*(?:patient|sample|finding|interpretation|conclusion|disclaimer)|$)"
  )

  rows <- list()
  idx <- 0L

  for (sec_name in names(section_patterns)) {
    match <- regmatches(
      text,
      regexpr(section_patterns[[sec_name]], text, perl = TRUE)
    )
    if (length(match) > 0L && nzchar(match)) {
      idx <- idx + 1L
      # Clean up the content
      content <- trimws(match)
      rows[[idx]] <- tibble::tibble(
        section = sec_name,
        content = content
      )
    }
  }

  if (length(rows) == 0L) {
    cli::cli_warn("No structured sections detected in PDF; returning raw text.")
    return(tibble::tibble(
      section = "raw_text",
      content = trimws(text)
    ))
  }

  dplyr::bind_rows(rows)
}


# == Nexus Pathology ===========================================================

#' Read Nexus pathology data
#'
#' Parse an export from a pathology information system (e.g. Nexus) in either
#' CSV or XML format.
#'
#' @param path_or_connection Character scalar. Path to the CSV or XML export
#'   file, or an open connection.
#'
#' @return A \code{molpath_parsed} object whose \code{data} slot is a
#'   \link[tibble]{tibble} with columns \code{patient_id}, \code{name},
#'   \code{dob}, \code{sex}, \code{sample_id}, \code{sample_type},
#'   \code{diagnosis}, and \code{report_date}.
#'
#' @examples
#' \donttest{
#' nexus_file <- system.file("extdata", "nexus_pathology.csv",
#'                           package = "molpathR")
#' if (nzchar(nexus_file)) {
#'   result <- mp_read_nexus_pathology(nexus_file)
#'   print(result)
#' }
#' }
#'
#' @export
mp_read_nexus_pathology <- function(path_or_connection) {
  # Determine if it's a path string vs connection
  if (is.character(path_or_connection)) {
    path <- normalizePath(path_or_connection, mustWork = FALSE)
    if (!file.exists(path)) {
      cli::cli_abort("Nexus pathology file not found: {.file {path}}")
    }
    cli::cli_alert_info("Reading Nexus pathology export: {.file {basename(path)}}")
    ext <- tolower(tools::file_ext(path))
    is_xml <- ext == "xml"

    # If extension is ambiguous, sniff content
    if (!ext %in% c("csv", "tsv", "txt", "xml")) {
      first_line <- readLines(path, n = 1L, warn = FALSE)
      is_xml <- grepl("^\\s*<", first_line)
    }

    if (is_xml) {
      tbl <- .parse_nexus_pathology_xml(path)
    } else {
      tbl <- .parse_nexus_pathology_csv(path)
    }

    cli::cli_alert_success("Parsed {nrow(tbl)} record(s) from Nexus pathology export")
    return(new_molpath_parsed(tbl, source_type = "nexus_pathology", source_file = path))
  }

  # Connection case
  cli::cli_alert_info("Reading Nexus pathology data from connection")
  lines <- readLines(path_or_connection, warn = FALSE)
  is_xml <- any(grepl("^\\s*<", lines[seq_len(min(5L, length(lines)))]))

  tmpfile <- tempfile(fileext = if (is_xml) ".xml" else ".csv")
  on.exit(unlink(tmpfile), add = TRUE)
  writeLines(lines, tmpfile)

  tbl <- if (is_xml) {
    .parse_nexus_pathology_xml(tmpfile)
  } else {
    .parse_nexus_pathology_csv(tmpfile)
  }

  cli::cli_alert_success("Parsed {nrow(tbl)} record(s) from Nexus pathology connection")
  new_molpath_parsed(tbl, source_type = "nexus_pathology",
                     source_file = "<connection>")
}


#' Parse Nexus pathology CSV (internal)
#' @noRd
.parse_nexus_pathology_csv <- function(path) {
  .standardise_nexus_pathology(.mp_read_tabular(path))
}


#' Parse Nexus pathology XML (internal)
#' @noRd
.parse_nexus_pathology_xml <- function(path) {
  doc <- xml2::read_xml(path)
  records <- xml2::xml_find_all(doc, ".//*[local-name()='Record' or local-name()='Patient' or local-name()='Case']")
  if (length(records) == 0L) {
    records <- xml2::xml_children(xml2::xml_root(doc))
  }

  rows <- lapply(records, function(node) {
    tibble::tibble(
      patient_id  = .xml_text_or_na(node, "PatientID|PatientId|patient_id"),
      name        = .xml_text_or_na(node, "Name|PatientName|name"),
      dob         = .xml_text_or_na(node, "DOB|DateOfBirth|dob|BirthDate"),
      sex         = .xml_text_or_na(node, "Sex|Gender|sex"),
      sample_id   = .xml_text_or_na(node, "SampleID|SampleId|sample_id|SpecimenID"),
      sample_type = .xml_text_or_na(node, "SampleType|SpecimenType|sample_type|Type"),
      diagnosis   = .xml_text_or_na(node, "Diagnosis|diagnosis|Dx"),
      report_date = .xml_text_or_na(node, "ReportDate|report_date|Date")
    )
  })

  if (length(rows) == 0L) {
    cli::cli_warn("No records found in Nexus pathology XML: {.file {path}}")
    return(.empty_nexus_pathology())
  }
  dplyr::bind_rows(rows)
}


#' Standardise Nexus pathology column names to expected output (internal)
#' @noRd
.standardise_nexus_pathology <- function(raw) {
  nms <- tolower(names(raw))
  # Map common variations
  mapping <- c(
    patient_id  = "patient_id|patientid|patient.id|pat_id|pid",
    age         = "age|patient_age|age_years",
    name        = "name|patient_name|patientname|patient.name",
    dob         = "dob|date_of_birth|dateofbirth|birth_date|birthdate",
    sex         = "sex|gender",
    sample_id   = "sample_id|sampleid|sample.id|specimen_id|specimenid",
    sample_type = "sample_type|sampletype|specimen_type|specimentype|type",
    diagnosis   = "diagnosis|dx|diagnose",
    report_date = "report_date|reportdate|date|report.date"
  )

  result <- .mp_map_fields(raw, mapping, required = c("patient_id", "sample_id"))
  result[["age"]] <- .mp_number(result[["age"]], "age")
  result
}


#' Empty tibble with Nexus pathology schema (internal)
#' @noRd
.empty_nexus_pathology <- function() {
  tibble::tibble(
    patient_id = character(), name = character(), dob = character(),
    sex = character(), sample_id = character(), sample_type = character(),
    diagnosis = character(), report_date = character()
  )
}


# == Nexus Clinical ============================================================

#' Read Nexus clinical data
#'
#' Parse a clinical data export (CSV format) from a clinical information system
#' such as Nexus.
#'
#' @param path_or_connection Character scalar. Path to the CSV file, or an open
#'   connection.
#'
#' @return A \code{molpath_parsed} object whose \code{data} slot is a
#'   \link[tibble]{tibble} with columns \code{patient_id}, \code{parameter},
#'   \code{value}, \code{unit}, \code{date}, and \code{source}.
#'
#' @examples
#' \donttest{
#' clin_file <- system.file("extdata", "nexus_clinical.csv",
#'                          package = "molpathR")
#' if (nzchar(clin_file)) {
#'   result <- mp_read_nexus_clinical(clin_file)
#'   print(result)
#' }
#' }
#'
#' @export
mp_read_nexus_clinical <- function(path_or_connection) {
  if (is.character(path_or_connection)) {
    path <- normalizePath(path_or_connection, mustWork = FALSE)
    if (!file.exists(path)) {
      cli::cli_abort("Nexus clinical file not found: {.file {path}}")
    }
    cli::cli_alert_info("Reading Nexus clinical export: {.file {basename(path)}}")
    src_file <- path
  } else {
    cli::cli_alert_info("Reading Nexus clinical data from connection")
    src_file <- "<connection>"
    path <- path_or_connection
  }

  raw <- .mp_read_tabular(path)

  tbl <- .standardise_nexus_clinical(raw)
  cli::cli_alert_success("Parsed {nrow(tbl)} clinical record(s)")
  new_molpath_parsed(tbl, source_type = "nexus_clinical", source_file = src_file)
}


#' Standardise Nexus clinical column names (internal)
#' @noRd
.standardise_nexus_clinical <- function(raw) {
  nms <- tolower(names(raw))
  mapping <- c(
    patient_id = "patient_id|patientid|patient.id|pat_id|pid",
    parameter  = "parameter|param|test|test_name|testname|analyte",
    value      = "value|result|val",
    unit       = "unit|units|uom",
    date       = "date|datetime|date_time|observation_date|obs_date",
    source     = "source|origin|system|lab"
  )

  result <- .mp_map_fields(raw, mapping, required = c("patient_id", "parameter", "value"))
  result
}


# == Survival ==================================================================

#' Read survival / outcome data
#'
#' Read a survival data file in Excel or CSV format and standardise the column
#' names to a canonical schema.
#'
#' @param path Character scalar. Path to a \code{.xlsx}, \code{.xls}, or
#'   \code{.csv} file.
#'
#' @return A \code{molpath_parsed} object whose \code{data} slot is a
#'   \link[tibble]{tibble} with columns \code{patient_id}, \code{os_months},
#'   \code{os_status}, \code{pfs_months}, and \code{pfs_status}.
#'
#' @examples
#' \donttest{
#' surv_file <- system.file("extdata", "survival.csv", package = "molpathR")
#' if (nzchar(surv_file)) {
#'   result <- mp_read_survival(surv_file)
#'   print(result)
#' }
#' }
#'
#' @export
mp_read_survival <- function(path) {
  path <- normalizePath(path, mustWork = FALSE)
  if (!file.exists(path)) {
    cli::cli_abort("Survival data file not found: {.file {path}}")
  }

  cli::cli_alert_info("Reading survival data: {.file {basename(path)}}")

  ext <- tolower(tools::file_ext(path))

  raw <- .mp_read_tabular(path)

  tbl <- .standardise_survival(raw)
  cli::cli_alert_success("Parsed {nrow(tbl)} patient record(s) with survival data")
  new_molpath_parsed(tbl, source_type = "survival", source_file = path)
}


#' Standardise survival column names (internal)
#' @noRd
.standardise_survival <- function(raw) {
  nms <- tolower(names(raw))
  mapping <- c(
    patient_id = "patient_id|patientid|patient.id|pat_id|pid|id|subject_id|subjectid",
    os_months  = "os_months|os.months|osmonths|overall_survival_months|os_time|os.time",
    os_status  = "os_status|os.status|osstatus|overall_survival_status|os_event|os.event|vital_status",
    pfs_months = "pfs_months|pfs.months|pfsmonths|progression_free_survival_months|pfs_time|pfs.time",
    pfs_status = "pfs_status|pfs.status|pfsstatus|progression_free_survival_status|pfs_event|pfs.event"
  )

  result <- .mp_map_fields(raw, mapping, required = "patient_id")
  for (field in c("os_months", "pfs_months")) result[[field]] <- .mp_number(result[[field]], field)
  for (field in c("os_status", "pfs_status")) result[[field]] <- .mp_number(result[[field]], field, event = TRUE)
  result
}


# == Auto-detect ===============================================================

#' Automatically read a molecular pathology file
#'
#' Detect the file type from its extension and/or content, then dispatch to the
#' appropriate parser.
#'
#' @param path Character scalar. Path to the file.
#' @param source_name Optional original filename for an extensionless upload.
#'   Dispatch uses its basename, and the result retains that basename as source
#'   identity. A disposable copy is removed after reading.
#'
#' @return A \code{molpath_parsed} object produced by the appropriate parser.
#'
#' @details
#' Extension mapping:
#' \itemize{
#'   \item \code{.vcf}, \code{.vcf.gz}: \code{\link{mp_read_vcf}}
#'   \item \code{.fastq}, \code{.fq}, \code{.fastq.gz}, \code{.fq.gz}:
#'     \code{\link{mp_read_fastq}}
#'   \item \code{.bam}: \code{\link{mp_read_bam}}
#'   \item \code{.xml}: \code{\link{mp_read_xml_report}}
#'   \item \code{.pdf}: \code{\link{mp_read_pdf_report}}
#'   \item \code{.xlsx}, \code{.xls}, \code{.csv}: tries survival/clinical
#'     format detection
#' }
#'
#' @examples
#' \donttest{
#' f <- system.file("extdata", "example.vcf", package = "molpathR")
#' if (nzchar(f)) {
#'   result <- mp_read_auto(f)
#'   print(result)
#' }
#' }
#'
#' @export
mp_read_auto <- function(path, source_name = NULL) {
  .mp_string(path, "path")
  if (!is.null(source_name)) {
    .mp_string(source_name, "source_name")
    source_name <- basename(source_name)
    if (source_name %in% c(".", "..")) cli::cli_abort("source_name must name a file.")
    if (!file.exists(path) || dir.exists(path)) cli::cli_abort("File not found: {.file {path}}")
    stage <- tempfile("molpath-import-")
    if (!dir.create(stage)) cli::cli_abort("Cannot stage uploaded source.")
    on.exit(unlink(stage, recursive = TRUE), add = TRUE)
    staged_file <- file.path(stage, source_name)
    if (!file.copy(path, staged_file)) cli::cli_abort("Cannot stage uploaded source.")
    result <- mp_read_auto(staged_file)
    result[["source_file"]] <- source_name
    return(result)
  }
  path <- normalizePath(path, mustWork = FALSE)
  if (!file.exists(path)) {
    cli::cli_abort("File not found: {.file {path}}")
  }

  fname <- tolower(basename(path))

  # Detect double extensions like .vcf.gz, .fastq.gz
  detected <- if (grepl("\\.vcf\\.gz$", fname) || grepl("\\.vcf$", fname)) {
    "vcf"
  } else if (grepl("\\.fastq\\.gz$", fname) || grepl("\\.fq\\.gz$", fname) ||
             grepl("\\.fastq$", fname)       || grepl("\\.fq$", fname)) {
    "fastq"
  } else if (grepl("\\.bam$", fname)) {
    "bam"
  } else if (grepl("\\.xml$", fname)) {
    "xml"
  } else if (grepl("\\.pdf$", fname)) {
    "pdf"
  } else if (grepl("\\.(xlsx|xls|csv|tsv)$", fname)) {
    "tabular"
  } else {
    NA_character_
  }

  if (is.na(detected)) {
    cli::cli_abort(c(
      "Cannot auto-detect file type for: {.file {basename(path)}}",
      "i" = "Supported extensions: .vcf, .vcf.gz, .fastq, .fq, .bam, .xml, .pdf, .xlsx, .xls, .csv"
    ))
  }

  cli::cli_alert_info("Auto-detected file type: {.val {detected}}")

  switch(detected,
    vcf    = mp_read_vcf(path),
    fastq  = mp_read_fastq(path),
    bam    = mp_read_bam(path),
    xml    = mp_read_xml_report(path),
    pdf    = mp_read_pdf_report(path),
    tabular = .read_tabular_auto(path)
  )
}


#' Auto-detect tabular file subtype (survival vs clinical) (internal)
#' @noRd
.read_tabular_auto <- function(path) {
  ext <- tolower(tools::file_ext(path))

  raw <- .mp_read_tabular(path, n_max = 5L)
  nms <- tolower(trimws(names(raw)))
  has_survival <- any(nms %in% c("os_months", "os.months", "osmonths", "overall_survival_months", "os_time", "os.time", "pfs_months", "pfs.time", "pfs_time"))
  has_clinical <- any(nms %in% c("parameter", "param", "test", "test_name", "testname", "analyte"))
  has_pathology <- any(nms %in% c("sample_id", "sampleid", "sample.id", "specimen_id", "specimenid"))
  if (sum(c(has_survival, has_clinical, has_pathology)) > 1L) cli::cli_abort("Ambiguous tabular source; use an explicit reader and unambiguous columns.")
  if (has_survival) return(mp_read_survival(path))
  if (has_clinical) return(mp_read_nexus_clinical(path))
  if (has_pathology) return(mp_read_nexus_pathology(path))
  cli::cli_abort("Cannot determine the tabular source from recognized columns; choose an explicit reader and verify the schema.")
}
