//(c) ISCTE-IUL, Pedro Ramos, 2022

//import org.bson.Document;
//import org.bson.*;
//import org.bson.conversions.*;

//import org.json.JSONArray;
//import org.json.JSONObject;
//import org.json.JSONException;

import java.awt.BorderLayout;
import java.awt.Dimension;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.io.FileInputStream;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.util.Properties;
import java.util.Random;

import javax.swing.JButton;
import javax.swing.JFrame;
import javax.swing.JLabel;
import javax.swing.JOptionPane;
import javax.swing.JScrollPane;
import javax.swing.JTextArea;
import javax.swing.SwingConstants;

import org.eclipse.paho.client.mqttv3.IMqttDeliveryToken;
import org.eclipse.paho.client.mqttv3.MqttCallback;
import org.eclipse.paho.client.mqttv3.MqttClient;
import org.eclipse.paho.client.mqttv3.MqttException;
import org.eclipse.paho.client.mqttv3.MqttMessage;

public class MqttToMysql implements MqttCallback {
	static JTextArea documentLabel = new JTextArea("\n");
	static Connection connTo;
	static String sql_database_connection_to = new String();
	static String sql_database_password_to = new String();
	static String sql_database_user_to = new String();
	static String sql_table_to = new String();

	MqttClient mqttclient;
	private static String cloudServer;
	private static String cloudTopic;

	private static void createWindow() {
		JFrame frame = new JFrame("Data from Mongo");
		frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
		JLabel textLabel = new JLabel("Data : ", SwingConstants.CENTER);
		textLabel.setPreferredSize(new Dimension(600, 30));
		JScrollPane scroll = new JScrollPane(documentLabel, JScrollPane.VERTICAL_SCROLLBAR_ALWAYS,
				JScrollPane.HORIZONTAL_SCROLLBAR_ALWAYS);
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

	public static void main(String[] args) {
		createWindow();
		try {
			// setup mysql
			Properties p = new Properties();
			p.load(new FileInputStream("WriteMysql.ini"));
			sql_table_to = p.getProperty("sql_table_to");
			sql_database_connection_to = p.getProperty("sql_database_connection_to");
			sql_database_password_to = p.getProperty("sql_database_password_to");
			sql_database_user_to = p.getProperty("sql_database_user_to");

			p.load(new FileInputStream("ReceiveCloud.ini"));
			cloudServer = p.getProperty("cloud_server");
			cloudTopic = p.getProperty("cloud_topic");
		} catch (Exception e) {
			System.out.println("Error reading WriteMysql.ini file " + e);
			JOptionPane.showMessageDialog(null, "The WriteMysql inifile wasn't found.", "Data Migration",
					JOptionPane.ERROR_MESSAGE);
		}
		MqttToMysql test = new MqttToMysql();
		test.connectDatabase_to();
		test.connectToMqttCloud();
	}

	public void connectDatabase_to() {
		try {
			Class.forName("org.mariadb.jdbc.Driver");
			connTo = DriverManager.getConnection(sql_database_connection_to, sql_database_user_to,
					sql_database_password_to);
			documentLabel.append("SQl Connection:" + sql_database_connection_to + "\n");
			documentLabel
					.append("Connection To MariaDB Destination " + sql_database_connection_to + " Suceeded" + "\n");
		} catch (Exception e) {
			System.out.println("Mysql Server Destination down, unable to make the connection. " + e);
		}
	}

	public void WriteToMySQL(String c) {
		try {
			PreparedStatement statement = connTo.prepareStatement("insert into ratos (name) values (?)");
			statement.setString(1, c);
			statement.execute();
			documentLabel.append("executing : " + statement.toString());
		} catch (Exception e) {
			System.out.println(e);
			System.out.println("Error Inserting in the database . " + e);
		}
	}

	public void connectToMqttCloud() {
		int i;
		try {
			i = new Random().nextInt(100000);
			mqttclient = new MqttClient(cloudServer, "MongoCloud" + String.valueOf(i) + "_" + cloudTopic);
			mqttclient.connect();
			mqttclient.setCallback(this);
			mqttclient.subscribe(cloudTopic);
		} catch (MqttException e) {
			e.printStackTrace();
		}
	}

	@Override
	public void connectionLost(Throwable arg0) {
		// TODO Auto-generated method stub

	}

	@Override
	public void deliveryComplete(IMqttDeliveryToken arg0) {
		// TODO Auto-generated method stub

	}

	@Override
	public void messageArrived(String arg0, MqttMessage arg1) throws Exception {
		// TODO Auto-generated method stub
		this.WriteToMySQL(arg1.toString());
	}

}
