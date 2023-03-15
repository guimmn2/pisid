package mysql;

import java.io.FileInputStream;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.util.Properties;

public class MysqlWriter {
	private Connection conn;
	private String db;
	private String password;
	private String user;
	private String table;

	// cria instância e liga-se à BD mediante ficheiro .ini
	public MysqlWriter() {
		try {
			Properties p = new Properties();
			p.load(new FileInputStream("config_files/WriteMysql.ini"));
			table = p.getProperty("sql_table_to");
			db = p.getProperty("sql_database_connection_to");
			password = p.getProperty("sql_database_password_to");
			user = p.getProperty("sql_database_user_to");
		} catch (Exception e) {
			System.out.println("Error reading WriteMysql.ini file " + e);
		}
	}

	public void connectToDb() {
		try {
			Class.forName("org.mariadb.jdbc.Driver");
			conn = DriverManager.getConnection(db, user, password);
			System.out.println("SQl Connection:" + db + "\n");
			System.out.println("Connection To MariaDB Destination " + db + " Suceeded" + "\n");
		} catch (Exception e) {
			System.out.println("Mysql Server Destination down, unable to make the connection. " + e);
		}
	}
	
	//funções para escrever na BD?
	//mediante msgs mqtt recebidas vamos escrever coisas diferentes
	public void writeTest(String name) {
		PreparedStatement statement;
		try {
			statement = conn.prepareStatement("insert into ratos (name) values (?)");
			statement.setString(1, name);
			statement.execute();
		} catch (SQLException e) {
			e.printStackTrace();
		}
	}
	
	

}
