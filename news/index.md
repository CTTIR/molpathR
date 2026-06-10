# Changelog

## molpathR 0.1.0

- Initial release.
- Parsers for VCF, FASTQ, BAM, XML reports, PDF reports, Nexus
  pathology/clinical exports, and survival data.
- In-memory relational database (`molpath_db`) with build, merge,
  validate, save/load operations.
- Query engine with tidy evaluation, variant filtering, free-text
  search.
- Six visualization functions: variant landscape, mutation spectrum,
  survival curves, cohort overview, VAF distribution, patient timeline.
- Interactive Shiny application with 6 tabs and cross-tab interactivity.
- Synthetic data generator
  ([`mp_example_db()`](https://cttir.github.io/molpathR/reference/mp_example_db.md))
  for demonstration and testing.
