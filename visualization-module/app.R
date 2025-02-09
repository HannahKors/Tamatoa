library(shiny)

source("R/plot_functions.R")
source("R/data_processing.R")
source("R/queries.R")

source("global.R")
source("ui.R")
source("server.R")

shinyApp(ui = ui, server = server)