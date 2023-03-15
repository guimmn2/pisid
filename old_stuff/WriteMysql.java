package mysql;
//(c) ISCTE-IUL, Pedro Ramos, 2022

//import org.bson.Document;
//import org.bson.*;
//import org.bson.conversions.*;

//import org.json.JSONArray;
//import org.json.JSONObject;
//import org.json.JSONException;

import java.io.*;
import java.util.*;
import java.util.List;
import java.text.SimpleDateFormat;  
import java.util.Date;  
import java.util.concurrent.*;
import java.sql.*;
import javax.swing.*;
import java.awt.event.*;
import java.awt.*; 
import javax.swing.text.BadLocationException;
import java.sql.SQLException;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;


public class WriteMysql {	
	static JTextArea documentLabel = new JTextArea("\n");
	static Connection connTo;
	static String sql_database_connection_to = new String();
	static String sql_database_password_to= new String();
	static String sql_database_user_to= new String();
	static String  sql_table_to= new String();
	
		
	private static void createWindow() {   
		JFrame frame = new JFrame("Data Bridge");    
		frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);       
		JLabel textLabel = new JLabel("Data : ",SwingConstants.CENTER);       
		textLabel.setPreferredSize(new Dimension(600, 30));   	
		JScrollPane scroll = new JScrollPane (documentLabel,JScrollPane.VERTICAL_SCROLLBAR_ALWAYS, JScrollPane.HORIZONTAL_SCROLLBAR_ALWAYS);
		scroll.setPreferredSize(new Dimension(600, 200)); 
		JButton b1 = new JButton("Stop the program");
		frame.getContentPane().add(textLabel, BorderLayout.PAGE_START);	
		frame.getContentPane().add(scroll, BorderLayout.CENTER);	
		frame.getContentPane().add(b1, BorderLayout.PAGE_END);	
		frame.setLocationRelativeTo(null);      	
		frame.pack();      
		frame.setVisible(true);    
		b1.addActionListener(new ActionListener() {
			public void actionPerformed(ActionEvent evt) {
				System.exit(0);
			}
		});
    }
	
	public  static void main(String[] args) {
		createWindow();
		try {	
            Properties p = new Properties();
            p.load(new FileInputStream("WriteMysql.ini"));			
			sql_table_to= p.getProperty("sql_table_to");
			sql_database_connection_to = p.getProperty("sql_database_connection_to");
			sql_database_password_to = p.getProperty("sql_database_password_to");
			sql_database_user_to= p.getProperty("sql_database_user_to");
        } catch (Exception e) {
            System.out.println("Error reading WriteMysql.ini file " + e);
            JOptionPane.showMessageDialog(null, "The WriteMysql inifile wasn't found.", "Data Migration", JOptionPane.ERROR_MESSAGE);
        }		
		new WriteMysql().connectDatabase_to();
		new WriteMysql().ReadData();
   }
   	
	public void connectDatabase_to() {
	       try {           
            Class.forName("org.mariadb.jdbc.Driver");		
			connTo =  DriverManager.getConnection(sql_database_connection_to,sql_database_user_to,sql_database_password_to);
			documentLabel.append("SQl Connection:"+sql_database_connection_to+"\n");				
			documentLabel.append("Connection To MariaDB Destination " + sql_database_connection_to + " Suceeded"+"\n");	
	   } catch (Exception e){System.out.println("Mysql Server Destination down, unable to make the connection. "+e);}
    }


	public void ReadData() {
		String doc = new String();
		int i=0;		
	    while (i<100) {	
				doc = "{Name:\"Nome_"+i+"\", Location:\"Portugal\", id:"+i+"}";
				//WriteToMySQL(com.mongodb.util.JSON.serialize(doc));						
				WriteToMySQL(doc);		
				i++;				
		}										
	}

	public void WriteToMySQL (String c){	
		String convertedjson = new String();
		convertedjson = c;		
		String fields = new String();
		String values = new String();
		String SqlCommando = new String();
		String column_database = new String();
		fields = "";
		values = "";
		column_database = " ";
		String x = convertedjson.toString();
		String[] splitArray = x.split(",");	
		for (int i=0; i<splitArray.length; i++) {
			String[] splitArray2 = splitArray[i].split(":");			
			if (i==0) fields = splitArray2[0];
			else fields = fields + ", " + splitArray2[0] ;
			if (i==0) values = splitArray2[1];	
			else values = values + ", " + splitArray2[1];
		}						
		fields = fields.replace("\"", "");
		SqlCommando = "Insert into " + sql_table_to + " (" + fields.substring(1, fields.length()) + ") values (" + values.substring(0, values.length()-1) + ");";							
		//System.out.println(SqlCommando);
        try {
				documentLabel.append(SqlCommando.toString()+"\n");	
        } catch (Exception e) {
            System.out.println(e);
        }		
		try {
			Statement s = connTo.createStatement(); 
			int result = new Integer(s.executeUpdate(SqlCommando));	
			s.close();										
		} catch (Exception e){System.out.println("Error Inserting in the database . " + e); System.out.println(SqlCommando);}	
	}

	
}