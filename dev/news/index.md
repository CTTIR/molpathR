# Changelog

## molpathR 0.1.0.9001

- Database construction, merging and persistence share typed table and
  value contracts. Conflicting primary identities are refused;
  incomplete links remain explicit. Known legacy empty-table and
  metadata representations are normalized.
- Actual pathology and XML imports retain patient/sample linkage. VCF
  integration uses explicit nonreference genotypes and preserves source
  fields without inventing annotations. Raw FASTQ/BAM data are no longer
  treated as variant calls.
- Delimited imports use exact field aliases, support semicolon/tab
  separation, reject malformed outcomes and retain unrecognized source
  columns.
- VCF ID/INFO/FORMAT/sample values are independent of optional typed
  backends; BAM fields, FASTQ first-n selection and quality values are
  repaired. Malformed input and command failures are visible.
- Database writes stage and verify serialization, with recovery on
  replacement failure. Loading rejects corrupt objects. Upload dispatch
  preserves the original filename without retaining a deleted temporary
  path.
- Plot and app filters select the same observations; stale selections
  are cleared and download formats match their contents. Gene survival
  groups describe recorded variants, without inferring a negative assay
  from missing records.
- Small synthetic cohorts work with stable types; generators restore
  caller RNG and synthetic file dates have an explicit fixed anchor.
- Development citation metadata no longer advertises the unresolving
  draft DOI; no release or deposit is claimed for this maintenance
  version.

## molpathR 0.1.0

- Standardize the named v5 package logo across README, documentation
  pages and available application headers, with matching light and dark
  artwork.

### Bug fixes

- [`mp_query_variants()`](https://cttir.github.io/molpathR/dev/reference/mp_query_variants.md)
  now correctly filters by `classification` and `variant_type`.
  Previously these arguments were shadowed by the columns of the same
  name during tidy evaluation, so the filters silently returned every
  variant.
- [`mp_read_vcf()`](https://cttir.github.io/molpathR/dev/reference/mp_read_vcf.md)
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
  ([`mp_example_db()`](https://cttir.github.io/molpathR/dev/reference/mp_example_db.md))
  for demonstration and testing.
