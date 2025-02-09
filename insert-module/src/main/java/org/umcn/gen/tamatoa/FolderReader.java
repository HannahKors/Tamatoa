package org.umcn.gen.tamatoa;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.File;
import java.io.IOException;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

/**
 * The FolderReader class is responsible for processing folders containing CSV files,
 * parsing their contents, and inserting the parsed data into the PostgreSQL database.
 */
public class FolderReader {
    private static final Logger LOG = LoggerFactory.getLogger(FolderReader.class);

    public static void main(String[] args) {

        try {
            processDataType(DataType.WGS);
            processDataType(DataType.WES);
            processDataType(DataType.LRS);
        } catch (Exception e) {
            System.err.println("An error occurred while reading data from folders: " + e.getMessage());
        }

    }


    /**
     * Processes all CSV files for a specific DataType by reading the folder, parsing
     * the files, and inserting the parsed data into a database.
     *
     * @param dataType The DataType for which CSV files are to be processed.
     * @throws IOException If an error occurs while reading the files or the folder.
     */
    static void processDataType(DataType dataType) throws IOException {
        File folder = dataType.getFolder();
        List<File> csvFiles = checkFolder(folder);

        for (File csvFile : csvFiles) {
            try {
                List<CsvData> csvDataList = CsvParser.readCsvFile(csvFile, dataType);

                if (csvDataList.isEmpty()) {
                    LOG.warn("No valid data found in file: {}", csvFile.getName());
                    continue;
                }

                try (Connection connection = PostgresConnector.getConnection()) {
                    CsvDataInserter inserter = new CsvDataInserter(connection);

                    for (CsvData csvData : csvDataList) {
                        if (csvData.getQualityData().isEmpty()) {
                            LOG.warn("Skipping empty CSV data: {}", csvFile.getName());
                            continue;
                        }
                        inserter.insertCsvData(csvData);
                        LOG.info("Successfully inserted data for sample: {} of Datatype: {}", csvData.getSampleId(), dataType.name());
                    }
                }
            } catch (SQLException e) {
                LOG.error("Error processing file {}: {}", csvFile.getName(), e.getMessage());
            }
        }
    }


    /**
     * Checks whether the specified folder exists, is a directory, and contains valid CSV files.
     *
     * @param folder The folder to check.
     * @return A list of valid CSV files in the folder.
     * @throws IOException If the folder is invalid, empty, or an error occurs while accessing it.
     */
    static List<File> checkFolder(File folder) throws IOException {
        if (!folder.exists() || !folder.isDirectory()) {
            throw new IOException("Invalid directory: " + folder.getAbsolutePath());
        }
        return validateCsvFiles(folder);
    }

    /**
     * Validates and retrieves CSV files from the specified folder. Non-CSV files are logged as warnings.
     *
     * @param folder The folder to validate.
     * @return A list of valid CSV files in the folder.
     * @throws IOException If the folder is empty or an error occurs while listing files.
     */
    static List<File> validateCsvFiles(File folder) throws IOException {
        File[] allFiles = folder.listFiles();
        List<File> csvFiles = new ArrayList<>();
        int nonCsvCount = 0;

        if (allFiles == null) {
            throw new IOException("Error listing files in directory: " + folder.getAbsolutePath());
        }
        if (allFiles.length == 0) {
            throw new IOException("The directory is empty: " + folder.getAbsolutePath());
        }
        for (File file : allFiles) {
            if (file.isFile() && file.getName().toLowerCase().endsWith(".csv")) {
                csvFiles.add(file);
            } else {
                nonCsvCount++;
            }
        }
        warnNonCsvFiles(folder, nonCsvCount);
        return csvFiles;
    }

    /**
     * Logs a warning if non-CSV files are detected in the folder.
     *
     * @param folder      The folder being checked.
     * @param nonCsvCount The number of non-CSV files found in the folder.
     */
    static void warnNonCsvFiles(File folder, int nonCsvCount) {
        if (nonCsvCount > 0) {
            LOG.warn("Non-CSV files detected in folder {}: {} non-CSV files found", folder.getAbsolutePath(), nonCsvCount);
        }
    }
}
