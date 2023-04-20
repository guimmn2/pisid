package mysql;

import java.io.FileInputStream;
import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
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

					ArrayList<ArrayList<Integer>> roomPairsFromSql = new ArrayList<ArrayList<Integer>>();

					while (true) {

						ArrayList<Integer> roomPairFromMqtt = new ArrayList<>();

						String message = movementQueue.take();
						JsonObject objMSG = JsonParser.parseString(message).getAsJsonObject();

						String time = objMSG.get("Hora").getAsString();
						int entry = objMSG.get("SalaEntrada").getAsInt();
						int exit = objMSG.get("SalaSaida").getAsInt();

						System.out.println("roomPairsFromSql: " + roomPairsFromSql);

						roomPairFromMqtt.add(entry);
						roomPairFromMqtt.add(exit);

						System.out.println("roomPairFromMqtt: " + roomPairFromMqtt);

						// ao receber 0-0 faz query à db remota para obter info de salas
						if (entry == 0 && exit == 0) {
							try (Connection cloudConn = DriverManager
									.getConnection("jdbc:mariadb://194.210.86.10/pisid_2023_maze", "aluno", "aluno")) {
								System.out.println("connecting to remote db to fetch room data");
								PreparedStatement stmnt = cloudConn
										.prepareStatement("select salaentrada, salasaida from corredor");
								ResultSet rs = stmnt.executeQuery();
								ResultSetMetaData rsmd = rs.getMetaData();
								int columnCount = rsmd.getColumnCount();

								// lista com todos os pares sala dos corredores
								roomPairsFromSql = new ArrayList<ArrayList<Integer>>(columnCount);
								while (rs.next()) {
									ArrayList<Integer> pair = new ArrayList<>();
									pair.add(rs.getInt("salaentrada"));
									pair.add(rs.getInt("salasaida"));
									roomPairsFromSql.add(pair);
								}
								// debug
								roomPairsFromSql.forEach(p -> System.out.println(p.toString()));

							}

						}
						for (ArrayList<Integer> arr : roomPairsFromSql) {
							// valida salas antes de chamar sp
							if (arr.containsAll(roomPairFromMqtt) || exit == 0 & entry == 0) {
								System.out.println("Corredor existe: " + roomPairFromMqtt + "Hora: " + time);
								CallableStatement cs = conn.prepareCall("{call WriteMov(?,?,?)}");
								cs.setTimestamp(1, Timestamp.valueOf(time));
								cs.setInt(2, entry);
								cs.setInt(3, exit);
								cs.executeUpdate();
								break;
							}

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
				try (Connection conn = dataSource.getConnection()) {
					while (true) {

						String message = alertsQueue.take();
						JsonObject objMSG = JsonParser.parseString(message).getAsJsonObject();

						// os atributos que os alertas ligeiros vindos do mongo têm em comum
						String type = objMSG.get("Tipo").getAsString();
						String description = objMSG.get("Mensagem").getAsString();
						String time = objMSG.get("Hora").getAsString();

						//periodicidade alertas repetidos
						long milliseconds = 30000;

						// tipo alerta ligeiro vindo do mongo que usa sensores
						if (type.equals("light_temp") || type.equals("light_avaria")) {

							int sensor = objMSG.get("Sensor").getAsInt();

							PreparedStatement stmnt = conn.prepareStatement(
									"select hora from alerta where tipo = ? and sensor = ? order by id desc limit 1 ");
							stmnt.setString(1, type);
							stmnt.setInt(2, sensor);
							ResultSet rs = stmnt.executeQuery();

							if (rs.next()) {
								milliseconds = Timestamp.valueOf(time).getTime()
										- Timestamp.valueOf(rs.getString("hora")).getTime();
							}

							// nao aceitar alertas iguais nos proximos 30 segundos

							if (milliseconds >= 30000) {

								CallableStatement cs = conn.prepareCall("{call WriteAlert(?,?,?,?,?,?,?)}");
								cs.setTimestamp(1, Timestamp.valueOf(time));
								cs.setInt(3, sensor);
								cs.setString(5, type);
								cs.setString(6, description);
								cs.executeUpdate();
							} 

						}

						// tipo alerta ligeiro vindo do mongo que usa salas
						if (type.equals("light_mov")) {

							int room = objMSG.get("Sala").getAsInt();

							PreparedStatement stmnt = conn.prepareStatement(
									"select hora from alerta where tipo = 'light_mov' and sala = ? order by id desc limit 1 ");
							stmnt.setInt(1, room);
							ResultSet rs = stmnt.executeQuery();

							if (rs.next()) {
								milliseconds = Timestamp.valueOf(time).getTime()
										- Timestamp.valueOf(rs.getString("hora")).getTime();
							}

							// nao aceitar alertas iguais nos proximos 30 segundos

							if (milliseconds >= 30000) {

								CallableStatement cs = conn.prepareCall("{call WriteAlert(?,?,?,?,?,?,?)}");

								cs.setTimestamp(1, Timestamp.valueOf(time));
								cs.setInt(2, room);
								cs.setString(5, type);
								cs.setString(6, description);
								cs.executeUpdate();
							}
						}

						if (type.equals("light_descartada")) {
							
							Double leitura = objMSG.get("Leitura").getAsDouble();
							int sensor = objMSG.get("Sensor").getAsInt();
							
							PreparedStatement stmnt = conn.prepareStatement(
									"select hora from alerta where tipo = ? and sensor = ? order by id desc limit 1 ");
							stmnt.setString(1, type);
							stmnt.setInt(2, sensor);
							ResultSet rs = stmnt.executeQuery();

							if (rs.next()) {
								milliseconds = Timestamp.valueOf(time).getTime()
										- Timestamp.valueOf(rs.getString("hora")).getTime();
							}

							// nao aceitar alertas iguais nos proximos 30 segundos

							if (milliseconds >= 30000) {

								CallableStatement cs = conn.prepareCall("{call WriteAlert(?,?,?,?,?,?,?)}");
								cs.setTimestamp(1, Timestamp.valueOf(time));
								cs.setInt(3, sensor);
								cs.setDouble(4, leitura);
								cs.setString(5, type);
								cs.setString(6, description);
								cs.executeUpdate();
							}
							
						}


					}
				} catch (InterruptedException | SQLException e) {
					// TODO Auto-generated catch block
					e.printStackTrace();
				}
			}
		}).start();

	}
}
