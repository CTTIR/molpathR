# plots.R
# Visualization functions for molpath_db objects
# ------------------------------------------------

# ---- Internal helpers --------------------------------------------------------

#' @noRd
theme_molpath <- function() {
  ggplot2::theme_minimal() +
    ggplot2::theme(
      plot.title = ggplot2::element_text(face = "bold", size = 14),
      plot.subtitle = ggplot2::element_text(size = 10, colour = "grey50"),
      legend.position = "bottom",
      panel.grid.minor = ggplot2::element_blank()
    )
}

#' @noRd
mp_classification_colors <- function() {
  c(
    "Pathogenic"        = "#D32F2F",
    "Likely pathogenic" = "#F57C00",
    "VUS"               = "#FBC02D",
    "Likely benign"     = "#64B5F6",
    "Benign"            = "#1976D2"
  )
}

#' @noRd
mp_diagnosis_colors <- function() {
  c(
    "Lung adenocarcinoma"  = "#7B2D8E",
    "Colorectal carcinoma" = "#2196F3",
    "Breast carcinoma"     = "#E91E63",
    "Melanoma"             = "#FF9800"
  )
}

# ---- Variant landscape -------------------------------------------------------

#' Plot variant landscape (oncoplot)
#'
#' Creates a tile plot showing variant classifications across samples and genes.
#'
#' @param db A `molpath_db` object.
#' @param genes Character vector of genes to display. If `NULL`, the top
#'   `top_n` most frequently mutated genes are shown.
#' @param top_n Integer. Number of top genes to show when `genes` is `NULL`.
#'
#' @return A [ggplot2::ggplot] object.
#' @export
#'
#' @examples
#' \donttest{
#' db <- mp_example_db(n_patients = 20, seed = 1)
#' mp_plot_variant_landscape(db, top_n = 10)
#' }
mp_plot_variant_landscape <- function(db, genes = NULL, top_n = 20) {
  if (!inherits(db, "molpath_db")) {
    rlang::abort("`db` must be a molpath_db object.")
  }
  vars <- db$variants
  if (nrow(vars) == 0L) {
    rlang::abort("No variants in the database to plot.")
  }

  if (is.null(genes)) {
    gene_freq <- sort(table(vars$gene), decreasing = TRUE)
    genes <- names(utils::head(gene_freq, top_n))
  }

  # Link variants to patients via samples
  plot_data <- dplyr::inner_join(
    dplyr::filter(vars, .data$gene %in% genes),
    db$samples[, c("sample_id", "patient_id")],
    by = "sample_id"
  )

  # Keep most severe classification per patient-gene pair
  class_order <- c("Pathogenic", "Likely pathogenic", "VUS", "Likely benign", "Benign")
  plot_data$classification <- factor(plot_data$classification, levels = class_order)

  plot_data <- dplyr::arrange(plot_data, .data$classification)
  plot_data <- dplyr::distinct(plot_data, .data$patient_id, .data$gene, .keep_all = TRUE)

  # Order genes by frequency
  plot_data$gene <- factor(plot_data$gene, levels = rev(genes))

  ggplot2::ggplot(plot_data, ggplot2::aes(
    x = .data$patient_id,
    y = .data$gene,
    fill = .data$classification
  )) +
    ggplot2::geom_tile(colour = "white", linewidth = 0.3) +
    ggplot2::scale_fill_manual(
      values = mp_classification_colors(),
      drop = FALSE,
      name = "Classification"
    ) +
    ggplot2::labs(
      title = "Variant Landscape",
      x = "Patient",
      y = "Gene"
    ) +
    theme_molpath() +
    ggplot2::theme(
      axis.text.x = ggplot2::element_text(angle = 90, hjust = 1, size = 5),
      panel.grid = ggplot2::element_blank()
    )
}

# ---- Mutation spectrum -------------------------------------------------------

#' Plot mutation spectrum
#'
#' Bar chart of SNV substitution types (C>A, C>G, C>T, T>A, T>C, T>G).
#'
#' @param db A `molpath_db` object.
#' @param sample_id Optional character vector of sample IDs to include.
#'   If `NULL`, aggregate across all samples.
#'
#' @return A [ggplot2::ggplot] object.
#' @export
#'
#' @examples
#' \donttest{
#' db <- mp_example_db(n_patients = 20, seed = 1)
#' mp_plot_mutation_spectrum(db)
#' }
mp_plot_mutation_spectrum <- function(db, sample_id = NULL) {
  if (!inherits(db, "molpath_db")) {
    rlang::abort("`db` must be a molpath_db object.")
  }
  vars <- db$variants
  if (!is.null(sample_id)) {
    vars <- dplyr::filter(vars, .data$sample_id %in% sample_id)
  }

  # Extract ref/alt if columns exist; otherwise try to parse from variant string
  if (all(c("ref_allele", "alt_allele") %in% names(vars))) {
    snvs <- dplyr::filter(vars,
      nchar(.data$ref_allele) == 1L,
      nchar(.data$alt_allele) == 1L,
      .data$ref_allele %in% c("A", "C", "G", "T"),
      .data$alt_allele %in% c("A", "C", "G", "T"),
      .data$ref_allele != .data$alt_allele
    )
    ref <- snvs$ref_allele
    alt <- snvs$alt_allele
  } else {
    # Attempt parse from variant column like c.123A>T
    pattern <- "([ACGT])>([ACGT])"
    idx <- stringr::str_detect(vars$variant, pattern)
    idx[is.na(idx)] <- FALSE
    snvs <- vars[idx, ]
    m <- stringr::str_match(snvs$variant, pattern)
    ref <- m[, 2]
    alt <- m[, 3]
  }

  if (length(ref) == 0L) {
    rlang::abort("No SNVs with parseable ref/alt alleles found.")
  }

  # Pyrimidine context: complement purines
  complement <- c(A = "T", T = "A", C = "G", G = "C")
  is_purine <- ref %in% c("A", "G")
  ref2 <- ifelse(is_purine, complement[ref], ref)
  alt2 <- ifelse(is_purine, complement[alt], alt)

  sub_type <- paste0(ref2, ">", alt2)

  # Standard order
  std_types <- c("C>A", "C>G", "C>T", "T>A", "T>C", "T>G")
  cosmic_colors <- c(
    "C>A" = "#1EBFF0",
    "C>G" = "#050708",
    "C>T" = "#E62725",
    "T>A" = "#CBCACB",
    "T>C" = "#A1CF64",
    "T>G" = "#EDC8C5"
  )

  counts <- table(factor(sub_type, levels = std_types))
  df <- tibble::tibble(
    substitution = factor(names(counts), levels = std_types),
    count = as.integer(counts)
  )

  ggplot2::ggplot(df, ggplot2::aes(
    x = .data$substitution,
    y = .data$count,
    fill = .data$substitution
  )) +
    ggplot2::geom_col(show.legend = FALSE) +
    ggplot2::scale_fill_manual(values = cosmic_colors) +
    ggplot2::labs(
      title = "Mutation Spectrum",
      x = "Substitution type",
      y = "Count"
    ) +
    theme_molpath()
}

# ---- Survival ----------------------------------------------------------------

#' Plot Kaplan-Meier survival curves
#'
#' Creates Kaplan-Meier curves from the survival table. Optionally stratifies
#' by a clinical variable or gene mutation status.
#'
#' @param db A `molpath_db` object.
#' @param group_by Optional character string. If it matches a column in the
#'   patients table (e.g., `"diagnosis"`), stratify by that variable. If it
#'   matches a gene name present in the variants table, stratify into
#'   "Mutated" vs "Wild-type".
#' @param type Character; `"os"` for overall survival or `"pfs"` for
#'   progression-free survival.
#'
#' @return A [ggplot2::ggplot] object.
#' @export
#'
#' @examples
#' \donttest{
#' db <- mp_example_db(n_patients = 50, seed = 1)
#' mp_plot_survival(db, type = "os")
#' mp_plot_survival(db, group_by = "diagnosis", type = "os")
#' }
mp_plot_survival <- function(db, group_by = NULL, type = c("os", "pfs")) {
  if (!inherits(db, "molpath_db")) {
    rlang::abort("`db` must be a molpath_db object.")
  }
  type <- match.arg(type)
  surv_data <- db$survival
  if (nrow(surv_data) == 0L) {
    rlang::abort("No survival data in the database.")
  }

  time_col <- if (type == "os") "os_months" else "pfs_months"
  status_col <- if (type == "os") "os_status" else "pfs_status"

  # Build plot data
  plot_df <- surv_data[, c("patient_id", time_col, status_col)]
  names(plot_df)[2:3] <- c("time", "status")
  plot_df <- dplyr::filter(plot_df, !is.na(.data$time), !is.na(.data$status))

  if (nrow(plot_df) == 0L) {
    rlang::abort("No valid survival data after removing NAs.")
  }

  # Determine grouping
  has_group <- FALSE
  if (!is.null(group_by)) {
    if (group_by %in% names(db$patients)) {
      grp <- db$patients[, c("patient_id", group_by)]
      plot_df <- dplyr::inner_join(plot_df, grp, by = "patient_id")
      names(plot_df)[names(plot_df) == group_by] <- "group"
      has_group <- TRUE
    } else {
      # Treat as gene name
      gene_patients <- character()
      if (nrow(db$variants) > 0L && nrow(db$samples) > 0L) {
        var_sids <- unique(dplyr::filter(db$variants, .data$gene == group_by)$sample_id)
        gene_patients <- unique(db$samples$patient_id[db$samples$sample_id %in% var_sids])
      }
      plot_df$group <- ifelse(
        plot_df$patient_id %in% gene_patients,
        paste0(group_by, " Mutated"),
        paste0(group_by, " Wild-type")
      )
      has_group <- TRUE
    }
  }

  # Check group count before fitting

  if (has_group && length(unique(plot_df$group)) < 2L) {
    cli::cli_warn("Only one group found for {.val {group_by}}. Plotting without stratification.")
    has_group <- FALSE
  }

  # Fit survival model
  if (has_group) {
    fit <- survival::survfit(survival::Surv(time, status) ~ group, data = plot_df)
  } else {
    fit <- survival::survfit(survival::Surv(time, status) ~ 1, data = plot_df)
  }

  # Convert survfit to data frame for ggplot
  surv_df <- .survfit_to_df(fit)

  # Base plot
  type_label <- if (type == "os") "Overall Survival" else "Progression-Free Survival"

  p <- ggplot2::ggplot(surv_df, ggplot2::aes(
    x = .data$time,
    y = .data$surv
  ))

  if (has_group) {
    p <- p +
      ggplot2::geom_step(ggplot2::aes(colour = .data$strata), linewidth = 1) +
      ggplot2::scale_colour_brewer(palette = "Set1", name = "Group")

    # Log-rank test
    sdiff <- survival::survdiff(survival::Surv(time, status) ~ group, data = plot_df)
    pval <- stats::pchisq(sdiff$chisq, length(sdiff$n) - 1L, lower.tail = FALSE)
    pval_label <- if (pval < 0.001) "p < 0.001" else paste0("p = ", round(pval, 3))
    p <- p + ggplot2::annotate(
      "text", x = max(surv_df$time) * 0.7, y = 0.95,
      label = paste("Log-rank:", pval_label),
      hjust = 0, size = 3.5
    )
  } else {
    p <- p + ggplot2::geom_step(colour = "#7B2D8E", linewidth = 1)
  }

  p +
    ggplot2::labs(
      title = type_label,
      x = "Time (months)",
      y = "Survival probability"
    ) +
    ggplot2::coord_cartesian(ylim = c(0, 1)) +
    theme_molpath()
}

#' Convert survfit object to data frame
#' @noRd
.survfit_to_df <- function(fit) {
  if (is.null(fit$strata)) {
    tibble::tibble(
      time   = c(0, fit$time),
      surv   = c(1, fit$surv),
      strata = "All"
    )
  } else {
    strata_names <- names(fit$strata)
    strata_sizes <- fit$strata
    strata_labels <- rep(strata_names, strata_sizes)
    # Clean labels
    strata_labels <- sub("^group=", "", strata_labels)

    df <- tibble::tibble(
      time   = fit$time,
      surv   = fit$surv,
      strata = strata_labels
    )
    # Add starting points
    starts <- tibble::tibble(
      time = 0,
      surv = 1,
      strata = unique(strata_labels)
    )
    dplyr::bind_rows(starts, df)
  }
}

# ---- Cohort overview ---------------------------------------------------------

#' Plot cohort overview
#'
#' Returns a list of four ggplot objects summarising the database:
#' diagnosis distribution, age by sex, sample types, and top mutated genes.
#' Arrange with `patchwork` or `cowplot` as needed.
#'
#' @param db A `molpath_db` object.
#'
#' @return A named list of four [ggplot2::ggplot] objects: `diagnosis`, `age`,
#'   `sample_types`, `top_genes`.
#' @export
#'
#' @examples
#' \donttest{
#' db <- mp_example_db(n_patients = 20, seed = 1)
#' plots <- mp_plot_cohort_overview(db)
#' plots$diagnosis
#' }
mp_plot_cohort_overview <- function(db) {
  if (!inherits(db, "molpath_db")) {
    rlang::abort("`db` must be a molpath_db object.")
  }

  # 1. Diagnosis distribution
  p_diag <- ggplot2::ggplot(db$patients, ggplot2::aes(
    x = stats::reorder(.data$diagnosis, .data$diagnosis, function(x) -length(x)),
    fill = .data$diagnosis
  )) +
    ggplot2::geom_bar(show.legend = FALSE) +
    ggplot2::scale_fill_manual(values = mp_diagnosis_colors()) +
    ggplot2::labs(title = "Diagnosis Distribution", x = NULL, y = "Count") +
    theme_molpath() +
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 30, hjust = 1))

  # 2. Age distribution by sex
  p_age <- ggplot2::ggplot(db$patients, ggplot2::aes(
    x = .data$age, fill = .data$sex
  )) +
    ggplot2::geom_histogram(binwidth = 5, position = "dodge", alpha = 0.8) +
    ggplot2::scale_fill_manual(values = c("M" = "#5C6BC0", "F" = "#EC407A")) +
    ggplot2::labs(title = "Age Distribution", x = "Age", y = "Count", fill = "Sex") +
    theme_molpath()

  # 3. Sample type distribution
  p_sample <- ggplot2::ggplot(db$samples, ggplot2::aes(
    x = stats::reorder(.data$sample_type, .data$sample_type, function(x) -length(x))
  )) +
    ggplot2::geom_bar(fill = "#7B2D8E", alpha = 0.8) +
    ggplot2::labs(title = "Sample Types", x = NULL, y = "Count") +
    theme_molpath()

  # 4. Top 10 mutated genes
  gene_counts <- sort(table(db$variants$gene), decreasing = TRUE)
  top10 <- utils::head(gene_counts, 10L)
  gene_df <- tibble::tibble(
    gene  = factor(names(top10), levels = rev(names(top10))),
    count = as.integer(top10)
  )
  p_genes <- ggplot2::ggplot(gene_df, ggplot2::aes(
    x = .data$gene, y = .data$count
  )) +
    ggplot2::geom_col(fill = "#9B59B6", alpha = 0.85) +
    ggplot2::coord_flip() +
    ggplot2::labs(title = "Top 10 Mutated Genes", x = NULL, y = "Variant count") +
    theme_molpath()

  list(
    diagnosis    = p_diag,
    age          = p_age,
    sample_types = p_sample,
    top_genes    = p_genes
  )
}

# ---- VAF distribution --------------------------------------------------------

#' Plot variant allele frequency distribution
#'
#' Histogram or density plot of variant allele frequencies (VAF), optionally
#' filtered by gene.
#'
#' @param db A `molpath_db` object.
#' @param gene Optional character vector of gene symbols to include.
#'
#' @return A [ggplot2::ggplot] object.
#' @export
#'
#' @examples
#' \donttest{
#' db <- mp_example_db(n_patients = 20, seed = 1)
#' mp_plot_vaf_distribution(db)
#' mp_plot_vaf_distribution(db, gene = "TP53")
#' }
mp_plot_vaf_distribution <- function(db, gene = NULL) {
  if (!inherits(db, "molpath_db")) {
    rlang::abort("`db` must be a molpath_db object.")
  }
  vars <- db$variants
  if (!is.null(gene)) {
    vars <- dplyr::filter(vars, .data$gene %in% gene)
  }
  if (nrow(vars) == 0L) {
    rlang::abort("No variants to plot.")
  }

  vars <- dplyr::filter(vars, !is.na(.data$vaf))

  if (!is.null(gene) && length(gene) > 1L) {
    p <- ggplot2::ggplot(vars, ggplot2::aes(x = .data$vaf, fill = .data$gene)) +
      ggplot2::geom_histogram(binwidth = 0.05, alpha = 0.7, position = "identity") +
      ggplot2::scale_fill_brewer(palette = "Set2", name = "Gene")
  } else {
    p <- ggplot2::ggplot(vars, ggplot2::aes(x = .data$vaf)) +
      ggplot2::geom_histogram(binwidth = 0.05, fill = "#7B2D8E", alpha = 0.8)
  }

  p +
    ggplot2::geom_vline(xintercept = 0.5, linetype = "dashed", colour = "grey50") +
    ggplot2::labs(
      title = "VAF Distribution",
      x = "Variant Allele Frequency",
      y = "Count"
    ) +
    theme_molpath()
}

# ---- Patient timeline --------------------------------------------------------

#' Plot patient timeline
#'
#' Displays a timeline of events for a single patient: sample collections,
#' report dates, and clinical measurements.
#'
#' @param db A `molpath_db` object.
#' @param patient_id A single patient ID.
#'
#' @return A [ggplot2::ggplot] object.
#' @export
#'
#' @examples
#' \donttest{
#' db <- mp_example_db(n_patients = 20, seed = 1)
#' pid <- db$patients$patient_id[1]
#' mp_plot_timeline(db, pid)
#' }
mp_plot_timeline <- function(db, patient_id) {
  if (!inherits(db, "molpath_db")) {
    rlang::abort("`db` must be a molpath_db object.")
  }
  pat <- mp_get_patient(db, patient_id)

  events <- tibble::tibble(
    date  = as.Date(character()),
    label = character(),
    type  = character()
  )

  # Samples
  if (nrow(pat$samples) > 0L && "date" %in% names(pat$samples)) {
    s <- tibble::tibble(
      date  = pat$samples$date,
      label = paste0("Sample: ", pat$samples$sample_type),
      type  = "Sample"
    )
    events <- dplyr::bind_rows(events, s)
  }

  # Reports
  if (nrow(pat$reports) > 0L && "report_date" %in% names(pat$reports)) {
    r <- tibble::tibble(
      date  = pat$reports$report_date,
      label = paste0("Report: ", pat$reports$report_type),
      type  = "Report"
    )
    events <- dplyr::bind_rows(events, r)
  }

  # Clinical
  if (nrow(pat$clinical) > 0L && "date" %in% names(pat$clinical)) {
    c_data <- tibble::tibble(
      date  = pat$clinical$date,
      label = pat$clinical$parameter,
      type  = "Clinical"
    )
    events <- dplyr::bind_rows(events, c_data)
  }

  if (nrow(events) == 0L) {
    rlang::abort("No timeline events found for this patient.")
  }

  events <- dplyr::filter(events, !is.na(.data$date))

  event_colors <- c(
    Sample   = "#7B2D8E",
    Report   = "#2196F3",
    Clinical = "#4CAF50"
  )

  ggplot2::ggplot(events, ggplot2::aes(
    x = .data$date,
    y = .data$type,
    colour = .data$type
  )) +
    ggplot2::geom_point(size = 4) +
    ggplot2::geom_text(
      ggplot2::aes(label = .data$label),
      vjust = -1, size = 2.5, show.legend = FALSE
    ) +
    ggplot2::scale_colour_manual(values = event_colors, name = "Event type") +
    ggplot2::labs(
      title = paste("Patient Timeline:", patient_id),
      x = "Date",
      y = NULL
    ) +
    theme_molpath()
}
