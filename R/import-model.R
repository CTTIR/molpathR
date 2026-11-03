# Normalize supported parsed sources without manufacturing clinical evidence.
.mp_merge_table <- function(left, right, name) {
  out <- dplyr::distinct(dplyr::bind_rows(left,right))
  primary <- switch(name,patients='patient_id',samples='sample_id',survival='patient_id',NULL)
  if (is.null(primary) || !anyDuplicated(out[[primary]])) return(.mp_table(out,name,fill=TRUE))
  rows <- lapply(unique(out[[primary]]),function(id) {
    group <- out[out[[primary]]==id,,drop=FALSE]
    first <- group[1L,,drop=FALSE]
    for (field in names(group)) {
      values <- group[[field]]
      if (is.list(values)) {
        if (length(unique(values))>1L) cli::cli_abort("Conflicting {name}.{field} values for {primary} {.val {id}}.")
      } else {
        observed <- unique(values[!is.na(values)])
        if (field=='source_file') {
          # All contributing paths are also retained in database provenance.
          observed <- utils::head(observed,1L)
        }
        if (length(observed)>1L) cli::cli_abort("Conflicting {name}.{field} values for {primary} {.val {id}}.")
        if (length(observed)) first[[field]] <- observed[1L]
      }
    }
    first
  })
  .mp_table(dplyr::bind_rows(rows),name,fill=TRUE)
}

.mp_vcf_variants <- function(parsed) {
  data <- parsed[['data']]
  declared_samples <- parsed[['metadata']][['sample_ids']]
  raw_vcf <- !is.null(declared_samples) || (all(c('chrom','pos','id','ref','alt','qual','filter','info') %in% names(data)) && !all(c('sample_id','variant','gene','classification','vaf') %in% names(data)))
  if (!raw_vcf && all(c('sample_id','variant') %in% names(data))) return(.mp_table(data,'variants',fill=TRUE))
  if (!all(c('chrom','pos','ref','alt','format') %in% names(data))) cli::cli_abort('VCF database integration requires sample FORMAT/GT calls or an explicitly normalized sample_id/variant table; a site list does not establish sample identity.')
  samples <- parsed[['metadata']][['sample_ids']]
  if (is.null(samples)) samples <- setdiff(names(data),c('chrom','pos','id','ref','alt','qual','filter','info','format'))
  if (!length(samples) || any(!samples %in% names(data))) cli::cli_abort('VCF database integration requires declared sample IDs.')
  rows <- list(); at <- 0L
  for (i in seq_len(nrow(data))) {
    format <- strsplit(data[['format']][i],':',fixed=TRUE)[[1L]]
    gt_position <- match('GT',format)
    if (is.na(gt_position)) cli::cli_abort('VCF record {i} has no GT field; supply explicitly normalized called variants rather than infer calls from other measurements.')
    alts <- strsplit(data[['alt']][i],',',fixed=TRUE)[[1L]]
    for (sample in samples) {
      token <- strsplit(data[[sample]][i],':',fixed=TRUE)[[1L]]
      gt <- if (gt_position<=length(token)) token[gt_position] else '.'
      if (!grepl('^([0-9]+|[.])([/|]([0-9]+|[.]))*$', gt)) cli::cli_abort('Malformed GT for sample {.val {sample}} at VCF record {i}.')
      alleles <- strsplit(gt,'[/|]')[[1L]]
      if (!length(alleles) || any(!grepl('^[0-9]+$|^[.]$',alleles))) cli::cli_abort('Malformed GT for sample {.val {sample}} at VCF record {i}.')
      indices <- suppressWarnings(as.numeric(alleles[alleles!='.']))
      if (any(!is.finite(indices) | indices>length(alts))) cli::cli_abort('GT allele index exceeds ALT values at VCF record {i}.')
      called <- unique(indices[indices>0])
      if (any(alts[called] %in% c('.', '<NON_REF>', '<*>'))) cli::cli_abort('VCF record {i} does not identify a specific alternate allele for its nonreference GT; supply explicitly interpreted calls.')
      for (j in called) {
        at <- at+1L; row <- data[i,setdiff(names(data),samples),drop=FALSE]
        row[['sample_fields']] <- data[[sample]][i]
        row[['sample_id']] <- sample
        row[['genotype']] <- gt
        row[['called_alt']] <- alts[j]
        row[['variant']] <- paste0(row[['chrom']],':',row[['pos']],':',row[['ref']],'>',alts[j])
        row[['source_file']] <- parsed[['source_file']]
        rows[[at]] <- row
      }
    }
  }
  if (!length(rows)) return(.mp_tables()[['variants']])
  .mp_table(dplyr::bind_rows(rows),'variants',fill=TRUE)
}

.mp_source_tables <- function(parsed) {
  if (!inherits(parsed,'molpath_parsed')) cli::cli_abort('Expected a molpath_parsed object.')
  .mp_string(parsed[['source_type']],'source_type'); .mp_string(parsed[['source_file']],'source_file')
  type <- parsed[['source_type']]; data <- parsed[['data']]; source <- parsed[['source_file']]
  tables <- .mp_tables()
  if (type %in% c('fastq','bam')) cli::cli_abort(c('Raw {.val {type}} reads or alignments are not interpreted variant calls.','i'='Keep the parsed raw data for inspection. Supply a called VCF with sample GT values or explicitly normalized variant records for database integration.'))
  if (is.list(data) && !is.data.frame(data)) {
    .mp_named(data,'Parsed tables')
    if (any(!names(data) %in% names(tables))) cli::cli_abort('Parsed table names must match the six database tables.')
    for (name in names(data)) tables[[name]] <- .mp_table(data[[name]],name,fill=TRUE)
    return(tables)
  }
  if (!is.data.frame(data)) cli::cli_abort('Parsed data must be a data frame or a named list of database tables.')
  data <- tibble::as_tibble(data)
  if (type=='vcf') {
    tables[['variants']] <- .mp_vcf_variants(parsed)
    samples <- parsed[['metadata']][['sample_ids']]
    if (is.null(samples)) samples <- unique(tables[['variants']][['sample_id']])
    samples <- samples[!is.na(samples) & nzchar(samples)]
    if (length(samples)) tables[['samples']] <- .mp_table(tibble::tibble(sample_id=samples,source_file=source),'samples',fill=TRUE)
  } else if (type=='nexus_pathology') {
    patient_fields <- intersect(c('patient_id','age','sex','diagnosis','name','dob'),names(data))
    tables[['patients']] <- .mp_merge_table(tables[['patients']],.mp_table(dplyr::distinct(data[,patient_fields,drop=FALSE]),'patients',fill=TRUE),'patients')
    sample_fields <- intersect(c('sample_id','patient_id','sample_type','date','report_date'),names(data))
    samples <- data[,sample_fields,drop=FALSE]
    if ('report_date' %in% names(samples) && !'date' %in% names(samples)) samples[['date']] <- samples[['report_date']]
    samples[['source_file']] <- rep(source,nrow(samples))
    tables[['samples']] <- .mp_merge_table(tables[['samples']],.mp_table(dplyr::distinct(samples),'samples',fill=TRUE),'samples')
  } else if (type=='xml_report') {
    data[['source_file']] <- rep(source,nrow(data))
    tables[['variants']] <- .mp_table(data,'variants',fill=TRUE)
    if ('patient_id' %in% names(data)) {
      patients <- data[!is.na(data[['patient_id']]) & nzchar(data[['patient_id']]),intersect(c('patient_id','patient_name','sex','diagnosis','age'),names(data)),drop=FALSE]
      if ('patient_name' %in% names(patients)) names(patients)[names(patients)=='patient_name'] <- 'name'
      tables[['patients']] <- .mp_merge_table(tables[['patients']],.mp_table(dplyr::distinct(patients),'patients',fill=TRUE),'patients')
    }
    samples <- data[!is.na(data[['sample_id']]) & nzchar(data[['sample_id']]),intersect(c('sample_id','patient_id','sample_type','source_file'),names(data)),drop=FALSE]
    tables[['samples']] <- .mp_merge_table(tables[['samples']],.mp_table(dplyr::distinct(samples),'samples',fill=TRUE),'samples')
  } else if (type=='pdf_report') {
    if (all(c('section','content') %in% names(data))) {
      full_text <- parsed[['metadata']][['pdf_text']]
      if (is.null(full_text)) full_text <- paste(data[['content']],collapse='\n\n')
      data <- tibble::tibble(sample_id=NA_character_,report_type='PDF',summary_text=full_text,source_file=source,sections=list(data))
    }
    tables[['reports']] <- .mp_table(data,'reports',fill=TRUE)
  } else if (type %in% c('nexus_clinical','survival')) {
    name <- if (type=='survival') 'survival' else 'clinical'
    tables[[name]] <- .mp_table(data,name,fill=TRUE)
  } else {
    rlang::warn(c('Unknown source type encountered.','i'=paste0("source_type '",type,"' is not recognized; data was not added.")),class='molpathR_unknown_source_type')
  }
  tables
}

.mp_add_sources <- function(db, parsed_list) {
  db <- .mp_normalize_db(db,legacy=TRUE)
  metadata <- db[['metadata']]
  records <- metadata[['source_records']]
  if (is.null(records)) records <- list()
  for (parsed in parsed_list) {
    tables <- .mp_source_tables(parsed)
    for (name in names(tables)) db[[name]] <- .mp_merge_table(db[[name]],tables[[name]],name)
    metadata[['source_files']] <- unique(c(metadata[['source_files']],parsed[['source_file']]))
    version <- parsed[['parser_version']]
    if (!is.null(version)) metadata[['parser_versions']] <- unique(c(unlist(metadata[['parser_versions']],use.names=FALSE),version))
    records[[length(records)+1L]] <- list(source_type=parsed[['source_type']],source_file=parsed[['source_file']],parse_date=parsed[['parse_date']],parser_version=version,details=parsed[['metadata']])
  }
  metadata[['source_records']] <- records
  metadata[['last_updated']] <- Sys.time()
  db[['metadata']] <- metadata
  .mp_normalize_db(db)
}
