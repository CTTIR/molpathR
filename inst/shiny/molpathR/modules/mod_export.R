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

        if (input$format == "rds") {
          export_db <- db
          for (l in c("patients", "samples", "variants", "reports", "clinical", "survival")) {
            if (!(l %in% layers)) export_db[[l]] <- export_db[[l]][0, ]
          }
          saveRDS(export_db, file)

        } else if (input$format == "xlsx") {
          if (requireNamespace("writexl", quietly = TRUE)) {
            data_list <- stats::setNames(
              lapply(layers, function(l) db[[l]]),
              layers
            )
            writexl::write_xlsx(data_list, file)
          } else {
            # Fallback to CSV zip
            tmpdir <- tempdir()
            files <- character()
            for (l in layers) {
              f <- file.path(tmpdir, paste0(l, ".csv"))
              utils::write.csv(db[[l]], f, row.names = FALSE)
              files <- c(files, f)
            }
            utils::zip(file, files, flags = "-j")
          }

        } else {
          sep <- if (input$format == "csv") "," else "\t"
          ext <- if (input$format == "csv") "csv" else "tsv"
          tmpdir <- tempdir()
          files <- character()
          for (l in layers) {
            f <- file.path(tmpdir, paste0(l, ".", ext))
            utils::write.table(db[[l]], f, sep = sep, row.names = FALSE, quote = TRUE)
            files <- c(files, f)
          }
          utils::zip(file, files, flags = "-j")
        }
      }
    )
  })
}
