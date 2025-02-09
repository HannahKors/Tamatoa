-- Created by Vertabelo (http://vertabelo.com)
-- Production date: 2024-10-10
-- Last modification date: 2024-10-11

-- tables
-- Table: Experiment
CREATE TABLE Experiment (
    experiment_identifier BIGSERIAL  NOT NULL,
    experiment_name Varchar  NOT NULL,
    analysis_date date  NOT NULL,
    run_id Varchar  NULL,
    sequencer_series Varchar  NULL,
    sequencer_id Varchar  NULL,
    library_prep_kit Varchar  NULL,
    enrichment_kit Varchar  NULL,
    NGS_ngs_type Varchar  NOT NULL,
    CONSTRAINT Experiment_pk PRIMARY KEY (experiment_identifier)
);

-- Table: NGS
CREATE TABLE NGS (
    ngs_type Varchar  NOT NULL,
    CONSTRAINT NGS_pk PRIMARY KEY (ngs_type)
);

-- Table: Quality_Metrics
CREATE TABLE Quality_Metrics (
    Sample_sample_identifier BIGSERIAL  NOT NULL,
    quality_metric_key Varchar  NOT NULL,
    quality_metric_value Varchar  NOT NULL,
    PRIMARY KEY (Sample_sample_identifier, quality_metric_key)
);

-- Table: Run_Quality_Metrics
CREATE TABLE Run_Quality_Metrics (
    Experiment_experiment_identifier BIGSERIAL  NOT NULL,
    run_quality_metric_key Varchar  NOT NULL,
    run_quality_metric_value Varchar  NOT NULL,
    PRIMARY KEY (Experiment_experiment_identifier, run_quality_metric_key)
);

-- Table: Sample
CREATE TABLE Sample (
    sample_identifier BIGSERIAL  NOT NULL,
    sample_id Varchar  NOT NULL,
    Experiment_experiment_identifier int  NOT NULL,
    CONSTRAINT Sample_pk PRIMARY KEY (sample_identifier)
);

-- foreign keys
-- Reference: Expirement_NGS (table: Experiment)
ALTER TABLE Experiment ADD CONSTRAINT Expirement_NGS
    FOREIGN KEY (NGS_ngs_type)
    REFERENCES NGS (ngs_type)  
    NOT DEFERRABLE 
    INITIALLY IMMEDIATE
;

-- Reference: Quality_Metrics_LRS_Experiment (table: Run_Quality_Metrics)
ALTER TABLE Run_Quality_Metrics ADD CONSTRAINT Quality_Metrics_LRS_Experiment
    FOREIGN KEY (Experiment_experiment_identifier)
    REFERENCES Experiment (experiment_identifier)  
    NOT DEFERRABLE 
    INITIALLY IMMEDIATE
;

-- Reference: Quality_Metrics_Sample (table: Quality_Metrics)
ALTER TABLE Quality_Metrics ADD CONSTRAINT Quality_Metrics_Sample
    FOREIGN KEY (Sample_sample_identifier)
    REFERENCES Sample (sample_identifier)  
    NOT DEFERRABLE 
    INITIALLY IMMEDIATE
;

-- Reference: Sample_Expirement (table: Sample)
ALTER TABLE Sample ADD CONSTRAINT Sample_Expirement
    FOREIGN KEY (Experiment_experiment_identifier)
    REFERENCES Experiment (experiment_identifier)  
    NOT DEFERRABLE 
    INITIALLY IMMEDIATE
;

-- End of file.
