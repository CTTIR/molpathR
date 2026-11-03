sequence_vcf_lines <- function() c(
  '##fileformat=VCFv4.2', '##contig=<ID=chr1,length=1000>',
  '##INFO=<ID=GENE,Number=1,Type=String,Description="Gene">',
  '##FORMAT=<ID=GT,Number=1,Type=String,Description="Genotype">',
  '##FORMAT=<ID=AD,Number=R,Type=Integer,Description="Allelic depths">',
  '#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\tS1',
  'chr1\t11\t.\tA\tC,G\t60\tPASS\tGENE=TP53\tGT:AD\t1/2:10,8,12')

test_that("VCF representation retains raw fields and declared sample schema", {
  path <- withr::local_tempfile(fileext = ".vcf")
  lines <- sequence_vcf_lines()
  writeLines(lines, path)
  x <- mp_read_vcf(path)
  expect_identical(x$data$id, ".")
  expect_identical(x$data$info, "GENE=TP53")
  expect_identical(x$data$format, "GT:AD")
  expect_identical(x$data$S1, "1/2:10,8,12")
  expect_identical(x$metadata$sample_ids, "S1")
  expect_identical(x$metadata$vcf_header, head(lines, -1L))
  writeLines(head(lines, -1L), path)
  empty <- mp_read_vcf(path)
  expect_identical(names(empty$data), names(x$data))
  expect_identical(empty$metadata$sample_ids, "S1")
  expect_equal(nrow(empty$data), 0)
  gz <- withr::local_tempfile(fileext = ".vcf.gz")
  con <- gzfile(gz, "wt"); writeLines(lines, con); close(con)
  expect_identical(mp_read_vcf(gz)$data, x$data)
})

test_that("malformed VCF structure and numeric fields cannot become partial results", {
  path <- withr::local_tempfile(fileext = ".vcf")
  lines <- sequence_vcf_lines()
  invalid <- list(c(lines, lines[6]),
    c(head(lines,-1), paste0(tail(lines,1), "\textra")),
    c(head(lines,-1), sub("\t11\t", "\tgarbage\t", tail(lines,1))),
    c(head(lines,-1), sub("\t60\t", "\tInf\t", tail(lines,1))),
    sub("FORMAT\tS1", "FORMAT\tchrom", lines, fixed=TRUE))
  for (x in invalid) {
    writeLines(x,path)
    expect_error(mp_read_vcf(path))
  }
})

test_that("real ShortRead returns the first records and exact quality strings", {
  skip_if_not_installed("ShortRead")
  skip_if_not_installed("Biostrings")
  path <- withr::local_tempfile(fileext = ".fastq")
  lines <- unlist(lapply(seq_len(20), function(i) c(paste0("@r",i),"ACGT","+","I!J#")))
  writeLines(lines,path)
  set.seed(31)
  x <- expect_no_warning(mp_read_fastq(path,n=3))$data
  expect_identical(x$read_id, c("r1","r2","r3"))
  expect_identical(x$quality, rep("I!J#",3))
  expect_identical(x, .parse_fastq_text(path,n=3))
  expect_equal(nrow(mp_read_fastq(path,n=0)$data),0)
  for (n in list(-1,1.5,NA_real_,Inf,c(1,2))) expect_error(mp_read_fastq(path,n=n), "'n'")
})

test_that("FASTQ text parsing rejects truncated or malformed records", {
  path <- withr::local_tempfile(fileext = ".fastq")
  for (lines in list(c("r1","ACGT","+","IIII"), c("@r1","ACGT","-","IIII"),
                     c("@r1","ACGT","+"),c("@r1","ACGT","+","III"),
                     c("@r1","ACGT","+different","IIII"))) {
    writeLines(lines,path)
    expect_error(.parse_fastq_text(path))
  }
})

test_that("actual BAM records and genomic restrictions are read rather than discarded", {
  skip_if_not_installed("Rsamtools")
  root <- withr::local_tempdir()
  sam <- file.path(root,"tiny.sam")
  writeLines(c("@HD\tVN:1.6\tSO:coordinate","@SQ\tSN:chr1\tLN:1000",
    "q1\t0\tchr1\t11\t60\t4M\t*\t0\t0\tACGT\tIIII",
    "q2\t0\tchr1\t21\t40\t4M\t*\t0\t0\tTGCA\tJJJJ"),sam)
  bam <- Rsamtools::asBam(sam,destination=file.path(root,"tiny"))
  Rsamtools::indexBam(bam)
  x <- expect_no_warning(mp_read_bam(bam))$data
  expect_identical(x$qname,c("q1","q2"))
  expect_identical(x$pos,c(11L,21L))
  expect_identical(x$seq,c("ACGT","TGCA"))
  expect_identical(x$qual,c("IIII","JJJJ"))
  one <- mp_read_bam(bam,regions="chr1:1-15")$data
  expect_identical(one$qname,"q1")
  for (region in list("chr1:0-10","chr1:20-10","chr1:1-Inf",c("chr1:1-10","chr1:20-30")))
    expect_error(mp_read_bam(bam,regions=region),"[Rr]egion")
})

test_that("samtools fallback preserves literal paths and refuses partial failed output", {
  skip_on_os("windows")
  root <- withr::local_tempdir()
  withr::local_dir(root)
  tool <- file.path(root,"samtools")
  sam_line <- "q1\\t0\\tchr1\\t11\\t60\\t4M\\t*\\t0\\t0\\tACGT\\tIIII\\n"
  writeLines(c("#!/bin/sh", 'test "$1" = view || exit 7', 'test -f "$2" || exit 8',
    paste0("printf '",sam_line,"'"),
    'case "$2" in *corrupt*) echo "synthetic decode failed" >&2; exit 13;; esac'),tool)
  Sys.chmod(tool,"0700")
  withr::local_path(root)
  # Exercise the actual reader body with its optional backend unavailable.
  reader <- mp_read_bam
  lookup <- new.env(parent=environment(reader))
  lookup$requireNamespace <- function(package,...) {
    if (package == "Rsamtools") FALSE else base::requireNamespace(package,...)
  }
  environment(reader) <- lookup
  input <- file.path(root,"input ' ; touch sentinel ; $ sample.bam")
  writeLines("synthetic placeholder",input)
  x <- reader(input)$data
  expect_identical(x$qname,"q1")
  expect_identical(x$seq,"ACGT")
  expect_false(file.exists(file.path(root,"sentinel")))
  corrupt <- file.path(root,"corrupt.bam")
  writeLines("synthetic placeholder",corrupt)
  expect_error(reader(corrupt),"exit 13.*synthetic decode failed")
})


test_that("VCF sample subfields obey FORMAT and preserve omitted trailing values", {
  path <- withr::local_tempfile(fileext=".vcf")
  lines <- sequence_vcf_lines()
  for (value in c("1/2:10,8,12:99", "1/2:", "1/:10,8,12", "3/0:10,8,12")) {
    writeLines(c(head(lines,-1L),sub("1/2:10,8,12",value,tail(lines,1L),fixed=TRUE)),path)
    expect_error(mp_read_vcf(path),"VCF")
  }
  for (value in c("1/2", ".", "0|.", "1")) {
    writeLines(c(head(lines,-1L),sub("1/2:10,8,12",value,tail(lines,1L),fixed=TRUE)),path)
    expect_identical(mp_read_vcf(path)$data$S1,value)
  }
})

test_that("raw VCF sample identities are independent of model annotation names", {
  path <- withr::local_tempfile(fileext=".vcf")
  lines <- sequence_vcf_lines()
  samples <- c("gene","classification","vaf","sample_id","variant")
  tokens <- c("0/1:10,8,12","1/2:10,8,12","0/0:30,0,0",".","1")
  lines[6] <- sub("S1$",paste(samples,collapse="\t"),lines[6])
  lines[7] <- sub("1/2:10,8,12$",paste(tokens,collapse="\t"),lines[7])
  writeLines(lines,path)
  x <- mp_read_vcf(path)
  expect_identical(x$metadata$sample_ids,samples)
  expect_identical(vapply(samples,function(s) x$data[[s]],character(1)),stats::setNames(tokens,samples))
})
