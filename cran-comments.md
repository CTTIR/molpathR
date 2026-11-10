## Submission

This is a new submission of `molpathR` (version 0.2.0).

## Test environments

* local macOS (aarch64), R 4.6.1:
  `R CMD check --as-cran --no-manual` (LaTeX is not installed locally, so
  the PDF manual was not built here)
* GitHub Actions (r-lib/actions v2, `--as-cran`):
  macos-latest (release), windows-latest (release),
  ubuntu-latest (devel, release, oldrel-1)

## R CMD check results

0 errors | 0 warnings | 1 note

* checking CRAN incoming feasibility ... NOTE
  New submission

## Notes for CRAN

* Packages in Suggests from Bioconductor ('Rsamtools', 'ShortRead',
  'Biostrings', 'GenomicRanges', 'IRanges', 'VariantAnnotation',
  'SummarizedExperiment', 'BiocGenerics') are optional. They are only used
  after `requireNamespace()` checks; examples and tests that need them are
  skipped when they are not installed, and the package passes
  `R CMD check` without them.
* All example data are synthetic and generated at run time
  (`mp_example_db()`, `mp_example_files()`); no patient data are included.
  Example files are written to `tempdir()` only.
* README.md and the vignettes carry CRAN badges linking to
  <https://CRAN.R-project.org/package=molpathR>, which returns 404 until
  the package has been accepted; all other URLs resolve.
