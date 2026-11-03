# Module: Reports (Tab 4)

mod_reports_ui <- function(id) {
  ns <- shiny::NS(id)
  bslib::layout_sidebar(
    fillable = FALSE,
    sidebar = bslib::sidebar(
      title = "Filters",
      shinyWidgets::pickerInput(ns("report_type_filter"), "Report Type",
        choices = NULL, multiple = TRUE,
        options = shinyWidgets::pickerOptions(actionsBox = TRUE)
      ),
      shiny::dateRangeInput(ns("date_range"), "Date Range",
        start = "2021-01-01", end = Sys.Date()
      ),
      shiny::checkboxInput(ns("include_missing"), "Include missing filter values", TRUE),
      shiny::textInput(ns("patient_search"), "Patient ID", placeholder = "PAT-2024-...")
    ),
    shiny::uiOutput(ns("cohort_label")),
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
        dates <- db$reports$report_date[!is.na(db$reports$report_date)]
        if (length(dates)) {
          dr <- range(dates)
          shiny::updateDateRangeInput(session, "date_range", start = dr[1], end = dr[2])
        }
      }
    })

    filtered_reports <- shiny::reactive({
      db <- shared$db
      shiny::req(db)
      reps <- db$reports

      # Filter by selected patient
      if (!is.null(shared$selected_patient)) {
        sids <- get_patient_sample_ids(db, shared$selected_patient)
        reps <- dplyr::filter(reps, .data$sample_id %in% .env$sids)
      }

      missing <- isTRUE(input$include_missing)
      reps <- dplyr::filter(reps, .data$report_type %in% .env$input$report_type_filter |
        (.env$missing & is.na(.data$report_type)))
      if ("report_date" %in% names(reps)) {
        reps <- dplyr::filter(reps,
          (.data$report_date >= .env$input$date_range[1] & .data$report_date <= .env$input$date_range[2]) |
            (.env$missing & is.na(.data$report_date))
        )
      }
      if (!is.null(input$patient_search) && nzchar(input$patient_search)) {
        pat_sids <- db$samples$sample_id[
          grepl(tolower(input$patient_search), tolower(db$samples$patient_id), fixed = TRUE)
        ]
        reps <- dplyr::filter(reps, .data$sample_id %in% .env$pat_sids)
      }
      reps
    })

    output$cohort_label <- shiny::renderUI({
      shiny::tags$p(if (is.null(shared$selected_patient)) "Cohort: all patients" else
        paste("Cohort: selected patient", shared$selected_patient))
    })
    selected_report <- shiny::reactiveVal(NULL)
    shiny::observeEvent(filtered_reports(), {
      selected_report(NULL)
      if (length(input$report_table_rows_selected)) {
        DT::selectRows(DT::dataTableProxy("report_table", session = session), NULL)
      }
    }, ignoreInit = TRUE, priority = 10)
    shiny::observeEvent(input$report_table_rows_selected, {
      sel <- input$report_table_rows_selected
      rows <- filtered_reports()
      selected_report(if (length(sel) == 1L && is.finite(sel) && sel == floor(sel) && sel >= 1L &&
        sel <= nrow(rows)) rows[sel, ] else NULL)
    }, ignoreNULL = FALSE)

    output$report_table <- DT::renderDataTable({
      DT::datatable(
        filtered_reports(),
        selection = "single",
        options = list(pageLength = 15, scrollX = TRUE),
        rownames = FALSE
      )
    })

    output$report_detail <- shiny::renderUI({
      report <- selected_report()
      shiny::req(report)
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
