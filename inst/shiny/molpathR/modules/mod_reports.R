# Module: Reports (Tab 4)

mod_reports_ui <- function(id) {
  ns <- shiny::NS(id)
  bslib::layout_sidebar(
    sidebar = bslib::sidebar(
      title = "Filters",
      shinyWidgets::pickerInput(ns("report_type_filter"), "Report Type",
        choices = NULL, multiple = TRUE,
        options = shinyWidgets::pickerOptions(actionsBox = TRUE)
      ),
      shiny::dateRangeInput(ns("date_range"), "Date Range",
        start = "2021-01-01", end = Sys.Date()
      ),
      shiny::textInput(ns("patient_search"), "Patient ID", placeholder = "PAT-2024-...")
    ),
    DT::dataTableOutput(ns("report_table")),
    shiny::hr(),
    shiny::uiOutput(ns("report_detail"))
  )
}

mod_reports_server <- function(id, shared) {
  shiny::moduleServer(id, function(input, output, session) {

    shiny::observe({
      db <- shared$db
      shiny::req(db)
      types <- sort(unique(db$reports$report_type))
      shinyWidgets::updatePickerInput(session, "report_type_filter",
        choices = types, selected = types
      )
      if (nrow(db$reports) > 0 && "report_date" %in% names(db$reports)) {
        dr <- range(db$reports$report_date, na.rm = TRUE)
        shiny::updateDateRangeInput(session, "date_range", start = dr[1], end = dr[2])
      }
    })

    filtered_reports <- shiny::reactive({
      db <- shared$db
      shiny::req(db)
      reps <- db$reports

      # Filter by selected patient
      if (!is.null(shared$selected_patient)) {
        sids <- db$samples$sample_id[db$samples$patient_id == shared$selected_patient]
        reps <- dplyr::filter(reps, .data$sample_id %in% sids)
      }

      if (!is.null(input$report_type_filter) && length(input$report_type_filter) > 0) {
        reps <- dplyr::filter(reps, .data$report_type %in% input$report_type_filter)
      }
      if ("report_date" %in% names(reps)) {
        reps <- dplyr::filter(reps,
          .data$report_date >= input$date_range[1],
          .data$report_date <= input$date_range[2]
        )
      }
      if (nchar(input$patient_search) > 0) {
        pat_sids <- db$samples$sample_id[
          grepl(input$patient_search, db$samples$patient_id, ignore.case = TRUE)
        ]
        reps <- dplyr::filter(reps, .data$sample_id %in% pat_sids)
      }
      reps
    })

    output$report_table <- DT::renderDataTable({
      DT::datatable(
        filtered_reports(),
        selection = "single",
        options = list(pageLength = 15, scrollX = TRUE),
        rownames = FALSE
      )
    })

    output$report_detail <- shiny::renderUI({
      sel <- input$report_table_rows_selected
      shiny::req(sel)
      report <- filtered_reports()[sel, ]
      bslib::card(
        bslib::card_header(paste("Report:", report$report_type)),
        bslib::card_body(
          shiny::tags$p(shiny::tags$strong("Sample: "), report$sample_id),
          shiny::tags$p(shiny::tags$strong("Date: "), as.character(report$report_date)),
          shiny::tags$hr(),
          shiny::tags$pre(
            style = "white-space: pre-wrap; max-height: 400px; overflow-y: auto;",
            report$summary_text
          )
        )
      )
    })
  })
}
