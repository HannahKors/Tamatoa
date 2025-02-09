package org.umcn.gen.tamatoa;

import java.io.File;

public enum DataType {
    //datatype.name prints the NGS type
//    WGS("C:/Users/Z468195/Documents/Test data/WGS", "\t"),
//    WES("C:/Users/Z468195/Documents/Test data/WES", "\t"),
//    LRS("C:/Users/Z468195/Documents/Test data/LRS", ",");

//    WGS("Z:/novaseq/genomes/trend", "\t"),
//    WES("Z:/novaseq/exomes/trend", "\t"),
//    LRS("H:/GD Thema NGS/trendanalysis/lrAmplicon", ",");

    WGS("C:/Users/Z468195/Documents/Data_16_1_2025_uur_13_55/trend_genome", "\t"),
    WES("C:/Users/Z468195/Documents/Data_16_1_2025_uur_13_55/trend_exome", "\t"),
    LRS("C:/Users/Z468195/Documents/Data_16_1_2025_uur_13_55/lrAmplicon",",");

    private final File folderPath;
    private final String delimiter;

    DataType(String standardPath, String delimiter) {
        this.folderPath = new File(standardPath);
        this.delimiter = delimiter;
    }

    public File getFolder() {
        return folderPath;
    }

    public String getDelimiter() {
        return delimiter;
    }
}
