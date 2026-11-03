# Module: Export (Tab 6)

mod_export_ui <- function(id) {
  ns <- shiny::NS(id)
  shiny::fluidRow(
    shiny::column(4,
      bslib::card(
        bslib::card_header("Select Data Layers"),
        bslib::card_body(
          shiny::checkboxGroupInput(ns("layers"), NULL,
            choices = c(
              "Patients"  = "patients",
              "Samples"   = "samples",
              "Variants"  = "variants",
              "Reports"   = "reports",
              "Clinical"  = "clinical",
              "Survival"  = "survival"
            ),
            selected = c("patients", "samples", "variants", "survival")
          ),
          shiny::hr(),
          shiny::radioButtons(ns("format"), "Export format",
            choices = c("CSV" = "csv", "TSV" = "tsv", "Excel (.xlsx)" = "xlsx", "RDS" = "rds"),
            selected = "csv"
          ),
          shiny::p("Exports contain the selected full database layers, independent of table filters. CSV/TSV require a zip executable; Excel requires writexl. Structured cells are JSON in CSV/TSV/Excel; RDS retains their R structures."),
          shiny::hr(),
          shiny::downloadButton(ns("download_export"), "Download Dataset",
            class = "btn-primary"
          )
        )
      )
    ),
    shiny::column(8,
      bslib::card(
        bslib::card_header("Preview"),
        bslib::card_body(
          shiny::uiOutput(ns("preview_info")),
          DT::dataTableOutput(ns("preview_table"))
        )
      )
    )
  )
}

mod_export_server <- function(id, shared) {
  shiny::moduleServer(id, function(input, output, session) {

    output$preview_info <- shiny::renderUI({
      db <- shared$db
      shiny::req(db)
      layers <- input$layers
      shiny::req(layers)
      info <- vapply(layers, function(l) nrow(db[[l]]), integer(1))
      shiny::tags$p(
        paste(
          paste0(tools::toTitleCase(names(info)), ": ", info, " rows"),
          collapse = " | "
        )
      )
    })

    output$preview_table <- DT::renderDataTable({
      db <- shared$db
      shiny::req(db)
      layers <- input$layers
      shiny::req(layers)
      # Show first selected layer as preview
      DT::datatable(
        utils::head(db[[layers[1]]], 50),
        options = list(pageLength = 10, scrollX = TRUE),
        rownames = FALSE,
        caption = paste("Preview:", tools::toTitleCase(layers[1]), "(first 50 rows)")
      )
    })

    output$download_export <- shiny::downloadHandler(
      filename = function() {
        ext <- switch(input$format,
          csv = "zip", tsv = "zip", xlsx = "xlsx", rds = "rds"
        )
        paste0("molpathR_export_", Sys.Date(), ".", ext)
      },
      content = function(file) {
        db <- shared$db
        shiny::req(db)
        layers <- input$layers
        shiny::req(layers)

        app_download(app_export_layers(db, layers, input$format, file))
      }
    )
  })
}
