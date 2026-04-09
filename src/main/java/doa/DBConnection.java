package doa;

import java.sql.Connection;
import java.sql.DriverManager;

public class DBConnection {
    private static Connection conn = null;

    public static Connection getConnection() {
        try {
            Class.forName("oracle.jdbc.driver.OracleDriver");

            if (conn == null || conn.isClosed()) {
                conn = DriverManager.getConnection(
                		"jdbc:oracle:thin:@localhost:1521/XEPDB1",
                    "spring",
                    "info123"
                );
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return conn;
    }
}