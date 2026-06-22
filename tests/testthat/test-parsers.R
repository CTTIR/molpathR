# Tests for R/parsers.R
# Cover text-fallback parsers, error/guard branches, switch dispatch,
# standardisation helpers, and auto-detection.

# ---- mp_read_vcf -------------------------------------------------------------

test_that("mp_read_vcf parses sample VCF", {
  vcf_content <- c(
    "##fileformat=VCFv4.2",
    "##source=test",
    "#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO",
    "chr1\t12345\t.\tA\tT\t100\tPASS\tDP=50",
    "chr7\t55249071\t.\tC\tG\t200\tPASS\tDP=80"
  )
  tmp <- withr::local_tempfile(fileext = ".vcf")
  writeLines(vcf_content, tmp)

  result <- mp_read_vcf(tmp)
  expect_s3_class(result, "molpath_parsed")
  expect_equal(result$source_type, "vcf")
  expect_equal(nrow(result$data), 2L)
  expect_true(all(c("chrom", "pos", "ref", "alt", "qual") %in% names(result$data)))
  expect_equal(result$data$chrom, c("chr1", "chr7"))
  expect_equal(result$data$pos, c(12345L, 55249071L))
})

test_that("mp_read_vcf keeps sample genotype columns after FORMAT", {
  vcf_content <- c(
    "##fileformat=VCFv4.2",
    "#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\tSAMPLE1",
    "chr1\t100\t.\tA\tG\t50\tPASS\tDP=30\tGT\t0/1"
  )
  tmp <- withr::local_tempfile(fileext = ".vcf")
  writeLines(vcf_content, tmp)
  result <- mp_read_vcf(tmp)
  expect_true("SAMPLE1" %in% names(result$data))
  expect_equal(result$data$SAMPLE1, "0/1")
})

test_that("mp_read_vcf text parser returns empty tibble for header-only VCF", {
  testthat::local_mocked_bindings(
    requireNamespace = function(package, ...) FALSE,
    .package = "base"
  )
  vcf_content <- c(
    "##fileformat=VCFv4.2",
    "#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO"
  )
  tmp <- withr::local_tempfile(fileext = ".vcf")
  writeLines(vcf_content, tmp)
  result <- mp_read_vcf(tmp)
  expect_equal(nrow(result$data), 0L)
  expect_true(all(c("chrom", "pos", "info") %in% names(result$data)))
})

test_that("mp_read_vcf aborts on missing file", {
  expect_error(mp_read_vcf(tempfile(fileext = ".vcf")), "not found")
})

test_that("mp_read_vcf aborts when #CHROM header absent", {
  tmp <- withr::local_tempfile(fileext = ".vcf")
  writeLines(c("##fileformat=VCFv4.2", "chr1\t1\t.\tA\tT\t1\tPASS\t."), tmp)
  expect_error(mp_read_vcf(tmp))
})

test_that("mp_read_vcf reads gzipped VCF", {
  vcf_content <- c(
    "##fileformat=VCFv4.2",
    "#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO",
    "chr2\t500\t.\tG\tA\t60\tPASS\tDP=40"
  )
  tmp <- withr::local_tempfile(fileext = ".vcf.gz")
  con <- gzfile(tmp, open = "wt")
  writeLines(vcf_content, con)
  close(con)
  result <- mp_read_vcf(tmp)
  expect_equal(nrow(result$data), 1L)
  expect_equal(result$data$chrom, "chr2")
})

test_that("mp_read_vcf falls back to text parser when VariantAnnotation absent", {
  testthat::local_mocked_bindings(
    requireNamespace = function(package, ...) FALSE,
    .package = "base"
  )
  vcf_content <- c(
    "##fileformat=VCFv4.2",
    "#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO",
    "chr1\t10\t.\tA\tT\t99\tPASS\tDP=10"
  )
  tmp <- withr::local_tempfile(fileext = ".vcf")
  writeLines(vcf_content, tmp)
  result <- mp_read_vcf(tmp)
  expect_s3_class(result, "molpath_parsed")
  expect_equal(nrow(result$data), 1L)
})

test_that("mp_read_vcf text parser output is a stable regression lock", {
  testthat::local_mocked_bindings(
    requireNamespace = function(package, ...) FALSE,
    .package = "base"
  )
  vcf_content <- c(
    "##fileformat=VCFv4.2",
    "#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO",
    "chr1\t12345\trs1\tA\tT\t100\tPASS\tDP=50;AF=0.3",
    "chr3\t999\t.\tGG\tG\t40\tLowQual\tDP=12"
  )
  tmp <- withr::local_tempfile(fileext = ".vcf")
  writeLines(vcf_content, tmp)
  result <- suppressMessages(suppressWarnings(mp_read_vcf(tmp)))
  expect_snapshot_value(as.data.frame(result$data), style = "json2")
})

# ---- mp_read_fastq -----------------------------------------------------------

test_that("mp_read_fastq parses sample FASTQ via text fallback", {
  testthat::local_mocked_bindings(
    requireNamespace = function(package, ...) FALSE,
    .package = "base"
  )
  fq_content <- c(
    "@read1", "ACGTACGTACGT", "+", "IIIIIIIIIIII",
    "@read2", "TGCATGCATGCA", "+", "IIIIIIIIIIII"
  )
  tmp <- withr::local_tempfile(fileext = ".fastq")
  writeLines(fq_content, tmp)
  result <- mp_read_fastq(tmp)
  expect_s3_class(result, "molpath_parsed")
  expect_equal(nrow(result$data), 2L)
  expect_equal(result$data$read_id, c("read1", "read2"))
  expect_equal(result$data$seq_length, c(12L, 12L))
})

test_that("mp_read_fastq honours n argument (text fallback)", {
  testthat::local_mocked_bindings(
    requireNamespace = function(package, ...) FALSE,
    .package = "base"
  )
  fq_content <- c(
    "@r1", "AAAA", "+", "IIII",
    "@r2", "CCCC", "+", "IIII",
    "@r3", "GGGG", "+", "IIII"
  )
  tmp <- withr::local_tempfile(fileext = ".fastq")
  writeLines(fq_content, tmp)
  result <- mp_read_fastq(tmp, n = 2)
  expect_equal(nrow(result$data), 2L)
})

test_that("mp_read_fastq reads gzipped fastq (text fallback)", {
  testthat::local_mocked_bindings(
    requireNamespace = function(package, ...) FALSE,
    .package = "base"
  )
  tmp <- withr::local_tempfile(fileext = ".fastq.gz")
  con <- gzfile(tmp, open = "wt")
  writeLines(c("@a", "ACGT", "+", "IIII"), con)
  close(con)
  result <- mp_read_fastq(tmp)
  expect_equal(nrow(result$data), 1L)
})

test_that("mp_read_fastq aborts on missing file", {
  expect_error(mp_read_fastq(tempfile(fileext = ".fastq")), "not found")
})

# ---- mp_read_bam -------------------------------------------------------------

test_that("mp_read_bam aborts when no backend available", {
  testthat::local_mocked_bindings(
    requireNamespace = function(package, ...) FALSE,
    .package = "base"
  )
  testthat::local_mocked_bindings(
    Sys.which = function(...) "",
    .package = "base"
  )
  tmp <- withr::local_tempfile(fileext = ".bam")
  writeLines("not really a bam", tmp)
  expect_error(mp_read_bam(tmp), "Cannot read BAM")
})

test_that("mp_read_bam aborts on missing file", {
  expect_error(mp_read_bam(tempfile(fileext = ".bam")), "not found")
})

# ---- mp_read_xml_report ------------------------------------------------------

test_that("mp_read_xml_report parses structured XML", {
  xml_content <- '<?xml version="1.0" encoding="UTF-8"?>
<VariantReport>
  <Patient><PatientID>PAT-001</PatientID>
    <Sample><SampleID>SAM-001</SampleID>
      <Variant><Gene>BRAF</Gene><HGVSp>p.V600E</HGVSp>
        <Classification>Pathogenic</Classification></Variant>
    </Sample>
  </Patient>
</VariantReport>'
  tmp <- withr::local_tempfile(fileext = ".xml")
  writeLines(xml_content, tmp)
  result <- mp_read_xml_report(tmp)
  expect_s3_class(result, "molpath_parsed")
  expect_equal(result$source_type, "xml_report")
  expect_equal(nrow(result$data), 1L)
  expect_equal(result$data$gene, "BRAF")
  expect_equal(result$data$variant, "p.V600E")
  expect_equal(result$data$classification, "Pathogenic")
})

test_that("mp_read_xml_report extracts attribute values", {
  xml_content <- '<?xml version="1.0"?>
<VariantReport><Patient Id="PAT-9">
  <Sample Id="SAM-9"><Variant Gene="TP53" Variant="p.R175H"/></Sample>
</Patient></VariantReport>'
  tmp <- withr::local_tempfile(fileext = ".xml")
  writeLines(xml_content, tmp)
  result <- mp_read_xml_report(tmp)
  expect_equal(result$data$gene, "TP53")
})

test_that("mp_read_xml_report warns and returns empty for no variants", {
  xml_content <- '<?xml version="1.0"?><Root><Nothing/></Root>'
  tmp <- withr::local_tempfile(fileext = ".xml")
  writeLines(xml_content, tmp)
  expect_warning(result <- mp_read_xml_report(tmp), "No Variant")
  expect_equal(nrow(result$data), 0L)
})

test_that("mp_read_xml_report warns on unknown provider then parses generically", {
  xml_content <- '<?xml version="1.0"?>
<R><Variant><Gene>KRAS</Gene></Variant></R>'
  tmp <- withr::local_tempfile(fileext = ".xml")
  writeLines(xml_content, tmp)
  expect_warning(result <- mp_read_xml_report(tmp, provider = "weird"),
                 "Unknown provider")
  expect_equal(result$data$gene, "KRAS")
})

test_that("mp_read_xml_report aborts on missing and malformed file", {
  expect_error(mp_read_xml_report(tempfile(fileext = ".xml")), "not found")
  tmp <- withr::local_tempfile(fileext = ".xml")
  writeLines("<unclosed>", tmp)
  expect_error(mp_read_xml_report(tmp))
})

# ---- mp_read_pdf_report ------------------------------------------------------

test_that("mp_read_pdf_report aborts on missing file", {
  expect_error(mp_read_pdf_report(tempfile(fileext = ".pdf")), "not found")
})

# ---- mp_read_nexus_pathology -------------------------------------------------

test_that("mp_read_nexus_pathology parses CSV and standardises columns", {
  csv <- c("PatientID,Name,Sex,SampleID,SampleType,Diagnosis,ReportDate",
           "P1,Doe,M,S1,FFPE,Melanoma,2024-01-01")
  tmp <- withr::local_tempfile(fileext = ".csv")
  writeLines(csv, tmp)
  result <- mp_read_nexus_pathology(tmp)
  expect_s3_class(result, "molpath_parsed")
  expect_equal(result$source_type, "nexus_pathology")
  expect_equal(result$data$patient_id, "P1")
  expect_equal(result$data$sample_type, "FFPE")
  expect_true("dob" %in% names(result$data))
})

test_that("mp_read_nexus_pathology parses XML by extension", {
  xml <- '<?xml version="1.0"?><Export>
    <Record><PatientID>P2</PatientID><Sex>F</Sex>
      <SampleID>S2</SampleID><Diagnosis>Lung</Diagnosis></Record>
  </Export>'
  tmp <- withr::local_tempfile(fileext = ".xml")
  writeLines(xml, tmp)
  result <- mp_read_nexus_pathology(tmp)
  expect_equal(result$data$patient_id, "P2")
  expect_equal(result$data$diagnosis, "Lung")
})

test_that("mp_read_nexus_pathology sniffs XML from ambiguous extension", {
  tmp <- withr::local_tempfile(fileext = ".dat")
  writeLines('<Export><Record><PatientID>P3</PatientID></Record></Export>', tmp)
  result <- mp_read_nexus_pathology(tmp)
  expect_equal(result$data$patient_id, "P3")
})

test_that("mp_read_nexus_pathology accepts a connection", {
  csv <- c("PatientID,SampleID,Diagnosis", "P5,S5,CRC")
  tmp <- withr::local_tempfile(fileext = ".csv")
  writeLines(csv, tmp)
  con <- file(tmp, open = "rt")
  on.exit(close(con), add = TRUE)
  result <- mp_read_nexus_pathology(con)
  expect_equal(result$data$patient_id, "P5")
  expect_equal(result$source_file, "<connection>")
})

test_that("mp_read_nexus_pathology aborts on missing file", {
  expect_error(mp_read_nexus_pathology(tempfile(fileext = ".csv")), "not found")
})

# ---- mp_read_nexus_clinical --------------------------------------------------

test_that("mp_read_nexus_clinical standardises columns", {
  csv <- c("patient_id,test_name,result,unit,date,lab",
           "P1,Ki-67,20,%,2024-01-01,LIMS")
  tmp <- withr::local_tempfile(fileext = ".csv")
  writeLines(csv, tmp)
  result <- mp_read_nexus_clinical(tmp)
  expect_equal(result$source_type, "nexus_clinical")
  expect_equal(result$data$parameter, "Ki-67")
  expect_equal(result$data$value, "20")
  expect_equal(result$data$source, "LIMS")
})

test_that("mp_read_nexus_clinical fills missing columns with NA", {
  csv <- c("patient_id,parameter,value", "P1,PD-L1,50")
  tmp <- withr::local_tempfile(fileext = ".csv")
  writeLines(csv, tmp)
  result <- mp_read_nexus_clinical(tmp)
  expect_true(all(is.na(result$data$unit)))
  expect_true(all(is.na(result$data$date)))
})

test_that("mp_read_nexus_clinical aborts on missing file", {
  expect_error(mp_read_nexus_clinical(tempfile(fileext = ".csv")), "not found")
})

# ---- mp_read_survival --------------------------------------------------------

test_that("mp_read_survival parses CSV with numeric coercion", {
  surv_data <- data.frame(
    patient_id = c("P1", "P2", "P3"),
    os_months = c(12, 24, 36),
    os_status = c(1, 0, 1),
    pfs_months = c(6, 18, 12),
    pfs_status = c(1, 0, 1)
  )
  tmp <- withr::local_tempfile(fileext = ".csv")
  utils::write.csv(surv_data, tmp, row.names = FALSE)
  result <- mp_read_survival(tmp)
  expect_equal(nrow(result$data), 3L)
  expect_type(result$data$os_months, "double")
  expect_type(result$data$os_status, "integer")
  expect_equal(result$data$os_months, c(12, 24, 36))
})

test_that("mp_read_survival fills missing columns with typed NA", {
  csv <- c("patient_id,os_months", "P1,12")
  tmp <- withr::local_tempfile(fileext = ".csv")
  writeLines(csv, tmp)
  result <- mp_read_survival(tmp)
  expect_true(is.na(result$data$pfs_months))
  expect_type(result$data$pfs_status, "integer")
})

test_that("mp_read_survival reads tsv extension", {
  tmp <- withr::local_tempfile(fileext = ".tsv")
  writeLines(c("patient_id\tos_months\tos_status", "P1\t10\t1"), tmp)
  result <- mp_read_survival(tmp)
  expect_equal(result$data$patient_id, "P1")
  expect_equal(result$data$os_months, 10)
})

test_that("mp_read_survival aborts on missing file", {
  expect_error(mp_read_survival(tempfile(fileext = ".csv")), "not found")
})

# ---- mp_read_auto ------------------------------------------------------------

test_that("mp_read_auto detects VCF", {
  vcf_content <- c(
    "##fileformat=VCFv4.2",
    "#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO",
    "chr1\t100\t.\tA\tG\t50\tPASS\tDP=30"
  )
  tmp <- withr::local_tempfile(fileext = ".vcf")
  writeLines(vcf_content, tmp)
  result <- mp_read_auto(tmp)
  expect_equal(result$source_type, "vcf")
})

test_that("mp_read_auto detects xml report", {
  xml <- '<?xml version="1.0"?><R><Variant><Gene>EGFR</Gene></Variant></R>'
  tmp <- withr::local_tempfile(fileext = ".xml")
  writeLines(xml, tmp)
  result <- mp_read_auto(tmp)
  expect_equal(result$source_type, "xml_report")
})

test_that("mp_read_auto routes survival-like csv to survival reader", {
  csv <- c("patient_id,os_months,os_status,pfs_months,pfs_status",
           "P1,12,1,6,1")
  tmp <- withr::local_tempfile(fileext = ".csv")
  writeLines(csv, tmp)
  result <- mp_read_auto(tmp)
  expect_equal(result$source_type, "survival")
})

test_that("mp_read_auto routes clinical-like csv to clinical reader", {
  csv <- c("patient_id,parameter,value,unit", "P1,Ki-67,20,%")
  tmp <- withr::local_tempfile(fileext = ".csv")
  writeLines(csv, tmp)
  result <- mp_read_auto(tmp)
  expect_equal(result$source_type, "nexus_clinical")
})

test_that("mp_read_auto defaults ambiguous tabular to survival reader", {
  csv <- c("patient_id,foo,bar", "P1,1,2")
  tmp <- withr::local_tempfile(fileext = ".csv")
  writeLines(csv, tmp)
  result <- mp_read_auto(tmp)
  expect_equal(result$source_type, "survival")
})

test_that("mp_read_auto aborts on unknown extension", {
  tmp <- withr::local_tempfile(fileext = ".dat")
  writeLines("x", tmp)
  expect_error(mp_read_auto(tmp), "auto-detect")
})

test_that("mp_read_auto aborts on missing file", {
  expect_error(mp_read_auto(tempfile(fileext = ".vcf")), "not found")
})
