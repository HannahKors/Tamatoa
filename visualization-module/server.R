library(shiny)
library(plotly)

server <- function(input, output, session) {
  # Helper reactive for selected NGS type
  clicked_ngs_type <- reactive({
    toupper(input$testType)
  })
  
  # Reactive to hold the date filters
  date_filters <- reactive({
    list(
      start_date = if (input$use_date_filter) input$dates[1] else NULL,
      end_date = if (input$use_date_filter) input$dates[2] else NULL
    )
  })
  
  # Function to load plots for a selected tab
  load_tab_plot <- function(tab_group, tab_name) {
    req(tab_group, tab_name)
    config <- tab_config[[tab_group]][[tab_name]]
    if (is.null(config)) {
      print(paste("No configuration found for tab:", tab_name))
      return(NULL)
    }
    dates <- date_filters()
    
    call_functions_render_plots(config, dates$start_date, dates$end_date)
  }
  
  # Automatically select the first tab for LRS or WES and process its first config
  observeEvent(clicked_ngs_type(), {
    ngs_type <- clicked_ngs_type()
    
    if (ngs_type == "LRS") {
      first_tab <- names(tab_config$lrs)[1]  # Get the first tab name
      updateTabsetPanel(session, "activeTab_lrs", selected = first_tab)
      load_tab_plot("lrs", first_tab)
    } else if (ngs_type == "WES") {
      first_tab <- names(tab_config$wes)[1]  # Get the first tab name
      updateTabsetPanel(session, "activeTab_wes", selected = first_tab)
      load_tab_plot("wes", first_tab)
    }
  })
  
  # Observe changes in tab selection and load the corresponding plots
  observe_tabs <- function(tab_group, tab_input) {
    observeEvent(input[[tab_input]], {
      req(input[[tab_input]])
      tab_name <- input[[tab_input]]
      print(paste("Loading plots for tab:", tab_name, "in group:", tab_group))
      load_tab_plot(tab_group, tab_name)
    })
  }
  
  # Add refresh functionality to reload the currently selected tab
  observeEvent(input$refresh, {
    print("Refreshing current tab...")
    tab_inputs <- c(
      "activeTab_wgsoverview" = "wgsoverview",
      "activeTab_wgscoverage" = "wgscoverage",
      "activeTab_wgsmapping" = "wgsmapping",
      "activeTab_wgsvariantcalling" = "wgsvariantcalling",
      "activeTab_lrs" = "lrs",
      "activeTab_wes" = "wes"
    )
    
    # Reload the active tab in each group
    for (tab_input in names(tab_inputs)) {
      tab_group <- tab_inputs[[tab_input]]
      if (!is.null(input[[tab_input]])) {
        load_tab_plot(tab_group, input[[tab_input]])
      }
    }
  })
  
  # Measure time for individual plot rendering
  call_functions_render_plots <- function(config, start_date, end_date) {
    lapply(config$plots, function(plot_config) {
      # Measure time for data querying and processing
      query_start_time <- Sys.time()
      
      query_function <- plot_config$query
      if (!is.function(query_function)) {
        stop("Error: query_function is not a valid function.")
      }
      
      query_args <- list(
        conn = conn,
        ngs_type = clicked_ngs_type(),
        start_date = start_date,
        end_date = end_date
      )
       # Handle scatter plot with X and Y keys
      if ("quality_key_x" %in% names(plot_config) && !is.null(plot_config$quality_key_x)) {
        query_args$quality_key_x <- plot_config$quality_key_x
      }
      if ("quality_key_y" %in% names(plot_config) && !is.null(plot_config$quality_key_y)) {
        query_args$quality_key_y <- plot_config$quality_key_y
      }
      if ("quality_key" %in% names(plot_config) && !is.null(plot_config$quality_key)) {
        query_args$quality_key <- plot_config$quality_key
      }
      if ("boxplot_quality_key" %in% names(plot_config) && !is.null(plot_config$boxplot_quality_key)) {
        query_args$boxplot_quality_key <- plot_config$boxplot_quality_key
      }
      
      result <- do.call(query_function, query_args)
      if (is.null(result) || nrow(result) == 0) {
        message <- paste(plot_config$plotly_output_id, "returned no data. Skipping plot rendering.")
        print(message)
        return(NULL)
      }
      
      processed_data <- NULL
      if (grepl("scatterplot_threshold_", plot_config$plotly_output_id)) {
        if (!is.null(plot_config$processing)) {
          processed_data <- plot_config$processing(result, thresholds = plot_config$thresholds)
        } else {
          processed_data <- result
        }
      } else if (grepl("scatterplot_nothreshold_", plot_config$plotly_output_id)) {
        processed_data <- result
      } else if (grepl("boxplot_", plot_config$plotly_output_id)) {
        if (!is.null(plot_config$processing)) {
          processed_data <- plot_config$processing(result, group_by = plot_config$group_by)
        } else {
          processed_data <- result
        }
        count_data <- plot_config$counting(processed_data)
        processed_data <- merge(processed_data, count_data, by = "boxplot_group", all.x = TRUE)
      } else {
        processed_data <- result
      }
      
      query_end_time <- Sys.time()
      print(paste("Querying and processing for", plot_config$plotly_output_id, "took:", 
                  round(difftime(query_end_time, query_start_time, units = "secs"), 2), "seconds"))
      
      # Render Plotly plot
      render_start_time <- Sys.time()
      output[[plot_config$plotly_output_id]] <- renderPlotly({
        plot_config$plotting(processed_data, plot_config)
      })
      render_end_time <- Sys.time()
      print(paste("Plotly rendering for", plot_config$plotly_output_id, "took:", 
                  round(difftime(render_end_time, render_start_time, units = "secs"), 4), "seconds"))
    })
  }
  
  # Observe tab inputs for different groups
  observe_tabs("wgsoverview", "activeTab_wgsoverview")
  observe_tabs("wgscoverage", "activeTab_wgscoverage")
  observe_tabs("wgsmapping", "activeTab_wgsmapping")
  observe_tabs("wgsvariantcalling", "activeTab_wgsvariantcalling")
  observe_tabs("wgscnv", "activeTab_wgscnv")
  observe_tabs("wgssv", "activeTab_wgssv")
  observe_tabs("wgsr1r2metrics", "activeTab_wgsr1r2metrics")
  observe_tabs("wgstime", "activeTab_wgstime")
  observe_tabs("lrs", "activeTab_lrs")
  observe_tabs("wes", "activeTab_wes")
}
