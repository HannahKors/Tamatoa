package org.umcn.gen.tamatoa;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.BufferedReader;
import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.*;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class CsvParser {

    private static final Logger LOG = LoggerFactory.getLogger(CsvParser.class);

    // Formatting rules for headers
    private static final String[][] HEADER_FORMATTING_RULES = {
            {"\"", ""},                    // Remove double quotes
            {"%", "percentage "},          // Replace % with "percentage "
            {" / ", " ratio "},            // Replace " / " with " ratio "
            {"/", " "},                    // Replace single / with a space
            {"=", ""},                     // Remove any "=" symbol
            {"-", "_"},                     // replace - with _
            {":", ""},                     // Remove colons
            {">", "bigger_than"},          // Replace ">" with "bigger_than"
            {"<", "less_than"},            // Replace "<" with "less_than"
            {"[()]", ""},                  // Remove parentheses
            {"\\[|\\]", ""},               // Remove brackets
            {"\\*", " times "},              // Replace * with "times"
            {" {2,}", " "},                // Replace multiple spaces with a single space
            {"≥", "bigger_than_or_equal_to"}
    };

    private static final String[][] LRS_HEADER_NAMES = {
            {"instrument", "sequencer_id"},
            {"run_name", "experiment_name"},
            {"sample_name", "sample_id"},
            {"transfer_complete", "analysis_date"},
            {"sample_comment", ""},
            {"sample_summary", ""},
            {"run_comments", ""},
            {"experiment_name", ""},
            {"experiment_id", ""},
            {"run_start", ""},
            {"run_complete", ""},
            {"run_id", ""},
            {"run_description", ""}
    };

    private static final String[][] WGS_WES_HEADERS = {
            {"sampleid", "sample_id"},
            {"runid", "run_id"}
    };

    /**
     * Reads a CSV file and parses its data into a CsvData object and also parses not-nullable columns of the database
     * into the CsvData class.
     *
     * @param file     The CSV file to read.
     * @param dataType The DataType used to determine the format and delimiter for parsing.
     * @return A CsvData object containing the file name, data type, and parsed data.
     * @throws IOException If an error occurs while reading the file.
     */
    public static List<CsvData> readCsvFile(File file, DataType dataType) throws IOException {
        List<CsvData> csvDataList = new ArrayList<>();
        String[] headers = null;

        try (BufferedReader br = Files.newBufferedReader(file.toPath())) {
            String headerLine = br.readLine();
            if (headerLine == null) {
                LOG.error("File is empty: {}", file.getAbsolutePath());
                return csvDataList; // Return an empty list
            }

            headers = parseHeaders(headerLine, dataType.getDelimiter());
            String line;

            while ((line = br.readLine()) != null) {
                Map<String, Object> csvDataMap = new HashMap<>();
                String sampleId = null;
                String experimentName = null;
                Date analysisDate = null;

                Object[] parsedValues = splitProcessDataLines(line, dataType, headers);
                Set<String> specialHeaders = Set.of("sample_id", "experiment_name", "analysis_date");

                for (int i = 0; i < headers.length; i++) {
                    if (i < parsedValues.length && parsedValues[i] != null && !parsedValues[i].toString().trim().isEmpty() && !headers[i].isEmpty()) {
                        String value = parsedValues[i].toString().trim();
                        if ("NA".equalsIgnoreCase(value)) {
                            continue; // Skip this key-value pair entirely
                        }

                        if (specialHeaders.contains(headers[i].toLowerCase())) {
                            if ("sample_id".equalsIgnoreCase(headers[i])) {
                                sampleId = value;
                            }
                            if ("experiment_name".equalsIgnoreCase(headers[i])) {
                                experimentName = value;
                            }
                            if ("analysis_date".equalsIgnoreCase(headers[i])) {
                                analysisDate = tryConvertDate(value, dataType);
                            }
                        } else {
                            csvDataMap.put(headers[i], parsedValues[i].toString().replaceAll(" ", ""));
                        }
                    }
                }

                if (analysisDate == null && dataType.name().equals("WES")) {
                    analysisDate = extractDateFromFilename(file.getName());
                }

                CsvData csvData = new CsvData(file.getName(), dataType.name(), sampleId, experimentName, analysisDate, csvDataMap);
                csvDataList.add(csvData);
            }
        }

        return csvDataList;
    }


    /**
     * Extracts a date from a filename using a specific pattern.
     *
     * @param filename The filename to extract the date from.
     * @return The extracted Date object, or null if parsing fails.
     */
    public static Date extractDateFromFilename(String filename) {
        // Regular expression to match a date in the yyyy_MM_dd or yyyy-MM-dd format (e.g., 2024_01_11 or 2024-01-11)
        String regex = "(\\d{4}[-_]\\d{2}[-_]\\d{2})";
        Pattern pattern = Pattern.compile(regex);
        Matcher matcher = pattern.matcher(filename);

        if (matcher.find()) {
            // Extract the date as a string
            String dateString = matcher.group(1);

            // Replace underscores with dashes to convert to the yyyy-MM-dd format if needed
            dateString = dateString.replace("_", "-");

            // Parse the extracted date string into a Date object
            SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd");
            try {
                return sdf.parse(dateString);
            } catch (Exception e) {
                // Handle any parsing error if needed
                e.printStackTrace();
            }
        }

        // Return null if no date is found
        return null;
    }


    /**
     * Processes a single CSV row into parsed values based on headers and data type.
     * This only processes the remaining values that were not assigned to the custom CsvData class
     *
     * @param line     The raw CSV row string.
     * @param dataType The data type containing delimiter information.
     * @return An array of parsed values for the row.
     */
    private static Object[] splitProcessDataLines(String line, DataType dataType, String[] headers) {
        String[] rawValues = processValues(line, dataType);
        Object[] parsedValues = new Object[rawValues.length];

        if (dataType.name().equals("LRS")) {
            replaceLRSHeaders(headers);
        }
        if (dataType.name().equals("WES") || dataType.name().equals("WGS")) {
            replaceWGSWESHeaders(headers);
        }
        for (int i = 0; i < rawValues.length; i++) {
            parsedValues[i] = convertValues(rawValues[i], dataType);
        }
        return parsedValues;
    }

    /**
     * Replaces LRS-specific headers with mapped names in the provided header array.
     *
     * @param headers The header array to be updated.
     */
    private static void replaceLRSHeaders(String[] headers) {
        for (int i = 0; i < headers.length; i++) {
            for (String[] nameMapping : LRS_HEADER_NAMES) {
                if (headers[i].equals(nameMapping[0])) {
                    headers[i] = nameMapping[1].isEmpty() ? "" : nameMapping[1];
                    break; // Stop checking other name mappings for this header
                }
            }
        }
    }

    /**
     * Replaces WGS/WES-specific headers with mapped names in the provided header array.
     *
     * @param headers The header array to be updated.
     */
    private static void replaceWGSWESHeaders(String[] headers) {
        for (int i = 0; i < headers.length; i++) {
            for (String[] nameMapping : WGS_WES_HEADERS) {
                if (headers[i].equals(nameMapping[0])) {
                    headers[i] = nameMapping[1].isEmpty() ? "" : nameMapping[1];
                    break; // Stop checking other name mappings for this header
                }
            }
        }
    }

    /**
     * Processes the raw values by splitting the line using the delimiter and removing quotes.
     *
     * @param line     The raw CSV row string.
     * @param dataType The data type containing delimiter information.
     * @return An array of raw values.
     */
    private static String[] processValues(String line, DataType dataType) {
        line = line.replaceAll("\"", "");  // Remove quotes from values
        String[] values = line.split(dataType.getDelimiter());

        for (int i = 0; i < values.length; i++) {
            // Check if the value ends with ".0" and remove it if so
            if (values[i].endsWith(".0")) {
                values[i] = values[i].substring(0, values[i].length() - 2);
            }
        }
        return values;
    }

    /**
     * Converts a raw CSV value to an appropriate data type: Integer, Double, Date (formatted as yyyy-MM-dd), or String.
     *
     * @param value    The raw value string.
     * @param dataType The data type.
     * @return The converted value (Integer, Double, Date, or String).
     */
    private static Object convertValues(String value, DataType dataType) {
        Integer intValue = tryConvertInt(value);
        if (intValue != null) {
            return intValue;
        }

        Double doubleValue = tryConvertDouble(value);
        if (doubleValue != null) {
            return doubleValue;
        }

        return value; // Return as String if no other type matched
    }

    /**
     * Attempts to convert a string to an Integer.
     *
     * @param value The string to parse.
     * @return The parsed Integer, or null if parsing fails.
     */
    private static Integer tryConvertInt(String value) {
        try {
            return Integer.parseInt(value.trim());
        } catch (NumberFormatException e) {
            return null;
        }
    }

    /**
     * Attempts to convert a string to a Double.
     *
     * @param value The string to parse.
     * @return The parsed Double, or null if parsing fails.
     */
    private static Double tryConvertDouble(String value) {
        try {
            return Double.parseDouble(value.trim());
        } catch (NumberFormatException e) {
            return null;
        }
    }

    /**
     * Attempts to convert a string into a Date object using common date formats.
     *
     * @param value The date string to parse.
     * @return The parsed Date, or null if parsing fails.
     */
    private static Date tryConvertDate(String value, DataType dataType) {
        // Define multiple date formats
        String[] dateFormatsLRS = {
                "MM.dd.yyyy HH:mm",  // Expected format for LRS (e.g., 07.28.2024 07:58)
        };

        String[] dateFormatsWGS = {
                "dd-MM-yyyy", // Expected format for WGS (e.g., 10-06-2024)
        };

        SimpleDateFormat sdf;

// Handle both LRS and WGS types with the same logic
        if (dataType.name().equals("LRS") || dataType.name().equals("WGS")) {
            // Choose the correct date formats based on the data type
            String[] dateFormats = dataType.name().equals("LRS") ? dateFormatsLRS : dateFormatsWGS;

            for (String format : dateFormats) {
                sdf = new SimpleDateFormat(format);
                try {
                    Date date = sdf.parse(value.trim());
                    // Return in yyyy-MM-dd format
                    SimpleDateFormat outputFormat = new SimpleDateFormat("yyyy-MM-dd");
                    return outputFormat.parse(outputFormat.format(date));
                } catch (ParseException e) {
                    // Continue if parsing fails
                }
            }
        }

        // If no format matched, log and return null
        LOG.error("Failed to parse date: {}", value);
        return null;
    }

    /**
     * Parses the header line of the CSV file and applies formatting rules to normalize it.
     *
     * @param headerLine The header line from the CSV file.
     * @param delimiter  The delimiter used to split the header values.
     * @return An array of normalized header strings.
     */
    private static String[] parseHeaders(String headerLine, String delimiter) {
        String normalizedHeader = headerLine.toLowerCase();
        for (String[] replacement : HEADER_FORMATTING_RULES) {
            normalizedHeader = normalizedHeader.replaceAll(replacement[0], replacement[1]);
        }

        String[] headers = normalizedHeader.split(delimiter);
        for (int i = 0; i < headers.length; i++) {
            headers[i] = headers[i].replace(" ", "_");  // Replace spaces with underscores
            if (headers[i].endsWith("_")) {
                headers[i] = headers[i].substring(0, headers[i].length() - 1);  // Remove trailing underscore
            }
        }
        return headers;
    }
}
