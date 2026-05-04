# ---- Non-exported helper: generate realistic HGVS variants ----

#' Generate a realistic HGVS variant notation for a given gene
#'
#' @param gene Character. Gene symbol.
#' @param variant_type Character. One of "SNV", "Indel", "CNV", "Fusion".
#' @return A character string with HGVS-like notation.
#' @noRd
generate_hgvs_variant <- function(gene, variant_type) {


  # --- well-known hotspot mutations per gene (protein-level) ---
  hotspots <- list(
    TP53 = c("p.R175H", "p.R248W", "p.R273H", "p.G245S", "p.R249S",
             "p.Y220C", "p.V157F", "p.R282W", "p.H179R", "p.C176Y"),
    KRAS = c("p.G12D", "p.G12V", "p.G12C", "p.G12R", "p.G12A",
             "p.G13D", "p.Q61H", "p.Q61L", "p.Q61R", "p.A146T"),
    EGFR = c("p.L858R", "p.T790M", "p.C797S", "p.G719A", "p.G719S",
             "p.S768I", "p.L861Q", "p.E746_A750del", "p.L747_P753del",
             "p.E709K"),
    BRAF = c("p.V600E", "p.V600K", "p.V600D", "p.V600R", "p.K601E",
             "p.G469A", "p.G466V", "p.D594G", "p.N581S", "p.L597Q"),
    PIK3CA = c("p.H1047R", "p.H1047L", "p.E545K", "p.E542K", "p.N345K",
               "p.C420R", "p.Q546R", "p.R88Q", "p.G1049R", "p.M1043I"),
    BRCA1 = c("p.C61G", "p.R1699Q", "p.M1775R", "p.A1708E", "p.R1443*",
              "c.68_69del", "c.181T>G", "c.5266dup", "c.3756_3759del",
              "c.5123C>A"),
    BRCA2 = c("p.R2336H", "p.D2723H", "p.T3033fs", "c.5946del",
              "c.6174delT", "c.9097dup", "c.3847_3848del", "c.7480C>T",
              "c.8537_8538del", "c.2808_2811del"),
    ALK  = c("p.F1174L", "p.R1275Q", "p.F1245C", "p.I1171N", "p.L1196M",
             "p.G1202R", "p.D1203N", "p.S1206Y", "p.G1269A", "p.V1180L"),
    ROS1 = c("p.G2032R", "p.D2033N", "p.L2026M", "p.S1986F", "p.L1951R",
             "p.F2004C", "p.F2004V", "p.L2086F", "p.E1935G", "p.G2101A"),
    MET  = c("p.D1228N", "p.D1228H", "p.Y1230H", "p.Y1230C", "p.M1250T",
             "p.T1010I", "p.H1094Y", "p.L1195V", "p.F1200I", "p.V1092I"),
    ERBB2 = c("p.S310F", "p.L755S", "p.V777L", "p.V842I", "p.D769H",
              "p.R678Q", "p.L869R", "p.G309A", "p.R896C", "p.T798M"),
    NRAS = c("p.Q61R", "p.Q61K", "p.Q61L", "p.Q61H", "p.G12D",
             "p.G12V", "p.G12C", "p.G13R", "p.G13V", "p.A146T"),
    APC  = c("p.R1450*", "p.R876*", "p.Q1338*", "p.R1114*", "p.E1309fs",
             "p.T1556fs", "p.Q1378*", "p.E853*", "p.Y935*", "p.R216*"),
    PTEN = c("p.R130Q", "p.R130*", "p.R233*", "p.R173C", "p.R173H",
             "p.C124S", "p.G129E", "p.K267fs", "p.R335*", "p.Y178*"),
    STK11 = c("p.D194Y", "p.F354L", "p.Q170*", "p.G163D", "p.P281L",
              "c.465_468del", "c.862C>T", "c.580G>T", "c.291_292del",
              "p.G242W"),
    KEAP1 = c("p.R320Q", "p.G333C", "p.R413L", "p.G186R", "p.D236H",
              "p.G364C", "p.R470C", "p.G480W", "p.R260Q", "p.A427V"),
    NF1  = c("p.R1276*", "p.R1947*", "p.Q1336*", "p.R304*", "p.W784*",
             "c.3826C>T", "c.5839C>T", "c.2041C>T", "c.731_732del",
             "p.L847fs"),
    RB1  = c("p.R320*", "p.R455*", "p.R552*", "p.R556*", "p.R787*",
             "c.958C>T", "c.1363C>T", "c.1654C>T", "p.E440*",
             "c.2106_2107del"),
    CDKN2A = c("p.R80*", "p.H83Y", "p.R58*", "p.W110*", "p.D108Y",
               "p.P114L", "p.G101W", "p.V126D", "p.A148T", "p.R24P"),
    SMAD4 = c("p.R361H", "p.R361C", "p.D351H", "p.R100T", "p.D537Y",
              "p.W524*", "p.Q311*", "p.P356L", "p.G386D", "p.S144*")
  )

  # --- fusion partners ---
  fusion_partners <- list(
    ALK  = c("EML4", "NPM1", "TFG", "KIF5B", "STRN"),
    ROS1 = c("CD74", "SLC34A2", "TPM3", "SDC4", "EZR"),
    RET  = c("KIF5B", "CCDC6", "NCOA4", "TRIM33", "CUX1"),
    NTRK1 = c("TPM3", "LMNA", "TFG", "PPL", "SQSTM1"),
    MET  = c("KIF5B", "HLA-DRB1", "ATXN7L1", "TRIM4", "ST7"),
    BRAF = c("KIAA1549", "AGK", "SND1", "TRIM24", "MACF1"),
    EGFR = c("SEPT14", "PSPH", "SEC61G", "VOPP1", "LANCL2"),
    ERBB2 = c("CDK12", "GRB7", "PERLD1", "STARD3", "PGAP3")
  )

  if (variant_type == "Fusion") {
    partners <- fusion_partners[[gene]]
    if (is.null(partners)) {
      partners <- c("UNKNOWN")
    }
    partner <- sample(partners, 1)
    return(paste0(gene, "-", partner, " fusion"))
  }

  if (variant_type == "CNV") {
    cnv_types <- c("amplification", "deletion", "gain", "loss")
    return(paste0(gene, " ", sample(cnv_types, 1)))
  }

  if (variant_type == "Indel") {
    # Return coding-level indels
    indel_pool <- c(
      paste0("c.", sample(100:2500, 1), "_", sample(100:2500, 1), "del"),
      paste0("c.", sample(100:2500, 1), "del"),
      paste0("c.", sample(100:2500, 1), "dup"),
      paste0("c.", sample(100:2500, 1), "_", sample(100:2500, 1), "ins",
             paste0(sample(c("A", "T", "G", "C"), sample(1:6, 1),
                           replace = TRUE), collapse = ""))
    )
    return(sample(indel_pool, 1))
  }

  # SNV: prefer hotspot if available
  hs <- hotspots[[gene]]
  if (!is.null(hs)) {
    return(sample(hs, 1))
  }


  # Generic missense for unknown genes
  aa <- c("A", "R", "N", "D", "C", "E", "Q", "G", "H", "I",
          "L", "K", "M", "F", "P", "S", "T", "W", "Y", "V")
  pos <- sample(10:800, 1)
  paste0("p.", sample(aa, 1), pos, sample(aa, 1))
}


# ---- Exported function: mp_example_db ----

#' Create a synthetic molecular pathology database
#'
#' Generates a realistic but entirely synthetic \code{molpath_db} object
#' containing patients, samples, variants, reports, clinical data, and
#' survival data.
#' The data set is designed to mirror the structure of a real-world
#' molecular pathology database with plausible clinical correlations,
#' including diagnosis-specific mutation profiles, TNM staging, and
#' survival outcomes.
#'
#' @param n_patients Integer. Number of patients to generate.
#'   Default \code{150}.
#' @param seed Integer. Random seed for reproducibility. Default \code{42}.
#'
#' @return A \code{molpath_db} object (S3 list) containing:
#'   \describe{
#'     \item{patients}{A \code{tibble} with columns patient_id, age, sex,
#'       diagnosis, diagnosis_date.}
#'     \item{samples}{A \code{tibble} with columns sample_id, patient_id,
#'       sample_type, date, source_file.}
#'     \item{variants}{A \code{tibble} with columns sample_id, gene, variant,
#'       variant_type, classification, vaf, chromosome, position, ref_allele,
#'       alt_allele.}
#'     \item{reports}{A \code{tibble} with columns sample_id, report_type,
#'       report_date, summary_text, source_file.}
#'     \item{clinical}{A \code{tibble} with columns patient_id, parameter,
#'       value, date, source.}
#'     \item{survival}{A \code{tibble} with columns patient_id, os_months,
#'       os_status, pfs_months, pfs_status.}
#'   }
#'
#' @examples
#' db <- mp_example_db()
#' db$patients
#' nrow(db$variants)
#'
#' # Smaller data set for quick tests
#' db_small <- mp_example_db(n_patients = 20, seed = 123)
#'
#' @export
mp_example_db <- function(n_patients = 150, seed = 42) {

  set.seed(seed)


  # ---- Patients ----
  patient_ids <- sprintf("PAT-2024-%04d", seq_len(n_patients))

  ages <- as.integer(pmin(85, pmax(18, stats::rnorm(n_patients,
                                                     mean = 62, sd = 12))))
  sexes <- sample(c("M", "F"), n_patients, replace = TRUE)

  diagnosis_probs <- c(0.40, 0.25, 0.20, 0.15)
  diagnoses_pool  <- c("Lung adenocarcinoma", "Colorectal carcinoma",
                        "Breast carcinoma", "Melanoma")
  diagnoses <- sample(diagnoses_pool, n_patients, replace = TRUE,
                      prob = diagnosis_probs)

  diagnosis_dates <- as.Date("2021-01-01") +
    sample(0:1460, n_patients, replace = TRUE)   # 2021-01-01 to ~2025-01-01

  patients <- tibble::tibble(
    patient_id     = patient_ids,
    age            = ages,
    sex            = sexes,
    diagnosis      = diagnoses,
    diagnosis_date = diagnosis_dates
  )

  # ---- Samples (1-4 per patient, ~2x on average -> ~300) ----
  sample_list <- lapply(seq_len(n_patients), function(i) {
    n_samp <- sample(1:4, 1, prob = c(0.25, 0.40, 0.25, 0.10))
    types_pool <- c("Tumor tissue", "Liquid biopsy", "FFPE", "Fresh frozen")
    s_types    <- sample(types_pool, n_samp, replace = TRUE)
    offsets    <- sort(sample(0:365, n_samp, replace = TRUE))
    s_dates    <- diagnosis_dates[i] + offsets

    tibble::tibble(
      patient_id  = patient_ids[i],
      sample_type = s_types,
      date = s_dates
    )
  })

  samples_raw <- dplyr::bind_rows(sample_list)
  n_samples   <- nrow(samples_raw)
  sample_years <- format(samples_raw$date, "%Y")
  sample_ids   <- sprintf("SAM-%s-%04d", sample_years, seq_len(n_samples))

  samples <- tibble::tibble(
    sample_id   = sample_ids,
    patient_id  = samples_raw$patient_id,
    sample_type = samples_raw$sample_type,
    date        = samples_raw$date,
    source_file = paste0("input/", sample_ids, ".vcf")
  )

  # ---- Variants (~2000 total across all samples) ----
  # Map each sample to its patient diagnosis for correlation
  sample_diag <- dplyr::left_join(samples, patients[, c("patient_id", "diagnosis")],
                                  by = "patient_id")

  gene_pool <- c("TP53", "KRAS", "EGFR", "BRAF", "PIK3CA", "BRCA1", "BRCA2",
                  "ALK", "ROS1", "MET", "ERBB2", "NRAS", "APC", "PTEN",
                  "STK11", "KEAP1", "NF1", "RB1", "CDKN2A", "SMAD4")

  # Diagnosis-specific gene weights (rows = genes, cols = diagnoses)
  # Order: Lung, CRC, Breast, Melanoma
  gene_weights <- matrix(c(
    # TP53  KRAS  EGFR  BRAF  PIK3CA BRCA1 BRCA2 ALK   ROS1  MET
      15,   12,   15,    3,    4,     1,    1,    8,    5,    6,
    #ERBB2  NRAS  APC   PTEN  STK11  KEAP1  NF1  RB1   CDKN2A SMAD4
       3,    2,    2,    3,    8,     6,     3,    3,    5,     1,  # Lung
    # CRC
      12,   18,    1,    8,    6,     1,    1,    0,    0,    1,
       1,    3,   20,    5,    1,     0,     2,    1,    1,   10,
    # Breast
      10,    1,    2,    1,   18,    12,   10,    0,    0,    1,
      12,    1,    1,    8,    1,     0,     2,    5,    3,    1,
    # Melanoma
       8,    2,    1,   22,    2,     1,    1,    0,    0,    2,
       1,   15,    1,    5,    1,     0,    10,    2,    8,    1
  ), nrow = 20, ncol = 4)

  rownames(gene_weights) <- gene_pool
  colnames(gene_weights) <- diagnoses_pool

  # Target ~2000 variants total; ~6-7 per sample
  target_variants <- 2000
  avg_per_sample  <- ceiling(target_variants / n_samples)

  variant_type_probs <- c(SNV = 0.65, Indel = 0.15, CNV = 0.12, Fusion = 0.08)

  # Chromosomes per gene (approximate)
  gene_chr <- c(
    TP53 = "17", KRAS = "12", EGFR = "7", BRAF = "7", PIK3CA = "3",
    BRCA1 = "17", BRCA2 = "13", ALK = "2", ROS1 = "6", MET = "7",
    ERBB2 = "17", NRAS = "1", APC = "5", PTEN = "10", STK11 = "19",
    KEAP1 = "19", NF1 = "17", RB1 = "13", CDKN2A = "9", SMAD4 = "18"
  )

  bases <- c("A", "T", "G", "C")

  variant_rows <- lapply(seq_len(n_samples), function(j) {
    diag_j <- sample_diag$diagnosis[j]
    wts    <- gene_weights[, diag_j]
    n_var  <- sample(max(1, avg_per_sample - 3):(avg_per_sample + 3), 1)

    genes_j  <- sample(gene_pool, n_var, replace = TRUE, prob = wts)
    vtypes_j <- sample(names(variant_type_probs), n_var, replace = TRUE,
                       prob = variant_type_probs)
    vafs_j   <- stats::rbeta(n_var, shape1 = 2, shape2 = 5)
    vafs_j   <- pmin(0.95, pmax(0.01, vafs_j))

    # Classification
    class_pool  <- c("Pathogenic", "Likely pathogenic", "VUS",
                     "Likely benign", "Benign")
    class_probs <- c(0.20, 0.15, 0.40, 0.15, 0.10)
    classes_j   <- sample(class_pool, n_var, replace = TRUE,
                          prob = class_probs)

    # Generate HGVS
    variants_j <- vapply(seq_len(n_var), function(k) {
      generate_hgvs_variant(genes_j[k], vtypes_j[k])
    }, character(1))

    # Genomic coordinates (synthetic)
    chroms_j <- gene_chr[genes_j]
    positions_j <- sample(1e6:2e8, n_var, replace = TRUE)
    ref_j <- ifelse(vtypes_j == "SNV", sample(bases, n_var, replace = TRUE), NA_character_)
    alt_j <- ifelse(vtypes_j == "SNV", sample(bases, n_var, replace = TRUE), NA_character_)
    # Ensure alt != ref for SNVs
    same <- which(!is.na(ref_j) & ref_j == alt_j)
    for (idx in same) {
      alt_j[idx] <- sample(setdiff(bases, ref_j[idx]), 1)
    }

    tibble::tibble(
      sample_id      = sample_ids[j],
      gene           = genes_j,
      variant        = variants_j,
      variant_type   = vtypes_j,
      classification = classes_j,
      vaf            = round(vafs_j, 4),
      chromosome     = chroms_j,
      position       = positions_j,
      ref_allele     = ref_j,
      alt_allele     = alt_j
    )
  })

  variants <- dplyr::bind_rows(variant_rows)

  # Force some diagnosis-specific hotspots for realism
  # BRAF V600E in melanoma samples
  mel_samples <- samples$sample_id[samples$patient_id %in%
    patients$patient_id[patients$diagnosis == "Melanoma"]]
  if (length(mel_samples) > 0) {
    n_force <- min(length(mel_samples), round(length(mel_samples) * 0.6))
    force_ids <- sample(mel_samples, n_force)
    forced_braf <- tibble::tibble(
      sample_id      = force_ids,
      gene           = "BRAF",
      variant        = "p.V600E",
      variant_type   = "SNV",
      classification = "Pathogenic",
      vaf            = round(stats::rbeta(n_force, 3, 4), 4),
      chromosome     = "7",
      position       = 140753336L,
      ref_allele     = "T",
      alt_allele     = "A"
    )
    variants <- dplyr::bind_rows(variants, forced_braf)
  }

  # KRAS G12D/G12V in CRC/Lung
  crc_lung_pats <- patients$patient_id[patients$diagnosis %in%
    c("Colorectal carcinoma", "Lung adenocarcinoma")]
  crc_lung_samples <- samples$sample_id[samples$patient_id %in% crc_lung_pats]
  if (length(crc_lung_samples) > 0) {
    n_force <- min(length(crc_lung_samples),
                   round(length(crc_lung_samples) * 0.35))
    force_ids <- sample(crc_lung_samples, n_force)
    forced_kras <- tibble::tibble(
      sample_id      = force_ids,
      gene           = "KRAS",
      variant        = sample(c("p.G12D", "p.G12V", "p.G12C"),
                              n_force, replace = TRUE),
      variant_type   = "SNV",
      classification = "Pathogenic",
      vaf            = round(stats::rbeta(n_force, 2, 5), 4),
      chromosome     = "12",
      position       = 25398284L,
      ref_allele     = "C",
      alt_allele     = sample(c("A", "T"), n_force, replace = TRUE)
    )
    variants <- dplyr::bind_rows(variants, forced_kras)
  }

  # BRCA1/2 in breast
  breast_pats <- patients$patient_id[patients$diagnosis == "Breast carcinoma"]
  breast_samples <- samples$sample_id[samples$patient_id %in% breast_pats]
  if (length(breast_samples) > 0) {
    n_force <- min(length(breast_samples),
                   round(length(breast_samples) * 0.3))
    force_ids <- sample(breast_samples, n_force)
    brca_genes <- sample(c("BRCA1", "BRCA2"), n_force, replace = TRUE)
    forced_brca <- tibble::tibble(
      sample_id      = force_ids,
      gene           = brca_genes,
      variant        = vapply(seq_len(n_force), function(k) {
        generate_hgvs_variant(
          sample(c("BRCA1", "BRCA2"), 1), "SNV")
      }, character(1)),
      variant_type   = "SNV",
      classification = sample(c("Pathogenic", "Likely pathogenic"),
                              n_force, replace = TRUE),
      vaf            = round(stats::rbeta(n_force, 2, 4), 4),
      chromosome     = ifelse(
        grepl("BRCA1", brca_genes, fixed = TRUE), "17", "13"
      ),
      position       = sample(30e6:80e6, n_force, replace = TRUE),
      ref_allele     = sample(bases, n_force, replace = TRUE),
      alt_allele     = sample(bases, n_force, replace = TRUE)
    )
    variants <- dplyr::bind_rows(variants, forced_brca)
  }

  # ---- Reports (~200) ----
  # Pick ~200 samples (with replacement if fewer samples)
  report_sample_ids <- sample(sample_ids, min(200, n_samples))
  report_types <- c("Molecular Health XML", "Pathology PDF", "Clinical Report")

  summaries_pool <- c(
    "Somatic variant analysis completed. Actionable mutations identified.",
    "Comprehensive genomic profiling performed. See variant table.",
    "Molecular analysis report. TMB: intermediate. MSI: stable.",
    "NGS panel results: actionable variants detected. Therapy options listed.",
    "Pathology report: invasive carcinoma with molecular correlates.",
    "Variant interpretation report. Tier I/II variants identified.",
    "Liquid biopsy analysis: ctDNA variants detected at low VAF.",
    "Genomic profiling complete. No actionable variants identified.",
    "Panel sequencing: multiple VUS detected. Clinical correlation advised.",
    "Comprehensive report: PD-L1 positive, MSI-high, TMB-high."
  )

  reports <- tibble::tibble(
    sample_id    = report_sample_ids,
    report_type  = sample(report_types, length(report_sample_ids),
                          replace = TRUE),
    report_date  = samples$date[
      match(report_sample_ids, samples$sample_id)] + sample(7:60,
        length(report_sample_ids), replace = TRUE),
    summary_text = sample(summaries_pool, length(report_sample_ids),
                          replace = TRUE),
    source_file  = paste0("reports/",
      gsub(" ", "_", tolower(sample(report_types,
        length(report_sample_ids), replace = TRUE))),
      "/", report_sample_ids, ".xml")
  )

  # ---- Clinical data (~600 records, ~4 per patient) ----
  clinical_list <- lapply(seq_len(n_patients), function(i) {
    diag <- diagnoses[i]
    d_date <- diagnosis_dates[i]

    # TNM stage
    t_stage <- sample(c("T1", "T2", "T3", "T4"), 1,
                      prob = c(0.15, 0.30, 0.35, 0.20))
    n_stage <- sample(c("N0", "N1", "N2", "N3"), 1,
                      prob = c(0.30, 0.30, 0.25, 0.15))
    m_stage <- sample(c("M0", "M1"), 1, prob = c(0.65, 0.35))

    grade <- sample(c("G1", "G2", "G3"), 1, prob = c(0.15, 0.45, 0.40))

    ki67 <- paste0(sample(5:80, 1), "%")

    pdl1 <- paste0(sample(c(0, 1, 5, 10, 20, 30, 50, 60, 80, 90), 1), "%")

    msi <- sample(c("MSS", "MSI-low", "MSI-high"), 1,
                  prob = c(0.70, 0.15, 0.15))

    params <- c("TNM_T", "TNM_N", "TNM_M", "Grading", "Ki-67", "PD-L1 TPS",
                "MSI status")
    values <- c(t_stage, n_stage, m_stage, grade, ki67, pdl1, msi)
    # Randomly select 3-5 parameters per patient
    n_params <- sample(3:5, 1)
    sel <- sample(seq_along(params), n_params)

    tibble::tibble(
      patient_id = patient_ids[i],
      parameter  = params[sel],
      value      = values[sel],
      date       = d_date + sample(0:30, n_params, replace = TRUE),
      source     = sample(c("KIS", "LIMS", "Pathology report", "NGS report"),
                          n_params, replace = TRUE)
    )
  })

  clinical <- dplyr::bind_rows(clinical_list)

  # ---- Survival data (all patients) ----
  # Base OS depends on diagnosis and stage
  # Correlate with TP53 mutations for worse outcome in lung
  tp53_samples <- unique(variants$sample_id[variants$gene == "TP53" &
    variants$classification %in% c("Pathogenic", "Likely pathogenic")])
  tp53_patients <- unique(
    samples$patient_id[samples$sample_id %in% tp53_samples])

  os_months <- vapply(seq_len(n_patients), function(i) {
    base <- switch(diagnoses[i],
      "Lung adenocarcinoma"   = stats::rgamma(1, shape = 4, rate = 0.15),
      "Colorectal carcinoma"  = stats::rgamma(1, shape = 5, rate = 0.12),
      "Breast carcinoma"      = stats::rgamma(1, shape = 6, rate = 0.10),
      "Melanoma"              = stats::rgamma(1, shape = 4, rate = 0.13),
      stats::rgamma(1, shape = 5, rate = 0.12)
    )
    # TP53 penalty for lung
    if (diagnoses[i] == "Lung adenocarcinoma" &&
        patient_ids[i] %in% tp53_patients) {
      base <- base * 0.7
    }
    max(6, min(60, round(base, 1)))
  }, numeric(1))

  os_status <- stats::rbinom(n_patients, 1, 0.60)  # ~40% censored

  pfs_months <- vapply(seq_len(n_patients), function(i) {
    pfs <- os_months[i] * stats::runif(1, 0.3, 0.8)
    max(3, min(36, round(pfs, 1)))
  }, numeric(1))

  pfs_status <- stats::rbinom(n_patients, 1, 0.50)  # ~50% censored

  survival <- tibble::tibble(
    patient_id = patient_ids,
    os_months  = os_months,
    os_status  = os_status,
    pfs_months = pfs_months,
    pfs_status = pfs_status
  )

  # ---- Assemble into molpath_db ----
  new_molpath_db(
    patients = patients,
    samples  = samples,
    variants = variants,
    reports  = reports,
    clinical = clinical,
    survival = survival
  )
}


# ---- Exported function: mp_example_files ----

#' Write synthetic example files to a directory
#'
#' Creates a set of realistic mock files that can be used to test the
#' \pkg{molpathR} import pipeline. Files include VCF, XML, text-based
#' PDF-like reports, a survival CSV, and a tiny FASTQ file.
#'
#' @param dir Character. Directory where files are written.
#'   Default \code{tempdir()}.
#' @param seed Integer. Random seed for reproducibility. Default \code{42}.
#'
#' @return A named list of file paths:
#'   \describe{
#'     \item{vcf}{Character vector of 5 VCF file paths.}
#'     \item{xml}{Character vector of 5 XML report file paths.}
#'     \item{pdf}{Character vector of 5 text-based mock PDF report paths.}
#'     \item{survival}{Path to the survival CSV file.}
#'     \item{fastq}{Path to the sample FASTQ file.}
#'   }
#'
#' @examples
#' \donttest{
#' files <- mp_example_files()
#' readLines(files$vcf[1], n = 5)
#' }
#'
#' @export
mp_example_files <- function(dir = tempdir(), seed = 42) {

  set.seed(seed)

  bases <- c("A", "T", "G", "C")

  # ---- helper directories ----
  vcf_dir  <- file.path(dir, "vcf")
  xml_dir  <- file.path(dir, "xml")
  pdf_dir  <- file.path(dir, "pdf")
  ngs_dir  <- file.path(dir, "ngs")

  for (d in c(vcf_dir, xml_dir, pdf_dir, ngs_dir)) {
    if (!dir.exists(d)) dir.create(d, recursive = TRUE)
  }

  # ---- sample identifiers ----
  sample_ids <- sprintf("SAM-2024-%04d", 1:5)

  gene_pool <- c("TP53", "KRAS", "EGFR", "BRAF", "PIK3CA", "BRCA1",
                  "ALK", "PTEN", "MET", "ERBB2")
  gene_chr <- c(
    TP53 = "17", KRAS = "12", EGFR = "7", BRAF = "7", PIK3CA = "3",
    BRCA1 = "17", ALK = "2", PTEN = "10", MET = "7", ERBB2 = "17"
  )

  # ---- VCF files ----
  vcf_paths <- vapply(seq_along(sample_ids), function(i) {
    n_var <- sample(8:15, 1)
    genes <- sample(gene_pool, n_var, replace = TRUE)
    chroms <- gene_chr[genes]
    positions <- sample(1e6:2e8, n_var)
    refs <- sample(bases, n_var, replace = TRUE)
    alts <- vapply(refs, function(r) sample(setdiff(bases, r), 1),
                   character(1))
    quals <- sample(30:200, n_var, replace = TRUE)

    header <- c(
      "##fileformat=VCFv4.2",
      paste0("##source=molpathR_synthetic_v0.1"),
      paste0("##reference=GRCh38"),
      '##INFO=<ID=DP,Number=1,Type=Integer,Description="Total Depth">',
      '##INFO=<ID=AF,Number=A,Type=Float,Description="Allele Frequency">',
      '##INFO=<ID=GENE,Number=1,Type=String,Description="Gene Symbol">',
      '##FORMAT=<ID=GT,Number=1,Type=String,Description="Genotype">',
      paste0("#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\t",
             sample_ids[i])
    )

    data_lines <- vapply(seq_len(n_var), function(j) {
      dp <- sample(50:500, 1)
      af <- round(stats::rbeta(1, 2, 5), 3)
      gt <- sample(c("0/1", "1/1"), 1, prob = c(0.75, 0.25))
      paste0("chr", chroms[j], "\t", positions[j], "\t.\t",
             refs[j], "\t", alts[j], "\t", quals[j], "\tPASS\t",
             "DP=", dp, ";AF=", af, ";GENE=", genes[j], "\tGT\t", gt)
    }, character(1))

    fpath <- file.path(vcf_dir, paste0(sample_ids[i], ".vcf"))
    writeLines(c(header, data_lines), fpath)
    fpath
  }, character(1))

  # ---- XML reports ----
  xml_paths <- vapply(seq_along(sample_ids), function(i) {
    n_var <- sample(3:8, 1)
    genes <- sample(gene_pool, n_var, replace = TRUE)
    variants <- vapply(genes, function(g) generate_hgvs_variant(g, "SNV"),
                       character(1))
    class_pool <- c("Pathogenic", "Likely pathogenic", "VUS",
                    "Likely benign", "Benign")
    classes <- sample(class_pool, n_var, replace = TRUE,
                      prob = c(0.20, 0.15, 0.40, 0.15, 0.10))

    xml_lines <- c(
      '<?xml version="1.0" encoding="UTF-8"?>',
      '<MolecularReport>',
      paste0('  <Patient id="PAT-2024-', sprintf("%04d", i), '">'),
      paste0('    <Sample id="', sample_ids[i], '">'),
      paste0('      <AnalysisDate>', Sys.Date() - sample(30:365, 1),
             '</AnalysisDate>'),
      '      <Variants>'
    )

    for (j in seq_len(n_var)) {
      xml_lines <- c(xml_lines,
        '        <Variant>',
        paste0('          <Gene>', genes[j], '</Gene>'),
        paste0('          <HGVSp>', variants[j], '</HGVSp>'),
        paste0('          <Classification>', classes[j],
               '</Classification>'),
        paste0('          <VAF>', round(stats::rbeta(1, 2, 5), 3),
               '</VAF>'),
        '        </Variant>'
      )
    }

    xml_lines <- c(xml_lines,
      '      </Variants>',
      '    </Sample>',
      '  </Patient>',
      '</MolecularReport>'
    )

    fpath <- file.path(xml_dir, paste0(sample_ids[i], "_report.xml"))
    writeLines(xml_lines, fpath)
    fpath
  }, character(1))

  # ---- Mock PDF reports (text files) ----
  pdf_paths <- vapply(seq_along(sample_ids), function(i) {
    diag <- sample(c("Lung adenocarcinoma", "Colorectal carcinoma",
                      "Breast carcinoma", "Melanoma"), 1)
    n_var <- sample(2:6, 1)
    genes <- sample(gene_pool, n_var, replace = TRUE)
    variants <- vapply(genes, function(g) generate_hgvs_variant(g, "SNV"),
                       character(1))
    class_pool <- c("Pathogenic", "Likely pathogenic", "VUS",
                    "Likely benign", "Benign")
    classes <- sample(class_pool, n_var, replace = TRUE)

    lines <- c(
      "============================================================",
      "         MOLECULAR PATHOLOGY REPORT",
      "============================================================",
      "",
      paste0("Patient ID:    PAT-2024-", sprintf("%04d", i)),
      paste0("Sample ID:     ", sample_ids[i]),
      paste0("Diagnosis:     ", diag),
      paste0("Report Date:   ", Sys.Date() - sample(10:200, 1)),
      paste0("Ordering MD:   Dr. ", sample(c("Mueller", "Schmidt",
        "Weber", "Fischer", "Meyer"), 1)),
      "",
      "------------------------------------------------------------",
      "VARIANT SUMMARY",
      "------------------------------------------------------------",
      ""
    )

    for (j in seq_len(n_var)) {
      lines <- c(lines,
        paste0("  Gene:           ", genes[j]),
        paste0("  Variant:        ", variants[j]),
        paste0("  Classification: ", classes[j]),
        paste0("  VAF:            ", round(stats::rbeta(1, 2, 5) * 100, 1),
               "%"),
        ""
      )
    }

    lines <- c(lines,
      "------------------------------------------------------------",
      "INTERPRETATION",
      "------------------------------------------------------------",
      "",
      "Somatic variant analysis was performed using a comprehensive",
      "NGS panel covering 500+ cancer-relevant genes. Variants were",
      "classified according to AMP/ASCO/CAP guidelines.",
      "",
      "Signed: Prof. Dr. med. Example Pathologist",
      "Institute for Molecular Pathology",
      "============================================================"
    )

    fpath <- file.path(pdf_dir, paste0(sample_ids[i], "_report.txt"))
    writeLines(lines, fpath)
    fpath
  }, character(1))

  # ---- Survival CSV ----
  surv_n <- 30
  surv_df <- data.frame(
    patient_id = sprintf("PAT-2024-%04d", seq_len(surv_n)),
    os_months  = round(stats::rgamma(surv_n, shape = 5, rate = 0.12), 1),
    os_status  = stats::rbinom(surv_n, 1, 0.60),
    pfs_months = round(stats::rgamma(surv_n, shape = 4, rate = 0.15), 1),
    pfs_status = stats::rbinom(surv_n, 1, 0.50),
    stringsAsFactors = FALSE
  )
  surv_df$os_months  <- pmin(60, pmax(6, surv_df$os_months))
  surv_df$pfs_months <- pmin(36, pmax(3, surv_df$pfs_months))

  surv_path <- file.path(dir, "survival.csv")
  utils::write.csv(surv_df, surv_path, row.names = FALSE)

  # ---- Tiny FASTQ (100 reads, 150bp) ----
  fastq_lines <- character(400)
  for (r in seq_len(100)) {
    idx <- (r - 1) * 4
    seq_str <- paste0(sample(bases, 150, replace = TRUE), collapse = "")
    qual_str <- paste0(
      sample(c("!", "#", "$", "%", "&", "(", ")", "*", "+", ",", "-", ".",
               "/", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", ":",
               ";", "<", "=", ">", "?", "@", "A", "B", "C", "D", "E", "F",
               "G", "H", "I"),
             150, replace = TRUE, prob = NULL), collapse = "")
    fastq_lines[idx + 1] <- paste0("@SYNTH:", r, ":FLOWCELL:1:1101:",
                                    sample(1000:9999, 1), ":",
                                    sample(1000:9999, 1), " 1:N:0:ATCACG")
    fastq_lines[idx + 2] <- seq_str
    fastq_lines[idx + 3] <- "+"
    fastq_lines[idx + 4] <- qual_str
  }

  fastq_path <- file.path(ngs_dir, "sample.fastq")
  writeLines(fastq_lines, fastq_path)

  # ---- Return paths ----
  list(
    vcf      = vcf_paths,
    xml      = xml_paths,
    pdf      = pdf_paths,
    survival = surv_path,
    fastq    = fastq_path
  )
}
