# Module: Patients (Tab 2)

mod_patients_ui <- function(id) {
  ns <- shiny::NS(id)
  bslib::layout_sidebar(
    fillable = FALSE,
    sidebar = bslib::sidebar(
      title = "Filters",
      shinyWidgets::pickerInput(ns("diag_filter"), "Diagnosis",
        choices = NULL, multiple = TRUE,
        options = shinyWidgets::pickerOptions(actionsBox = TRUE)
      ),
      shinyWidgets::pickerInput(ns("sex_filter"), "Sex",
        choices = c("M", "F"), multiple = TRUE, selected = c("M", "F")
      ),
      shiny::sliderInput(ns("age_range"), "Age range",
        min = 0, max = 100, value = c(0, 100)
      ),
      shiny::checkboxInput(ns("include_missing"), "Include missing filter values", TRUE),
      shiny::actionButton(ns("clear_patient"), "Clear patient selection"),
      shiny::downloadButton(ns("download_patients"), "Download CSV",
        class = "btn-outline-secondary btn-sm"
      )
    ),
    DT::dataTableOutput(ns("patient_table")),
    shiny::hr(),
    shiny::uiOutput(ns("patient_detail"))
  )
}

mod_patients_server <- function(id, shared) {
  shiny::moduleServer(id, function(input, output, session) {

    # Update filter choices when db changes
    shiny::observe({
      db <- shared$db
      shiny::req(db)
      diags <- sort(unique(db$patients$diagnosis))
      shinyWidgets::updatePickerInput(session, "diag_filter",
        choices = diags, selected = diags
      )
      finite_ages <- db$patients$age[is.finite(db$patients$age)]
      ages <- if (length(finite_ages)) range(finite_ages) else c(0, 100)
      shiny::updateSliderInput(session, "age_range",
        min = floor(ages[1]), max = ceiling(ages[2]),
        value = c(floor(ages[1]), ceiling(ages[2]))
      )
    })

    filtered_patients <- shiny::reactive({
      db <- shared$db
      shiny::req(db)
      pts <- db$patients
      shiny::req(length(input$age_range) == 2L)
      missing <- isTRUE(input$include_missing)
      pts <- dplyr::filter(pts,
        .data$diagnosis %in% .env$input$diag_filter | (.env$missing & is.na(.data$diagnosis)),
        .data$sex %in% .env$input$sex_filter | (.env$missing & is.na(.data$sex)),
        (.data$age >= .env$input$age_range[1] & .data$age <= .env$input$age_range[2]) |
          (.env$missing & is.na(.data$age)))
      pts
    })

    output$patient_table <- DT::renderDataTable({
      DT::datatable(
        filtered_patients(),
        selection = "single",
        options = list(pageLength = 15, scrollX = TRUE),
        rownames = FALSE
      )
    })

    reset_patient <- function() {
      shared$selected_patient <- NULL
      shared$selected_gene <- NULL
      if (length(input$patient_table_rows_selected)) {
        DT::selectRows(DT::dataTableProxy("patient_table", session = session), NULL)
      }
    }
    shiny::observeEvent(list(shared$db, input$diag_filter, input$sex_filter, input$age_range, input$include_missing), {
      reset_patient()
    }, priority = 100)
    shiny::observeEvent(input$clear_patient, reset_patient())
    shiny::observeEvent(input$patient_table_rows_selected, {
      sel <- input$patient_table_rows_selected
      rows <- filtered_patients()
      shared$selected_patient <- if (length(sel) == 1L && is.finite(sel) && sel == floor(sel) &&
        sel >= 1L && sel <= nrow(rows)) rows$patient_id[[sel]] else NULL
    }, ignoreNULL = FALSE)
    patient_data <- shiny::reactive({
      shiny::req(shared$db, shared$selected_patient)
      molpathR::mp_get_patient(shared$db, shared$selected_patient)
    })
    output$patient_detail <- shiny::renderUI({
      shiny::req(shared$selected_patient)
      shiny::tagList(
        shiny::h4(paste("Patient:", shared$selected_patient)),
        shiny::p("This selection filters Variants and Reports. Survival uses the full cohort."),
        bslib::layout_column_wrap(width = 1 / 2,
          bslib::card(bslib::card_header("Samples"), DT::dataTableOutput(session$ns("detail_samples"))),
          bslib::card(bslib::card_header("Variants"), DT::dataTableOutput(session$ns("detail_variants"))),
          bslib::card(bslib::card_header("Clinical"), DT::dataTableOutput(session$ns("detail_clinical"))),
          bslib::card(bslib::card_header("Survival"), DT::dataTableOutput(session$ns("detail_survival")))
        )
      )
    })
    for (layer in c("samples", "variants", "clinical", "survival")) local({
      current_layer <- layer
      output[[paste0("detail_", current_layer)]] <- DT::renderDataTable({
        DT::datatable(patient_data()[[current_layer]], rownames = FALSE,
          options = list(pageLength = 5, scrollX = TRUE))
      })
    })

    output$download_patients <- shiny::downloadHandler(
      filename = function() paste0("patients_", Sys.Date(), ".csv"),
      content = function(file) app_download(utils::write.csv(
        app_flat_table(filtered_patients(), "patients"), file, row.names = FALSE))
    )
  })
}
