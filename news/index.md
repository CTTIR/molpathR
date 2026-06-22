# Changelog

## molpathR 0.1.0

### Bug fixes

- [`mp_query_variants()`](https://cttir.github.io/molpathR/reference/mp_query_variants.md)
  now correctly filters by `classification` and `variant_type`.
  Previously these arguments were shadowed by the columns of the same
  name during tidy evaluation, so the filters silently returned every
  variant.
- [`mp_read_vcf()`](https://cttir.github.io/molpathR/reference/mp_read_vcf.md)
  now returns an empty result for a header-only VCF instead of a row of
  `NA` values, fixing a reversed index range in the text parser.

### Features

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
