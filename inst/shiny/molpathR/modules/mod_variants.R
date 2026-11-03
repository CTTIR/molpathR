# Module: Variants (Tab 3)

mod_variants_ui <- function(id) {
  ns <- shiny::NS(id)
  bslib::layout_sidebar(
    sidebar = bslib::sidebar(
      title = "Filters",
      shinyWidgets::pickerInput(ns("gene_filter"), "Genes",
        choices = NULL, multiple = TRUE,
        options = shinyWidgets::pickerOptions(
          actionsBox = TRUE, liveSearch = TRUE, liveSearchPlaceholder = "Search genes..."
        )
      ),
      shinyWidgets::pickerInput(ns("class_filter"), "Classification",
        choices = c("Pathogenic", "Likely pathogenic", "VUS", "Likely benign", "Benign"),
        multiple = TRUE,
        selected = c("Pathogenic", "Likely pathogenic", "VUS", "Likely benign", "Benign"),
        options = shinyWidgets::pickerOptions(actionsBox = TRUE)
      ),
      shiny::sliderInput(ns("vaf_range"), "VAF range",
        min = 0, max = 1, value = c(0, 1), step = 0.01
      ),
      shiny::checkboxInput(ns("include_missing"), "Include missing filter values", TRUE),
      shiny::downloadButton(ns("download_variants"), "Download CSV",
        class = "btn-outline-secondary btn-sm"
      )
    ),
    shiny::uiOutput(ns("cohort_label")),
    bslib::navset_card_tab(
      bslib::nav_panel("Table",
        DT::dataTableOutput(ns("variant_table"))
      ),
      bslib::nav_panel("Landscape",
        plotly::plotlyOutput(ns("landscape_plot"), height = "500px")
      ),
      bslib::nav_panel("Mutation Spectrum",
        plotly::plotlyOutput(ns("spectrum_plot"), height = "400px")
      ),
      bslib::nav_panel("VAF Distribution",
        plotly::plotlyOutput(ns("vaf_plot"), height = "400px")
      )
    )
  )
}

mod_variants_server <- function(id, shared) {
  shiny::moduleServer(id, function(input, output, session) {

    shiny::observe({
      db <- shared$db
      shiny::req(db)
      genes <- sort(unique(db$variants$gene))
      shinyWidgets::updatePickerInput(session, "gene_filter",
        choices = genes, selected = genes
      )
    })

    filtered_variants <- shiny::reactive({
      db <- shared$db
      shiny::req(db)
      vars <- db$variants

      # If a patient is selected in the Patients tab, filter to that patient
      if (!is.null(shared$selected_patient)) {
        sids <- get_patient_sample_ids(db, shared$selected_patient)
        vars <- dplyr::filter(vars, .data$sample_id %in% .env$sids)
      }

      shiny::req(length(input$vaf_range) == 2L)
      missing <- isTRUE(input$include_missing)
      vars <- dplyr::filter(vars,
        .data$gene %in% .env$input$gene_filter | (.env$missing & is.na(.data$gene)),
        .data$classification %in% .env$input$class_filter | (.env$missing & is.na(.data$classification)),
        (.data$vaf >= .env$input$vaf_range[1] & .data$vaf <= .env$input$vaf_range[2]) |
          (.env$missing & is.na(.data$vaf)))
      vars
    })

    output$cohort_label <- shiny::renderUI({
      shiny::tags$p(if (is.null(shared$selected_patient)) "Cohort: all patients" else
        paste("Cohort: selected patient", shared$selected_patient),
        "— figures and CSV use the table filters.")
    })
    filtered_db <- shiny::reactive({
      db <- shared$db
      shiny::req(db)
      db$variants <- filtered_variants()
      shiny::validate(shiny::need(nrow(db$variants) > 0, "No variants match the current filters."))
      db
    })
    shiny::observeEvent(filtered_variants(), {
      shared$selected_gene <- NULL
      if (length(input$variant_table_rows_selected)) {
        DT::selectRows(DT::dataTableProxy("variant_table", session = session), NULL)
      }
    }, ignoreInit = TRUE, priority = 10)

    output$variant_table <- DT::renderDataTable({
      DT::datatable(
        filtered_variants(),
        selection = "single",
        options = list(pageLength = 15, scrollX = TRUE),
        rownames = FALSE
      )
    })

    output$landscape_plot <- plotly::renderPlotly({
      db <- filtered_db()
      p <- app_plot(molpathR::mp_plot_variant_landscape(db, top_n = 15))
      plotly::ggplotly(p, tooltip = c("x", "y", "fill"))
    })

    output$spectrum_plot <- plotly::renderPlotly({
      db <- filtered_db()
      p <- tryCatch(
        molpathR::mp_plot_mutation_spectrum(db),
        error = function(e) {
          ggplot2::ggplot() +
            ggplot2::annotate("text", x = 1, y = 1, label = conditionMessage(e)) +
            ggplot2::theme_void()
        }
      )
      plotly::ggplotly(p)
    })

    output$vaf_plot <- plotly::renderPlotly({
      db <- filtered_db()
      p <- app_plot(molpathR::mp_plot_vaf_distribution(db))
      plotly::ggplotly(p)
    })

    # Propagate gene selection to survival tab
    shiny::observeEvent(input$variant_table_rows_selected, {
      sel <- input$variant_table_rows_selected
      rows <- filtered_variants()
      shared$selected_gene <- if (length(sel) == 1L && is.finite(sel) && sel == floor(sel) &&
        sel >= 1L && sel <= nrow(rows)) rows$gene[[sel]] else NULL
    }, ignoreNULL = FALSE)

    output$download_variants <- shiny::downloadHandler(
      filename = function() paste0("variants_", Sys.Date(), ".csv"),
      content = function(file) app_download(utils::write.csv(
        app_flat_table(filtered_variants(), "variants"), file, row.names = FALSE))
    )
  })
}
