#data_processing.R

library(dplyr)
library(stringr)

#processes the thresholds
process_threshold_data <- function(data, quality_key, thresholds) {
  # Check which column to use for thresholds
  if ("quality_metric_y" %in% colnames(data)) {
    value_column <- "quality_metric_y"
  } else if ("quality_metric_value" %in% colnames(data)) {
    value_column <- "quality_metric_value"
  } else {
    print("QColumn to apply visualization thresholds to was found in data")
  }

  # Apply thresholds
  data$adjusted_value <- ifelse(
    data[[value_column]] < thresholds$adjusted_min,
    thresholds$adjusted_min,
    ifelse(
      data[[value_column]] > thresholds$adjusted_max,
      thresholds$adjusted_max,
      data[[value_column]]
    )
  )

  # Apply specific adjustment rules based on adjusted thresholds
  data$adjusted_value <- ifelse(
    data[[value_column]] < thresholds$adjusted_min,
    thresholds$adjusted_min,
    ifelse(
      data[[value_column]] > thresholds$adjusted_max,
      thresholds$adjusted_max,
      data$adjusted_value
    )
  )

  # Determine value status based on the adjusted and metric value comparison
  data$value_status <- ifelse(
    data[[value_column]] >= thresholds$min_threshold &
      data[[value_column]] <= thresholds$max_threshold,
    'Normal',
    ifelse(
      data$adjusted_value == data[[value_column]],
      'Not Normal and Not Adjusted',
      'Not Normal and Adjusted'
    )
  )

  # Assign visual properties
  data <- data %>% mutate(
    colour = case_when(
      value_status == 'Normal' ~ 'green',
      value_status == 'Not Normal and Not Adjusted' ~ 'red',
      value_status == 'Not Normal and Adjusted' ~ 'red'
    ),
    symbol = case_when(
      value_status == 'Normal' ~ 'circle',
      value_status == 'Not Normal and Not Adjusted' ~ 'circle',
      value_status == 'Not Normal and Adjusted' ~ 'x'
    ),
    size = case_when(
      value_status == 'Normal' ~ 5,
      value_status == 'Not Normal and Not Adjusted' ~ 5,
      value_status == 'Not Normal and Adjusted' ~ 10
    )
  )
  return(data)
}

extract_serial_stage_old <- function(run_id) {
  serial_number = ifelse(is.na(run_id), "NA", str_sub(run_id, 8, 13))
  stage = str_sub(run_id, 20, 20)
  serial_number_stage = ifelse(is.na(run_id), "NA", paste(serial_number, stage, sep = "_"))
  return(
    data.frame(
      serial_number = serial_number,
      stage = stage,
      serial_number_stage = serial_number_stage
    )
  )
}

extract_serial_stage <- function(run_id) {
  serial_number = ifelse(is.na(run_id),
                         "NA",
                         stringr::str_extract(run_id, "(?<=_)[A-Z0-9]+(?=_)"))
  stage = stringr::str_extract(run_id, "(?<=_)[A-Z](?=[A-Z0-9]{9}$)")
  serial_number_stage = ifelse(is.na(run_id), "NA", paste(serial_number, stage, sep = "_"))
  return(
    data.frame(
      serial_number = serial_number,
      stage = stage,
      serial_number_stage = serial_number_stage
    )
  )
}


# Helper function to process and group data
process_and_group_serialnumberstage <- function(data, group_by) {
  if (!is.null(data)) {
    # Extract serial_number and stage
    extracted <- extract_serial_stage(data$run_id)
    data$serial_number <- extracted$serial_number
    data$serial_number_stage <- extracted$serial_number_stage
    
    # Ensure the group_by column exists
    if (group_by %in% colnames(data)) {
      # Add group column dynamically based on the group_by argument
      data$boxplot_group <- data[[group_by]]
      
      # Return only the required columns: group and quality_metric_value
      return(data %>% select(boxplot_group, quality_metric_value))
    } else {
      stop(paste("Group_by column", group_by, "is missing in the data"))
    }
  } else {
    return(NULL)
  }
}

counting <- function(data) {
  if (!is.null(data)) {
    if ("boxplot_group" %in% colnames(data)) {
      result <- data %>%
        group_by(boxplot_group) %>%
        summarise(counts = n(), .groups = 'drop')
      return(result)
    } else {
      stop(paste("Group_by column 'boxplot_group' is missing in the data"))
    }
  } else {
    stop("Data is empty...")
  }
}
