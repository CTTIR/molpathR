test_that("mp_read_vcf parses sample VCF", {
  # Create a minimal VCF file
  vcf_content <- c(
    "##fileformat=VCFv4.2",
    "##source=test",
    "#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO",
    "chr1\t12345\t.\tA\tT\t100\tPASS\tDP=50",
    "chr7\t55249071\t.\tC\tG\t200\tPASS\tDP=80"
  )
  tmp <- tempfile(fileext = ".vcf")
  on.exit(unlink(tmp), add = TRUE)
  writeLines(vcf_content, tmp)

  result <- mp_read_vcf(tmp)
  expect_s3_class(result, "molpath_parsed")
  expect_true(nrow(result$data) >= 2L)
  expect_true("chrom" %in% names(result$data) || "CHROM" %in% names(result$data) ||
              "#CHROM" %in% names(result$data))
})

test_that("mp_read_fastq parses sample FASTQ", {
  fq_content <- c(
    "@read1",
    "ACGTACGTACGT",
    "+",
    "IIIIIIIIIIII",
    "@read2",
    "TGCATGCATGCA",
    "+",
    "IIIIIIIIIIII"
  )
  tmp <- tempfile(fileext = ".fastq")
  on.exit(unlink(tmp), add = TRUE)
  writeLines(fq_content, tmp)

  result <- mp_read_fastq(tmp)
  expect_s3_class(result, "molpath_parsed")
  expect_true(nrow(result$data) >= 2L)
})

test_that("mp_read_survival parses CSV", {
  surv_data <- data.frame(
    patient_id = c("P1", "P2", "P3"),
    os_months = c(12, 24, 36),
    os_status = c(1, 0, 1),
    pfs_months = c(6, 18, 12),
    pfs_status = c(1, 0, 1)
  )
  tmp <- tempfile(fileext = ".csv")
  on.exit(unlink(tmp), add = TRUE)
  utils::write.csv(surv_data, tmp, row.names = FALSE)

  result <- mp_read_survival(tmp)
  expect_s3_class(result, "molpath_parsed")
  expect_equal(nrow(result$data), 3L)
  expect_true("patient_id" %in% names(result$data))
})

test_that("mp_read_xml_report parses XML", {
  xml_content <- '<?xml version="1.0" encoding="UTF-8"?>
<VariantReport>
  <Patient id="PAT-001">
    <Sample id="SAM-001" type="Tumor tissue">
      <Variant gene="BRAF" variant="p.V600E" classification="Pathogenic"
               vaf="0.45" evidence="Level 1" therapeutic="Vemurafenib"/>
    </Sample>
  </Patient>
</VariantReport>'
  tmp <- tempfile(fileext = ".xml")
  on.exit(unlink(tmp), add = TRUE)
  writeLines(xml_content, tmp)

  result <- mp_read_xml_report(tmp)
  expect_s3_class(result, "molpath_parsed")
  expect_true(nrow(result$data) >= 1L)
})

test_that("mp_read_auto detects VCF", {
  vcf_content <- c(
    "##fileformat=VCFv4.2",
    "#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO",
    "chr1\t100\t.\tA\tG\t50\tPASS\tDP=30"
  )
  tmp <- tempfile(fileext = ".vcf")
  on.exit(unlink(tmp), add = TRUE)
  writeLines(vcf_content, tmp)

  result <- mp_read_auto(tmp)
  expect_s3_class(result, "molpath_parsed")
  expect_equal(result$source_type, "vcf")
})
