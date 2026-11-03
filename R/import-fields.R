# Text/worksheet imports share exact field matching and conversion rules.
.mp_read_tabular <- function(path,n_max=Inf) {
  ext <- if (is.character(path)) tolower(tools::file_ext(path)) else ''
  if (ext %in% c('xlsx','xls')) {
    out <- readxl::read_excel(path,col_types='text',n_max=n_max,.name_repair='minimal')
  } else {
    out <- readr::read_delim(path,delim=NULL,col_types=readr::cols(.default='c'),n_max=n_max,name_repair='minimal',show_col_types=FALSE,progress=FALSE)
    if (nrow(readr::problems(out))) cli::cli_abort('Tabular input contains inconsistent fields; correct the reported source rows before import.')
  }
  if (anyNA(names(out)) || any(!nzchar(trimws(names(out)))) || anyDuplicated(tolower(trimws(names(out))))) cli::cli_abort('Input column names must be nonempty and unique, ignoring case.')
  out
}

.mp_map_fields <- function(raw,mapping,required=character()) {
  nms <- tolower(trimws(names(raw)))
  if (anyDuplicated(nms)) cli::cli_abort('Input contains duplicate column names.')
  out <- tibble::tibble(.rows=nrow(raw)); used <- integer()
  for (field in names(mapping)) {
    aliases <- strsplit(mapping[[field]],'|',fixed=TRUE)[[1L]]
    matched <- which(nms %in% aliases)
    if (length(matched)>1L) cli::cli_abort('Multiple input columns map to {.val {field}}; select one unambiguous field before import.')
    if (length(matched)) {
      out[[field]] <- raw[[matched]]; used <- c(used,matched)
    } else {
      if (field %in% required) cli::cli_abort('Input is missing a recognized {.val {field}} column.')
      out[[field]] <- rep(NA_character_,nrow(raw))
    }
  }
  for (j in setdiff(seq_along(raw),used)) out[[names(raw)[j]]] <- raw[[j]]
  out
}

.mp_number <- function(x,label,event=FALSE) {
  if (is.character(x)) x[!is.na(x) & !nzchar(trimws(x))] <- NA_character_
  out <- suppressWarnings(as.numeric(x))
  if (any(!is.na(x) & (is.na(out) | !is.finite(out)))) cli::cli_abort('{label} contains an invalid numeric value.')
  if (event && any(!is.na(out) & !out %in% c(0,1))) cli::cli_abort('{label} must use exactly 0 (censored) or 1 (event), or NA.')
  if (!event && any(out<0,na.rm=TRUE)) cli::cli_abort('{label} cannot contain negative values.')
  if (event) as.integer(out) else out
}
