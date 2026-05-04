# ---- parsers.R ---------------------------------------------------------------
# Parser functions for molpathR: read heterogeneous molecular pathology files
# and return molpath_parsed S3 objects.
# ------------------------------------------------------------------------------


# == VCF ======================================================================

#' Read a VCF file
#'
#' Parse a Variant Call Format (VCF 4.x) file and return a tidy tibble of
#' variant calls.
#'
#' The function first attempts to use
#' \code{VariantAnnotation::readVcf()} from Bioconductor.
#' If the package is not installed it falls back to a lightweight text parser
#' that handles single- and multi-sample VCFs.
#'
#' @param path Character scalar. Path to a \code{.vcf} or \code{.vcf.gz} file.
#'
#' @return A \code{molpath_parsed} object whose \code{data} slot is a
#'   \link[tibble]{tibble} with columns \code{chrom}, \code{pos}, \code{id},
#'   \code{ref}, \code{alt}, \code{qual}, \code{filter}, \code{info}, and any
#'   sample-level columns present in the file.
#'
#' @examples
#' \donttest{
#' vcf_file <- system.file("extdata", "example.vcf", package = "molpathR")
#' if (nzchar(vcf_file)) {
#'   result <- mp_read_vcf(vcf_file)
#'   print(result)
#' }
#' }
#'
#' @export
mp_read_vcf <- function(path) {
  path <- normalizePath(path, mustWork = FALSE)
  if (!file.exists(path)) {
    cli::cli_abort("VCF file not found: {.file {path}}")
  }

  cli::cli_alert_info("Reading VCF file: {.file {basename(path)}}")

  # --- Bioconductor path ------------------------------------------------------
  if (requireNamespace("VariantAnnotation", quietly = TRUE)) {
    tbl <- tryCatch(
      {
        cli::cli_alert_info("Using {.pkg VariantAnnotation} backend")
        vcf <- VariantAnnotation::readVcf(path)
        rd <- SummarizedExperiment::rowRanges(vcf)

        base_df <- tibble::tibble(
          chrom  = as.character(GenomicRanges::seqnames(rd)),
          pos    = BiocGenerics::start(rd),
          id     = names(rd),
          ref    = as.character(rd$REF),
          alt    = vapply(
            as.list(rd$ALT),
            function(x) paste(as.character(x), collapse = ","),
            character(1)
          ),
          qual   = VariantAnnotation::fixed(vcf)$QUAL,
          filter = VariantAnnotation::fixed(vcf)$FILTER,
          info   = vapply(
            seq_len(nrow(VariantAnnotation::info(vcf))),
            function(i) {
              row <- VariantAnnotation::info(vcf)[i, , drop = FALSE]
              paste(names(row), "=",
                    vapply(row, function(v) paste(as.character(v), collapse = ","),
                           character(1)),
                    collapse = ";")
            },
            character(1)
          )
        )

        # Sample genotype columns
        geno_data <- VariantAnnotation::geno(vcf)
        if ("GT" %in% names(geno_data)) {
          gt_mat <- geno_data[["GT"]]
          for (samp in colnames(gt_mat)) {
            base_df[[samp]] <- gt_mat[, samp]
          }
        }
        base_df
      },
      error = function(e) {
        cli::cli_warn(
          "VariantAnnotation failed ({conditionMessage(e)}); falling back to text parser."
        )
        NULL
      }
    )
    if (!is.null(tbl)) {
      cli::cli_alert_success("Parsed {nrow(tbl)} variant(s) via VariantAnnotation")
      return(new_molpath_parsed(tbl, source_type = "vcf", source_file = path))
    }
  }

  # --- Text fallback ----------------------------------------------------------
  tbl <- tryCatch(
    .parse_vcf_text(path),
    error = function(e) {
      cli::cli_abort(
        c("Failed to parse VCF file: {.file {path}}",
          "x" = conditionMessage(e))
      )
    }
  )
  cli::cli_alert_success("Parsed {nrow(tbl)} variant(s) via text parser")
  new_molpath_parsed(tbl, source_type = "vcf", source_file = path)
}


#' Text-based VCF parser (internal)
#' @noRd
.parse_vcf_text <- function(path) {
  # Support gzipped files
  if (grepl("\\.gz$", path, ignore.case = TRUE)) {
    con <- gzfile(path, open = "rt")
    on.exit(close(con), add = TRUE)
    lines <- readLines(con, warn = FALSE)
  } else {
    lines <- readLines(path, warn = FALSE)
  }

  # Separate meta, header, data

  meta_idx <- grep("^##", lines)
  header_idx <- grep("^#CHROM", lines)
  if (length(header_idx) == 0L) {
    cli::cli_abort("No #CHROM header line found in VCF file.")
  }
  header_line <- lines[header_idx[1L]]
  col_names <- strsplit(sub("^#", "", header_line), "\t")[[1L]]

  data_lines <- lines[seq(header_idx[1L] + 1L, length(lines))]
  data_lines <- data_lines[nzchar(data_lines)]

  if (length(data_lines) == 0L) {
    tbl <- tibble::tibble(
      chrom = character(), pos = integer(), id = character(),
      ref = character(), alt = character(), qual = numeric(),
      filter = character(), info = character()
    )
    return(tbl)
  }

  raw <- utils::read.delim(
    textConnection(paste(data_lines, collapse = "\n")),
    header = FALSE, sep = "\t", stringsAsFactors = FALSE,
    colClasses = "character", quote = ""
  )
  if (ncol(raw) != length(col_names)) {
    cli::cli_warn("Column count mismatch in VCF; trimming to header count.")
    raw <- raw[, seq_along(col_names), drop = FALSE]
  }
  names(raw) <- col_names

  tbl <- tibble::tibble(
    chrom  = raw[["CHROM"]],
    pos    = as.integer(raw[["POS"]]),
    id     = raw[["ID"]],
    ref    = raw[["REF"]],
    alt    = raw[["ALT"]],
    qual   = suppressWarnings(as.numeric(raw[["QUAL"]])),
    filter = raw[["FILTER"]],
    info   = raw[["INFO"]]
  )


  # Append sample columns (everything after FORMAT)
  fixed_cols <- c("CHROM", "POS", "ID", "REF", "ALT", "QUAL", "FILTER", "INFO", "FORMAT")
  sample_cols <- setdiff(col_names, fixed_cols)
  for (sc in sample_cols) {
    tbl[[sc]] <- raw[[sc]]
  }
  tbl
}


# == FASTQ ====================================================================

#' Read a FASTQ file
#'
#' Parse a FASTQ file into a tidy tibble of sequencing reads.
#'
#' Tries \code{ShortRead::readFastq()} first.
#' Falls back to a base-R text parser that reads 4-line FASTQ records.
#'
#' @param path Character scalar. Path to a \code{.fastq}, \code{.fq},
#'   \code{.fastq.gz}, or \code{.fq.gz} file.
#' @param n Integer or \code{NULL}. If specified, only the first \code{n}
#'   records are returned.
#'
#' @return A \code{molpath_parsed} object whose \code{data} slot is a
#'   \link[tibble]{tibble} with columns \code{read_id}, \code{sequence},
#'   \code{quality}, and \code{seq_length}.
#'
#' @examples
#' \donttest{
#' fq_file <- system.file("extdata", "example.fastq", package = "molpathR")
#' if (nzchar(fq_file)) {
#'   result <- mp_read_fastq(fq_file, n = 100)
#'   print(result)
#' }
#' }
#'
#' @export
mp_read_fastq <- function(path, n = NULL) {
  path <- normalizePath(path, mustWork = FALSE)
  if (!file.exists(path)) {
    cli::cli_abort("FASTQ file not found: {.file {path}}")
  }

  cli::cli_alert_info("Reading FASTQ file: {.file {basename(path)}}")


  # --- ShortRead path ---------------------------------------------------------
  if (requireNamespace("ShortRead", quietly = TRUE) &&
      requireNamespace("Biostrings", quietly = TRUE)) {
    tbl <- tryCatch(
      {
        cli::cli_alert_info("Using {.pkg ShortRead} backend")
        fq <- if (!is.null(n)) {
          sampler <- ShortRead::FastqSampler(path, n = n)
          on.exit(close(sampler), add = TRUE)
          ShortRead::yield(sampler)
        } else {
          ShortRead::readFastq(path)
        }
        seqs <- ShortRead::sread(fq)
        quals <- Biostrings::quality(fq)
        tibble::tibble(
          read_id    = as.character(ShortRead::id(fq)),
          sequence   = as.character(seqs),
          quality    = as.character(quals),
          seq_length = Biostrings::width(seqs)
        )
      },
      error = function(e) {
        cli::cli_warn(
          "ShortRead failed ({conditionMessage(e)}); falling back to text parser."
        )
        NULL
      }
    )
    if (!is.null(tbl)) {
      if (!is.null(n)) tbl <- tbl[seq_len(min(n, nrow(tbl))), ]
      cli::cli_alert_success("Parsed {nrow(tbl)} read(s) via ShortRead")
      return(new_molpath_parsed(tbl, source_type = "fastq", source_file = path))
    }
  }

  # --- Text fallback ----------------------------------------------------------
  tbl <- tryCatch(
    .parse_fastq_text(path, n),
    error = function(e) {
      cli::cli_abort(
        c("Failed to parse FASTQ file: {.file {path}}",
          "x" = conditionMessage(e))
      )
    }
  )
  cli::cli_alert_success("Parsed {nrow(tbl)} read(s) via text parser")
  new_molpath_parsed(tbl, source_type = "fastq", source_file = path)
}


#' Text-based FASTQ parser (internal)
#' @noRd
.parse_fastq_text <- function(path, n = NULL) {
  if (grepl("\\.gz$", path, ignore.case = TRUE)) {
    con <- gzfile(path, open = "rt")
    on.exit(close(con), add = TRUE)
  } else {
    con <- file(path, open = "rt")
    on.exit(close(con), add = TRUE)
  }

  ids  <- character()
  seqs <- character()
  quals <- character()

  max_records <- if (!is.null(n)) n else Inf
  count <- 0L

  while (count < max_records) {
    header <- readLines(con, n = 1L, warn = FALSE)
    if (length(header) == 0L || !nzchar(header)) break
    seq_line <- readLines(con, n = 1L, warn = FALSE)
    plus_line <- readLines(con, n = 1L, warn = FALSE)
    qual_line <- readLines(con, n = 1L, warn = FALSE)
    if (length(seq_line) == 0L || length(qual_line) == 0L) break

    count <- count + 1L
    ids[count]  <- sub("^@", "", header)
    seqs[count] <- seq_line
    quals[count] <- qual_line
  }

  tibble::tibble(
    read_id    = ids,
    sequence   = seqs,
    quality    = quals,
    seq_length = nchar(seqs)
  )
}


# == BAM ======================================================================

#' Read a BAM file
#'
#' Parse a BAM (Binary Alignment Map) file into a tidy tibble.
#'
#' Attempts \code{Rsamtools::scanBam()} first, then falls back to a system
#' call to \code{samtools view}.
#' If neither is available an informative error is raised.
#'
#' @param path Character scalar. Path to a \code{.bam} file.
#' @param regions Character scalar or \code{NULL}. An optional genomic region
#'   string such as \code{"chr1:1000-2000"} to restrict the query.
#'
#' @return A \code{molpath_parsed} object whose \code{data} slot is a
#'   \link[tibble]{tibble} with columns \code{qname}, \code{flag},
#'   \code{rname}, \code{pos}, \code{mapq}, \code{cigar}, \code{seq}, and
#'   \code{qual}.
#'
#' @examples
#' \donttest{
#' bam_file <- system.file("extdata", "example.bam", package = "molpathR")
#' if (nzchar(bam_file)) {
#'   result <- mp_read_bam(bam_file)
#'   print(result)
#' }
#' }
#'
#' @export
mp_read_bam <- function(path, regions = NULL) {
  path <- normalizePath(path, mustWork = FALSE)
  if (!file.exists(path)) {
    cli::cli_abort("BAM file not found: {.file {path}}")
  }

  cli::cli_alert_info("Reading BAM file: {.file {basename(path)}}")

  # --- Rsamtools path ---------------------------------------------------------
  if (requireNamespace("Rsamtools", quietly = TRUE)) {
    tbl <- tryCatch(
      {
        cli::cli_alert_info("Using {.pkg Rsamtools} backend")
        param <- if (!is.null(regions) &&
                     requireNamespace("GenomicRanges", quietly = TRUE) &&
                     requireNamespace("IRanges", quietly = TRUE)) {
          gr <- .parse_region_string(regions)
          Rsamtools::ScanBamParam(which = gr)
        } else {
          Rsamtools::ScanBamParam()
        }
        raw <- Rsamtools::scanBam(path, param = param)[[1L]]
        tibble::tibble(
          qname = raw[["qname"]] %||% character(),
          flag  = raw[["flag"]]  %||% integer(),
          rname = as.character(raw[["rname"]] %||% character()),
          pos   = raw[["pos"]]   %||% integer(),
          mapq  = raw[["mapq"]]  %||% integer(),
          cigar = raw[["cigar"]] %||% character(),
          seq   = as.character(raw[["seq"]]  %||% character()),
          qual  = as.character(raw[["qual"]] %||% character())
        )
      },
      error = function(e) {
        cli::cli_warn(
          "Rsamtools failed ({conditionMessage(e)}); trying samtools."
        )
        NULL
      }
    )
    if (!is.null(tbl)) {
      cli::cli_alert_success("Parsed {nrow(tbl)} alignment(s) via Rsamtools")
      return(new_molpath_parsed(tbl, source_type = "bam", source_file = path))
    }
  }

  # --- samtools fallback ------------------------------------------------------
  samtools_bin <- Sys.which("samtools")
  if (nzchar(samtools_bin)) {
    tbl <- tryCatch(
      {
        cli::cli_alert_info("Using system {.code samtools view}")
        args <- c("view", path)
        if (!is.null(regions)) args <- c(args, regions)
        out <- system2(samtools_bin, args, stdout = TRUE, stderr = FALSE)
        if (length(out) == 0L) {
          tibble::tibble(
            qname = character(), flag = integer(), rname = character(),
            pos = integer(), mapq = integer(), cigar = character(),
            seq = character(), qual = character()
          )
        } else {
          fields <- strsplit(out, "\t")
          tibble::tibble(
            qname = vapply(fields, `[`, character(1), 1L),
            flag  = as.integer(vapply(fields, `[`, character(1), 2L)),
            rname = vapply(fields, `[`, character(1), 3L),
            pos   = as.integer(vapply(fields, `[`, character(1), 4L)),
            mapq  = as.integer(vapply(fields, `[`, character(1), 5L)),
            cigar = vapply(fields, `[`, character(1), 6L),
            seq   = vapply(fields, `[`, character(1), 10L),
            qual  = vapply(fields, `[`, character(1), 11L)
          )
        }
      },
      error = function(e) {
        cli::cli_warn(
          "samtools failed ({conditionMessage(e)})."
        )
        NULL
      }
    )
    if (!is.null(tbl)) {
      cli::cli_alert_success("Parsed {nrow(tbl)} alignment(s) via samtools")
      return(new_molpath_parsed(tbl, source_type = "bam", source_file = path))
    }
  }

  cli::cli_abort(c(
    "Cannot read BAM file: neither {.pkg Rsamtools} nor system {.code samtools} is available.",
    "i" = "Install {.pkg Rsamtools} from Bioconductor or add {.code samtools} to your PATH."
  ))
}


#' Parse a region string like "chr1:1000-2000" into a GRanges object
#' @noRd
.parse_region_string <- function(region) {
  parts <- regmatches(
    region,
    regexec("^([^:]+):([0-9]+)-([0-9]+)$", region)
  )[[1L]]
  if (length(parts) != 4L) {
    cli::cli_abort("Invalid region format: {.val {region}}. Expected 'chr:start-end'.")
  }
  GenomicRanges::GRanges(
    seqnames = parts[2L],
    ranges   = IRanges::IRanges(
      start = as.integer(parts[3L]),
      end   = as.integer(parts[4L])
    )
  )
}


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
#'   level, and therapeutic implications.
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
    patient_id   <- .xml_text_or_na(pnode, "PatientID|PatientId|ID|Id")
    patient_name <- .xml_text_or_na(pnode, "Name|PatientName")

    sample_nodes <- xml2::xml_find_all(pnode, ".//Sample")
    if (length(sample_nodes) == 0L) {
      sample_nodes <- xml2::xml_find_all(pnode, ".//*[local-name()='Sample']")
    }
    # If no Sample level, look for Variants directly
    if (length(sample_nodes) == 0L) sample_nodes <- list(pnode)

    for (snode in sample_nodes) {
      sample_id   <- .xml_text_or_na(snode, "SampleID|SampleId|ID|Id")
      sample_type <- .xml_text_or_na(snode, "SampleType|Type")

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
      classification = character(), evidence = character(),
      therapeutic = character()
    ))
  }

  dplyr::bind_rows(rows)
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
    child <- xml2::xml_find_first(node, paste0(".//", nm))
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
#' \code{pdftools::pdf_text()} and regex-based section parsing.
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
  new_molpath_parsed(tbl, source_type = "pdf_report", source_file = path)
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
  raw <- tryCatch(
    readr::read_csv(path, show_col_types = FALSE, col_types = readr::cols(.default = "c")),
    error = function(e) {
      # Try semicolon delimiter (common in European systems)
      tryCatch(
        readr::read_delim(path, delim = ";", show_col_types = FALSE,
                          col_types = readr::cols(.default = "c")),
        error = function(e2) {
          cli::cli_abort(c(
            "Failed to parse Nexus pathology CSV: {.file {path}}",
            "x" = conditionMessage(e2)
          ))
        }
      )
    }
  )

  # Standardise column names
  .standardise_nexus_pathology(raw)
}


#' Parse Nexus pathology XML (internal)
#' @noRd
.parse_nexus_pathology_xml <- function(path) {
  doc <- xml2::read_xml(path)
  records <- xml2::xml_find_all(doc, ".//Record|.//Patient|.//Case")
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
    name        = "name|patient_name|patientname|patient.name",
    dob         = "dob|date_of_birth|dateofbirth|birth_date|birthdate",
    sex         = "sex|gender",
    sample_id   = "sample_id|sampleid|sample.id|specimen_id|specimenid",
    sample_type = "sample_type|sampletype|specimen_type|specimentype|type",
    diagnosis   = "diagnosis|dx|diagnose",
    report_date = "report_date|reportdate|date|report.date"
  )

  result <- tibble::tibble(.rows = nrow(raw))

  for (col_out in names(mapping)) {
    pattern <- mapping[[col_out]]
    matched <- grep(pattern, nms)
    if (length(matched) > 0L) {
      result[[col_out]] <- raw[[matched[1L]]]
    } else {
      result[[col_out]] <- NA_character_
    }
  }

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

  raw <- tryCatch(
    readr::read_csv(path, show_col_types = FALSE,
                    col_types = readr::cols(.default = "c")),
    error = function(e) {
      tryCatch(
        readr::read_delim(path, delim = ";", show_col_types = FALSE,
                          col_types = readr::cols(.default = "c")),
        error = function(e2) {
          cli::cli_abort(c(
            "Failed to parse Nexus clinical CSV",
            "x" = conditionMessage(e2)
          ))
        }
      )
    }
  )

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

  result <- tibble::tibble(.rows = nrow(raw))

  for (col_out in names(mapping)) {
    pattern <- mapping[[col_out]]
    matched <- grep(pattern, nms)
    if (length(matched) > 0L) {
      result[[col_out]] <- raw[[matched[1L]]]
    } else {
      result[[col_out]] <- NA_character_
    }
  }

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

  raw <- tryCatch(
    {
      if (ext %in% c("xlsx", "xls")) {
        readxl::read_excel(path, col_types = "text")
      } else if (ext == "csv") {
        readr::read_csv(path, show_col_types = FALSE,
                        col_types = readr::cols(.default = "c"))
      } else if (ext == "tsv") {
        readr::read_tsv(path, show_col_types = FALSE,
                        col_types = readr::cols(.default = "c"))
      } else {
        # Try CSV as default
        readr::read_csv(path, show_col_types = FALSE,
                        col_types = readr::cols(.default = "c"))
      }
    },
    error = function(e) {
      cli::cli_abort(c(
        "Failed to read survival data: {.file {path}}",
        "x" = conditionMessage(e)
      ))
    }
  )

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

  result <- tibble::tibble(.rows = nrow(raw))

  for (col_out in names(mapping)) {
    pattern <- mapping[[col_out]]
    matched <- grep(pattern, nms)
    if (length(matched) > 0L) {
      val <- raw[[matched[1L]]]
      # Convert numeric columns
      if (col_out %in% c("os_months", "pfs_months")) {
        result[[col_out]] <- suppressWarnings(as.numeric(val))
      } else if (col_out %in% c("os_status", "pfs_status")) {
        result[[col_out]] <- suppressWarnings(as.integer(val))
      } else {
        result[[col_out]] <- val
      }
    } else {
      if (col_out %in% c("os_months", "pfs_months")) {
        result[[col_out]] <- NA_real_
      } else if (col_out %in% c("os_status", "pfs_status")) {
        result[[col_out]] <- NA_integer_
      } else {
        result[[col_out]] <- NA_character_
      }
    }
  }

  result
}


# == Auto-detect ===============================================================

#' Automatically read a molecular pathology file
#'
#' Detect the file type from its extension and/or content, then dispatch to the
#' appropriate parser.
#'
#' @param path Character scalar. Path to the file.
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
mp_read_auto <- function(path) {
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
  } else if (grepl("\\.(xlsx|xls|csv)$", fname)) {
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

  raw <- tryCatch(
    {
      if (ext %in% c("xlsx", "xls")) {
        readxl::read_excel(path, n_max = 5L, col_types = "text")
      } else {
        readr::read_csv(path, n_max = 5L, show_col_types = FALSE,
                        col_types = readr::cols(.default = "c"))
      }
    },
    error = function(e) {
      # Try semicolon delimited
      tryCatch(
        readr::read_delim(path, delim = ";", n_max = 5L,
                          show_col_types = FALSE,
                          col_types = readr::cols(.default = "c")),
        error = function(e2) {
          cli::cli_abort(c(
            "Cannot read tabular file: {.file {path}}",
            "x" = conditionMessage(e2)
          ))
        }
      )
    }
  )

  nms <- tolower(names(raw))

  # Heuristic: survival-like columns
  has_survival <- any(grepl("os_|pfs_|overall_survival|progression_free", nms))
  # Heuristic: clinical-like columns
  has_clinical <- any(grepl("parameter|analyte|test_name|unit", nms))

  if (has_survival) {
    cli::cli_alert_info("Detected survival/outcome data format")
    return(mp_read_survival(path))
  }
  if (has_clinical) {
    cli::cli_alert_info("Detected clinical data format")
    return(mp_read_nexus_clinical(path))
  }

  # Default to survival reader (most permissive)
  cli::cli_alert_info("Defaulting to survival/tabular reader")
  mp_read_survival(path)
}
