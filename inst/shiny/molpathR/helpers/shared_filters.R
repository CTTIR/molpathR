# Shared filter helper functions for the Shiny app
# These are used across multiple modules for consistent filtering

#' Get sample IDs for a given patient
#' @noRd
get_patient_sample_ids <- function(db, patient_id) {
  if (is.null(patient_id) || is.null(db)) return(character())
  db$samples$sample_id[db$samples$patient_id == patient_id]
}
