import_fixture <- function(name, lines) {
  path <- file.path(withr::local_tempdir(.local_envir=parent.frame()),name)
  writeLines(lines,path)
  path
}

linked_fixture <- function() new_molpath_db(
  patients=tibble::tibble(patient_id='P1',age=50,sex='F',diagnosis='Example'),
  samples=tibble::tibble(sample_id='S1',patient_id='P1',sample_type='synthetic',date=as.Date('2025-01-01'),source_file='synthetic.csv')
)

test_that('real pathology, clinical and survival imports form one linked schema', {
  pathology <- mp_read_nexus_pathology(import_fixture('pathology.csv',c(
    'patient_id,name,dob,sex,sample_id,sample_type,diagnosis,report_date',
    'P1,Synthetic,1960-01-01,F,S1,FFPE,Example,2025-01-01',
    'P1,Synthetic,1960-01-01,F,S2,FFPE,Example,2025-02-01')))
  clinical <- mp_read_nexus_clinical(import_fixture('clinical.csv',c('patient_id;parameter;value;unit;date;source','P1;marker;17;U;2025-01-01;synthetic')))
  survival <- mp_read_survival(import_fixture('survival.csv',c('patient_id,os_months,os_status','P1,12,0')))
  original <- serialize(list(pathology,clinical,survival),NULL)
  db <- mp_build_db(pathology,clinical,survival)
  expect_equal(nrow(db$patients),1)
  expect_identical(db$samples$sample_id,c('S1','S2'))
  expect_identical(db$clinical$value,'17')
  expect_s3_class(db$samples$date,'Date')
  expect_true(mp_validate_db(db)$valid)
  expect_no_warning(validate_molpath_db(db))
  expect_identical(serialize(list(pathology,clinical,survival),NULL),original)
  path <- withr::local_tempfile(fileext='.rds')
  mp_save_db(db,path)
  expect_identical(mp_load_db(path),db)
  expect_setequal(db$metadata$source_files,c(pathology$source_file,clinical$source_file,survival$source_file))
})

test_that('schema and linkage checks retain incomplete evidence without false validity', {
  parsed <- new_molpath_parsed(tibble::tibble(patient_id='P1',os_months=12,os_status=1L,pfs_months=8,pfs_status=0L),'survival','synthetic.csv')
  db <- mp_build_db(parsed)
  expect_named(db$patients,c('patient_id','age','sex','diagnosis'))
  expect_false(mp_validate_db(db)$valid)
  expect_match(paste(mp_validate_db(db)$issues,collapse=' '),'not found in patients')
  db <- new_molpath_db()
  db$variants <- tibble::tibble(sample_id='missing',gene='TP53',variant='p.X',classification='VUS',vaf=.3)
  expect_false(mp_validate_db(db)$valid)
  db$variants$vaf <- Inf
  expect_error(validate_molpath_db(db),'finite')
  db <- linked_fixture(); db$patients <- dplyr::bind_rows(db$patients,db$patients)
  expect_error(validate_molpath_db(db),'duplicate')
})

test_that('exact aliases and numeric outcomes cannot silently change patient evidence', {
  path <- import_fixture('survival.csv',c('patient_id_backup,patient_id,os_months,os_status','WRONG,P1,12,0'))
  parsed <- mp_read_survival(path)
  expect_identical(parsed$data$patient_id,'P1')
  expect_identical(parsed$data$patient_id_backup,'WRONG')
  for (value in c('0.9','2','-1','Inf','not-recorded')) {
    writeLines(c('patient_id,os_months,os_status',paste0('P1,12,',value)),path)
    expect_error(mp_read_survival(path),'invalid|exactly')
  }
  writeLines(c('patient_id,os_months,os_status','P1,-12,0'),path)
  expect_error(mp_read_survival(path),'negative')
  writeLines(c('patient_id,patientid,os_months','P1,OTHER,12'),path)
  expect_error(mp_read_survival(path),'Multiple')
})

test_that('namespace-safe XML keeps each explicit patient and sample identity', {
  path <- import_fixture('report.xml',c(
    '<Report xmlns="urn:synthetic"><Patient><PatientID>P1</PatientID><Name>Synthetic</Name>',
    '<Sample><SampleID>S1</SampleID><Variant><Gene>TP53</Gene><Description>p.X</Description></Variant></Sample>',
    '<Sample><SampleID>S2</SampleID><Variant><Gene>KRAS</Gene><Description>p.Y</Description></Variant></Sample>',
    '</Patient></Report>'))
  parsed <- mp_read_xml_report(path)
  expect_identical(parsed$data$patient_id,c('P1','P1'))
  expect_identical(parsed$data$sample_id,c('S1','S2'))
  expect_identical(parsed$data$gene,c('TP53','KRAS'))
  db <- mp_build_db(parsed)
  expect_equal(nrow(db$patients),1)
  expect_equal(nrow(db$samples),2)
  expect_true(mp_validate_db(db)$valid)
  expect_identical(mp_get_patient(db,'P1')$variants$gene,c('TP53','KRAS'))
})

test_that('conflicting primary identities never merge silently', {
  left <- linked_fixture();right <- linked_fixture();right$patients$sex <- 'M'
  before <- serialize(left,NULL)
  expect_error(mp_merge_db(left,right),'Conflicting')
  expect_identical(serialize(left,NULL),before)
  expect_equal(nrow(mp_merge_db(left,left)$patients),1)
})

test_that('raw sequence reads do not become interpreted variants', {
  for (type in c('fastq','bam')) {
    parsed <- new_molpath_parsed(tibble::tibble(sequence='ACGT'),type,paste0('synthetic.',type))
    expect_error(mp_build_db(parsed),'not interpreted variant calls')
  }
})

test_that('extensionless uploads retain original type and stable source identity', {
  path <- import_fixture('upload0',c('patient_id,parameter,value','P1,marker,17'))
  parsed <- mp_read_auto(path,source_name='clinical.csv')
  expect_identical(parsed$source_type,'nexus_clinical')
  expect_identical(parsed$source_file,'clinical.csv')
  expect_identical(parsed$data$value,'17')
  writeLines(c('patient_id,foo,bar','P1,1,2'),path)
  expect_error(mp_read_auto(path,source_name='unknown.csv'),'Cannot determine')
})

test_that('failed serialization preserves the existing destination bytes', {
  path <- withr::local_tempfile(fileext='.rds')
  original <- list(original='keep');saveRDS(original,path)
  before <- readBin(path,'raw',n=file.info(path)$size)
  testthat::local_mocked_bindings(saveRDS=function(object,file,...) {
    writeBin(charToRaw('partial output'),file)
    rlang::abort('Synthetic encoder failure')
  },.package='base')
  expect_error(mp_save_db(new_molpath_db(),path),'encoder failure')
  expect_identical(readBin(path,'raw',n=file.info(path)$size),before)
  expect_identical(readRDS(path),original)
})

test_that('replacement failure restores old bytes and leaves no staging files', {
  directory <- withr::local_tempdir();path <- file.path(directory,'db.rds')
  saveRDS(list(original='keep'),path)
  rename <- .mp_rename
  testthat::local_mocked_bindings(.mp_rename=function(from,to) {
    if (startsWith(basename(from),'.molpath-stage-')) return(FALSE)
    rename(from,to)
  })
  expect_error(mp_save_db(new_molpath_db(),path),'previous destination was restored')
  expect_identical(readRDS(path),list(original='keep'))
  expect_identical(list.files(directory,all.files=TRUE,no..=TRUE),'db.rds')
})

test_that('loading checks schema and explicitly migrates known legacy empty tables', {
  path <- withr::local_tempfile(fileext='.rds')
  saveRDS(structure(list(patients='bad'),class='molpath_db'),path)
  expect_error(mp_load_db(path),'must be a tibble|Missing required')
  legacy <- new_molpath_db();legacy$variants<-tibble::tibble()
  legacy$metadata<-tibble::tibble(creation_date=Sys.time(),source_files=list(character()),parser_versions=list(character()))
  saveRDS(legacy,path);loaded<-mp_load_db(path)
  expect_named(loaded$variants,c('sample_id','gene','variant','classification','vaf'))
  expect_identical(loaded$metadata$source_files,character())
  expect_false(tibble::is_tibble(loaded$metadata))
})

test_that('VCF integration preserves sample evidence and does not invent annotation', {
  path <- import_fixture('calls.vcf',c('##fileformat=VCFv4.2',
    '#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\tS1\tS2',
    '1\t100\t.\tA\tG,T\t50\tPASS\tDP=50\tGT:DP\t1/2:20\t0/0:30'))
  parsed <- mp_read_vcf(path);db <- mp_build_db(parsed)
  expect_identical(db$samples$sample_id,c('S1','S2'))
  expect_identical(db$variants$sample_id,c('S1','S1'))
  expect_identical(db$variants$called_alt,c('G','T'))
  expect_identical(db$variants$sample_fields,c('1/2:20','1/2:20'))
  expect_identical(db$variants$format,c('GT:DP','GT:DP'))
  expect_true(all(is.na(db$variants$gene)))
  expect_true(all(is.na(db$variants$vaf)))
  expect_false(mp_validate_db(db)$valid)
  pathology <- mp_read_nexus_pathology(import_fixture('pathology.csv',c(
    'patient_id,sample_id','P1,S1','P1,S2')))
  linked <- mp_add_data(db,pathology)
  expect_true(mp_validate_db(linked)$valid)
  expect_identical(mp_get_patient(linked,'P1')$variants$called_alt,c('G','T'))
  expect_identical(linked$metadata$source_records[[1]]$details$vcf_header,parsed$metadata$vcf_header)
})

test_that('patient-level XML variants never borrow the patient ID as a sample', {
  path <- import_fixture('patient-only.xml',c('<Report><Patient><ID>P1</ID>',
    '<Variant><Gene>TP53</Gene><Description>p.X</Description></Variant>',
    '</Patient></Report>'))
  parsed <- mp_read_xml_report(path)
  expect_identical(parsed$data$patient_id,'P1')
  expect_true(is.na(parsed$data$sample_id))
  db <- mp_build_db(parsed)
  expect_equal(nrow(db$samples),0)
  expect_false(mp_validate_db(db)$valid)
})

test_that('explicit pathology age is numeric and malformed ages are rejected', {
  path <- import_fixture('age.csv',c('patient_id,sample_id,age,sex','P1,S1,55,F'))
  db <- mp_build_db(mp_read_nexus_pathology(path))
  expect_identical(db$patients$age,55)
  writeLines(c('patient_id,sample_id,age,sex','P1,S1,55years,F'),path)
  expect_error(mp_read_nexus_pathology(path),'invalid numeric')
})

test_that('raw VCF sample names cannot become annotations or normalized IDs', {
  path <- import_fixture('named-samples.vcf',c('##fileformat=VCFv4.2',
    '#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\tgene\tsample_id\tvariant',
    '1\t100\t.\tA\tG\t50\tPASS\t.\tGT:DP\t0/1:10\t0/1:20\t0/1:30'))
  parsed <- mp_read_vcf(path)
  expect_identical(parsed$data$gene,'0/1:10')
  db <- mp_build_db(parsed)
  expect_identical(db$variants$sample_id,c('gene','sample_id','variant'))
  expect_identical(db$variants$sample_fields,c('0/1:10','0/1:20','0/1:30'))
  expect_identical(db$variants$variant,rep('1:100:A>G',3))
  expect_true(all(is.na(db$variants$gene)))
  expect_true(all(is.na(db$variants$vaf)))
})

test_that('full PDF extraction survives heuristic sections and persistence', {
  path <- withr::local_tempfile(fileext='.pdf')
  grDevices::pdf(path,width=8,height=5)
  graphics::plot.new()
  lines <- c('Unlabelled provenance KEEPSYNTHETIC123',
    'Findings: synthetic finding', 'Interpretation: synthetic summary',
    'Unsupported heading PRESERVEEND')
  graphics::text(.05,seq(.9,.3,length.out=length(lines)),labels=lines,adj=0)
  grDevices::dev.off()
  extracted <- pdftools::pdf_text(path)
  parsed <- mp_read_pdf_report(path)
  expect_identical(parsed$metadata$pdf_pages,extracted)
  expect_match(parsed$metadata$pdf_text,'KEEPSYNTHETIC123')
  db <- mp_build_db(parsed)
  expect_identical(db$reports$summary_text,paste(extracted,collapse='\n'))
  expect_match(db$reports$summary_text,'PRESERVEEND')
  saved <- withr::local_tempfile(fileext='.rds')
  expect_warning(mp_save_db(db,saved),class='molpathR_validation_warning')
  expect_identical(mp_load_db(saved)$reports$summary_text,db$reports$summary_text)
})

test_that('generated XML files retain their explicit lowercase identities and VAF', {
  directory <- withr::local_tempdir()
  files <- mp_example_files(directory,seed=31)
  parsed <- mp_read_xml_report(files$xml[[1]])
  db <- mp_build_db(parsed)
  expect_true(all(!is.na(parsed$data$patient_id)))
  expect_true(all(!is.na(parsed$data$sample_id)))
  expect_true(mp_validate_db(db)$valid)
  original <- xml2::read_xml(files$xml[[1]])
  expected <- as.numeric(xml2::xml_text(xml2::xml_find_all(original,'.//VAF')))
  expect_identical(db$variants$vaf,expected)
})
