package org.umcn.gen.tamatoa;

import org.junit.Rule;
import org.junit.Test;
import org.junit.rules.TemporaryFolder;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.util.List;

import static org.junit.Assert.*;

public class FolderReaderTest {

    @Rule
    public TemporaryFolder temporaryFolder = new TemporaryFolder();

    /**
     * Test to check if the FolderReader correctly identifies and retrieves CSV files
     * from a directory containing only valid CSV files.
     *
     * @throws IOException If an error occurs during file creation or directory access.
     */
    @Test
    public void testCheckFolderWithValidCsvFiles() throws IOException {
        File tempDir = temporaryFolder.newFolder("testDirWithCsv");
        createTempFile(tempDir, "valid1.csv", "header1,header2\nvalue1,value2");
        createTempFile(tempDir, "valid2.csv", "header1,header2\nvalue3,value4");

        List<File> csvFiles = FolderReader.checkFolder(tempDir);

        // Ensure only CSV files are included
        assertEquals(2, csvFiles.size());
        assertTrue(csvFiles.stream().allMatch(file -> file.getName().endsWith(".csv")));
    }

    /**
     * Test to ensure that FolderReader correctly filters CSV files from a directory
     * containing mixed file types.
     *
     * @throws IOException If an error occurs during file creation or directory access.
     */
    @Test
    public void testCheckFolderMixedFileTypes() throws IOException {
        File tempDir = temporaryFolder.newFolder("mixedFileDir");
        createTempFile(tempDir, "data.csv", "header1,header2\nvalue1,value2");
        createTempFile(tempDir, "data.txt", "header1,header2\nvalue1,value2");

        List<File> csvFiles = FolderReader.checkFolder(tempDir);

        // Only the CSV file should be in the list
        assertEquals(1, csvFiles.size());
        assertEquals("data.csv", csvFiles.get(0).getName());
    }

    /**
     * Test to ensure FolderReader handles an empty directory correctly,
     * returning an empty list of CSV files.
     *
     * @throws IOException If an error occurs during directory creation.
     */
    @Test
    public void testEmptyDirectory() throws IOException {
        File tempDir = temporaryFolder.newFolder("emptyDir");
        Exception e = assertThrows(IOException.class, () -> {
            FolderReader.checkFolder(tempDir);
        });
        assertEquals("The directory is empty: " + tempDir.getAbsolutePath(), e.getMessage());
    }


    /**
     * Test to ensure FolderReader throws an appropriate error message when attempting
     * to read from a non-existent directory.
     */
    @Test
    public void testNonExistentDirectory() {
        File nonExistentDir = new File("nonExistentDir");

        IOException exception = assertThrows(IOException.class, () -> {
            FolderReader.checkFolder(nonExistentDir);
        });

        // Ensure proper error message for non-existent directory
        assertEquals("Invalid directory: " + nonExistentDir.getAbsolutePath(), exception.getMessage());
    }

    /**
     * Test to verify that FolderReader does not mistakenly add non-CSV files to the
     * list of retrieved files, even if they are present in the directory.
     *
     * @throws IOException If an error occurs during file creation or directory access.
     */
    @Test
    public void testFolderWithNonCsvFiles() throws IOException {
        File tempDir = temporaryFolder.newFolder("testDirWithNonCsv");
        createTempFile(tempDir, "notCsvFile.txt", "header1,header2\nvalue1,value2");

        List<File> csvFiles = FolderReader.checkFolder(tempDir);

        // Ensure no CSV files are found and result is empty
         assertTrue(csvFiles.isEmpty());
    }


    /**
     * Helper method to create a temporary file with specified content in the given directory.
     *
     * @param dir The directory in which the temporary file is created.
     * @param fileName The name of the temporary file.
     * @param content The content to write to the file.
     * @throws IOException If an error occurs during file creation or writing content.
     */
    private void createTempFile(File dir, String fileName, String content) throws IOException {
        File tempFile = new File(dir, fileName);
        Files.writeString(tempFile.toPath(), content);
    }
}
