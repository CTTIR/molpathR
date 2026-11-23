# molpathR 0.2.0

* Prepared the package for a first CRAN submission.
* Examples now run on synthetic files written to the temporary directory
  (`mp_example_files()`) instead of referring to files that were not shipped;
  fast examples are no longer wrapped in `\donttest{}` and the Shiny example
  runs only in interactive sessions.
* The BAM example is skipped unless the optional 'Rsamtools' package is
  installed.
* `DESCRIPTION`: reworded description, added `Language`, removed the unused
  `LazyData` field and updated the maintainer address.
* Citation metadata describe the package version instead of a development
  milestone.

## Changes since 0.1.0


* Database construction, merging and persistence share typed table and value
  contracts. Conflicting primary identities are refused; incomplete links remain
  explicit. Known legacy empty-table and metadata representations are normalized.
* Actual pathology and XML imports retain patient/sample linkage. VCF integration
  uses explicit nonreference genotypes and preserves source fields without
  inventing annotations. Raw FASTQ/BAM data are no longer treated as variant calls.
* Delimited imports use exact field aliases, support semicolon/tab separation,
  reject malformed outcomes and retain unrecognized source columns.
* VCF ID/INFO/FORMAT/sample values are independent of optional typed backends;
  BAM fields, FASTQ first-n selection and quality values are repaired. Malformed
  input and command failures are visible.
* Database writes stage and verify serialization, with recovery on replacement
  failure. Loading rejects corrupt objects. Upload dispatch preserves the
  original filename without retaining a deleted temporary path.
* Plot and app filters select the same observations; stale selections are cleared
  and download formats match their contents. Gene survival groups describe
  recorded variants, without inferring a negative assay from missing records.
* Small synthetic cohorts work with stable types; generators restore caller RNG
  and synthetic file dates have an explicit fixed anchor.
* Development citation metadata no longer advertises the unresolving draft DOI;
  no release or deposit is claimed for this maintenance version.

## Figures

* `mp_plot_survival()` colours groups with the colour-blind-safe Okabe-Ito
  palette instead of 'RColorBrewer' Set1 (red and green), marks censored
  observations with `+`, and places the log-rank label in the lower-left
  corner, where it no longer overlaps the curves. The note on genes without a
  recorded variant is dropped when the plot falls back to one group.
* `mp_plot_timeline()` places each label to the right of its event and moves
  labels that would overlap onto separate lanes; clinical events show their
  value and the date axis shows the year. A patient whose events are all undated now gives an informative
  error instead of an empty panel.
* `mp_plot_vaf_distribution()` bins start at 0, so no bar extends below a VAF
  of 0; several genes are drawn in one panel each instead of overlaid
  translucent histograms that could not be told apart, and the axis states
  that VAF is a proportion.
* `mp_plot_variant_landscape()` patient labels are larger (8 pt for up to 25
  patients); beyond 60 patients, where labels overlap at any usual width, they
  are omitted and the axis title gives the number of patients. The
  "Unclassified" legend key only appears when such records are present.
* `mp_plot_cohort_overview()` gives diagnoses and sex codes outside the
  built-in palette their own colours instead of the grey missing-value fill;
  the age axis states its unit (years).

## Bug fixes

* `mp_search()` refuses an empty or missing `term` with an informative error
  instead of emitting one warning per text column and returning no matches.
* `mp_read_auto()` recognizes every survival time column alias that
  `mp_read_survival()` accepts (for example `pfs.months`), so such tables are
  no longer refused as unrecognized; its error message lists all supported
  extensions.

## Documentation

* The pkgdown site inherits the navigation bar of the shared themakR template,
  which restores the changelog link and the light/dark switch.

# molpathR 0.1.0

* Standardize the named v5 package logo across README, documentation pages
  and available application headers, with matching light and dark artwork.


## Bug fixes

* `mp_query_variants()` now correctly filters by `classification` and
  `variant_type`. Previously these arguments were shadowed by the columns of
  the same name during tidy evaluation, so the filters silently returned every
  variant.
* `mp_read_vcf()` now returns an empty result for a header-only VCF instead of
  a row of `NA` values, fixing a reversed index range in the text parser.

## Features

* Initial release.
* Parsers for VCF, FASTQ, BAM, XML reports, PDF reports, Nexus pathology/clinical exports, and survival data.
* In-memory relational database (`molpath_db`) with build, merge, validate, save/load operations.
* Query engine with tidy evaluation, variant filtering, free-text search.
* Six visualization functions: variant landscape, mutation spectrum, survival curves, cohort overview, VAF distribution, patient timeline.
* Interactive Shiny application with 6 tabs and cross-tab interactivity.
* Synthetic data generator (`mp_example_db()`) for demonstration and testing.
