#queries.R

library(DBI)
library(RPostgres)
library(dplyr)
library(stringr)


# Function to generate the date filter SQL
get_date_filter <- function(start_date, end_date) {
  if (!is.null(start_date) && !is.null(end_date)) {
    return(
      paste(
        " AND analysis_date >= '",
        start_date,
        "' AND analysis_date <= '",
        end_date,
        "'",
        sep = ""
      )
    )
  } else {
    return("")  # Return an empty string if no date range is specified
  }
}

# Generic query for count of experiments per month
query_experiment_count_per_month <- function(conn,
                                             ngs_type,
                                             start_date = NULL,
                                             end_date = NULL) {
  date_filter_sql <- get_date_filter(start_date, end_date)
  query <- paste0(
    "SELECT TO_CHAR(analysis_date, 'YYYY-MM') AS analysis_month_year,
            COUNT(*) AS count
     FROM Experiment
     WHERE NGS_ngs_type = '",
    ngs_type,
    "'",
    date_filter_sql,
    " GROUP BY TO_CHAR(analysis_date, 'YYYY-MM')"
  )
  return(dbGetQuery(conn, query))
}

# Generic query for sample count per month
query_sample_count_per_month <- function(conn,
                                         ngs_type,
                                         start_date = NULL,
                                         end_date = NULL) {
  date_filter_sql <- get_date_filter(start_date, end_date)
  query <- paste0(
    "SELECT TO_CHAR(analysis_date, 'YYYY-MM') AS analysis_month_year,
            COUNT(s.sample_identifier) AS count
     FROM Experiment e
     JOIN Sample s ON e.experiment_identifier = s.Experiment_experiment_identifier
     WHERE NGS_ngs_type = '",
    ngs_type,
    "'",
    date_filter_sql,
    " GROUP BY TO_CHAR(analysis_date, 'YYYY-MM')"
  )
  return(dbGetQuery(conn, query))
}


query_quality_metric_data <- function(conn,
                                      ngs_type,
                                      start_date = NULL,
                                      end_date = NULL,
                                      quality_key) {
  date_filter_sql <- get_date_filter(start_date, end_date)
  
  query <- paste0(
    "SELECT e.analysis_date,
            s.sample_id,
            CAST(qm.quality_metric_value AS FLOAT) AS quality_metric_value,
            e.experiment_name
     FROM Experiment e
     JOIN Sample s ON e.experiment_identifier = s.Experiment_experiment_identifier
     JOIN Quality_Metrics qm ON s.sample_identifier = qm.Sample_sample_identifier
     WHERE qm.quality_metric_key = '",
    quality_key,
    "'
       AND e.NGS_ngs_type = '",
    ngs_type,
    "'",
    date_filter_sql
  )
  
  return(dbGetQuery(conn, query))
}

# Function to query data for scatter plots
query_quality_metric_xy <- function(conn, ngs_type, start_date = NULL, end_date = NULL, quality_key_x, quality_key_y) {
  date_filter_sql <- get_date_filter(start_date, end_date)

  query <- paste0(
    "SELECT e.analysis_date,
            s.sample_id,
            CAST(qm_x.quality_metric_value AS FLOAT) AS quality_metric_x,
            CAST(qm_y.quality_metric_value AS FLOAT) AS quality_metric_y,
            e.experiment_name
     FROM Experiment e
     JOIN Sample s ON e.experiment_identifier = s.Experiment_experiment_identifier
     JOIN Quality_Metrics qm_x ON s.sample_identifier = qm_x.Sample_sample_identifier
     JOIN Quality_Metrics qm_y ON s.sample_identifier = qm_y.Sample_sample_identifier
     WHERE qm_x.quality_metric_key = '", quality_key_x, "'
       AND qm_y.quality_metric_key = '", quality_key_y, "'
       AND e.NGS_ngs_type = '", ngs_type, "'",
    date_filter_sql
  )

  return(dbGetQuery(conn, query))
}

query_qualitykey_serialnumber <- function(conn,
                                          ngs_type,
                                          start_date = NULL,
                                          end_date = NULL,
                                          quality_key) {
  date_filter_sql <- get_date_filter(start_date, end_date)
  
  query <- paste0(
    "SELECT
        qm.quality_metric_key,
        CAST(qm.quality_metric_value AS FLOAT) AS quality_metric_value,
        e.run_id,
        e.analysis_date,
        s.sample_id
     FROM
        Experiment e
     JOIN
        Sample s ON e.experiment_identifier = s.Experiment_experiment_identifier
     JOIN
        Quality_Metrics qm ON s.sample_identifier = qm.Sample_sample_identifier
     JOIN
        ngs n ON n.ngs_type = e.ngs_ngs_type
     WHERE qm.quality_metric_key = '",
    quality_key,
    "'
       AND e.NGS_ngs_type = '",
    ngs_type,
    "'",
    date_filter_sql
  )
  return(dbGetQuery(conn, query))
}

query_run_quality_metric_data <- function(conn,
                                          ngs_type,
                                          start_date = NULL,
                                          end_date = NULL,
                                          quality_key) {
  date_filter_sql <- get_date_filter(start_date, end_date)
  
  query <- paste0(
    "SELECT e.analysis_date,
        CAST(rqm.run_quality_metric_value AS FLOAT) AS quality_metric_value,
        e.experiment_name,
        rqm.run_quality_metric_key
    FROM Experiment e
    JOIN run_quality_metrics rqm on e.experiment_identifier = rqm.experiment_experiment_identifier
    WHERE rqm.run_quality_metric_key = '",
    quality_key,
    "'
      AND e.NGS_ngs_type= '",
    ngs_type,
    "'",
    date_filter_sql
  )
  return(dbGetQuery(conn, query))
}

query_run_quality_metric_data_serialnumber <- function(conn,
                                                       ngs_type,
                                                       start_date = NULL,
                                                       end_date = NULL,
                                                       quality_key) {
  date_filter_sql <- get_date_filter(start_date, end_date)
  
  query <- paste0(
    "SELECT CAST(rqm.run_quality_metric_value AS FLOAT) AS quality_metric_value,
       CAST(e.sequencer_id AS VARCHAR) AS boxplot_group
    FROM Experiment e
    JOIN run_quality_metrics rqm on e.experiment_identifier = rqm.experiment_experiment_identifier
    WHERE rqm.run_quality_metric_key = '",
    quality_key,
    "'
      AND e.NGS_ngs_type = '",
    ngs_type,
    "'",
    date_filter_sql
  )
  return(dbGetQuery(conn, query))
}


query_qualitykey_boxplotkey <- function(conn,
                                        ngs_type,
                                        start_date = NULL,
                                        end_date = NULL,
                                        quality_key,
                                        boxplot_quality_key) {
  date_filter_sql <- get_date_filter(start_date, end_date)
  
  query <- paste0(
    "SELECT
        CAST(rqm.run_quality_metric_value AS FLOAT) AS quality_metric_value,
        CAST(rqm2.run_quality_metric_value AS VARCHAR) AS boxplot_group
    FROM
        experiment e
        JOIN run_quality_metrics rqm ON e.experiment_identifier = rqm.experiment_experiment_identifier
        JOIN run_quality_metrics rqm2 ON e.experiment_identifier = rqm2.experiment_experiment_identifier
    JOIN ngs n ON n.ngs_type = e.ngs_ngs_type
    WHERE rqm.run_quality_metric_key = '",
    quality_key,
    "'
      AND rqm2.run_quality_metric_key = '",
    boxplot_quality_key,
    "'
      AND e.NGS_ngs_type= '",
    ngs_type,
    "'",
    date_filter_sql
  )
  return(dbGetQuery(conn, query))
}