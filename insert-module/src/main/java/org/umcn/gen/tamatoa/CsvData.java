package org.umcn.gen.tamatoa;

import java.util.Date;
import java.util.Map;
import java.util.StringJoiner;

public class CsvData {
    private final String fileName;
    private final String ngsType;
    private final String sampleId;
    private final String experimentName;
    private final Date analysisDate;
    private final Map<String, Object> qualityData;

    public CsvData(String fileName, String ngsType, String sampleId, String experimentName, Date analysisDate, Map<String, Object> qualityData) {
        this.fileName = fileName;
        this.ngsType = ngsType;
        this.sampleId = sampleId;
        this.experimentName = experimentName;
        this.analysisDate = analysisDate;
        this.qualityData = qualityData;
    }

    public String getFileName() {
        return fileName;
    }

    public String getNgsType() {
        return ngsType;
    }

    public String getSampleId() {
        return sampleId;
    }

    public String getExperimentName() {
        return experimentName;
    }

    public Date getAnalysisDate() {
        return analysisDate;
    }

    public Map<String, Object> getQualityData() {
        return qualityData;
    }

    @Override
    public String toString() {
        StringJoiner sj = new StringJoiner("\n");
        sj.add("File: " + fileName);
        sj.add("NGS Type: " + ngsType);
        sj.add("Sample ID: " + (sampleId != null ? sampleId : "N/A"));
        sj.add("Experiment Name: " + (experimentName != null ? experimentName : "N/A"));
        sj.add("Analysis Date: " + (analysisDate != null ? analysisDate : "N/A"));

        for (Map.Entry<String, Object> entry : qualityData.entrySet()) {
            sj.add("\t" + entry.getKey() + ": " + entry.getValue());
        }
        return sj.toString();
    }
}
