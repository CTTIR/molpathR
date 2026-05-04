# app.R — entry point for molpathR Shiny application

# Source modules
for (f in list.files(file.path(app_dir <- ".", "modules"), full.names = TRUE, pattern = "\\.R$")) {
  source(f, local = TRUE)
}
for (f in list.files(file.path(app_dir, "helpers"), full.names = TRUE, pattern = "\\.R$")) {
  source(f, local = TRUE)
}

# ---- UI ----------------------------------------------------------------------

ui <- bslib::page_navbar(
  title = shiny::tags$span(
    shiny::tags$img(src = "logo.svg", height = "30px", style = "margin-right: 8px;"),
    "molpathR"
  ),
  theme = bslib::bs_theme(
    bootswatch = "flatly",
    primary = "#7B2D8E",
    secondary = "#9B59B6",
    font_scale = 0.95
  ),
  header = shiny::tags$head(
    shiny::tags$link(rel = "stylesheet", type = "text/css", href = "custom.css")
  ),
  bslib::nav_panel("Database",    mod_database_ui("database")),
  bslib::nav_panel("Patients",    mod_patients_ui("patients")),
  bslib::nav_panel("Variants",    mod_variants_ui("variants")),
  bslib::nav_panel("Reports",     mod_reports_ui("reports")),
  bslib::nav_panel("Survival",    mod_survival_ui("survival")),
  bslib::nav_panel("Export",      mod_export_ui("export"))
)

# ---- Server ------------------------------------------------------------------

server <- function(input, output, session) {
  # Shared reactive: the database
  shared <- shiny::reactiveValues(
    db = NULL,
    selected_patient = NULL,
    selected_gene = NULL
  )

  # Check if pre-loaded database was passed via mp_run_app()
  shiny::observe({
    env <- getFromNamespace(".molpathR_env", "molpathR")
    if (!is.null(env$shiny_db)) {
      shared$db <- env$shiny_db
    }
  })

  mod_database_server("database", shared)
  mod_patients_server("patients", shared)
  mod_variants_server("variants", shared)
  mod_reports_server("reports", shared)
  mod_survival_server("survival", shared)
  mod_export_server("export", shared)
}

shiny::shinyApp(ui, server)
