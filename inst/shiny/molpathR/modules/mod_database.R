# Module: Database (Tab 1)

mod_database_ui <- function(id) {
  ns <- shiny::NS(id)
  bslib::layout_sidebar(
    sidebar = bslib::sidebar(
      title = "Load Data",
      shiny::fileInput(ns("file_upload"), "Upload files",
        multiple = TRUE,
        accept = c(".rds", ".vcf", ".xml", ".pdf", ".csv", ".xlsx", ".xls",
                   ".fastq", ".fq", ".bam", ".txt")
      ),
      shiny::actionButton(ns("load_example"), "Load Example Database",
        class = "btn-primary btn-sm", width = "100%"
      ),
      shiny::hr(),
      shiny::downloadButton(ns("save_db"), "Save Database (.rds)",
        class = "btn-outline-secondary btn-sm"
      ),
      shiny::downloadButton(ns("export_summary"), "Export Summary (.csv)",
        class = "btn-outline-secondary btn-sm"
      )
    ),
    # Main panel
    shiny::uiOutput(ns("summary_cards")),
    shiny::br(),
    DT::dataTableOutput(ns("source_table"))
  )
}

mod_database_server <- function(id, shared) {
  shiny::moduleServer(id, function(input, output, session) {

    # Load example database
    shiny::observeEvent(input$load_example, {
      shared$db <- molpathR::mp_example_db()
      shiny::showNotification("Example database loaded!", type = "message")
    })

    # Upload files
    shiny::observeEvent(input$file_upload, {
      shiny::withProgress(message = "Parsing files...", {
        files <- input$file_upload
        parsed_list <- list()
        for (i in seq_len(nrow(files))) {
          shiny::incProgress(1 / nrow(files), detail = files$name[i])
          ext <- tolower(tools::file_ext(files$name[i]))
          tryCatch({
            if (ext == "rds") {
              loaded <- readRDS(files$datapath[i])
              if (inherits(loaded, "molpath_db")) {
                shared$db <- loaded
                shiny::showNotification("Database loaded from RDS!", type = "message")
                return()
              }
            }
            p <- molpathR::mp_read_auto(files$datapath[i])
            parsed_list[[i]] <- p
          }, error = function(e) {
            shiny::showNotification(
              paste("Error parsing", files$name[i], ":", e$message),
              type = "error"
            )
          })
        }
        parsed_list <- parsed_list[!vapply(parsed_list, is.null, logical(1))]
        if (length(parsed_list) > 0) {
          if (is.null(shared$db)) {
            shared$db <- molpathR::mp_build_db(parsed_list)
          } else {
            for (p in parsed_list) {
              shared$db <- molpathR::mp_add_data(shared$db, p)
            }
          }
          shiny::showNotification("Files parsed and added!", type = "message")
        }
      })
    })

    # Summary cards
    output$summary_cards <- shiny::renderUI({
      db <- shared$db
      if (is.null(db)) {
        return(shiny::div(
          class = "text-center text-muted p-5",
          shiny::h4("No database loaded"),
          shiny::p("Upload data files or load the example database to get started.")
        ))
      }
      bslib::layout_column_wrap(
        width = 1 / 4,
        bslib::value_box(
          title = "Patients", value = nrow(db$patients),
          theme = "primary", showcase = shiny::icon("users")
        ),
        bslib::value_box(
          title = "Samples", value = nrow(db$samples),
          theme = "secondary", showcase = shiny::icon("vial")
        ),
        bslib::value_box(
          title = "Variants", value = nrow(db$variants),
          theme = "info", showcase = shiny::icon("dna")
        ),
        bslib::value_box(
          title = "Reports", value = nrow(db$reports),
          theme = "success", showcase = shiny::icon("file-medical")
        )
      )
    })

    # Source table
    output$source_table <- DT::renderDataTable({
      db <- shared$db
      shiny::req(db)
      tibble::tibble(
        Table = c("Patients", "Samples", "Variants", "Reports", "Clinical", "Survival"),
        Records = c(
          nrow(db$patients), nrow(db$samples), nrow(db$variants),
          nrow(db$reports), nrow(db$clinical), nrow(db$survival)
        ),
        Columns = c(
          ncol(db$patients), ncol(db$samples), ncol(db$variants),
          ncol(db$reports), ncol(db$clinical), ncol(db$survival)
        )
      )
    }, options = list(dom = "t", pageLength = 10))

    # Save database
    output$save_db <- shiny::downloadHandler(
      filename = function() paste0("molpathR_db_", Sys.Date(), ".rds"),
      content = function(file) {
        shiny::req(shared$db)
        saveRDS(shared$db, file)
      }
    )

    # Export summary
    output$export_summary <- shiny::downloadHandler(
      filename = function() paste0("molpathR_summary_", Sys.Date(), ".csv"),
      content = function(file) {
        shiny::req(shared$db)
        s <- molpathR::mp_summary(shared$db)
        df <- tibble::tibble(
          Metric = c("Patients", "Samples", "Variants", "Reports", "Clinical"),
          Count = c(s$n_patients, s$n_samples, s$n_variants, s$n_reports, s$n_clinical)
        )
        utils::write.csv(df, file, row.names = FALSE)
      }
    )
  })
}
