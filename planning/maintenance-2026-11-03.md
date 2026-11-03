# Maintenance plan and evidence — 3 November 2026

Base: `a3c2f7afde825b79f453e693538dc0b20b478598` (public CTTIR/molpathR).
The clean original checkout and its 316 tracked files are preserved. Work is
isolated on `maintenance/public-readiness-20261103`. No patient records or
private research data are used; all new fixtures are synthetic.

## Purpose, baseline and acceptance

The useful current release is a dependable local exploratory workflow: inspect
supported source files, construct explicitly linked patient/sample/variant/report
records, query the same cohort shown in plots, and save/reload it without loss.
Sequence reads and alignments are not interpreted variant calls. Missing
assay/annotation/linkage evidence must remain unknown rather than be invented.
This maintenance milestone does not establish clinical diagnostic qualification,
a hosted multi-user deployment, or vendor-specific production interoperability.

The unchanged source suite passed 252 assertions, with zero failures, errors,
warnings or skips. VariantAnnotation was initially absent; the other declared
imports/suggests were available. Its real backend qualification is a separate
step. Independent realistic probes exposed failures not covered by that suite.
External evidence is retained under the audit workspace's `evidence/molpathR/`.

## Confirmed findings

| Priority | Evidence and impact | Required repair |
|---|---|---|
| Essential | Builder returns zero-column empty tables that fail its own class validator; actual pathology input makes repeated patient rows and no samples | One canonical typed schema; normalize actual source outputs and preserve source identities |
| Essential | Empty parent tables bypass orphan checks; duplicate IDs, impossible measures and corrupt saved objects are accepted | Shared structural/value checks, explicit linkage issues, validated persistence |
| Essential | Semicolon rows silently populate every field with an entire line; partial header matching chooses `patient_id_backup`; event 0.9 becomes 0 | Delimiter-aware input, exact aliases, ambiguity checks and strict numeric/event conversion |
| Essential | VCF FORMAT is dropped; raw VCF cannot satisfy interpreted variant schema; FASTQ/BAM are put into variants | Preserve genotype/FORMAT/metadata; explicit normalization and refuse unsupported raw calling |
| Essential | Real two-read BAM is returned as zero records because no fields are selected; ShortRead quality conversion fails and its sampler contradicts first-n semantics | Explicit BAM fields, validated region/failure handling, deterministic first-n streaming and exact quality values |
| Essential | Malformed/truncated FASTQ silently succeeds | Validate records and fail with source position; no backend fallback that conceals invalid input |
| Essential | An injected encoder failure destroys an existing RDS; a class-labelled corrupt RDS loads successfully | Stage, validate and replace safely; retain previous bytes on failure; validate loaded objects |
| Essential | Plot gene/sample filters are ignored by data-mask collisions; app figures ignore table filters | Shared filtered data and exact argument binding with independent coordinate/count checks |
| Essential | App retains old patient after deselection/reload; extensionless upload fails; CSV ZIP is named XLSX | Clear stale selections, preserve upload name/type safely, truthful export format |
| Scientific | No variant record is labelled wild-type without assay coverage evidence | Use recorded/no-recorded-variant categories and explain missing evidence |
| Everyday use | Small synthetic cohorts fail on logical/character chromosome types; example generation changes caller RNG | Stable typed generation, input checks and preserved caller RNG |

Core probes: `core-probes/baseline-independent.R/.json/.log`. The initial probe
also exposed the small-cohort generator defect; later core probes use independent
fixtures. The save failure is injected at the real writer boundary, not an
observed disk-full event. Backend evidence: `runtime-review/probe-backends.*`.
App/filter evidence: `app/baseline-probes.*`.

## Milestones and tradeoffs

1. **Stored-model integrity.** Retain the six public table names and supported
   extra columns. Supply typed empty tables, enforce unambiguous identifiers,
   scalar metadata and finite/range-valid observed values. Distinguish structural
   invalidity from incomplete cross-table linkage; report all orphan links even
   when parents are empty. Reject conflicting primary-key rows on merge rather
   than silently choose a patient. Normalize the known legacy metadata/empty-table
   representations explicitly; do not silently reinterpret malformed saved data.
   Acceptance: valid construction/build/add/merge share one schema; mismatched
   identities and corrupt inputs fail before mutation; inputs remain unchanged.
2. **Real import journeys.** Split pathology rows into patients and samples;
   carry explicit XML patient/sample links, report text and source provenance.
   Normalize supported VCF calls using actual sample/genotype evidence, keeping
   raw genomic fields, FORMAT and supplied metadata. Do not infer gene effects,
   pathogenicity, negative assay coverage or patient identity from filenames.
   FASTQ/BAM remain useful raw readers; database integration of raw sequences
   must refuse with an actionable explanation until a separate called/annotated
   table is supplied. Preserve current public reader results and supported extra
   fields; document any additive mapping arguments and legacy migration.
   Acceptance: tiny asymmetric multi-source fixtures survive query/save/load;
   two samples remain distinct and absent evidence stays missing.
3. **Parser fidelity and persistence.** Repair exact header aliases, actual
   delimiters, strict event/time conversion, namespaced XML and first-n FASTQ/
   complete BAM reads. Exercise both optional backends and fallbacks; no silent
   partial output for malformed records or failed external commands. Stage RDS
   writes beside the target, verify the staged object, then replace with recovery
   on failure. Acceptance: baseline-failing regressions, exact observed values,
   existing-target preservation and no leaked staging artifacts.
4. **Exploration and app consistency.** Apply filters consistently to tables,
   exports and plots; clear stale patient/database selections; handle invalid
   settings visibly. Use explicit recorded-variant survival categories and
   check event/time/count assumptions. Make upload type and download extension
   match actual content. Acceptance: direct plot oracles, module regression
   tests and a disposable browser import/filter/select/export/reload journey.
5. **Distribution and evidence.** Update roxygen/docs/examples together, provide
   a runnable synthetic import path, run full/minimal checks as appropriate,
   meaningful coverage and house/workflow lint, build/read the PDF and pkgdown
   guide, inspect final archive contents and independently review changes.
   Separate local evidence, observed hosted CI and externally unperformed
   vendor/clinical qualification. Normal main publication follows the existing
   authorization; no release, tag or manual deployment is part of this work.

Longer-term: raw sequence storage/variant calling, vendor-certified templates,
assay coverage models, authenticated hosted multi-user access and clinical
validation require distinct designs and real qualification data. They are not
implemented by relabelling imported rows or widening readiness claims.

## Source contracts

- [HTS format specifications](https://samtools.github.io/hts-specs/) define VCF
  FORMAT and per-sample data; FORMAT must remain available to interpret fields.
- [ShortRead manual](https://bioconductor.org/packages/release/bioc/manuals/ShortRead/man/ShortRead.pdf)
  distinguishes random sampling from successive records returned by a streamer.
- [Rsamtools manual](https://bioconductor.org/packages/release/bioc/manuals/Rsamtools/man/Rsamtools.pdf)
  specifies selection through `ScanBamParam(what=..., which=...)`.

## Completion record

The five milestones are complete for the local exploratory scope. The original
checkout remains clean at the base commit; all 316 original tracked files retain
their recorded hashes. No real patient records or excluded repositories were used.

Additional independent review exposed and repaired boundary defects: XML no
longer borrows a generic patient ID as a missing sample ID; generated lowercase
XML identity attributes and explicit VAF are retained; recognized pathology age
is numeric; raw VCF sample names such as `gene` or `sample_id` cannot overwrite
model annotations; complete extracted PDF text survives section parsing,
serialization and export; unknown patient links do not enter a queried cohort;
and list-valued report sections use JSON in rectangular exports. No annotation,
negative assay, sequence calling or clinical interpretation is fabricated.

Persistence verifies the staged RDS before replacement. Encoder and replacement
failure probes preserve existing data; when both replacement and restoration
fail, the preserved backup is named explicitly. This is a one-writer local file
contract, not a multi-process transaction or a simulated disk-full qualification.

### Observed verification

| Gate | Actual result |
|---|---|
| Unchanged baseline | 252 assertions passed; 0 failures, errors, warnings or skips |
| Final installed full suite | 494 assertions passed; 0 failures, errors, warnings or skips |
| Full source-package check | 0 errors, 0 warnings, 1 NOTE: new submission/development version |
| Minimal dependency archive check | 0 errors, 0 warnings, same 1 NOTE; 469 assertions passed, 3 expected optional tests skipped (Rsamtools, ShortRead, writexl) |
| Coverage | 92.9931%; CI floor raised from the rebaseline placeholder 0 to 90 |
| Source/workflow lint | Zero blocking condition findings; 3 retained compatibility-alias vocabulary style findings; actionlint passed |
| Independent core review | All 9 material review findings repaired; 11 checks passed both from source and a fresh isolated archive installation |
| Real reader qualification | Tiny synthetic VCF/gzip, ShortRead first-n/quality, Rsamtools BAM/region and actual samtools fallback passed; parser/example affected suite 150 assertions |
| Shiny browser | 31 actual functional checks; focused app/query/plot suite 152 assertions; final pagination controls at least 4.96:1 measured contrast, active navbar 8.05:1; mobile390px and selection/detail layout checked |
| First use | Executed the import-guide chunks against the fresh installed archive: 2 patients, 2 samples, 1 actual nonreference call, linked validation and identical RDS roundtrip |
| Manual | All 29 pages visually reviewed; final changed pages rechecked; no clipping/overlap; 5,672 words within page bounds; VAF link defect repaired |
| Development site | 50 pages/1,908 local references valid; six browser flows and 100 viewport/theme observations; no local broken assets, page overflow or JS errors |
| Citation metadata | CFF1.2 schema validation passed; coherent development version/author/license, no unavailable DOI advertised |

Exact checked archive: `molpathR_0.1.0.9001.tar.gz`, SHA256
`8a0d25a224fd5cc2569e1af727673784c55467280b26b3a3261457188a85d86a`.
Final stock manual SHA256
`098c8afe3033ceb111d9d4eb404e8df9fefab6c2155585942b6b742624110c4f`.
The archive excludes linked-worktree `.git`, planning/evidence, Rplots and site
artifacts. Independent archive inspection found no symlink/traversal entries;
source inputs match, apart from standard DESCRIPTION build normalization.

Evidence paths relative to `evidence/molpathR/`: `release-check.*`,
`minimal-check/`, `coverage.json`, `source-lineage.json`, `release-artifact.json`,
`first-use-guide.*`, `independent-root/REVIEW.json`,
`independent-root/installed-acceptance.json`, `runtime-review/AUDIT.md`,
`runtime-review/final-integration-review.json`, `app/REPORT.md`,
`app/CLOSEOUT.json`, `manual-review/MANUAL-REVIEW.md`, and `site-review/REPORT.md`.
Original failing probes and the first candidate's documentation warning remain
preserved separately. The final full check ran all examples and rebuilt all
vignettes/manual; no unrun result is counted as verified.

### First use and remaining limits

README supplies R >=4.1, the pdftools platform prerequisites and source install
commands. After installation:

```r
library(molpathR)
db <- mp_example_db(n_patients = 20, seed = 42)
mp_validate_db(db)
mp_run_app(db, host = "127.0.0.1", launch.browser = TRUE)
```

The data-import guide provides a complete synthetic import/save/reload path.
Package installation was exercised in fresh isolated R libraries on this Mac,
not on a fresh OS. The bslib0.5.0 UI was rendered with the installed modern Shiny;
the newly explicit Shiny1.6.0 floor was not independently installed and qualified.
Native hosted OS checks remain separate observed CI evidence after publication.

The old advertised DOI/Zenodo record returned404 and was removed from active
citation/release claims; `.zenodo.json` is an unpublished development draft.
No CRAN submission, Zenodo deposit, release or tag was created. The Dependabot
read returned403 because alerts are disabled, so it is not a zero-vulnerability
result. The external CRAN badge service returned500 during site review. The
local guides and installation path remain usable.

Scientific figure colors are now retained in both site themes by a narrow
pkgdown override. Shared search was verified after the index loaded; instant
first-focus/paste behavior is not claimed. Site/app checks are bounded usability
and contrast evidence, not comprehensive accessibility certification.

Clinical diagnostic validation, real vendor-template interoperability, OCR,
assay coverage/negative calls, variant calling and authenticated hosted service
operation remain outside this release. Normal main publication is authorized;
its commit, remote receipt and actual hosted workflow outcomes are recorded
separately in the external verification record. A future formal release requires
a deliberate version/tag/release and deposit/submission step after any intended
external qualification. None is performed by this maintenance milestone.
