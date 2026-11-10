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
#' A validated text parser preserves original ID, INFO, FORMAT and sample fields
#' for single- and multi-sample VCFs, including gzip input. Installing
#' VariantAnnotation does not change the returned representation. Header lines
#' and declared sample names are retained in the result metadata.
#'
#' @param path Character scalar. Path to a \code{.vcf} or \code{.vcf.gz} file.
#'
#' @return A \code{molpath_parsed} object whose \code{data} slot is a
#'   \link[tibble]{tibble} with columns \code{chrom}, \code{pos}, \code{id},
#'   \code{ref}, \code{alt}, \code{qual}, \code{filter}, \code{info}, and any
#'   sample-level columns present in the file, plus \code{format} when declared.
#'   Sample names conflicting with these fixed output names are rejected.
#'
#' @examples
#' files <- mp_example_files(file.path(tempdir(), "molpathR-example"))
#' result <- mp_read_vcf(files$vcf[1])
#' result
#' result$data
#'
#' @export
mp_read_vcf <- function(path) {
  path <- .mp_sequence_path(path, "VCF")
  tbl <- .parse_vcf_text(path)
  metadata <- attr(tbl, "vcf_metadata", exact = TRUE)
  attr(tbl, "vcf_metadata") <- NULL
  new_molpath_parsed(tbl, source_type = "vcf", source_file = path,
                    metadata = metadata)
}

.mp_sequence_path <- function(path, kind) {
  if (!is.character(path) || length(path) != 1L || is.na(path) || !nzchar(path))
    cli::cli_abort("{kind} path must be one nonempty string.")
  if (!file.exists(path) || dir.exists(path))
    cli::cli_abort("{kind} file not found: {.file {path}}")
  normalizePath(path, mustWork = TRUE)
}

# Keep raw VCF field values: optional typed backends must not change IDs,
# FORMAT ordering, INFO flags or genotype subfields.
.parse_vcf_text <- function(path) {
  con <- if (grepl("\\.gz$", path, ignore.case = TRUE)) gzfile(path, "rt") else file(path, "rt")
  on.exit(close(con), add = TRUE)
  lines <- readLines(con, warn = FALSE)
  header <- which(grepl("^#CHROM(\\t|$)", lines))
  if (length(header) != 1L) cli::cli_abort("VCF requires exactly one #CHROM header.")
  before <- if (header > 1L) lines[seq_len(header - 1L)] else character()
  if (any(!grepl("^##", before))) cli::cli_abort("Invalid content before the VCF header.")
  if (!any(grepl("^##fileformat=VCFv4[.]", before)))
    cli::cli_abort("VCF requires a VCF 4.x fileformat declaration.")
  columns <- strsplit(sub("^#", "", lines[header]), "\t", fixed = TRUE)[[1L]]
  fixed <- c("CHROM", "POS", "ID", "REF", "ALT", "QUAL", "FILTER", "INFO")
  if (length(columns) < 8L || !identical(columns[seq_len(8L)], fixed) ||
      (length(columns) > 8L && columns[9L] != "FORMAT") ||
      anyDuplicated(columns) || any(!nzchar(columns)))
    cli::cli_abort("Invalid or duplicate VCF header columns.")
  samples <- if (length(columns) > 9L) columns[seq.int(10L, length(columns))] else character()
  if (any(samples %in% c(tolower(fixed), "format")))
    cli::cli_abort("VCF sample names conflict with reserved output column names.")
  data_lines <- if (header < length(lines)) lines[seq.int(header + 1L, length(lines))] else character()
  data_lines <- data_lines[nzchar(data_lines)]
  fields <- if (length(data_lines)) strsplit(paste0(data_lines, "\t\001"), "\t", fixed = TRUE) else list()
  fields <- lapply(fields, function(x) x[-length(x)])
  if (any(lengths(fields) != length(columns)) || any(vapply(fields, function(x) any(!nzchar(x)), logical(1))))
    cli::cli_abort("VCF data rows must have exactly the declared number of nonempty fields.")
  raw <- if (length(fields)) do.call(rbind, fields) else matrix(character(), 0L, length(columns))
  colnames(raw) <- columns
  pos <- suppressWarnings(as.numeric(unname(raw[, "POS"])))
  if (any(!grepl("^[0-9]+$", unname(raw[, "POS"]))) || any(!is.finite(pos) | pos < 1 | pos > .Machine$integer.max))
    cli::cli_abort("VCF POS must be a positive representable integer.")
  qual <- suppressWarnings(as.numeric(unname(raw[, "QUAL"])))
  if (any(unname(raw[, "QUAL"]) != "." & (!is.finite(qual) | qual < 0)))
    cli::cli_abort("VCF QUAL must be nonnegative and finite, or '.'.")
  tbl <- tibble::tibble(chrom = unname(raw[, "CHROM"]), pos = as.integer(pos),
    id = unname(raw[, "ID"]), ref = unname(raw[, "REF"]), alt = unname(raw[, "ALT"]), qual = qual,
    filter = unname(raw[, "FILTER"]), info = unname(raw[, "INFO"]))
  if (length(columns) > 8L) {
    formats <- strsplit(unname(raw[, "FORMAT"]), ":", fixed = TRUE)
    if (any(vapply(formats, function(x) any(!nzchar(x)) || anyDuplicated(x) > 0L, logical(1))))
      cli::cli_abort("VCF FORMAT keys must be nonempty and unique.")
    tbl$format <- unname(raw[, "FORMAT"])
    for (i in seq_len(nrow(raw))) for (sample in samples) {
      token <- raw[i, sample]
      if (token == ".") next
      values <- strsplit(paste0(token, ":\001"), ":", fixed = TRUE)[[1L]]
      values <- values[-length(values)]
      if (any(!nzchar(values)) || length(values) > length(formats[[i]]) ||
          identical(formats[[i]], "."))
        cli::cli_abort("VCF sample fields must match FORMAT; missing values use '.'.")
      gt <- match("GT", formats[[i]])
      if (!is.na(gt) && gt <= length(values)) {
        genotype <- values[gt]
        if (!grepl("^(\\.|[0-9]+)([/|](\\.|[0-9]+))*$", genotype))
          cli::cli_abort("Invalid VCF GT allele/separator syntax.")
        alleles <- strsplit(genotype, "[/|]")[[1L]]
        indexes <- suppressWarnings(as.numeric(alleles[alleles != "."]))
        alternatives <- if (raw[i, "ALT"] == ".") 0L else length(strsplit(raw[i, "ALT"], ",", fixed = TRUE)[[1L]])
        if (any(!is.finite(indexes) | indexes > alternatives))
          cli::cli_abort("VCF GT refers to an allele absent from ALT.")
      }
    }
  }
  for (sample in samples) tbl[[sample]] <- unname(raw[, sample])
  attr(tbl, "vcf_metadata") <- list(vcf_header = lines[seq_len(header)], sample_ids = samples)
  tbl
}


# == FASTQ ====================================================================

#' Read a FASTQ file
#'
#' Parse a FASTQ file into a tidy tibble of sequencing reads.
#'
#' Uses ShortRead when installed, streaming the first requested records rather
#' than sampling. Otherwise a strict 4-line text parser is used. Invalid or
#' incomplete records raise an error; backend parse errors are not hidden.
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
#' files <- mp_example_files(file.path(tempdir(), "molpathR-example"))
#' \donttest{
#' # Loading the optional 'ShortRead' backend, when installed, can take
#' # several seconds.
#' result <- mp_read_fastq(files$fastq, n = 10)
#' result$data
#' }
#'
#' @export
mp_read_fastq <- function(path, n = NULL) {
  path <- .mp_sequence_path(path, "FASTQ")
  .mp_read_limit(n)
  if (identical(n, 0) || identical(n, 0L)) {
    tbl <- .mp_empty_fastq()
  } else if (requireNamespace("ShortRead", quietly = TRUE) &&
             requireNamespace("Biostrings", quietly = TRUE)) {
    fq <- if (is.null(n)) ShortRead::readFastq(path) else {
      streamer <- ShortRead::FastqStreamer(path, n = n)
      on.exit(close(streamer), add = TRUE)
      ShortRead::yield(streamer)
    }
    sequences <- as.character(ShortRead::sread(fq))
    qualities <- as.character(Biostrings::quality(Biostrings::quality(fq)))
    if (any(nchar(sequences, type = "bytes") != nchar(qualities, type = "bytes")))
      cli::cli_abort("FASTQ sequence and quality lengths differ.")
    tbl <- tibble::tibble(read_id = as.character(ShortRead::id(fq)),
      sequence = sequences, quality = qualities, seq_length = nchar(sequences))
  } else {
    tbl <- .parse_fastq_text(path, n)
  }
  new_molpath_parsed(tbl, source_type = "fastq", source_file = path)
}

.mp_read_limit <- function(n) {
  if (!is.null(n) && (!is.numeric(n) || length(n) != 1L || is.na(n) ||
      !is.finite(n) || n < 0 || n != floor(n) || n > .Machine$integer.max))
    cli::cli_abort("'n' must be NULL or one nonnegative integer.")
}

.mp_empty_fastq <- function() tibble::tibble(read_id = character(),
  sequence = character(), quality = character(), seq_length = integer())


#' Text-based FASTQ parser (internal)
#' @noRd
.parse_fastq_text <- function(path, n = NULL) {
  .mp_read_limit(n)
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
    if (length(header) == 0L) break
    if (!startsWith(header, "@") || nchar(header) < 2L)
      cli::cli_abort("Invalid FASTQ record header.")
    seq_line <- readLines(con, n = 1L, warn = FALSE)
    plus_line <- readLines(con, n = 1L, warn = FALSE)
    qual_line <- readLines(con, n = 1L, warn = FALSE)
    if (length(seq_line) == 0L || length(plus_line) == 0L || length(qual_line) == 0L)
      cli::cli_abort("Truncated FASTQ record.")
    if (!startsWith(plus_line, "+")) cli::cli_abort("Invalid FASTQ separator.")
    if (nchar(plus_line) > 1L && substring(plus_line, 2L) != substring(header, 2L))
      cli::cli_abort("FASTQ separator identifier does not match its header.")
    if (grepl("[[:space:]]", seq_line) || !grepl("^[!-~]*$", qual_line) ||
        nchar(seq_line, type = "bytes") != nchar(qual_line, type = "bytes"))
      cli::cli_abort("Invalid FASTQ sequence or quality length/encoding.")

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
#' Uses \code{Rsamtools::scanBam()} when installed. Otherwise it calls
#' \code{samtools view}; if neither is available an informative error is raised.
#' Backend decoding errors are reported rather than triggering another reader.
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
#' # Building a BAM file requires the optional Bioconductor package Rsamtools.
#' if (requireNamespace("Rsamtools", quietly = TRUE)) {
#'   root <- tempfile("molpathR-bam-")
#'   dir.create(root)
#'   sam <- file.path(root, "tiny.sam")
#'   writeLines(c(
#'     "@HD\tVN:1.6\tSO:coordinate", "@SQ\tSN:chr1\tLN:1000",
#'     "q1\t0\tchr1\t11\t60\t4M\t*\t0\t0\tACGT\tIIII",
#'     "q2\t0\tchr1\t21\t40\t4M\t*\t0\t0\tTGCA\tJJJJ"
#'   ), sam)
#'   bam <- Rsamtools::asBam(sam, destination = file.path(root, "tiny"))
#'   mp_read_bam(bam)$data
#'   unlink(root, recursive = TRUE)
#' }
#'
#' @export
mp_read_bam <- function(path, regions = NULL) {
  path <- .mp_sequence_path(path, "BAM")
  if (!is.null(regions)) .mp_region_parts(regions)
  fields <- c("qname", "flag", "rname", "pos", "mapq", "cigar", "seq", "qual")

  cli::cli_alert_info("Reading BAM file: {.file {basename(path)}}")

  # --- Rsamtools path ---------------------------------------------------------
  if (requireNamespace("Rsamtools", quietly = TRUE)) {
    tbl <- tryCatch(
      {
        cli::cli_alert_info("Using {.pkg Rsamtools} backend")
        param <- if (!is.null(regions)) {
          if (!requireNamespace("GenomicRanges", quietly = TRUE) ||
              !requireNamespace("IRanges", quietly = TRUE))
            cli::cli_abort("BAM region queries require GenomicRanges and IRanges.")
          gr <- .parse_region_string(regions)
          Rsamtools::ScanBamParam(which = gr, what = fields)
        } else {
          Rsamtools::ScanBamParam(what = fields)
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
        cli::cli_abort("Rsamtools could not read the requested BAM data: {conditionMessage(e)}", parent = e)
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
        diagnostic <- tempfile("molpath-samtools-")
        on.exit(unlink(diagnostic), add = TRUE)
        out <- suppressWarnings(system2(samtools_bin, shQuote(args), stdout = TRUE, stderr = diagnostic))
        status <- attr(out, "status", exact = TRUE)
        if (!is.null(status) && status != 0L) {
          details <- paste(readLines(diagnostic, warn = FALSE), collapse = "\n")
          cli::cli_abort("samtools view failed (exit {status}): {details}")
        }
        if (length(out) == 0L) {
          tibble::tibble(
            qname = character(), flag = integer(), rname = character(),
            pos = integer(), mapq = integer(), cigar = character(),
            seq = character(), qual = character()
          )
        } else {
          fields <- strsplit(out, "\t", fixed = TRUE)
          if (any(lengths(fields) < 11L)) cli::cli_abort("samtools returned a malformed SAM record.")
          numeric_fields <- unlist(lapply(fields, function(x) x[c(2L, 4L, 5L)]), use.names = FALSE)
          numbers <- suppressWarnings(as.numeric(numeric_fields))
          if (any(!grepl("^[0-9]+$", numeric_fields)) || any(!is.finite(numbers) | numbers > .Machine$integer.max))
            cli::cli_abort("samtools returned invalid numeric SAM fields.")
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
        cli::cli_abort("Could not read the requested BAM data: {conditionMessage(e)}", parent = e)
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
.mp_region_parts <- function(region) {
  if (!is.character(region) || length(region) != 1L || is.na(region))
    cli::cli_abort("A genomic region must be one 'chr:start-end' string.")
  parts <- regmatches(region, regexec("^([^:[:space:]]+):([0-9]+)-([0-9]+)$", region))[[1L]]
  if (length(parts) != 4L) cli::cli_abort("Invalid region; expected 'chr:start-end'.")
  bounds <- suppressWarnings(as.numeric(parts[3:4]))
  if (any(!is.finite(bounds) | bounds < 1 | bounds > .Machine$integer.max) || bounds[2L] < bounds[1L])
    cli::cli_abort("Region bounds must be ordered positive representable integers.")
  list(chrom = parts[2L], bounds = as.integer(bounds))
}

.parse_region_string <- function(region) {
  parts <- .mp_region_parts(region)
  GenomicRanges::GRanges(seqnames = parts$chrom,
    ranges = IRanges::IRanges(start = parts$bounds[1L], end = parts$bounds[2L]))
}
