package mysql;

import java.io.FileInputStream;
import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.Properties;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.LinkedBlockingQueue;

import org.eclipse.paho.client.mqttv3.IMqttDeliveryToken;
import org.eclipse.paho.client.mqttv3.MqttCallback;
import org.eclipse.paho.client.mqttv3.MqttClient;
import org.eclipse.paho.client.mqttv3.MqttMessage;

import com.google.gson.JsonObject;
import com.google.gson.JsonParser;
import com.zaxxer.hikari.HikariConfig;
import com.zaxxer.hikari.HikariDataSource;

import mysql.Utils.Pair;

public class MqttToMysql {

	private static String mqttBroker;
	private static String[] mqttTopics;
	private static String dbUrl;
	private static String dbUser;
	private static String dbPassword;
	private static final int N_TABLES_TO_WRITE = 3;
	private static final int MQTT_MESSAGE_QUEUE_SIZE = 1000;

	public static void main(String[] args) throws Exception {

		// Set up connection to remote mysql server
		Connection cloudConn = DriverManager.getConnection("jdbc:mariadb://194.210.86.10/pisid_2023_maze", "aluno",
				"aluno");
		// --

		Properties p = new Properties();

		// get MQTT configs from .ini file
		p.load(new FileInputStream("config_files/ReceiveCloud.ini"));
		mqttBroker = p.getProperty("cloud_server");
		mqttTopics = p.getProperty("cloud_topic").split(",");
		// --

		// Set up MQTT client
		MqttClient client = new MqttClient(mqttBroker, MqttClient.generateClientId());
		client.connect();
		client.subscribe(mqttTopics);
		// --

		// get SQL configs from .ini file
		p.load(new FileInputStream("config_files/WriteMysql.ini"));
		dbUrl = p.getProperty("sql_database_connection_to");
		dbPassword = p.getProperty("sql_database_password_to");
		dbUser = p.getProperty("sql_database_user_to");
		// --

		// Set up HikariCP connection pool
		HikariConfig config = new HikariConfig();

		config.setJdbcUrl(dbUrl);
		config.setUsername(dbUser);
		config.setPassword(dbPassword);
		config.setMaximumPoolSize(N_TABLES_TO_WRITE);
		HikariDataSource dataSource = new HikariDataSource(config);
		// --

		// Set up message queues for each topic
		BlockingQueue<String> temperatureQueue = new LinkedBlockingQueue<>(MQTT_MESSAGE_QUEUE_SIZE);
		BlockingQueue<String> movementQueue = new LinkedBlockingQueue<>(MQTT_MESSAGE_QUEUE_SIZE);
		BlockingQueue<String> alertsQueue = new LinkedBlockingQueue<>(MQTT_MESSAGE_QUEUE_SIZE);
		// --

		// Set up message listener
		client.setCallback(new MqttCallback() {

			public void connectionLost(Throwable throwable) {
				// handle losing connection
			}

			public void messageArrived(String topic, MqttMessage mqttMessage) throws InterruptedException {
				String message = new String(mqttMessage.getPayload());

				switch (topic) {
				case "readings/temp": {
					temperatureQueue.put(message);
					break;
				}
				case "readings/mov": {
					movementQueue.put(message);
					break;
				}
				case "lightWarnings": {
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
						JsonObject objMSG = JsonParser.parseString(message).getAsJsonObject();

						String time = objMSG.get("Hora").getAsString();
						double reading = objMSG.get("Leitura").getAsDouble();
						int sensor = objMSG.get("Sensor").getAsInt();

						CallableStatement cs = conn.prepareCall("{call WriteTemp(?,?,?)}");
						cs.setInt(1, sensor);
						cs.setTimestamp(2, Timestamp.valueOf(time));
						cs.setDouble(3, reading);

						cs.executeUpdate();
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
						JsonObject objMSG = JsonParser.parseString(message).getAsJsonObject();

						String time = objMSG.get("Hora").getAsString();
						int entry = objMSG.get("SalaEntrada").getAsInt();
						int exit = objMSG.get("SalaSaida").getAsInt();

						ArrayList<Pair> roomPairs = new ArrayList<>();
						// ao receber 0-0 faz query à db remota para obter info de salas
						if (entry == 0 && exit == 0) {
							System.out.println("connecting to remote db to fetch room data on conn: " + cloudConn.hashCode());
							PreparedStatement stmnt = cloudConn
									.prepareStatement("select salaentrada, salasaida from corredor");
							ResultSet rs = stmnt.executeQuery();
							roomPairs = Utils.resultSetToList(rs);
						}

						// valida salas antes de chamar sp
						if (Utils.existsPair(new Pair(entry, exit), roomPairs)) {
							System.out.println("calling sp on conn: " + conn.hashCode());
							CallableStatement cs = conn.prepareCall("{call WriteMov(?,?,?)}");
							cs.setTimestamp(1, Timestamp.valueOf(time));
							cs.setInt(2, entry);
							cs.setInt(3, exit);
							cs.executeUpdate();
							cs.close();
						}

					}
				} catch (InterruptedException | SQLException e) {
					// TODO Auto-generated catch block
					e.printStackTrace();
				}
			}
		}).start();

		// TODO
		// alerts thread
		new Thread(new Runnable() {

			@Override
			public void run() {
				while (true) {
					try (Connection conn = dataSource.getConnection()) {
						String message = alertsQueue.take();
						// PreparedStatement stmnt = conn.prepareStatement("insert into
						// mediçõestemperature (Hora, Leitura, Sensor) values (?, ?, ?)");
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
