package mysql;

import java.io.FileInputStream;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.util.Properties;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.LinkedBlockingQueue;

import org.eclipse.paho.client.mqttv3.IMqttDeliveryToken;
import org.eclipse.paho.client.mqttv3.MqttCallback;
import org.eclipse.paho.client.mqttv3.MqttClient;
import org.eclipse.paho.client.mqttv3.MqttMessage;

import com.zaxxer.hikari.HikariConfig;
import com.zaxxer.hikari.HikariDataSource;

public class MqttToMysql {

	private static String mqttBroker;
	private static String[] mqttTopics;
	private static String dbUrl;
	private static String dbUser;
	private static String dbPassword;
	private static final int N_TABLES_TO_WRITE = 3;
	private static final int MQTT_MESSAGE_QUEUE_SIZE = 1000;

	public static void main(String[] args) throws Exception {
		Properties p = new Properties();

		// get MQTT configs from .ini file
		p.load(new FileInputStream("config_files/ReceiveCloud.ini"));
		mqttBroker = p.getProperty("cloud_server");
		mqttTopics = p.getProperty("cloud_topic").split(",");

		// Set up MQTT client
		MqttClient client = new MqttClient(mqttBroker, MqttClient.generateClientId());
		client.connect();
		client.subscribe(mqttTopics);

		// get SQL configs from .ini file
		p.load(new FileInputStream("config_files/WriteMysql.ini"));
		dbUrl = p.getProperty("sql_database_connection_to");
		dbPassword = p.getProperty("sql_database_password_to");
		System.out.println("password is: " + dbPassword);
		dbUser = p.getProperty("sql_database_user_to");

		// Set up HikariCP connection pool
		HikariConfig config = new HikariConfig();

		config.setJdbcUrl(dbUrl);
		config.setUsername(dbUser);
		config.setPassword(dbPassword);
		config.setMaximumPoolSize(N_TABLES_TO_WRITE);
		HikariDataSource dataSource = new HikariDataSource(config);

		// Set up message queues for each topic

		BlockingQueue<String> temperatureQueue = new LinkedBlockingQueue<>(MQTT_MESSAGE_QUEUE_SIZE);
		BlockingQueue<String> movementQueue = new LinkedBlockingQueue<>(MQTT_MESSAGE_QUEUE_SIZE);
		BlockingQueue<String> alertsQueue = new LinkedBlockingQueue<>(MQTT_MESSAGE_QUEUE_SIZE);

		// Set up message listener
		client.setCallback(new MqttCallback() {

			public void connectionLost(Throwable throwable) {
				// handle losing connection
			}

			public void messageArrived(String topic, MqttMessage mqttMessage) throws InterruptedException {
				String message = new String(mqttMessage.getPayload());

				switch (topic) {
				case "readings/temp": {
					System.out.println("temp message: " + message);
					temperatureQueue.put(message);
					break;
				}
				case "readings/mov": {
					System.out.println("mov message: " + message);
					movementQueue.put(message);
					break;
				}
				case "lightWarnings": {
					System.out.println("alert message: " + message);
					alertsQueue.put(message);
					break;
				}
				default:
					throw new IllegalArgumentException("Unexpected value: " + topic);
				}
			}

			public void deliveryComplete(IMqttDeliveryToken iMqttDeliveryToken) {
				// handle delivery complete for certain messages ?
			}
		});

		// temperature thread
		new Thread(new Runnable() {

			@Override
			public void run() {
				try (Connection conn = dataSource.getConnection()) {
					while (true) {

						String message = temperatureQueue.take();
						PreparedStatement stmnt = conn
								.prepareStatement("insert into mediçõestemperatura (Leitura, Sensor) values (?, ?)");
						stmnt.setDouble(1, 2.2);
						stmnt.setInt(2, 2);
						stmnt.executeUpdate();
						System.out.println("temperature thread: " + message);
					}
				} catch (InterruptedException | SQLException e) {
					// TODO Auto-generated catch block
					e.printStackTrace();
				}
			}
		}).start();

		// movement thread
		new Thread(new Runnable() {

			@Override
			public void run() {
				try (Connection conn = dataSource.getConnection()) {
					while (true) {

						String message = movementQueue.take();
						PreparedStatement stmnt = conn.prepareStatement(
								"insert into mediçõespassagens (SalaEntrada, SalaSaída) values (?, ?)");
						stmnt.setInt(1, 2);
						stmnt.setInt(2, 2);
						stmnt.executeUpdate();
						System.out.println("movement thread: " + message);
					}
				} catch (InterruptedException | SQLException e) {
					// TODO Auto-generated catch block
					e.printStackTrace();
				}
			}
		}).start();

		// alerts thread
		new Thread(new Runnable() {

			@Override
			public void run() {
				while (true) {
					try (Connection conn = dataSource.getConnection()) {
						String message = alertsQueue.take();
						// PreparedStatement stmnt = conn.prepareStatement("insert into
						// mediçõestemperature (Hora, Leitura, Sensor) values (?, ?, ?)");
						System.out.println("alerts thread: " + message);
					} catch (InterruptedException | SQLException e) {
						// TODO Auto-generated catch block
						e.printStackTrace();
					}
				}
			}
		}).start();

		// Wait for messages
		while (true) {
			Thread.sleep(1000);
		}
	}
}