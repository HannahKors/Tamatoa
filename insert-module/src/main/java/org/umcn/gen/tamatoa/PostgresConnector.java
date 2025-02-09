package org.umcn.gen.tamatoa;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class PostgresConnector {
    private static final Logger LOG = LoggerFactory.getLogger(PostgresConnector.class);

    private static final String URL = "";
    private static final String USER = "";
    private static final String PASSWORD = "";

    // Returns a connection object to the PostgreSQL database
    public static Connection getConnection() {
        try {
            if (URL.isEmpty() || USER.isEmpty() || PASSWORD.isEmpty()) {
                LOG.error("Database log in credentials are missing.");
            } else {
                Connection connection = DriverManager.getConnection(URL, USER, PASSWORD);
                LOG.info("Successfully connected to the database.");
                return connection;
            }
        } catch (SQLException e) {
            LOG.error("Failed to establish connection: {} - {}", e.getSQLState(), e.getMessage());
        }
        return null;
    }
}
