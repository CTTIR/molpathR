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

# Okabe-Ito colour-blind-safe qualitative palette, as reproduced in
# Wong B (2011) Points of view: Color blindness. Nature Methods 8(6), 441,
# Figure 2, p. 441. doi:10.1038/nmeth.1618. Reordered so that the
# low-contrast yellow is used last.
#' @noRd
mp_okabe_ito <- function() {
  c("#0072B2", "#D55E00", "#009E73", "#CC79A7", "#E69F00", "#56B4E9",
    "#000000", "#F0E442")
}

# Named fill values for `levels`: known levels keep their colour, other levels
# take unused Okabe-Ito colours (then hue colours) instead of the grey NA fill.
#' @noRd
.mp_level_colors <- function(levels, known = character()) {
  levels <- unique(levels[!is.na(levels)])
  out <- known[intersect(levels, names(known))]
  extra <- setdiff(levels, names(out))
  if (length(extra)) {
    pool <- setdiff(mp_okabe_ito(), out)
    if (length(extra) > length(pool)) {
      pool <- c(pool, grDevices::hcl(
        h = seq(15, 375, length.out = length(extra) - length(pool) + 1L)[-1L],
        c = 100, l = 65
      ))
    }
    out <- c(out, stats::setNames(pool[seq_along(extra)], extra))
  }
  out
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
#' db <- mp_example_db(n_patients = 20, seed = 1)
#' mp_plot_variant_landscape(db, top_n = 10)
mp_plot_variant_landscape <- function(db, genes = NULL, top_n = 20) {
  if (!inherits(db, "molpath_db")) {
    rlang::abort("`db` must be a molpath_db object.")
  }
  if (!is.numeric(top_n) || length(top_n) != 1L || !is.finite(top_n) ||
      top_n < 1 || top_n != floor(top_n)) {
    rlang::abort("`top_n` must be one positive integer.")
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
    dplyr::filter(vars, .data$gene %in% .env$genes),
    db$samples[, c("sample_id", "patient_id")],
    by = "sample_id"
  )

  if (nrow(plot_data) == 0L) {
    rlang::abort("No requested variants linked to patients are available to plot.")
  }

  # Unknown classifications stay visible without implying a known severity.
  class_order <- c("Pathogenic", "Likely pathogenic", "VUS", "Likely benign", "Benign")
  unknown <- is.na(plot_data$classification) | !plot_data$classification %in% class_order
  plot_data$classification[unknown] <- "Unclassified"
  plot_data$classification <- factor(plot_data$classification, levels = c(class_order, "Unclassified"))

  plot_data <- dplyr::arrange(plot_data, .data$classification)
  plot_data <- dplyr::distinct(plot_data, .data$patient_id, .data$gene, .keep_all = TRUE)
  # Show the "Unclassified" key only when such records are present.
  if (!any(plot_data$classification == "Unclassified")) {
    plot_data$classification <- factor(plot_data$classification, levels = class_order)
  }

  # Order genes by frequency
  plot_data$gene <- factor(plot_data$gene, levels = rev(genes))

  # Patient labels shrink with cohort size but stay legible.
  n_patients <- length(unique(plot_data$patient_id))
  x_size <- if (n_patients <= 25L) 8 else if (n_patients <= 50L) 7 else 6

  ggplot2::ggplot(plot_data, ggplot2::aes(
    x = .data$patient_id,
    y = .data$gene,
    fill = .data$classification
  )) +
    ggplot2::geom_tile(colour = "white", linewidth = 0.3) +
    ggplot2::scale_fill_manual(
      values = c(mp_classification_colors(), Unclassified = "#707070"),
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
      axis.text.x = ggplot2::element_text(angle = 90, hjust = 1, vjust = 0.5, size = x_size),
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
#' db <- mp_example_db(n_patients = 20, seed = 1)
#' mp_plot_mutation_spectrum(db)
mp_plot_mutation_spectrum <- function(db, sample_id = NULL) {
  if (!inherits(db, "molpath_db")) {
    rlang::abort("`db` must be a molpath_db object.")
  }
  vars <- db$variants
  if (!is.null(sample_id)) {
    vars <- dplyr::filter(vars, .data$sample_id %in% .env$sample_id)
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
#'   matches a gene name present in the variants table, stratify by presence
#'   of a recorded variant. Absence of a record does not establish a negative
#'   assay or wild-type genotype.
#' @param type Character; `"os"` for overall survival or `"pfs"` for
#'   progression-free survival.
#'
#' @return A [ggplot2::ggplot] object.
#' @export
#'
#' @examples
#' db <- mp_example_db(n_patients = 50, seed = 1)
#' mp_plot_survival(db, type = "os")
#' mp_plot_survival(db, group_by = "diagnosis", type = "os")
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

  # This database records variants, not gene-level assay coverage or negative calls.
  has_group <- FALSE
  gene_group <- FALSE
  if (!is.null(group_by)) {
    if (!is.character(group_by) || length(group_by) != 1L ||
        is.na(group_by) || !nzchar(group_by)) {
      rlang::abort("`group_by` must be NULL or one nonempty column/gene name.")
    }
    if (group_by %in% names(db$patients)) {
      grp <- tibble::tibble(patient_id = db$patients$patient_id,
                           group = db$patients[[group_by]])
      plot_df <- dplyr::inner_join(plot_df, grp, by = "patient_id")
      missing_group <- is.na(plot_df$group)
      if (any(missing_group)) {
        cli::cli_warn("Omitting {sum(missing_group)} survival records with missing group values.")
        plot_df <- plot_df[!missing_group, , drop = FALSE]
      }
      has_group <- TRUE
    } else {
      if (!group_by %in% db$variants$gene) {
        rlang::abort("No recorded variants for the requested gene; negative assay status is unknown.")
      }
      var_sids <- unique(dplyr::filter(db$variants, .data$gene == .env$group_by)$sample_id)
      gene_patients <- unique(db$samples$patient_id[db$samples$sample_id %in% var_sids])
      plot_df$group <- ifelse(
        plot_df$patient_id %in% gene_patients,
        paste0(group_by, ": recorded variant"),
        paste0(group_by, ": no recorded variant")
      )
      has_group <- TRUE
      gene_group <- TRUE
    }
  }
  if (nrow(plot_df) == 0L) {
    rlang::abort("No survival records with available grouping data.")
  }
  if (has_group && length(unique(plot_df$group)) < 2L) {
    cli::cli_warn("Only one group found for {.val {group_by}}. Plotting without stratification.")
    has_group <- FALSE
    gene_group <- FALSE
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

  censored <- surv_df[surv_df$n_censor > 0, , drop = FALSE]

  if (has_group) {
    p <- p +
      ggplot2::geom_step(ggplot2::aes(colour = .data$strata), linewidth = 1) +
      ggplot2::geom_point(
        data = censored, ggplot2::aes(colour = .data$strata),
        shape = 3, size = 2, show.legend = FALSE
      ) +
      ggplot2::scale_colour_manual(
        values = .mp_level_colors(sort(unique(surv_df$strata))),
        name = "Group"
      )

    # Log-rank test
    pval <- NA_real_
    if (any(plot_df$status == 1)) {
      sdiff <- survival::survdiff(survival::Surv(time, status) ~ group, data = plot_df)
      pval <- stats::pchisq(sdiff$chisq, length(sdiff$n) - 1L, lower.tail = FALSE)
    }
    pval_label <- if (!is.finite(pval)) "unavailable (no informative events)" else if (pval < 0.001) {
      "p < 0.001"
    } else paste0("p = ", round(pval, 3))
    # Bottom-left corner: Kaplan-Meier curves start at the top left, so this
    # area stays free of curves and censoring marks in most cohorts.
    p <- p + ggplot2::annotate(
      "text", x = 0, y = 0.02,
      label = paste("Log-rank:", pval_label),
      hjust = 0, vjust = 0, size = 3.5
    )
  } else {
    p <- p +
      ggplot2::geom_step(colour = "#7B2D8E", linewidth = 1) +
      ggplot2::geom_point(data = censored, colour = "#7B2D8E", shape = 3, size = 2)
  }

  p <- p +
    ggplot2::labs(
      title = type_label,
      subtitle = if (gene_group) "No recorded variant does not establish a negative assay or wild-type genotype." else NULL,
      caption = if (nrow(censored) > 0L) "+ censored observation" else NULL,
      x = "Time (months)",
      y = "Survival probability"
    ) +
    ggplot2::coord_cartesian(ylim = c(0, 1)) +
    theme_molpath()
  attr(p, "molpath_survival_data") <- plot_df
  attr(p, "molpath_survival_fit") <- fit
  p
}

#' Convert survfit object to data frame
#' @noRd
.survfit_to_df <- function(fit) {
  if (is.null(fit$strata)) {
    tibble::tibble(
      time     = c(0, fit$time),
      surv     = c(1, fit$surv),
      n_censor = c(0, fit$n.censor),
      strata   = "All"
    )
  } else {
    strata_names <- names(fit$strata)
    strata_sizes <- fit$strata
    strata_labels <- rep(strata_names, strata_sizes)
    # Clean labels
    strata_labels <- sub("^group=", "", strata_labels)

    df <- tibble::tibble(
      time     = fit$time,
      surv     = fit$surv,
      n_censor = fit$n.censor,
      strata   = strata_labels
    )
    # Add starting points
    starts <- tibble::tibble(
      time = 0,
      surv = 1,
      n_censor = 0,
      strata = sub("^group=", "", strata_names)
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
#' db <- mp_example_db(n_patients = 20, seed = 1)
#' plots <- mp_plot_cohort_overview(db)
#' plots$diagnosis
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
    ggplot2::scale_fill_manual(
      values = .mp_level_colors(db$patients$diagnosis, mp_diagnosis_colors()),
      na.value = "grey60"
    ) +
    ggplot2::labs(title = "Diagnosis Distribution", x = NULL, y = "Count") +
    theme_molpath() +
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 30, hjust = 1))

  # 2. Age distribution by sex
  p_age <- ggplot2::ggplot(db$patients, ggplot2::aes(
    x = .data$age, fill = .data$sex
  )) +
    ggplot2::geom_histogram(binwidth = 5, position = "dodge", alpha = 0.8) +
    ggplot2::scale_fill_manual(
      values = .mp_level_colors(db$patients$sex, c("M" = "#5C6BC0", "F" = "#EC407A")),
      na.value = "grey60"
    ) +
    ggplot2::labs(title = "Age Distribution", x = "Age (years)", y = "Count", fill = "Sex") +
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
#' Histogram of variant allele frequencies (VAF), optionally filtered by gene.
#' Bins are 0.05 wide and start at 0; the dashed line marks a VAF of 0.5.
#' When `gene` selects several genes, each gene gets its own panel.
#'
#' @param db A `molpath_db` object.
#' @param gene Optional character vector of gene symbols to include.
#'
#' @return A [ggplot2::ggplot] object.
#' @export
#'
#' @examples
#' db <- mp_example_db(n_patients = 20, seed = 1)
#' mp_plot_vaf_distribution(db)
#' mp_plot_vaf_distribution(db, gene = "TP53")
mp_plot_vaf_distribution <- function(db, gene = NULL) {
  if (!inherits(db, "molpath_db")) {
    rlang::abort("`db` must be a molpath_db object.")
  }
  vars <- db$variants
  if (!is.null(gene)) {
    vars <- dplyr::filter(vars, .data$gene %in% .env$gene)
  }
  if (nrow(vars) == 0L) {
    rlang::abort("No variants to plot.")
  }

  vars <- dplyr::filter(vars, !is.na(.data$vaf))
  if (nrow(vars) == 0L) rlang::abort("No measured VAF values to plot.")

  # Bins start at 0 so that no bar extends outside the [0, 1] proportion scale.
  p <- ggplot2::ggplot(vars, ggplot2::aes(x = .data$vaf)) +
    ggplot2::geom_histogram(
      binwidth = 0.05, boundary = 0, closed = "left",
      fill = "#7B2D8E", alpha = 0.8
    )
  if (!is.null(gene) && length(unique(vars$gene)) > 1L) {
    # One panel per gene: overlaid translucent histograms are hard to read.
    p <- p + ggplot2::facet_wrap(ggplot2::vars(.data$gene))
  }

  p +
    ggplot2::geom_vline(xintercept = 0.5, linetype = "dashed", colour = "grey50") +
    ggplot2::coord_cartesian(xlim = c(0, 1)) +
    ggplot2::labs(
      title = "VAF Distribution",
      x = "Variant allele frequency (proportion)",
      y = "Count"
    ) +
    theme_molpath() +
    # Keep the end labels of neighbouring panels ("1.00" and "0.00") apart.
    ggplot2::theme(panel.spacing.x = ggplot2::unit(1.5, "lines"))
}

# ---- Patient timeline --------------------------------------------------------

#' Plot patient timeline
#'
#' Displays a timeline of events for a single patient: sample collections,
#' report dates, and clinical measurements (with their values). Labels are
#' placed to the right of each event and moved to separate lanes where they
#' would otherwise overlap. Events without a date are omitted.
#'
#' @param db A `molpath_db` object.
#' @param patient_id A single patient ID.
#'
#' @return A [ggplot2::ggplot] object.
#' @export
#'
#' @examples
#' db <- mp_example_db(n_patients = 20, seed = 1)
#' pid <- db$patients$patient_id[1]
#' mp_plot_timeline(db, pid)
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
    clin_label <- pat$clinical$parameter
    has_value <- !is.na(pat$clinical$value) & nzchar(pat$clinical$value)
    clin_label[has_value] <- paste0(clin_label[has_value], ": ", pat$clinical$value[has_value])
    c_data <- tibble::tibble(
      date  = pat$clinical$date,
      label = clin_label,
      type  = "Clinical"
    )
    events <- dplyr::bind_rows(events, c_data)
  }

  if (nrow(events) == 0L) {
    rlang::abort("No timeline events found for this patient.")
  }

  events <- dplyr::filter(events, !is.na(.data$date))
  if (nrow(events) == 0L) {
    rlang::abort("No dated timeline events found for this patient.")
  }

  event_colors <- c(
    Sample   = "#7B2D8E",
    Report   = "#2196F3",
    Clinical = "#4CAF50"
  )
  events <- .mp_timeline_lanes(events, types = names(event_colors))
  n_types <- length(names(event_colors))

  ggplot2::ggplot(events, ggplot2::aes(
    x = .data$date,
    y = .data$y,
    colour = .data$type
  )) +
    ggplot2::geom_point(size = 3) +
    ggplot2::geom_text(
      ggplot2::aes(x = .data$label_x, label = .data$label),
      hjust = 0, size = 2.8, show.legend = FALSE
    ) +
    ggplot2::scale_colour_manual(values = event_colors, name = "Event type", drop = TRUE) +
    ggplot2::scale_x_date(expand = ggplot2::expansion(
      mult = c(0.03, attr(events, "label_room") + 0.03)
    )) +
    ggplot2::scale_y_continuous(
      breaks = seq_len(n_types), labels = names(event_colors),
      limits = c(0.5, n_types + 0.5), expand = ggplot2::expansion()
    ) +
    ggplot2::labs(
      title = paste("Patient Timeline:", patient_id),
      x = "Date",
      y = NULL
    ) +
    theme_molpath() +
    ggplot2::theme(panel.grid.major.y = ggplot2::element_blank())
}

#' Assign non-overlapping label lanes to timeline events
#'
#' Labels are drawn to the right of each point. Within one event type, an
#' event moves to the next free lane when its label would overlap the label of
#' an earlier event, so that every label stays readable.
#'
#' @param events Tibble with `date`, `label` and `type`.
#' @param types Event types in their display order (bottom to top).
#' @param char_frac Approximate width of one label character as a fraction of
#'   the date range at the default 7-inch figure width.
#' @return `events` with `y` and `label_x` columns and a `label_room`
#'   attribute (right-hand axis expansion needed for the longest label).
#' @noRd
.mp_timeline_lanes <- function(events, types, char_frac = 0.0095) {
  events <- events[order(match(events$type, types), events$date), , drop = FALSE]
  span <- as.numeric(diff(range(events$date)))
  if (!is.finite(span) || span <= 0) span <- 30
  gap <- span * 0.012
  width <- nchar(events$label) * char_frac * span + 2 * gap
  events$label_x <- events$date + gap
  events$y <- NA_real_
  for (type in unique(events$type)) {
    rows <- which(events$type == type)
    lane_end <- numeric()
    lane <- integer(length(rows))
    for (k in seq_along(rows)) {
      start <- as.numeric(events$date[rows[k]])
      free <- which(lane_end < start)
      lane[k] <- if (length(free)) free[1L] else length(lane_end) + 1L
      lane_end[lane[k]] <- start + width[rows[k]]
    }
    n_lanes <- max(lane)
    step <- min(0.22, 0.8 / max(n_lanes, 1L))
    centre <- match(type, types)
    events$y[rows] <- centre - (n_lanes - 1) * step / 2 + (lane - 1) * step
  }
  attr(events, "label_room") <- max(width) / span
  events
}
