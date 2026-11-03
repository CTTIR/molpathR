# Stage serialization before touching the previous destination.
.mp_rename <- function(from,to) file.rename(from,to)

.mp_write_rds <- function(db,path) {
  directory <- dirname(path)
  if (!dir.exists(directory) && !dir.create(directory,recursive=TRUE)) cli::cli_abort('Cannot create database directory {.file {directory}}.')
  if (dir.exists(path)) cli::cli_abort('Database destination {.file {path}} is a directory.')
  stage <- tempfile('.molpath-stage-',tmpdir=directory)
  backup <- tempfile('.molpath-backup-',tmpdir=directory)
  on.exit(unlink(stage),add=TRUE)
  saveRDS(db,file=stage,compress='gzip')
  restored <- readRDS(stage)
  .mp_normalize_db(restored)
  if (!identical(restored,db)) cli::cli_abort('Staged database verification failed; the previous destination was not changed.')
  existed <- file.exists(path)
  if (existed && !.mp_rename(path,backup)) cli::cli_abort('Cannot preserve the existing database at {.file {path}}; it was not replaced.')
  if (!.mp_rename(stage,path)) {
    if (existed && !.mp_rename(backup,path)) cli::cli_abort('Database replacement and recovery failed. The previous database remains at {.file {backup}}; preserve this file for recovery.')
    cli::cli_abort('Database replacement failed; the previous destination was restored.')
  }
  if (existed && file.exists(backup)) unlink(backup)
  invisible(path)
}
