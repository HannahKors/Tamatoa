-- Created by Vertabelo (http://vertabelo.com)
-- Production date: 2024-10-10
-- Last modification date: 2024-10-11

-- foreign keys
ALTER TABLE Experiment
    DROP CONSTRAINT Expirement_NGS;

ALTER TABLE Run_Quality_Metrics
    DROP CONSTRAINT Quality_Metrics_LRS_Experiment;

ALTER TABLE Quality_Metrics
    DROP CONSTRAINT Quality_Metrics_Sample;

ALTER TABLE Sample
    DROP CONSTRAINT Sample_Expirement;

-- tables
DROP TABLE Experiment;

DROP TABLE NGS;

DROP TABLE Quality_Metrics;

DROP TABLE Run_Quality_Metrics;

DROP TABLE Sample;

-- End of file.
