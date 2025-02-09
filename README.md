# Tamatoa

## Overview
This tool processes and visualizes genomic data from Whole Genome Sequencing (WGS), Whole Exome Sequencing (WES), and Long-Read Sequencing (LRS) datasets. It integrates PostgreSQL for data storage, Maven for project management, and Shiny Server for data visualization.

## Prerequisites
* PostgreSQL version 17.0
* Maven version 4.0.0
* R version 4.4.1
  * Shiny pacakge version 1.9.1

## Installation
1. ### Database Setup
Navigate to the database\db_setup directory.
Execute the CreateQCDatabase.sql script to create the necessary tables:
```
psql -U your_username -f CreateQCDatabase.sql
```

To drop the existing tables, use the DropQCDatabase.sql script:
```
psql -U your_username -f DropQCDatabase.sql
```

2. ### Maven Project Configuration
Navigate to the insert-module\src\main\java\org\umcn\gen\tamatoa directory.
Update the DataType.java file with the correct folder paths and delimiters:
```
WGS("C:/Users/Z468195/Documents/Data/trend_genome", "\t"),
WES("C:/Users/Z468195/Documents/Data/trend_exome", "\t"),
LRS("C:/Users/Z468195/Documents/Data/lrAmplicon", ",");
```

Update the Postgresconnector.java file with your PostgreSQL credentials:
```
private static final String URL = "your_database_url";
private static final String USER = "your_database_user";
private static final String PASSWORD = "your_database_password";
```

3. ### Data Processing
The CsvParser.java file handles data processing with specific formatting rules and header mappings.
Ensure the header formatting rules and mappings are correctly specified in the CsvParser.java file.

4. ### Shiny Server Setup
Navigate to the localhosting Shiny-Server directory.
Run the run.R file to start the Shiny Server:
```
Rscript run.R
```

5. ### Visualization Module Configuration
Navigate to the visualization-module directory.
Update the global.R file with your database credentials:
```
dbname = "your_database_name",
host = "your_database_host",
port = "your_database_port",
user = "your_database_user",
password = "your_database_password"
```

The plots are also configured in global.R, specifying thresholds, processing details, y-axis labels, and visualization thresholds.
Alterations to the plots can be altered here.

## Usage
Ensure the PostgreSQL database is set up and running.
Process and isnert the data using the Maven project.
Start the Shiny Server to visualize the data and visit the URL on which the Tamatoa Shiny web application runs on.
