test_that("small synthetic cohorts retain typed variant columns", {
  for (seed in c(1L,4L)) {
    x <- mp_example_db(n_patients=2,seed=seed)
    expect_equal(nrow(x$patients),2)
    expect_type(x$variants$chromosome,"character")
    expect_true(all(x$variants$sample_id %in% x$samples$sample_id))
  }
  for (n in list(0,-1,1.5,Inf,NA_real_,c(1,2))) expect_error(mp_example_db(n),"n_patients")
})

test_that("example generation preserves caller RNG state and reproducible tables", {
  withr::local_seed(928)
  before <- .Random.seed
  x <- mp_example_db(10,42)
  expect_identical(.Random.seed,before)
  y <- mp_example_db(10,42)
  expect_identical(x[setdiff(names(x),"metadata")],y[setdiff(names(y),"metadata")])
  expect_identical(.Random.seed,before)
  root <- withr::local_tempdir()
  files <- mp_example_files(root,seed=42)
  expect_identical(.Random.seed,before)
  other <- withr::local_tempdir()
  writer <- mp_example_files
  lookup <- new.env(parent=environment(writer))
  lookup$Sys.Date <- function() as.Date("2030-01-01")
  environment(writer) <- lookup
  second <- writer(other,seed=42)
  first_bytes <- lapply(unlist(files),readBin,what="raw",n=1e7)
  second_bytes <- lapply(unlist(second),readBin,what="raw",n=1e7)
  expect_identical(unname(first_bytes),unname(second_bytes))
  expect_error(mp_example_files(root,reference_date=NA),"reference_date")
  expect_identical(.Random.seed,before)
})


test_that("example failures restore the RNG and generators do not create caller state", {
  previous <- if (exists(".Random.seed", envir=.GlobalEnv, inherits=FALSE)) get(".Random.seed",.GlobalEnv) else NULL
  withr::defer(if (is.null(previous)) {
    if (exists(".Random.seed",envir=.GlobalEnv,inherits=FALSE)) rm(".Random.seed",envir=.GlobalEnv)
  } else assign(".Random.seed",previous,envir=.GlobalEnv))
  if (exists(".Random.seed",envir=.GlobalEnv,inherits=FALSE)) rm(".Random.seed",envir=.GlobalEnv)
  invisible(mp_example_db(10,42))
  expect_false(exists(".Random.seed",envir=.GlobalEnv,inherits=FALSE))
  set.seed(123); before <- .Random.seed
  local_mocked_bindings(new_molpath_db=function(...) cli::cli_abort("construction interrupted"),
                        .package="molpathR")
  expect_error(mp_example_db(10,42),"construction interrupted")
  expect_identical(.Random.seed,before)
})
