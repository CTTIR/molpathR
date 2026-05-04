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
      shiny::downloadButton(ns("download_variants"), "Download CSV",
        class = "btn-outline-secondary btn-sm"
      )
    ),
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
        sids <- db$samples$sample_id[db$samples$patient_id == shared$selected_patient]
        vars <- dplyr::filter(vars, .data$sample_id %in% sids)
      }

      if (!is.null(input$gene_filter) && length(input$gene_filter) > 0) {
        vars <- dplyr::filter(vars, .data$gene %in% input$gene_filter)
      }
      if (!is.null(input$class_filter) && length(input$class_filter) > 0) {
        vars <- dplyr::filter(vars, .data$classification %in% input$class_filter)
      }
      vars <- dplyr::filter(vars,
        .data$vaf >= input$vaf_range[1],
        .data$vaf <= input$vaf_range[2]
      )
      vars
    })

    output$variant_table <- DT::renderDataTable({
      DT::datatable(
        filtered_variants(),
        selection = "single",
        options = list(pageLength = 15, scrollX = TRUE),
        rownames = FALSE
      )
    })

    output$landscape_plot <- plotly::renderPlotly({
      db <- shared$db
      shiny::req(db, nrow(db$variants) > 0)
      p <- molpathR::mp_plot_variant_landscape(db, top_n = 15)
      plotly::ggplotly(p, tooltip = c("x", "y", "fill"))
    })

    output$spectrum_plot <- plotly::renderPlotly({
      db <- shared$db
      shiny::req(db, nrow(db$variants) > 0)
      p <- tryCatch(
        molpathR::mp_plot_mutation_spectrum(db),
        error = function(e) {
          ggplot2::ggplot() +
            ggplot2::annotate("text", x = 1, y = 1, label = "No SNV data available") +
            ggplot2::theme_void()
        }
      )
      plotly::ggplotly(p)
    })

    output$vaf_plot <- plotly::renderPlotly({
      db <- shared$db
      shiny::req(db, nrow(db$variants) > 0)
      p <- molpathR::mp_plot_vaf_distribution(db)
      plotly::ggplotly(p)
    })

    # Propagate gene selection to survival tab
    shiny::observeEvent(input$variant_table_rows_selected, {
      sel <- input$variant_table_rows_selected
      if (!is.null(sel)) {
        shared$selected_gene <- filtered_variants()$gene[sel]
      }
    })

    output$download_variants <- shiny::downloadHandler(
      filename = function() paste0("variants_", Sys.Date(), ".csv"),
      content = function(file) utils::write.csv(filtered_variants(), file, row.names = FALSE)
    )
  })
}
