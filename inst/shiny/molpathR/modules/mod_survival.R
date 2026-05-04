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
      patient_cols <- setdiff(names(db$patients), "patient_id")
      choices <- c("None" = "none", stats::setNames(patient_cols, tools::toTitleCase(patient_cols)))
      shinyWidgets::updatePickerInput(session, "group_var", choices = choices)
    })

    # Use selected gene from variants tab
    shiny::observe({
      if (!is.null(shared$selected_gene)) {
        shiny::updateTextInput(session, "gene_stratify", value = shared$selected_gene)
      }
    })

    surv_group <- shiny::reactive({
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
      molpathR::mp_plot_survival(db, group_by = surv_group(), type = input$surv_type)
    })

    output$surv_plot <- plotly::renderPlotly({
      plotly::ggplotly(surv_plot_obj())
    })

    output$surv_stats <- shiny::renderPrint({
      db <- shared$db
      shiny::req(db, nrow(db$survival) > 0)
      type <- input$surv_type
      time_col <- if (type == "os") "os_months" else "pfs_months"
      status_col <- if (type == "os") "os_status" else "pfs_status"
      surv_df <- db$survival[, c(time_col, status_col)]
      names(surv_df) <- c("time", "status")
      surv_df <- surv_df[!is.na(surv_df$time) & !is.na(surv_df$status), ]
      fit <- survival::survfit(survival::Surv(time, status) ~ 1, data = surv_df)
      cat("Median survival:", round(summary(fit)$table["median"], 1), "months\n")
      cat("Events:", sum(surv_df$status == 1), "/", nrow(surv_df), "\n")
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
        shiny::req(shared$db)
        utils::write.csv(shared$db$survival, file, row.names = FALSE)
      }
    )
  })
}
