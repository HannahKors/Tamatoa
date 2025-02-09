source("R/plot_functions.R")
source("R/data_processing.R")
source("R/queries.R")

# Required Libraries
library(shiny)
library(plotly)
library(DBI)
library(RPostgres)
library(stringr)
library(dplyr)

# Function to connect to PostgreSQL database
connect_to_db <- function() {
  tryCatch({
    dbConnect(
      RPostgres::Postgres(),
      dbname = "",
      host = "",
      port = "",
      user = "",
      password = ""

    )
  }, error = function(e) {
    cat("Error: Unable to connect to the database.\n")
    stop(e)
  })
}

# Establish the database connection outside the server function
conn <- connect_to_db()

# Base configuration for barplots
base_config_barplot <- list(
  title = 'default title',
  xaxis_title = "Month",
  yaxis_title = "Count",
  x = "analysis_month_year",  # Default x-axis column
  y = "count",         # Default y-axis column
  query = query_sample_count_per_month,
  plotting = render_bar_plot
)

# Base config for scatter plots (no thresholds)
base_config_scatter_nothreshold <- list(
  x = "analysis_date",
  y = "quality_metric_value",
  title = "default title",
  xaxis_title = "Analysis Date",
  yaxis_title = "default title",
  query = query_quality_metric_data,
  plotting = render_scatter_plot_nothreshold
)

# Base config for scatter plots (no thresholds, LRS-specific)
base_config_scatter_nothreshold_lrs <- list(
  x = "analysis_date",
  y = "quality_metric_value",
  title = "default title",
  xaxis_title = "Analysis Date",
  yaxis_title = "default title",
  query = query_run_quality_metric_data,
  plotting = render_scatter_plot_nothreshold
)

# Base config for scatter plots (threshold)
base_config_scatter_threshold <- list(
  x = "analysis_date",
  y = "adjusted_value",
  title = "default title",
  xaxis_title = "Analysis Date",
  yaxis_title = "Count",
  color = "colour",
  symbol = "symbol",
  size = "size",
  legend_title = "Status",
  query = query_quality_metric_data,
  processing = process_threshold_data,
  plotting = render_scatter_plot_threshold,
  thresholds = list(
    min_threshold = NA,
    max_threshold = NA,
    adjusted_min = NA,
    adjusted_max = NA
  )
)

# Base config for scatter plots (threshold) where one key is shown on x and the other on y
# the thresholds are applied to the y key, just like in the old version
base_config_scatter_threshold_xy <- list(
  x = "quality_metric_x",
  y = "quality_metric_y",
  title = "default title",
  xaxis_title = "quality metric x",
  yaxis_title = "quality metric y",
  color = "colour",
  symbol = "symbol",
  size = "size",
  legend_title = "Status",
  query = query_quality_metric_xy,
  quality_key_x = NA,
  quality_key_y = NA,
  processing = process_threshold_data,
  plotting = render_scatter_plot_threshold,
  thresholds = list(
    min_threshold = NA,
    max_threshold = NA,
    adjusted_min = NA,
    adjusted_max = NA
  )
)

# Base configuration for boxplots
base_config_boxplot <- list(
  plotly_output_id = NULL,
  title = "default title",
  yaxis_title = "Metric Value",
  query = query_qualitykey_serialnumber,
  group_by = NA,
  processing = process_and_group_serialnumberstage,
  counting = counting,
  plotting = render_box_plot,
  xaxis_title = "default title",
  yaxis_title = "default title",
  legend_title = "default legend title"
)

# Base configuration for boxplots (LRS, serial number)
base_config_boxplot_lrs_serialnumber <- list(
  plotly_output_id = NULL,
  title = "default title",
  yaxis_title = "Metric Value",
  query = query_run_quality_metric_data_serialnumber,
  counting = counting,
  plotting = render_box_plot,
  xaxis_title = "default title",
  yaxis_title = "default title",
  legend_title = "default legend title"
)

# Base configuration for boxplots (LRS-specific)
base_config_boxplot_lrs <- list(
  plotly_output_id = NULL,
  title = "default title",
  yaxis_title = "Metric Value",
  quality_key = NA,
  boxplot_quality_key = NA,
  query = query_qualitykey_boxplotkey,
  counting = counting,
  plotting = render_box_plot,
  xaxis_title = "default title",
  yaxis_title = "default title",
  legend_title = "default legend title"
)


processed_samples_config <- list(plots = list(
  barplot_samples = modifyList(
    base_config_barplot,
    list(
      plotly_output_id = "barplot_amount_samples_wgs_per_month",
      title = "Sample Count per Month"
    )
  ),
  barplot_experiments = modifyList(
    base_config_barplot,
    list(
      plotly_output_id = "barplot_amount_experiments_wgs_per_month",
      title = "Experiment Count per Month",
      query = query_experiment_count_per_month
    )
  )
))


duplicate_reads_config <- list(plots = list(
  scatter_plot = modifyList(
    base_config_scatter_threshold,
    list(
      plotly_output_id = "scatterplot_threshold_wgs_percentage_duplicates",
      title = "Percentage of Duplicate Marked Reads",
      yaxis_title = "Percentage",
      thresholds = list(
        min_threshold = 0,
        max_threshold = 15,
        adjusted_min = 0,
        adjusted_max = 17
      ),
      quality_key = "percentage_number_of_duplicate_marked_reads"
    )
  ),
  boxplot = modifyList(
    base_config_boxplot,
    list(
      plotly_output_id = "boxplot_wgs_serialnumber_percentage_duplicates",
      title = "Percentage of Duplicate Marked Reads by Serial Number Novaseq",
      quality_key = "percentage_number_of_duplicate_marked_reads",
      group_by = "serial_number"
    )
  ),
  boxplot_stage = modifyList(
    # Changed to avoid duplication
    base_config_boxplot,
    list(
      plotly_output_id = "boxplot_wgs_serialnumber_and_stage_percentage_duplicates",
      title = "Percentage of Duplicate Marked Reads by Serial Number Novaseq",
      quality_key = "percentage_number_of_duplicate_marked_reads",
      group_by = "serial_number_stage"
    )
  )
))

contamination_config <- list(plots = list(scatter_plot = modifyList(
  base_config_scatter_threshold,
  list(
    plotly_output_id = "scatterplot_threshold_wgs_contamination",
    title = "Estimated Sample Contamination",
    yaxis_title = "Decimal representation of percentage contamination",
    thresholds = list(
      min_threshold = 0,
      max_threshold = 0.001,
      adjusted_min = 0,
      adjusted_max = 0.05
    ),
    quality_key = "estimated_sample_contamination"
  )
)))

average_autosomal_coverage_config <- list(plots = list(
  scatterplot = modifyList(
    base_config_scatter_threshold,
    list(
      plotly_output_id = "scatterplot_threshold_wgs_average_autosomal_coverage",
      title = "Average Autosomal Coverage",
      yaxis_title = "Average Autosomal Coverage",
      quality_key = "average_autosomal_coverage_over_genome",
      thresholds = list(
        min_threshold = 25,
        max_threshold = 75,
        adjusted_min = 15,
        adjusted_max = 75
        )
    )
  ),
  boxplot = modifyList(
    base_config_boxplot,
    list(
      plotly_output_id = "boxplot_wgs_serialnumber_averageautosomalcoverage",
      title = "Average Autosomal Coverage by Serial Number Novaseq",
      quality_key = "average_autosomal_coverage_over_genome",
      group_by = "serial_number",
      yaxis_title = "Average Autosomal Coverage",
      xaxis_title = "Serial Number",
      legend_title = "Serial Number"

    )
  ),
  boxplot_stage = modifyList(
    # Changed to avoid duplication
    base_config_boxplot,
    list(
      plotly_output_id = "boxplot_wgs_serialnumber_and_stage_averageautosomalcoverage",
      title = "Percentage of Duplicate Marked Reads by Serial Number Novaseq",
      quality_key = "average_autosomal_coverage_over_genome",
      group_by = "serial_number_stage",
      yaxis_title = "Average Autosomal Coverage",
      xaxis_title = "Serial Number and Stage",
      legend_title = "Serial Number and Stage"

    )
  )
))

median_autosomal_coverage_config <- list(plots = list(
  scatterplot = modifyList(
    base_config_scatter_threshold,
    list(
      plotly_output_id = "scatterplot_threshold_wgs_medianautosomalcoverage",
      title = "Median autosomal coverage",
      yaxis_title = "Median Autosomal Coverage",
      quality_key = "median_autosomal_coverage_over_genome",
      thresholds = list(
        min_threshold = 25,
        max_threshold = 75,
        adjusted_min = 11,
        adjusted_max = 78
      )
    )
  )
))

mean_median_autosomal_coverage_config <- list(plots = list(
  scatterplot = modifyList(
    base_config_scatter_threshold,
    list(
      plotly_output_id = "scatterplot_threshold_wgs_mean_median",
      title = "Mean/Median autosomal coverage",
      yaxis_title = "Mean/median autosomal coverage ratio",
      quality_key = "mean_median_autosomal_coverage_ratio_over_genome",
      thresholds = list(
          min_threshold = 0.95,
          max_threshold = 5,
          adjusted_min = 0.85,
          adjusted_max = 5
      )
    )
  )
))

pct_bigger_than_0.2_config <- list(plots = list(
  scatterplot = modifyList(
    base_config_scatter_threshold,
    list(
      plotly_output_id = "scatterplot_threshold_wgs_uniformity_02",
      title = "Uniformity of coverage (PCT >0.2*mean)",
        yaxis_title = "Uniformity of coverage (PCT >0.2*mean)",
      quality_key = "uniformity_of_coverage_pct_bigger_than_0.2_times_mean_over_genome",
      thresholds = list(
          min_threshold = 93,
          max_threshold = 100,
          adjusted_min = 93,
          adjusted_max = 100
      )
    )
  )
))

pct_bigger_than_0.4_config <- list(plots = list(
  scatterplot = modifyList(
    base_config_scatter_threshold,
    list(
      plotly_output_id = "scatterplot_threshold_wgs_uniformity_04",
      title = "Uniformity of coverage (PCT >0.4*mean)",
        yaxis_title = "Uniformity of coverage (PCT >0.4*mean)",
      quality_key = "uniformity_of_coverage_pct_bigger_than_0.4_times_mean_over_genome",
      thresholds = list(
          min_threshold = 93,
          max_threshold = 100,
          adjusted_min = 92,
          adjusted_max = 100
      )
    )
  )
))

mitochondiral_coverage_config <- list(plots = list(
  scatterplot = modifyList(
    base_config_scatter_threshold,
    list(
      plotly_output_id = "scatterplot_threshold_wgs_mitochondrialcoverage",
        title = "Average mitochondiral coverage",
        yaxis_title = "Average mitochondiral coverage",
      quality_key = "average_mitochondrial_coverage_over_genome",
      thresholds = list(
          min_threshold = 500,
          max_threshold = 10000,
          adjusted_min = 400,
          adjusted_max = 10000
      )
    )
  )
))

chromosome_x_coverage_config <- list(plots = list(
  scatterplot = modifyList(
    base_config_scatter_nothreshold,
    list(
      plotly_output_id = "scatterplot_nothreshold_wgs_coverage_x",
      title = "Average Chromosome X coverage",
      yaxis_title = "Coverage",
      quality_key = "average_chr_x_coverage_over_genome"

    )
  )
))

chromosome_y_coverage_config <- list(plots = list(
  scatterplot = modifyList(
    base_config_scatter_nothreshold,
    list(
      plotly_output_id = "scatterplot_nothreshold_wgs_coverage_y",
      title = "Average Chromosome Y coverage",
      yaxis_title = "Coverage",
      quality_key = "average_chr_y_coverage_over_genome"

    )
  )
))

#loops through all the chrmomosomes and creates
chromosomes_median_over_autosomal_median_config <- list(plots = lapply(c(1:22, "x", "y"), function(chromosome) {
  modifyList(
    base_config_scatter_nothreshold,
    list(
      plotly_output_id = paste0("scatterplot_nothreshold_wgs_chr", chromosome),
      title = paste0("Median Chromosome ", chromosome, " coverage divided by median autosomal coverage"),
      yaxis_title = paste0("Chr", chromosome, " median / autosomal median"),
      quality_key = paste0(chromosome, "_median_ratio_autosomal_median")
    )
  )
}))

input_reads_config <- list(plots = list(
  scatter_plot = modifyList(
    base_config_scatter_nothreshold,
    list(
      plotly_output_id = "scatterplot_nothreshold_wgs_inputreads",
        title = "Total Input Reads",
      yaxis_title = "Amount",
      quality_key = "total_input_reads"
    )
  )))

mapped_reads_config <- list(plots = list(
  scatter_plot = modifyList(
    base_config_scatter_threshold,
    list(
      plotly_output_id = "scatterplot_threshold_wgs_percentage_mapped_reads",
        title = "Percentage Mapped Reads",
      yaxis_title = "Percentage",
      thresholds = list(
          min_threshold = 97.5,
          max_threshold = 100,
          adjusted_min = 97,
          adjusted_max = 100
      ),
      quality_key = "percentage_mapped_reads"
    )
  )))

  q30_bases_config <- list(plots = list(
  scatter_plot = modifyList(
    base_config_scatter_threshold,
    list(
      plotly_output_id = "scatterplot_threshold_wgs_q30bases",
      title = "Q30 Bases (%)",
      yaxis_title = "Percentage",
      thresholds = list(
        min_threshold = 85,
        max_threshold = 100,
        adjusted_min = 85,
        adjusted_max = 100
      ),
      quality_key = "percentage_q30_bases"
    )
  ),
  boxplot = modifyList(
    base_config_boxplot,
    list(
      plotly_output_id = "boxplot_wgs_serialnumber_q30bases",
      title = "Q30 bases by Serial Number Novaseq",
      quality_key = "percentage_q30_bases",
      group_by = "serial_number"
    )
  ),
  boxplot_stage = modifyList(
    # Changed to avoid duplication
    base_config_boxplot,
    list(
      plotly_output_id = "boxplot_wgs_serialnumber_and_stage_q30bases",
      title = "Q30 bases by Serial Number Novaseq",
      quality_key = "percentage_q30_bases",
      group_by = "serial_number_stage"
    )
  )
))

softclipped_bases_config <- list(plots = list(
  scatter_plot = modifyList(
    base_config_scatter_threshold,
    list(
      plotly_output_id = "scatterplot_threshold_wgs_softclippedbases",
      title = "Softclipped Bases (%)",
      yaxis_title = "Percentage",
      thresholds = list(
        min_threshold = 0,
        max_threshold = 5,
        adjusted_min = 0,
        adjusted_max = 5
      ),
      quality_key = "percentage_softclipped_bases"
    )
  )
))

paired_properly_config <- list(
  plots = list(
    scatter_plot = modifyList(
      base_config_scatter_threshold,
      list(
        plotly_output_id = "scatterplot_threshold_wgs_properlypaired",
        title = "Percentage of Reads Paired Properly",
        yaxis_title = "Percentage",
        thresholds = list(
          min_threshold = 92.5,
          max_threshold = 100,
          adjusted_min = 92,
          adjusted_max = 100
        ),
        quality_key = "percentage_properly_paired_reads"
      )
    )
  )
)

paired_dif_chr_config <- list(
  plots = list(
    scatter_plot = modifyList(
      base_config_scatter_nothreshold,
      list(
        plotly_output_id = "scatterplot_nothreshold_wgs_pairedchromosome",
        title = "Percentage of Paired Reads Mapped to Different Chromosomes",
        yaxis_title = "Percentage",
        quality_key = "percentage_paired_reads_mapped_to_different_chromosomes_mapqbigger_than10"
      )
    )
  )
)

insert_length_mean_config <- list(
  plots = list(
    scatter_plot = modifyList(
      base_config_scatter_threshold,
      list(
        plotly_output_id = "scatterplot_threshold_wgs_insertlength_mean",
        title = "Mean Insert Length",
        yaxis_title = "Length",
        thresholds = list(
          min_threshold = 450,
          max_threshold = 600,
          adjusted_min = 220,
          adjusted_max = 680
        ),
        quality_key = "insert_length_mean"
      )
    )
  )
)

insert_length_median_config <- list(
  plots = list(
    scatter_plot = modifyList(
      base_config_scatter_threshold,
      list(
        plotly_output_id = "scatterplot_threshold_wgs_insertlength_median",
        title = "Median Insert Length",
        yaxis_title = "Length",
        thresholds = list(
          min_threshold = 450,
          max_threshold = 600,
          adjusted_min = 220,
          adjusted_max = 680
        ),
        quality_key = "insert_length_median"
      )
    )
  )
)
insert_length_std_dev_config <- list(
  plots = list(
    scatter_plot = modifyList(
      base_config_scatter_nothreshold,
      list(
        plotly_output_id = "scatterplot_nothreshold_wgs_insertlength_stddev",
        title = "Insert Length Standard Deviation",
        yaxis_title = "Length",
        quality_key = "insert_length_standard_deviation"
      )
    )
  )
)

total_variants_config <- list(
  plots = list(
    scatter_plot = modifyList(
      base_config_scatter_threshold,
      list(
        plotly_output_id = "scatterplot_threshold_wgs_total_variants",
        title = "Total Variants",
        yaxis_title = "Count",
        thresholds = list(
          min_threshold = 4750000,
          max_threshold = 10000000,
          adjusted_min = 4500000,
          adjusted_max = 10000000
        ),
        quality_key = "total_variants"
      )
    )
  )
)

bi_allelic_config <- list(
  plots = list(
    scatter_plot = modifyList(
      base_config_scatter_nothreshold,
      list(
        plotly_output_id = "scatterplot_nothreshold_wgs_biallelic",
        title = "Percentage Bi-allelic Variants",
        yaxis_title = "Percentage",
        quality_key = "percentage_biallelic"
      )
    )
  )
)

multi_allelic_config <- list(
  plots = list(
    scatter_plot = modifyList(
      base_config_scatter_nothreshold,
      list(
        plotly_output_id = "scatterplot_nothreshold_wgs_multiallelic",
        title = "Percentage Multi-allelic Variants",
        yaxis_title = "Percentage",
        quality_key = "percentage_multiallelic"
      )
    )
  )
)

snp_config <- list(
  plots = list(
    scatter_plot = modifyList(
      base_config_scatter_threshold,
      list(
        plotly_output_id = "scatterplot_threshold_wgs_snps",
        title = "Percentage SNPs",
        yaxis_title = "Percentage",
        thresholds = list(
          min_threshold = 80,
          max_threshold = 81,
          adjusted_min = 70,
          adjusted_max = 100
        ),
        quality_key = "percentage_snps"
      )
    )
  )
)

titv_config <- list(
  plots = list(
    scatter_plot = modifyList(
      base_config_scatter_threshold,
      list(
        plotly_output_id = "scatterplot_threshold_wgs_titv",
        title = "Ti/Tv ratio",
        yaxis_title = "Ratio",
        thresholds = list(
          min_threshold = 1.96,
          max_threshold = 1.98,
          adjusted_min = 0,
          adjusted_max = 2.2
        ),
        quality_key = "ti_tv_ratio"
      )
    )
  )
)

hethom_config <- list(
  plots = list(
    scatter_plot = modifyList(
      base_config_scatter_threshold,
      list(
        plotly_output_id = "scatterplot_threshold_wgs_hethom",
        title = "Het/Hom ratio",
        yaxis_title = "Ratio",
        thresholds = list(
          min_threshold = 1.3,
          max_threshold = 2.8,
          adjusted_min = 0,
          adjusted_max = 3.5
        ),
        quality_key = "het_hom_ratio"
      )
    )
  )
)

target_intervals_config <- list(
  plots = list(
    scatter_plot = modifyList(
      base_config_scatter_nothreshold,
      list(
        plotly_output_id = "scatterplot_nothreshold_wgs_intervals",
        title = "Target Intervals",
        yaxis_title = "Count",
        quality_key = "number_of_target_intervals"
      )
    )
  )
)

segments_config <- list( 
  plots = list(
    scatter_plot = modifyList(
      base_config_scatter_nothreshold,
      list(
        plotly_output_id = "scatterplot_nothreshold_wgs_segments",
        title = "Number of segments",
        yaxis_title = "Number of segments",
        quality_key = "number_of_segments"
      )
    )
  )
)

amplifications_config <- list(
  plots = list(
    scatter_plot = modifyList(
      base_config_scatter_nothreshold,
      list(
        plotly_output_id = "scatterplot_nothreshold_wgs_amplifications",
        title = "Number of amplifications",
        yaxis_title = "Number of amplifications",
        quality_key = "number_of_amplifications"
      )
    )
  )
)

deletions_config <- list(
  plots = list(
    scatter_plot = modifyList(
      base_config_scatter_nothreshold,
      list(
        plotly_output_id = "scatterplot_nothreshold_wgs_deletions",
        title = "Number of deletions",
        yaxis_title = "Number of deletions",
        quality_key = "number_of_deletions"
      )
    )
  )
)

passing_amplifications_config <- list(
  plots = list(
    scatter_plot = modifyList(
      base_config_scatter_nothreshold,
      list(
        plotly_output_id = "scatterplot_nothreshold_wgs_passing_amplifications",
        title = "Number of passing amplifications",
        yaxis_title = "Number of passing amplifications",
        quality_key = "percentage_number_of_passing_amplifications"
      )
    )
  )
)

passing_deletions_config <- list(
  plots = list(
    scatter_plot = modifyList(
      base_config_scatter_nothreshold,
      list(
        plotly_output_id = "scatterplot_nothreshold_wgs_passing_deletions",
        title = "Number of passing deletions",
        yaxis_title = "Number of passing deletions",
        quality_key = "percentage_number_of_passing_deletions"
      )
    )
  )
)

total_sv_config <- list(
  plots = list(
    scatter_plot = modifyList(
      base_config_scatter_threshold,
      list(
        plotly_output_id = "scatterplot_threshold_wgs_structural",
        title = "Total Structural Variants",
        yaxis_title = "Count",
        thresholds = list(
          min_threshold = 5000,
          max_threshold = 20000,
          adjusted_min = 5000,
          adjusted_max = 20000
        ),
        quality_key = "total_number_of_structural_variants_pass"
      )
    )
  )
)

deletions_sv_config <- list(
  plots = list(
    scatter_plot = modifyList(
      base_config_scatter_threshold,
      list(
        plotly_output_id = "scatterplot_threshold_wgs_deletions_sv",
        title = "Number of SV - deletions (%)",
        yaxis_title = "Percentage",
        thresholds = list(
          min_threshold = 0,
          max_threshold = 48,
          adjusted_min = 0,
          adjusted_max = 50
        ),
        quality_key = "percentage_number_of_deletions_pass"
      )
    )
  )
)

insertions_sv_config <- list(
  plots = list(
    scatter_plot = modifyList(
      base_config_scatter_threshold,
      list(
        plotly_output_id = "scatterplot_threshold_wgs_insertions_sv",
        title = "Number of SV - insertions (%)",
        yaxis_title = "Percentage",
        thresholds = list(
          min_threshold = 45,
          max_threshold = 80,
          adjusted_min = 45,
          adjusted_max = 80
        ),
        quality_key = "percentage_number_of_insertions_pass"
      )
    )
  )
)

duplications_sv_config <- list(
  plots = list(
    scatter_plot = modifyList(
      base_config_scatter_nothreshold,
      list(
        plotly_output_id = "scatterplot_nothreshold_wgs_duplications_sv",
        title = "Number of SV - duplications (%)",
        yaxis_title = "Percentage",
        quality_key = "percentage_number_of_duplications_pass"
      )
    )
  )
)

breakends_sv_config <- list(
  plots = list(
    scatter_plot = modifyList(
      base_config_scatter_nothreshold,
      list(
        plotly_output_id = "scatterplot_nothreshold_wgs_breakends_sv",
        title = "Number of SV - breakends (%)",
        yaxis_title = "Percentage",
        quality_key = "percentage_number_of_breakend_pairs_pass"
      )
    )
  )
)


mapped_reads_r1_config <- list(
  plots = list(
    scatter_plot = modifyList(
      base_config_scatter_threshold,
      list(
        plotly_output_id = "scatterplot_threshold_wgs_mappedreads_r1",
        title = "Mapped Reads - Read 1 (%)",
        yaxis_title = "Percentage",
        thresholds = list(
          min_threshold = 95,
          max_threshold = 100,
          adjusted_min = 95,
          adjusted_max = 100
        ),
        quality_key = "percentage_mapped_reads_r1"
      )
    )
  )
)

mapped_reads_r2_config <- list(
  plots = list(
    scatter_plot = modifyList(
      base_config_scatter_threshold,
      list(
        plotly_output_id = "scatterplot_threshold_wgs_mappedreads_r2",
        title = "Mapped Reads - Read 2 (%)",
        yaxis_title = "Percentage",
        thresholds = list(
          min_threshold = 95,
          max_threshold = 100,
          adjusted_min = 95,
          adjusted_max = 100
        ),
        quality_key = "percentage_mapped_reads_r2"
      )
    )
  )
)

q30_bases_r1_config <- list(
  plots = list(
    scatter_plot = modifyList(
      base_config_scatter_threshold,
      list(
        plotly_output_id = "scatterplot_threshold_wgs_q30bases_r1",
        title = "Q30 Bases - Read 1(%)",
        yaxis_title = "Percentage",
        thresholds = list(
          min_threshold = 85,
          max_threshold = 100,
          adjusted_min = 80,
          adjusted_max = 100
        ),
        quality_key = "percentage_q30_bases_r1"
      )
    )
  )
)

q30_bases_r2_config <- list(
  plots = list(
    scatter_plot = modifyList(
      base_config_scatter_threshold,
      list(
        plotly_output_id = "scatterplot_threshold_wgs_q30bases_r2",
        title = "Q30 Bases  - Read 2 (%)",
        yaxis_title = "Percentage",
        thresholds = list(
          min_threshold = 85,
          max_threshold = 100,
          adjusted_min = 80,
          adjusted_max = 100
        ),
        quality_key = "percentage_q30_bases_r2"
      )
    )
  )
)

softclipped_bases_r1_config <- list(
  plots = list(
    scatter_plot = modifyList(
      base_config_scatter_nothreshold,
      list(
        plotly_output_id = "scatterplot_nothreshold_wgs_softclippedbases_r1",
        title = "Softclipped Bases - Read 1 (%)",
        yaxis_title = "Percentage",
        quality_key = "percentage_soft_clipped_bases_r1"
      )
    )
  )
)

softclipped_bases_r2_config <- list(
  plots = list(
    scatter_plot = modifyList(
      base_config_scatter_nothreshold,
      list(
        plotly_output_id = "scatterplot_nothreshold_wgs_softclippedbases_r2",
        title = "Softclipped Bases - Read 2 (%)",
        yaxis_title = "Percentage",
        quality_key = "percentage_soft_clipped_bases_r2"
      )
    )
  )
)

mismatched_bases_r1_config <- list(
  plots = list(
    scatter_plot = modifyList(
      base_config_scatter_nothreshold,
      list(
        plotly_output_id = "scatterplot_nothreshold_wgs_mismatchedbases_r1",
        title = "Mismatched Bases - Read 1 (%)",
        yaxis_title = "Percentage",
        quality_key = "percentage_mismatched_bases_r1"
      )
    )
  )
)

mismatched_bases_r2_config <- list(
  plots = list(
    scatter_plot = modifyList(
      base_config_scatter_nothreshold,
      list(
        plotly_output_id = "scatterplot_nothreshold_wgs_mismatchedbases_r2",
        title = "Mismatched Bases - Read 2 (%)",
        yaxis_title = "Percentage",
        quality_key = "percentage_mismatched_bases_r2"
      )
    )
  )
)

runtime_config <- list(
  plots = list(
    scatter_plot = modifyList(
      base_config_scatter_nothreshold,
      list(
        plotly_output_id = "scatterplot_nothreshold_wgs_runtime",
        title = "Total Runtime DRAGEN (seconds)",
        yaxis_title = "Seconds",
        quality_key = "total_runtime"
      )
    )
  )
)

total_bases_config <- list(
  plots = list(
    scatter_plot = modifyList(
      base_config_scatter_nothreshold_lrs,
      list(
        plotly_output_id = "scatterplot_nothreshold_lrs_totalbases",
        title = "Total Bases (GB)",
        yaxis_title = "Total Bases (GB)",
        quality_key = "total_bases_gb",
        query = query_run_quality_metric_data
      )
    ),
    boxplot_serialnumber = modifyList(
      base_config_boxplot_lrs_serialnumber,
      list(
        plotly_output_id = "boxplot_lrs_serialnumber_totalbases",
        title = "Total Bases by Serial Number Seqeuncer",
        yaxis_title = "Total Bases (GB)",
        xaxis_title = "Serial Number",
        quality_key = "total_bases_gb"
      )
    ),
    boxplot_smrt_cell_lot_number = modifyList(
      base_config_boxplot_lrs,
      list(
        plotly_output_id = "boxplot_lrs_smrt_cell_lot_number_totalbases",
        title = "Total Bases by SMRTcell Lotnumber",
        yaxis_title = "Total Bases (GB)",
        xaxis_title = "SMRTcell Lotnumber",
        quality_key = "total_bases_gb",
        boxplot_quality_key = "smrt_cell_lot_number"
      )
    ),
    boxplot_sequencing_kit = modifyList(
      base_config_boxplot_lrs,
      list(
        plotly_output_id = "boxplot_lrs_sequencing_kit_totalbases",
        title = "Total Bases by Sequencing Kit Lotnumber",
        yaxis_title = "Total Bases (GB)",
        xaxis_title = "Sequencing Kit Lotnumber",
        quality_key = "total_bases_gb",
        boxplot_quality_key = "sequencing_kit"
      )
    )
  )
)

p0_config <- list(
  plots = list(
    scatter_plot = modifyList(
      base_config_scatter_nothreshold_lrs,
      list(
        plotly_output_id = "scatterplot_nothreshold_lrs_p0",
        title = "P0 (%)",
        yaxis_title = "Productivity - P0",
        quality_key = "p0_percentage",
        query = query_run_quality_metric_data
      )
    ),
    boxplot_serialnumber = modifyList(
      base_config_boxplot_lrs_serialnumber,
      list(
        plotly_output_id = "boxplot_lrs_serialnumber_p0",
        title = "P0 by Serial Number Seqeuncer",
        yaxis_title = "Productivity - P0",
        xaxis_title = "Serial Number",
        quality_key = "p0_percentage"
      )
    ),
    boxplot_smrt_cell_lot_number = modifyList(
      base_config_boxplot_lrs,
      list(
        plotly_output_id = "boxplot_lrs_smrt_cell_lot_number_p0",
        title = "P0 by SMRTcell Lotnumber",
        yaxis_title = "Productivity - P0",
        xaxis_title = "SMRTcell Lotnumber",
        quality_key = "p0_percentage",
        boxplot_quality_key = "smrt_cell_lot_number"
      )
    ),
    boxplot_sequencing_kit = modifyList(
      base_config_boxplot_lrs,
      list(
        plotly_output_id = "boxplot_lrs_sequencing_kit_p0",
        title = "P0 by Sequencing Kit Lotnumber",
        yaxis_title = "Productivity - P0",
        xaxis_title = "Sequencing Kit Lotnumber",
        quality_key = "p0_percentage",
        boxplot_quality_key = "sequencing_kit"
      )
    )
  )
)

p1_config <- list(
  plots = list(
    scatter_plot = modifyList(
      base_config_scatter_nothreshold_lrs,
      list(
        plotly_output_id = "scatterplot_nothreshold_lrs_p1",
        title = "P1 (%)",
        yaxis_title = "Productivity - P1",
        quality_key = "p1_percentage",
        query = query_run_quality_metric_data
      )
    ),
    boxplot_serialnumber = modifyList(
      base_config_boxplot_lrs_serialnumber,
      list(
        plotly_output_id = "boxplot_lrs_serialnumber_p1",
        title = "P1 by Serial Number Seqeuncer",
        yaxis_title = "Productivity - P1",
        xaxis_title = "Serial Number",
        quality_key = "p1_percentage"
      )
    ),
    boxplot_smrt_cell_lot_number = modifyList(
      base_config_boxplot_lrs,
      list(
        plotly_output_id = "boxplot_lrs_smrt_cell_lot_number_p1",
        title = "P1 by SMRTcell Lotnumber",
        yaxis_title = "Productivity - P1",
        xaxis_title = "SMRTcell Lotnumber",
        quality_key = "p1_percentage",
        boxplot_quality_key = "smrt_cell_lot_number"
      )
    ),
    boxplot_sequencing_kit = modifyList(
      base_config_boxplot_lrs,
      list(
        plotly_output_id = "boxplot_lrs_sequencing_kit_p1",
        title = "P1 by Sequencing Kit Lotnumber",
        yaxis_title = "Productivity - P1",
        xaxis_title = "Sequencing Kit Lotnumber",
        quality_key = "p1_percentage",
        boxplot_quality_key = "sequencing_kit"
      )
    )
  )
)

p2_config <- list(
  plots = list(
    scatter_plot = modifyList(
      base_config_scatter_nothreshold_lrs,
      list(
        plotly_output_id = "scatterplot_nothreshold_lrs_p2",
        title = "P2 (%)",
        yaxis_title = "Productivity - P2",
        quality_key = "p2_percentage",
        query = query_run_quality_metric_data
      )
    ),
    boxplot_serialnumber = modifyList(
      base_config_boxplot_lrs_serialnumber,
      list(
        plotly_output_id = "boxplot_lrs_serialnumber_p2",
        title = "P2 by Serial Number Seqeuncer",
        yaxis_title = "Productivity - P2",
        xaxis_title = "Serial Number",
        quality_key = "p2_percentage"
      )
    ),
    boxplot_smrt_cell_lot_number = modifyList(
      base_config_boxplot_lrs,
      list(
        plotly_output_id = "boxplot_lrs_smrt_cell_lot_number_p2",
        title = "P2 by SMRTcell Lotnumber",
        yaxis_title = "Productivity - P2",
        xaxis_title = "SMRTcell Lotnumber",
        quality_key = "p2_percentage",
        boxplot_quality_key = "smrt_cell_lot_number"
      )
    ),
    boxplot_sequencing_kit = modifyList(
      base_config_boxplot_lrs,
      list(
        plotly_output_id = "boxplot_lrs_sequencing_kit_p2",
        title = "P2 by Sequencing Kit Lotnumber",
        yaxis_title = "Productivity - P2",
        xaxis_title = "Sequencing Kit Lotnumber",
        quality_key = "p2_percentage",
        boxplot_quality_key = "sequencing_kit"
      )
    )
  )
)

polymerase_rl_config <- list(
  plots = list(
  scatter_plot = modifyList(
    base_config_scatter_nothreshold_lrs,
    list(
      plotly_output_id = "scatterplot_nothreshold_lrs_polymerasereadlength",
      title = "Polymerase Read Length (bp)",
      yaxis_title = "basepairs",
      quality_key = "polymerase_rl_bp",
      query = query_run_quality_metric_data
      )
    ),
    boxplot_serialnumber = modifyList(
      base_config_boxplot_lrs_serialnumber,
      list(
        plotly_output_id = "boxplot_lrs_serialnumber_polymerasereadlength",
        title = "Polymerase Read Length by Serial Number Seqeuncer",
        yaxis_title = "basepairs",
        xaxis_title = "Serial Number",
        quality_key = "polymerase_rl_bp"
      )
    ),
    boxplot_smrt_cell_lot_number = modifyList(
      base_config_boxplot_lrs,
      list(
        plotly_output_id = "boxplot_lrs_smrt_cell_lot_number_polymerasereadlength",
        title = "Polymerase Read Length by SMRTcell Lotnumber",
        yaxis_title = "basepairs",
        xaxis_title = "SMRTcell Lotnumber",
        quality_key = "polymerase_rl_bp",
        boxplot_quality_key = "smrt_cell_lot_number"
      )
    ),
    boxplot_sequencing_kit = modifyList(
      base_config_boxplot_lrs,
      list(
        plotly_output_id = "boxplot_lrs_sequencing_kit_polymerasereadlength",
        title = "Polymerase Read Length by Sequencing Kit Lotnumber",
        yaxis_title = "basepairs",
        xaxis_title = "Sequencing Kit Lotnumber",
        quality_key = "polymerase_rl_bp",
        boxplot_quality_key = "sequencing_kit"
      )
    )
  )
)

control_reads_config <- list(
  plots = list(
    scatter_plot = modifyList(
      base_config_scatter_nothreshold_lrs,
      list(
        plotly_output_id = "scatterplot_nothreshold_lrs_controlreads",
        title = "Number of Control Reads",
        yaxis_title = "Total Control Reads",
        quality_key = "control_total_reads",
        query = query_run_quality_metric_data
      )
    ),
    boxplot_serialnumber = modifyList(
      base_config_boxplot_lrs_serialnumber,
      list(
        plotly_output_id = "boxplot_lrs_serialnumber_controlreads",
        title = "Control Reads by Serial Number Seqeuncer",
        yaxis_title = "Total Control Reads",
        xaxis_title = "Serial Number",
        quality_key = "control_total_reads"
      )
    ),
    boxplot_smrt_cell_lot_number = modifyList(
      base_config_boxplot_lrs,
      list(
        plotly_output_id = "boxplot_lrs_smrt_cell_lot_number_controlreads",
        title = "Control Reads by SMRTcell Lotnumber",
        yaxis_title = "Total control reads",
        xaxis_title = "SMRTcell Lotnumber",
        quality_key = "control_total_reads",
        boxplot_quality_key = "smrt_cell_lot_number"
      )
    ),
    boxplot_sequencing_kit = modifyList(
      base_config_boxplot_lrs,
      list(
        plotly_output_id = "boxplot_lrs_sequencing_kit_controlreads",
        title = "Control Reads by Sequencing Kit Lotnumber",
        yaxis_title = "Total control reads",
        xaxis_title = "Sequencing Kit Lotnumber",
        quality_key = "control_total_reads",
        boxplot_quality_key = "sequencing_kit"
      )
    )
  )
)

control_polymerase_rl_config <- list(
  plots = list(
    scatter_plot = modifyList(
      base_config_scatter_nothreshold_lrs,
      list(
        plotly_output_id = "scatterplot_nothreshold_lrs_controlpolymeraserl",
        title = "Control Polymerase Read Length",
        yaxis_title = "basepairs",
        quality_key = "control_poly_rl_mean_bp",
        query = query_run_quality_metric_data
      )
    ),
    boxplot_serialnumber = modifyList(
      base_config_boxplot_lrs_serialnumber,
      list(
        plotly_output_id = "boxplot_lrs_serialnumber_controlpolymeraserl",
        title = "Control Polymerase Read Length by Serial Number Seqeuncer",
        yaxis_title = "basepairs",
        xaxis_title = "Serial Number",
        quality_key = "control_poly_rl_mean_bp"
      )
    ),
    boxplot_smrt_cell_lot_number = modifyList(
      base_config_boxplot_lrs,
      list(
        plotly_output_id = "boxplot_lrs_smrt_cell_lot_number_controlpolymeraserl",
        title = "Control Polymerase Read Length by SMRTcell Lotnumber",
        yaxis_title = "basepairs",
        xaxis_title = "SMRTcell Lotnumber",
        quality_key = "control_poly_rl_mean_bp",
        boxplot_quality_key = "smrt_cell_lot_number"
      )
    ),
    boxplot_sequencing_kit = modifyList(
      base_config_boxplot_lrs,
      list(
        plotly_output_id = "boxplot_lrs_sequencing_kit_controlpolymeraserl",
        title = "Control Polymerase Read Length by Sequencing Kit Lotnumber",
        yaxis_title = "basepairs",
        xaxis_title = "Sequencing Kit Lotnumber",
        quality_key = "control_poly_rl_mean_bp",
        boxplot_quality_key = "sequencing_kit"
      )
    )
  )
)

control_concordance_config <- list(
  plots = list(
    scatter_plot = modifyList(
      base_config_scatter_nothreshold_lrs,
      list(
        plotly_output_id = "scatterplot_nothreshold_lrs_controlconcordance",
        title = "Control Concordance (mean)",
        yaxis_title = "Percentage",
        quality_key = "control_concordance_mean",
        query = query_run_quality_metric_data
      )
    ),
    boxplot_serialnumber = modifyList(
      base_config_boxplot_lrs_serialnumber,
      list(
        plotly_output_id = "boxplot_lrs_serialnumber_controlconcordance",
        title = "Control Concordance by Serial Number Seqeuncer",
        yaxis_title = "Percentage",
        xaxis_title = "Serial Number",
        quality_key = "control_concordance_mean"
      )
    ),
    boxplot_smrt_cell_lot_number = modifyList(
      base_config_boxplot_lrs,
      list(
        plotly_output_id = "boxplot_lrs_smrt_cell_lot_number_controlconcordance",
        title = "Control Concordance by SMRTcell Lotnumber",
        yaxis_title = "Percentage",
        xaxis_title = "SMRTcell Lotnumber",
        quality_key = "control_concordance_mean",
        boxplot_quality_key = "smrt_cell_lot_number"
      )
    ),
    boxplot_sequencing_kit = modifyList(
      base_config_boxplot_lrs,
      list(
        plotly_output_id = "boxplot_lrs_sequencing_kit_controlconcordance",
        title = "Control Concordance by Sequencing Kit Lotnumber",
        yaxis_title = "Percentage",
        xaxis_title = "Sequencing Kit Lotnumber",
        quality_key = "control_concordance_mean",
        boxplot_quality_key = "sequencing_kit"
      )
    )
  )
)

coverage_config <- list(
  plots = list(
    scatter_plot = modifyList(
      base_config_scatter_threshold,
      list(
        plotly_output_id = "scatterplot_threshold_wes_coverage",
        title = "Coverage (mean)",
        yaxis_title = "Coverage (mean)",
        quality_key = "qm_mean_coverage",
        thresholds = list(
          min_threshold = 80,
          max_threshold = 500,
          adjusted_min = 15,
          adjusted_max = 400
        )
      )
    )
  )
)

coverage_20x_config <- list(
  plots = list(
    scatter_plot = modifyList(
      base_config_scatter_threshold,
      list(
        plotly_output_id = "scatterplot_threshold_wes_20xcoverage",
        title = ">20x Coverage (%)",
        yaxis_title = "Percentage",
        quality_key = "qm_percentage_20x",
        thresholds = list(
          min_threshold = 99,
          max_threshold = 100,
          adjusted_min = 98,
          adjusted_max = 100
        )
      )
    )
  )
)

coverage_50x_config <- list(
  plots = list(
    scatter_plot = modifyList(
      base_config_scatter_threshold,
      list(
        plotly_output_id = "scatterplot_threshold_wes_50xcoverage",
        title = ">50x Coverage (%)",
        yaxis_title = "Percentage",
        quality_key = "qm_percentage_50x",
        thresholds = list(
          min_threshold = 25,
          max_threshold = 100,
          adjusted_min = 25,
          adjusted_max = 100
        )
      )
    )
  )
)

duplicates_config <- list(
  plots = list(
    scatter_plot = modifyList(
      base_config_scatter_threshold,
      list(
        plotly_output_id = "scatterplot_threshold_wes_duplicates",
        title = "Duplicates (%)",
        yaxis_title = "Percentage",
        thresholds = list(
          min_threshold = 0,
          max_threshold = 15,
          adjusted_min = 0,
          adjusted_max = 30
        ),
        quality_key = "qm_percentage_dup_mapped_reads"
      )
    )
  )
)

on_target_config <- list(
  plots = list(
    scatter_plot = modifyList(
      base_config_scatter_threshold,
      list(
        plotly_output_id = "scatterplot_threshold_wes_ontarget",
        title = "On Target (%)",
        yaxis_title = "Percentage",
        thresholds = list(
          min_threshold = 60,
          max_threshold = 100,
          adjusted_min = 40,
          adjusted_max = 100
        ),
        quality_key = "qm_percentage_on_target_reads"
      )
    ),
    scatter_plt_xy = modifyList(
      base_config_scatter_threshold_xy,
      list(
        plotly_output_id = "scatterplot_threshold_wes_ontarget_insert",
        title = "On Target (%) vs Insert size (bp)",
        yaxis_title = "On Target (%)",
        xaxis_title = "Median Insert Size (bp)",
        quality_key_x = "qm_median_insert_size",
        quality_key_y = "qm_percentage_on_target_reads",
        thresholds = list(
          min_threshold = 60,
          max_threshold = 100,
          adjusted_min = 40,
          adjusted_max = 100
        )
      )
    )
  )
)

insert_size_config <- list(
  plots = list(
    scatter_plot = modifyList(
      base_config_scatter_threshold,
      list(
        plotly_output_id = "scatterplot_threshold_wes_insert",
        title = "Insert Size (median)",
        yaxis_title = "Basepairs",
        thresholds = list(
          min_threshold = 150,
          max_threshold = 300,
          adjusted_min = 50,
          adjusted_max = 350
        ),
        quality_key = "qm_median_insert_size"
      )
    ),
    scatter_plot_xy = modifyList(
      base_config_scatter_threshold_xy,
      list(
        plotly_output_id = "scatterplot_threshold_wes_insert_ontarget",
        title = "Insert size (bp) vs On Target (%)",
        yaxis_title = "Median Insert Size (bp)",
        xaxis_title = "On Target (%)",
        quality_key_x = "qm_percentage_on_target_reads",
        quality_key_y = "qm_median_insert_size",
        thresholds = list(
          min_threshold = 150,
          max_threshold = 300,
          adjusted_min = 50,
          adjusted_max = 350
        )
      )
    )
  )
)

error_rate_config <- list(
  plots = list(
    scatter_plot = modifyList(
      base_config_scatter_threshold,
      list(
        plotly_output_id = "scatterplot_threshold_wes_errorrate",
        title = "Decimal representation of percentage Error Rate",
        yaxis_title = "Decimal representation of percentage",
        thresholds = list(
          min_threshold = 0,
          max_threshold = 0.008,
          adjusted_min = 0,
          adjusted_max = 0.01
        ),
        quality_key = "qm_error_rate"
      )
    )
  )
)

conifer_config <- list(
  plots = list(
    scatter_plot = modifyList(
      base_config_scatter_threshold,
      list(
        plotly_output_id = "scatterplot_threshold_wes_conifer",
        title = "Total Conifer Segments",
        yaxis_title = "Count",
        thresholds = list(
          min_threshold = 0,
          max_threshold = 25,
          adjusted_min = 0,
          adjusted_max = 200
        ),
        quality_key = "total_conifer_segments"
      )
    )
  )
)

gc_config <- list(
  plots = list(
    scatter_plot = modifyList(
      base_config_scatter_threshold,
      list(
        plotly_output_id = "scatterplot_threshold_wes_gc",
        title = "GC (%)",
        yaxis_title = "Percentage",
        thresholds = list(
          min_threshold = 50,
          max_threshold = 60,
          adjusted_min = 30,
          adjusted_max = 80
        ),
        quality_key = "qm_gc_percentage"
      )
    )
  )
)

contamination_config <- list(
  plots = list(
    scatter_plot = modifyList(
      base_config_scatter_threshold,
      list(
        plotly_output_id = "scatterplot_threshold_wes_contamination",
        title = "Estimated Sample Contamination (%)",
        yaxis_title = "Percentage",
        thresholds = list(
          min_threshold = 0,
          max_threshold = 2,
          adjusted_min = 0,
          adjusted_max = 15
        ),
        quality_key = "estimated_contamination_percentage"
      )
    )
  )
)

amount_wes_sample_config <- list(
  plots = list(
    bar_plot = modifyList(
      base_config_barplot,
      list(
        plotly_output_id = "barplot_amount_samples_wes_per_month",
        title = "Processed Samples",
        yaxis_title = "Count"
      )
    )
  )
)

# Centralized configuration for tabs and their corresponding actions
tab_config <- list(
  wgsoverview = list(
    "Processed Samples" = processed_samples_config,
    "Duplicate Reads (%)" = duplicate_reads_config,
    "Contamination" = contamination_config
  ),
  wgscoverage = list(
    "Average Autosomal Coverage" = average_autosomal_coverage_config,
    "Median Autosomal Coverage" = median_autosomal_coverage_config,
    "Mean/Median Ratio" = mean_median_autosomal_coverage_config,
    "Uniformity of coverage (PCT > 0.2*mean)" = pct_bigger_than_0.2_config,
    "Uniformity of coverage (PCT > 0.4*mean)" = pct_bigger_than_0.4_config,
    "Mitochondrial" = mitochondiral_coverage_config,
    "Chromosome x" = chromosome_x_coverage_config,
    "Chromosome y" = chromosome_y_coverage_config,
    "Chromosome" = chromosomes_median_over_autosomal_median_config
  ),
  wgsmapping = list(
    "Input Reads" = input_reads_config,
    "Mapped Reads" = mapped_reads_config,
    "Q30 Bases" = q30_bases_config,
    "Soft-Clipped Bases" = softclipped_bases_config,
    "Paired Properly" = paired_properly_config,
    "Paired dif Chr" = paired_dif_chr_config,
    "Insert length (Mean)" = insert_length_mean_config,
    "Insert length (Median)" = insert_length_median_config,
    "Insert length (std dev)" = insert_length_std_dev_config
  ),
  wgsvariantcalling = list(
    "Total Variants" = total_variants_config,
    "Bi-allelic" = bi_allelic_config,
    "Multi-allelic" = multi_allelic_config,
    "SNPs (%)" = snp_config,
    "Ti/Tv ratio" = titv_config,
    "Het/Hom ratio" = hethom_config
  ),
  wgscnv = list(
    "Target Intervals" = target_intervals_config,
    "Segments" = segments_config,
    "Amplifications" = amplifications_config,
    "Deletions" = deletions_config,
    "Passing Amplifications" = passing_amplifications_config,
    "Passing Deletions" = passing_deletions_config
  ),
  wgssv = list(
    "Total Structural Variants" = total_sv_config,
    "SV Deletions (%)" = deletions_sv_config,
    "SV Insertions (%)" = insertions_sv_config,
    "SV Duplications (%)" = duplications_sv_config,
    "SV Breakends (%)" = breakends_sv_config
  ),
  wgsr1r2metrics = list(
    "Mapped Reads (R1)" = mapped_reads_r1_config,
    "Mapped Reads (R2)" = mapped_reads_r2_config,
    "Q30 Bases (R1)" = q30_bases_r1_config,
    "Q30 Bases (R2)" = q30_bases_r2_config,
    "Soft-Clipped Bases (R1)" = softclipped_bases_r1_config,
    "Soft-Clipped Bases (R2)" = softclipped_bases_r2_config,
    "Mismatched bases (R1)" = mismatched_bases_r1_config,
    "Mismatched bases (R2)" = mismatched_bases_r2_config
  ),
  wgstime = list(
    "Total Runtime" = runtime_config
  ),
  lrs = list(
    "Total Bases" = total_bases_config,
    "P0" = p0_config,
    "P1" = p1_config,
    "P2" = p2_config,
    "Polymerase RL" = polymerase_rl_config,
    "Control Reads" = control_reads_config,
    "Control Polymerase RL" = control_polymerase_rl_config,
    "Control Concordance"  = control_concordance_config
  ),
  wes = list(
    "Coverage" = coverage_config,
    ">20x Coverage (%)" = coverage_20x_config,
    ">50x Coverage (%)" = coverage_50x_config,
    "Duplicates (%)" = duplicates_config,
    "On Target (%)" = on_target_config,
    "Insert Size" = insert_size_config,
    "Error Rate (%)" = error_rate_config,
    "Conifer Segments" = conifer_config,
    "GC (%)" = gc_config,
    "Contamination (%)" = contamination_config,
    "Processed Samples" = amount_wes_sample_config
  )
)