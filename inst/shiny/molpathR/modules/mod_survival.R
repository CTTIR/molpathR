# Module: Survival (Tab 5)

mod_survival_ui <- function(id) {
  ns <- shiny::NS(id)
  bslib::layout_sidebar(
    sidebar = bslib::sidebar(
      title = "Settings",
      shiny::radioButtons(ns("surv_type"), "Survival type",
        choices = c("Overall Survival" = "os", "Progression-Free" = "pfs"),
        selected = "os"
      ),
      shinyWidgets::pickerInput(ns("group_var"), "Stratify by",
        choices = c("None" = "none", "Diagnosis" = "diagnosis", "Sex" = "sex"),
        selected = "none"
      ),
      shiny::textInput(ns("gene_stratify"), "Stratify by gene",
        placeholder = "e.g., TP53"
      ),
      shiny::downloadButton(ns("download_plot"), "Download Plot (PNG)",
        class = "btn-outline-secondary btn-sm"
      ),
      shiny::downloadButton(ns("download_data"), "Download Data (CSV)",
        class = "btn-outline-secondary btn-sm"
      )
    ),
    shiny::p("Survival uses the full cohort with available outcome and grouping values. Patient selection does not restrict this analysis."),
    shiny::p("Gene groups describe recorded variants. No recorded variant does not establish a negative assay or wild-type genotype."),
    plotly::plotlyOutput(ns("surv_plot"), height = "500px"),
    shiny::br(),
    shiny::verbatimTextOutput(ns("surv_stats"))
  )
}

mod_survival_server <- function(id, shared) {
  shiny::moduleServer(id, function(input, output, session) {

    shiny::observe({
      db <- shared$db
      shiny::req(db)
      # Add gene options from variants
      genes <- sort(unique(db$variants$gene))
      patient_cols <- intersect(c("diagnosis", "sex"), names(db$patients))
      choices <- c("None" = "none", stats::setNames(patient_cols, tools::toTitleCase(patient_cols)))
      shinyWidgets::updatePickerInput(session, "group_var", choices = choices)
    })

    # Clear a propagated value when its selection disappears, while preserving
    # a later manual edit. A replacement database always starts a fresh query.
    propagated_gene <- shiny::reactiveVal(NULL)
    shiny::observeEvent(shared$db, {
      propagated_gene(NULL)
      shiny::updateTextInput(session, "gene_stratify", value = "")
    }, priority = 100, ignoreNULL = FALSE)
    shiny::observeEvent(shared$selected_gene, {
      selected <- shared$selected_gene
      previous <- propagated_gene()
      if (!is.null(selected)) {
        shiny::updateTextInput(session, "gene_stratify", value = selected)
      } else if (!is.null(previous) && identical(input$gene_stratify, previous)) {
        shiny::updateTextInput(session, "gene_stratify", value = "")
      }
      propagated_gene(selected)
    }, ignoreNULL = FALSE)

    surv_group <- shiny::reactive({
      shiny::req(!is.null(input$gene_stratify), !is.null(input$group_var))
      gene_input <- trimws(input$gene_stratify)
      if (nchar(gene_input) > 0) {
        return(gene_input)
      }
      if (input$group_var != "none") {
        return(input$group_var)
      }
      NULL
    })

    surv_plot_obj <- shiny::reactive({
      db <- shared$db
      shiny::req(db, nrow(db$survival) > 0)
      app_plot(molpathR::mp_plot_survival(db, group_by = surv_group(), type = input$surv_type))
    })

    output$surv_plot <- plotly::renderPlotly({
      plotly::ggplotly(surv_plot_obj())
    })

    output$surv_stats <- shiny::renderPrint({
      p <- surv_plot_obj()
      fit <- attr(p, "molpath_survival_fit")
      surv_df <- attr(p, "molpath_survival_data")
      cat("Analysis records:", nrow(surv_df), "\n")
      cat("Events:", sum(surv_df$status == 1), "\n")
      cat("Survival summary (median in months):\n")
      print(summary(fit)$table)
    })

    output$download_plot <- shiny::downloadHandler(
      filename = function() paste0("survival_", input$surv_type, "_", Sys.Date(), ".png"),
      content = function(file) {
        ggplot2::ggsave(file, plot = surv_plot_obj(), width = 8, height = 6, dpi = 150)
      }
    )

    output$download_data <- shiny::downloadHandler(
      filename = function() paste0("survival_data_", Sys.Date(), ".csv"),
      content = function(file) {
        utils::write.csv(attr(surv_plot_obj(), "molpath_survival_data"), file, row.names = FALSE)
      }
    )
  })
}
