# Module: Patients (Tab 2)

mod_patients_ui <- function(id) {
  ns <- shiny::NS(id)
  bslib::layout_sidebar(
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
      ages <- range(db$patients$age, na.rm = TRUE)
      shiny::updateSliderInput(session, "age_range",
        min = floor(ages[1]), max = ceiling(ages[2]),
        value = c(floor(ages[1]), ceiling(ages[2]))
      )
    })

    filtered_patients <- shiny::reactive({
      db <- shared$db
      shiny::req(db)
      pts <- db$patients
      if (!is.null(input$diag_filter) && length(input$diag_filter) > 0) {
        pts <- dplyr::filter(pts, .data$diagnosis %in% input$diag_filter)
      }
      if (!is.null(input$sex_filter) && length(input$sex_filter) > 0) {
        pts <- dplyr::filter(pts, .data$sex %in% input$sex_filter)
      }
      pts <- dplyr::filter(pts,
        .data$age >= input$age_range[1],
        .data$age <= input$age_range[2]
      )
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

    # Patient detail on row click
    output$patient_detail <- shiny::renderUI({
      sel <- input$patient_table_rows_selected
      shiny::req(sel)
      db <- shared$db
      shiny::req(db)
      pid <- filtered_patients()$patient_id[sel]
      shared$selected_patient <- pid

      pat <- molpathR::mp_get_patient(db, pid)
      shiny::tagList(
        shiny::h4(paste("Patient:", pid)),
        bslib::layout_column_wrap(
          width = 1 / 2,
          bslib::card(
            bslib::card_header("Samples"),
            DT::renderDataTable(DT::datatable(pat$samples, options = list(dom = "t"), rownames = FALSE))
          ),
          bslib::card(
            bslib::card_header("Variants"),
            DT::renderDataTable(DT::datatable(pat$variants, options = list(dom = "tp", pageLength = 5), rownames = FALSE))
          )
        ),
        bslib::layout_column_wrap(
          width = 1 / 2,
          bslib::card(
            bslib::card_header("Clinical"),
            DT::renderDataTable(DT::datatable(pat$clinical, options = list(dom = "t"), rownames = FALSE))
          ),
          bslib::card(
            bslib::card_header("Survival"),
            DT::renderDataTable(DT::datatable(pat$survival, options = list(dom = "t"), rownames = FALSE))
          )
        )
      )
    })

    output$download_patients <- shiny::downloadHandler(
      filename = function() paste0("patients_", Sys.Date(), ".csv"),
      content = function(file) utils::write.csv(filtered_patients(), file, row.names = FALSE)
    )
  })
}
