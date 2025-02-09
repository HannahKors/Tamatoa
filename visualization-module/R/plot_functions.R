library(plotly)

# Generic function to create a bar plot
render_bar_plot <- function(data, config) {
  x <- config$x
  y <- config$y
  title <- config$title
  xaxis_title <- config$xaxis_title
  yaxis_title <- config$yaxis_title
  # Create hover text dynamically
  data$hover_text <- paste0(
    "Count: ", data$count, "<br>",
    "Month: ", data$analysis_month_year
  )
  
  plot_ly(
    data = data,
    x = ~ get(x),
    y = ~ get(y),
    type = "bar",
    text = ~ hover_text,
    hoverinfo = "text"
  ) %>%
    layout(
      title = title,
      xaxis = list(title = xaxis_title, tickformat = "%b %Y"),
      yaxis = list(title = yaxis_title)
    )
}

render_scatter_plot_threshold <- function(data, config) {
  # Extract config values
  x <- config$x
  y <- config$y
  color <- config$color
  symbol <- config$symbol
  size <- config$size
  title <- config$title
  xaxis_title <- config$xaxis_title
  yaxis_title <- config$yaxis_title
  hover_text_template <- config$hover_text_template
  legend_title <- config$legend_title

  # Create hover text dynamically
  data$hover_text <- paste0(
    "Sample: ", data$sample_id, "<br>",
    "Experiment Name: ", data$experiment_name, "<br>",
    "Value: ", data$quality_metric_value, "<br>",
    "Adjusted Value: ", data$adjusted_value, "<br>",
    "Date: ", data$analysis_date
  )
  
  # Plot all data points initially (using adjusted_value for scatter plot)
  plot <- plot_ly(
    data = data,
    x = ~ get(x),
    y = ~ get(y),
    type = "scatter",
    mode = "markers",
    text = ~ hover_text, 
    hoverinfo = "text", # so it only shows my hovertext
    marker = list(
      color = I(data[[color]]),
      symbol = I(data[[symbol]]),
      size = I(data[[size]]),
      opacity = 0.7,
      line = list(width = 0)  # Remove the border around the symbols
    ),
    showlegend = FALSE
  ) %>%
    layout(
      title = title,
      xaxis = list(title = xaxis_title),
      yaxis = list(title = yaxis_title),
      legend = list(title = list(text = legend_title))
    )
  
  # Add traces for each unique value_status to create the legend
  unique_statuses <- unique(data$value_status)
  for (status in unique_statuses) {
    status_data <- data %>% filter(value_status == status)
    plot <- plot %>% add_trace(
      data = status_data,
      x = ~ get(x),
      y = ~ get(y),
      type = "scatter",
      mode = "markers",
      marker = list(
        color = I(status_data[[color]][1]),
        symbol = I(status_data[[symbol]][1]),
        size = I(status_data[[size]][1]),
        opacity = 0.7,
        line = list(width = 0)  # Remove the border around the symbols
      ),
      name = status,
      showlegend = TRUE
    )
  }
  
  return(plot)
}


render_scatter_plot_nothreshold <- function(data, config) {
  x <- config$x
  y <- config$y
  title <- config$title
  xaxis_title <- config$xaxis_title
  yaxis_title <- config$yaxis_title
  legend_title <- config$legend_title
  
  # Create hover text dynamically
  data$hover_text <- paste0(
    "Sample: ", data$sample_id, "<br>",
    "Experiment Name: ", data$experiment_name, "<br>",
    "Value: ", data$quality_metric_value, "<br>",
    "Date: ", data$analysis_date
  )
  
  plot <- plot_ly(
    data = data,
    x = ~ get(x),
    y = ~ get(y),
    type = "scatter",
    mode = "markers",
    text = ~ hover_text,
    hoverinfo = "text", # so it only shows my hovertext
    showlegend = FALSE
  ) %>%
    layout(
      title = title,
      xaxis = list(title = xaxis_title),
      yaxis = list(title = yaxis_title),
      legend = list(title = list(text = legend_title))
    )
  
  return(plot)
}

render_box_plot <- function(data, config) {
  # Convert boxplot_group to a character string and add an underscore if it contains only integers
  data$boxplot_group <- sapply(as.character(data$boxplot_group), function(group_name) {
    if (grepl("^[0-9]+$", group_name)) {
      return(paste0(group_name, "_"))
    } else {
      return(group_name)
    }
  })
  
  # Create the boxplot grouped by the 'group' column
  plot <- plot_ly(
    data = data,
    x = ~ boxplot_group,
    # Grouping by the specified column
    y = ~ quality_metric_value,
    type = "box",
    boxpoints = "outliers",
    # Display outliers
    name = ~ boxplot_group  # Display group names in the legend
  ) %>%
    layout(
      title = config$title,
      xaxis = list(title = config$xaxis_title),
      yaxis = list(title = config$yaxis_title),
      legend = list(title = config$legend_title)
    )
  
  # Create annotations for each group using the count of experiments or samples
  annotations <- lapply(unique(data$boxplot_group), function(group_name) {
    # Get the sample count for the group
    count <- data$counts[data$boxplot_group == group_name][1] # selects the first count of the group because all groups have the same count
    
    list(
      x = group_name,
      y = max(data$quality_metric_value),
      text = count,
      showarrow = FALSE,
      font = list(size = 15, color = "black")
    )
  })
  
  # Add annotations to the plot
  plot <- plot %>% layout(annotations = annotations)
  
  return(plot)
}
