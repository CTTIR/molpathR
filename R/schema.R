# Shared stored-model contracts.
.mp_tables <- function() {
  list(
    patients = tibble::tibble(patient_id=character(), age=double(), sex=character(), diagnosis=character()),
    samples = tibble::tibble(sample_id=character(), patient_id=character(), sample_type=character(), date=as.Date(character()), source_file=character()),
    variants = tibble::tibble(sample_id=character(), gene=character(), variant=character(), classification=character(), vaf=double()),
    reports = tibble::tibble(sample_id=character(), report_type=character(), report_date=as.Date(character()), summary_text=character(), source_file=character()),
    clinical = tibble::tibble(patient_id=character(), parameter=character(), value=character(), date=as.Date(character()), source=character()),
    survival = tibble::tibble(patient_id=character(), os_months=double(), os_status=integer(), pfs_months=double(), pfs_status=integer())
  )
}

.mp_named <- function(x, label) {
  if (!is.list(x) || is.null(names(x)) || anyNA(names(x)) || any(!nzchar(names(x))) || anyDuplicated(names(x))) {
    cli::cli_abort("{label} must be a list with unique, nonempty names.")
  }
}

.mp_string <- function(x, label, allow_empty=FALSE) {
  if (!is.character(x) || length(x)!=1L || is.na(x) || (!allow_empty && !nzchar(trimws(x)))) {
    cli::cli_abort("{label} must be a single nonmissing character string.")
  }
}

.mp_date <- function(x, label) {
  if (inherits(x, 'Date')) {
    if (any(!is.na(x) & !is.finite(as.numeric(x)))) cli::cli_abort("{label} contains invalid dates.")
    return(x)
  }
  if (is.logical(x) && all(is.na(x))) return(as.Date(rep(NA_character_,length(x))))
  if (!is.character(x)) cli::cli_abort("{label} must contain Date values or ISO dates (YYYY-MM-DD).")
  x[!is.na(x) & !nzchar(trimws(x))] <- NA_character_
  out <- suppressWarnings(as.Date(x,format='%Y-%m-%d'))
  bad <- !is.na(x) & (is.na(out) | format(out,'%Y-%m-%d')!=x)
  if (any(bad)) cli::cli_abort("{label} contains invalid ISO dates (YYYY-MM-DD).")
  out
}

.mp_table <- function(x, name, fill=FALSE) {
  template <- .mp_tables()[[name]]
  if (!tibble::is_tibble(x)) cli::cli_abort("Table {.val {name}} must be a tibble.")
  if (anyNA(names(x)) || any(!nzchar(names(x))) || anyDuplicated(names(x))) cli::cli_abort("Table {.val {name}} needs unique, nonempty column names.")
  missing <- setdiff(names(template),names(x))
  if (length(missing) && !fill) cli::cli_abort("Table {.val {name}} is missing required column{?s}: {.field {missing}}.")
  for (field in missing) x[[field]] <- rep(template[[field]][NA_integer_],nrow(x))
  for (field in names(template)) {
    value <- x[[field]]; label <- paste0(name,'.',field)
    if (inherits(template[[field]],'Date')) {
      x[[field]] <- .mp_date(value,label)
    } else if (is.character(template[[field]])) {
      if (is.factor(value)) value <- as.character(value)
      if (is.logical(value) && all(is.na(value))) value <- rep(NA_character_,length(value))
      if (!is.character(value) || !is.null(dim(value))) cli::cli_abort("{label} must be a character vector.")
      x[[field]] <- value
    } else {
      if (is.logical(value) && all(is.na(value))) value <- rep(NA_real_,length(value))
      if (!is.numeric(value) || is.complex(value) || !is.null(dim(value)) || any(!is.na(value) & !is.finite(value))) cli::cli_abort("{label} must contain finite numeric values or NA.")
      if (field %in% c('os_status','pfs_status') && any(!is.na(value) & !value %in% c(0,1))) cli::cli_abort("{label} must use 0 (censored) or 1 (event), or NA.")
      if (field %in% c('age','os_months','pfs_months') && any(value<0,na.rm=TRUE)) cli::cli_abort("{label} cannot contain negative values.")
      if (field=='vaf' && any(value<0 | value>1,na.rm=TRUE)) cli::cli_abort("{label} must be between 0 and 1, or NA.")
      x[[field]] <- if (is.integer(template[[field]])) as.integer(value) else as.numeric(value)
    }
  }
  primary <- switch(name,patients='patient_id',samples='sample_id',survival='patient_id',NULL)
  if (!is.null(primary)) {
    ids <- x[[primary]]
    if (anyNA(ids) || any(!nzchar(trimws(ids)))) cli::cli_abort("{name}.{primary} requires nonmissing, nonempty identifiers.")
    if (anyDuplicated(ids)) cli::cli_abort("{name}.{primary} contains duplicate identifiers; resolve conflicting records before merging.")
  }
  x
}

.mp_metadata <- function(x, legacy=FALSE) {
  if (legacy && tibble::is_tibble(x) && nrow(x)==1L) {
    x <- as.list(x)
    for (field in intersect(c('source_files','parser_versions'),names(x))) {
      if (is.list(x[[field]]) && length(x[[field]])==1L) x[[field]] <- x[[field]][[1L]]
    }
  }
  .mp_named(x,'Metadata')
  required <- c('creation_date','source_files','parser_versions')
  missing <- setdiff(required,names(x))
  if (length(missing)) cli::cli_abort("Metadata is missing required field{?s}: {.field {missing}}.")
  created <- x[['creation_date']]
  if (!inherits(created,'POSIXct') || length(created)!=1L || is.na(created) || !is.finite(as.numeric(created))) cli::cli_abort("Metadata creation_date must be one finite POSIXct timestamp.")
  files <- x[['source_files']]
  if (!is.character(files) || anyNA(files)) cli::cli_abort("Metadata source_files must be a character vector without NA.")
  versions <- x[['parser_versions']]
  if (!(is.character(versions) && !anyNA(versions)) && !(is.list(versions) && all(vapply(versions,function(v)is.character(v)&&length(v)==1L&&!is.na(v),logical(1))))) cli::cli_abort("Metadata parser_versions must contain character version strings.")
  x
}

.mp_normalize_db <- function(x, legacy=FALSE) {
  .mp_named(x,'molpath_db')
  for (name in names(.mp_tables())) {
    if (!name %in% names(x)) cli::cli_abort("Missing required table {.val {name}} in molpath_db.")
    fill <- legacy && tibble::is_tibble(x[[name]]) && nrow(x[[name]])==0L
    x[[name]] <- .mp_table(x[[name]],name,fill=fill)
  }
  if (!'metadata' %in% names(x)) cli::cli_abort("Missing {.val metadata} list in molpath_db.")
  x[['metadata']] <- .mp_metadata(x[['metadata']],legacy=legacy)
  structure(x,class='molpath_db')
}

.mp_link_issues <- function(db) {
  edges <- list(c('samples','patient_id','patients'),c('variants','sample_id','samples'),c('reports','sample_id','samples'),c('clinical','patient_id','patients'),c('survival','patient_id','patients'))
  issues <- character()
  for (edge in edges) {
    ids <- db[[edge[1]]][[edge[2]]]; parent <- db[[edge[3]]][[edge[2]]]
    missing <- is.na(ids) | !nzchar(trimws(ids))
    orphan <- unique(ids[!missing & !ids %in% parent])
    if (any(missing)) issues <- c(issues,paste0(edge[1],': ',sum(missing),' record(s) lack ',edge[2],'; linkage is unknown.'))
    if (length(orphan)) issues <- c(issues,paste0(edge[1],': ',length(orphan),' ',edge[2],' value(s) not found in ',edge[3],': ',paste(utils::head(orphan,5),collapse=', '),'.'))
  }
  issues
}
