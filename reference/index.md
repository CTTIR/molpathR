# Package index

## Parsers

Functions for reading molecular pathology data files

- [`mp_read_vcf()`](https://cttir.github.io/molpathR/reference/mp_read_vcf.md)
  : Read a VCF file
- [`mp_read_fastq()`](https://cttir.github.io/molpathR/reference/mp_read_fastq.md)
  : Read a FASTQ file
- [`mp_read_bam()`](https://cttir.github.io/molpathR/reference/mp_read_bam.md)
  : Read a BAM file
- [`mp_read_xml_report()`](https://cttir.github.io/molpathR/reference/mp_read_xml_report.md)
  : Read an XML variant report
- [`mp_read_pdf_report()`](https://cttir.github.io/molpathR/reference/mp_read_pdf_report.md)
  : Read a PDF pathology report
- [`mp_read_nexus_pathology()`](https://cttir.github.io/molpathR/reference/mp_read_nexus_pathology.md)
  : Read Nexus pathology data
- [`mp_read_nexus_clinical()`](https://cttir.github.io/molpathR/reference/mp_read_nexus_clinical.md)
  : Read Nexus clinical data
- [`mp_read_survival()`](https://cttir.github.io/molpathR/reference/mp_read_survival.md)
  : Read survival / outcome data
- [`mp_read_auto()`](https://cttir.github.io/molpathR/reference/mp_read_auto.md)
  : Automatically read a molecular pathology file

## Database

Build and manage the in-memory database

- [`mp_build_db()`](https://cttir.github.io/molpathR/reference/mp_build_db.md)
  : Build a molpath_db from parsed data objects
- [`mp_add_data()`](https://cttir.github.io/molpathR/reference/mp_add_data.md)
  : Add parsed data to an existing molpath_db
- [`mp_merge_db()`](https://cttir.github.io/molpathR/reference/mp_merge_db.md)
  : Merge two molpath_db objects
- [`mp_validate_db()`](https://cttir.github.io/molpathR/reference/mp_validate_db.md)
  : Validate a molpath_db for referential integrity and completeness
- [`mp_save_db()`](https://cttir.github.io/molpathR/reference/mp_save_db.md)
  : Save a molpath_db to disk
- [`mp_load_db()`](https://cttir.github.io/molpathR/reference/mp_load_db.md)
  : Load a molpath_db from disk

## Queries

Filter and search the database

- [`mp_query_patients()`](https://cttir.github.io/molpathR/reference/mp_query_patients.md)
  : Filter patients in a molpath_db
- [`mp_query_variants()`](https://cttir.github.io/molpathR/reference/mp_query_variants.md)
  : Filter variants in a molpath_db
- [`mp_query_samples()`](https://cttir.github.io/molpathR/reference/mp_query_samples.md)
  : Filter samples in a molpath_db
- [`mp_get_patient()`](https://cttir.github.io/molpathR/reference/mp_get_patient.md)
  : Get all data for a single patient
- [`mp_summary()`](https://cttir.github.io/molpathR/reference/mp_summary.md)
  : Cohort-level summary of a molpath_db
- [`mp_search()`](https://cttir.github.io/molpathR/reference/mp_search.md)
  : Free-text search across a molpath_db

## Visualization

Publication-ready plots

- [`mp_plot_variant_landscape()`](https://cttir.github.io/molpathR/reference/mp_plot_variant_landscape.md)
  : Plot variant landscape (oncoplot)
- [`mp_plot_mutation_spectrum()`](https://cttir.github.io/molpathR/reference/mp_plot_mutation_spectrum.md)
  : Plot mutation spectrum
- [`mp_plot_survival()`](https://cttir.github.io/molpathR/reference/mp_plot_survival.md)
  : Plot Kaplan-Meier survival curves
- [`mp_plot_cohort_overview()`](https://cttir.github.io/molpathR/reference/mp_plot_cohort_overview.md)
  : Plot cohort overview
- [`mp_plot_vaf_distribution()`](https://cttir.github.io/molpathR/reference/mp_plot_vaf_distribution.md)
  : Plot variant allele frequency distribution
- [`mp_plot_timeline()`](https://cttir.github.io/molpathR/reference/mp_plot_timeline.md)
  : Plot patient timeline

## Shiny

Interactive application

- [`mp_run_app()`](https://cttir.github.io/molpathR/reference/mp_run_app.md)
  : Launch the molpathR Shiny application

## Data

Example data generation

- [`mp_example_db()`](https://cttir.github.io/molpathR/reference/mp_example_db.md)
  : Create a synthetic molecular pathology database
- [`mp_example_files()`](https://cttir.github.io/molpathR/reference/mp_example_files.md)
  : Write synthetic example files to a directory

## Classes

S3 class constructors

- [`new_molpath_db()`](https://cttir.github.io/molpathR/reference/new_molpath_db.md)
  : Create a new molpath_db object
- [`new_molpath_parsed()`](https://cttir.github.io/molpathR/reference/new_molpath_parsed.md)
  : Create a new molpath_parsed object
- [`validate_molpath_db()`](https://cttir.github.io/molpathR/reference/validate_molpath_db.md)
  : Validate a molpath_db object
- [`print(`*`<molpath_db>`*`)`](https://cttir.github.io/molpathR/reference/print.molpath_db.md)
  : Print a molpath_db object
- [`print(`*`<molpath_parsed>`*`)`](https://cttir.github.io/molpathR/reference/print.molpath_parsed.md)
  : Print a molpath_parsed object
- [`summary(`*`<molpath_db>`*`)`](https://cttir.github.io/molpathR/reference/summary.molpath_db.md)
  : Summarise a molpath_db object
- [`summary(`*`<molpath_parsed>`*`)`](https://cttir.github.io/molpathR/reference/summary.molpath_parsed.md)
  : Summarise a molpath_parsed object
