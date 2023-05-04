package mysql;

import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.sql.Types;
import java.util.ArrayList;
import java.util.Properties;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.LinkedBlockingQueue;

import org.eclipse.paho.client.mqttv3.IMqttDeliveryToken;
import org.eclipse.paho.client.mqttv3.MqttCallback;
import org.eclipse.paho.client.mqttv3.MqttClient;
import org.eclipse.paho.client.mqttv3.MqttConnectOptions;
import org.eclipse.paho.client.mqttv3.MqttMessage;

import com.google.gson.JsonObject;
import com.google.gson.JsonParser;
import com.zaxxer.hikari.HikariConfig;
import com.zaxxer.hikari.HikariDataSource;

import javax.swing.*;
import org.eclipse.paho.client.mqttv3.*;
import org.eclipse.paho.client.mqttv3.persist.MemoryPersistence;

@SuppressWarnings("serial")
public class MqttToMysql extends JFrame implements MqttCallback {

	private JTextArea textArea;
	private static String dbUrl;
	private static String dbUser;
	private static String dbPassword;
	private static final int N_TABLES_TO_WRITE = 3;
	private static final int MQTT_MESSAGE_QUEUE_SIZE = 1000;
	private static final long RESET_TIME_MS = 4000; // Qual é o tempo máximo para dar reset a um contador
	private static int[] varRooms; // Contadores em que cada i + 1 corresponde a uma sala (Sala 1 = varRooms[0])
	private static long[] lastUpdateTime; // Em cada posição diz quando foi a última vez que foi atualizado o contador
											// da sala correspondente

	static BlockingQueue<String> temperatureQueue = new LinkedBlockingQueue<>(MQTT_MESSAGE_QUEUE_SIZE);
	static BlockingQueue<String> movementQueue = new LinkedBlockingQueue<>(MQTT_MESSAGE_QUEUE_SIZE);
	static BlockingQueue<String> alertsQueue = new LinkedBlockingQueue<>(MQTT_MESSAGE_QUEUE_SIZE);

	static HikariDataSource dataSource;

	public MqttToMysql() throws FileNotFoundException, IOException {
		super("MQTT Receiver");
		setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
		setSize(400, 300);

		// Create the text area
		textArea = new JTextArea();

		JScrollPane scrollPane = new JScrollPane(textArea);
		scrollPane.setAutoscrolls(true);
		add(scrollPane);

		// Connect to the MQTT broker
		String broker = "tcp://broker.mqtt-dashboard.com:1883";
		String clientId = "5005";
		MemoryPersistence persistence = new MemoryPersistence();
		try {
			MqttClient mqttClient = new MqttClient(broker, clientId, persistence);
			mqttClient.setCallback(this);
			MqttConnectOptions mqttConnectOptions = new MqttConnectOptions();
			mqttConnectOptions.setUserName("SQL");
			String aux = "Golfinho";
			mqttConnectOptions.setPassword(aux.toCharArray());
			mqttConnectOptions.setCleanSession(false);
			mqttClient.connect(mqttConnectOptions);

			// Subscribe to three MQTT topics
			mqttClient.subscribe("lightWarnings");
			mqttClient.subscribe("readings/temps");
			mqttClient.subscribe("readings/movs");

			// get SQL configs from .ini file
			Properties p = new Properties();
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
			dataSource = new HikariDataSource(config);

		} catch (MqttException e) {
			e.printStackTrace();
		}

		setVisible(true);
	}

	public static void main(String[] args) throws FileNotFoundException, IOException {
		new MqttToMysql();

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

						String id = objMSG.get("_id").getAsJsonObject().get("$oid").getAsString();
						String time = objMSG.get("Hora").getAsString();
						int nRoomRatLeft = objMSG.get("SalaEntrada").getAsInt();
						int nRoomRatJoin = objMSG.get("SalaSaida").getAsInt();
						int nsalas = 0;

						roomPairFromMqtt.add(nRoomRatLeft);
						roomPairFromMqtt.add(nRoomRatJoin);

						// ao receber 0-0 faz query à db remota para obter info
						if (nRoomRatLeft == 0 && nRoomRatJoin == 0) {
							try (Connection cloudConn = DriverManager
									.getConnection("jdbc:mariadb://194.210.86.10/pisid_2023_maze", "aluno", "aluno")) {
								System.out.println("Debug: Connecting to remote db to fetch room data");

								// Statement para os corredores
								PreparedStatement stmnt = cloudConn
										.prepareStatement("select salaentrada, salasaida from corredor");
								ResultSet rs = stmnt.executeQuery();
								ResultSetMetaData rsmd = rs.getMetaData();
								int columnCount = rsmd.getColumnCount();

								// Statement para configuraçãoslabirinto
								PreparedStatement stmntConfig = cloudConn.prepareStatement(
										"select numerosalas, temperaturaprogramada, segundosaberturaportaexterior from configuraçãolabirinto");

								ResultSet rsConfig = stmntConfig.executeQuery();

								if (rsConfig.next()) {
									try {
										Double temp_prog = rsConfig.getDouble("temperaturaprogramada");
										int seg_exterior = rsConfig.getInt("segundosaberturaportaexterior");
										nsalas = rsConfig.getInt("numerosalas");

										varRooms = new int[nsalas];
										lastUpdateTime = new long[nsalas];
										CallableStatement csConfig = conn.prepareCall("{call WriteConfig(?,?,?)}");
										csConfig.setDouble(1, temp_prog);
										csConfig.setInt(2, seg_exterior);
										csConfig.setInt(3, nsalas);

										csConfig.executeUpdate();
									} catch (SQLException e) {
										System.err.println("Aviso: Configuracões não foram carregadas");
									}

								}

								// lista com todos os pares sala dos corredores
								roomPairsFromSql = new ArrayList<ArrayList<Integer>>(columnCount);
								while (rs.next()) {
									ArrayList<Integer> pair = new ArrayList<>();
									pair.add(rs.getInt("salaentrada"));
									pair.add(rs.getInt("salasaida"));
									roomPairsFromSql.add(pair);
								}

							}

						}
						for (ArrayList<Integer> arr : roomPairsFromSql) {
							// valida salas antes de chamar sp
							if (arr.containsAll(roomPairFromMqtt) || nRoomRatJoin == 0 && nRoomRatLeft == 0) {
								try {

									long currentTime = System.currentTimeMillis();
									for (int i = 0; i < nsalas; i++)
										if (varRooms[i] > 0 && currentTime - lastUpdateTime[i] > RESET_TIME_MS)
											varRooms[i] = 0;

									CallableStatement cs = conn.prepareCall("{call WriteMov(?,?,?,?)}");
									cs.setString(1, id);
									cs.setTimestamp(2, Timestamp.valueOf(time));
									cs.setInt(3, nRoomRatLeft);
									cs.setInt(4, nRoomRatJoin);

									// Preparing a CallableStatement to call a function
									CallableStatement cstmt = conn.prepareCall("{? = call GetRatsInRoom(?)}");
									// Registering the out parameter of the function (return type)
									cstmt.registerOutParameter(1, Types.INTEGER);

									// Setting the input parameters of the function
									cstmt.setInt(2, nRoomRatLeft);

									// Executing the statement
									cstmt.execute();

									int nRatsOnTheRoom = cstmt.getInt(1);

									if (nRatsOnTheRoom > 0 || nRoomRatJoin == 0 && nRoomRatLeft == 0) {

										if (nRoomRatLeft != 0 && nRoomRatJoin != 0) {
											// Incrementa o contador da Sala de Entrada da mensagem
											varRooms[nRoomRatLeft - 1]++;
											varRooms[nRoomRatJoin - 1]--;

											// Dá update do vetor de lastUpdateTime
											lastUpdateTime[nRoomRatLeft - 1] = System.currentTimeMillis();
											lastUpdateTime[nRoomRatJoin - 1] = System.currentTimeMillis();

											// Caso o contador exceda 5 cria um lightWarning
											if (varRooms[nRoomRatLeft - 1] >= 5) {
												CallableStatement csVar = conn
														.prepareCall("{call WriteAlert(?,?,?,?,?,?,?)}");
												csVar.setTimestamp(1, Timestamp.valueOf(time));
												csVar.setInt(2, nRoomRatLeft);
												csVar.setString(5, "light_mov");
												csVar.setString(6,
														"Rapida movimentacao de ratos na sala " + nRoomRatLeft);
												csVar.executeUpdate();
												varRooms[nRoomRatLeft - 1] = 0;
											}

											// Caso o contador exceda -5 cria um lightWarning
											if (varRooms[nRoomRatJoin - 1] <= -5) {
												CallableStatement csVar = conn
														.prepareCall("{call WriteAlert(?,?,?,?,?,?,?)}");
												csVar.setTimestamp(1, Timestamp.valueOf(time));
												csVar.setInt(2, nRoomRatJoin);
												csVar.setString(5, "light_mov");
												csVar.setString(6,
														"Rapida movimentacao de ratos na sala " + nRoomRatJoin);
												csVar.executeUpdate();
												varRooms[nRoomRatJoin - 1] = 0;
											}
										}

										cs.executeUpdate();
									}

								} catch (SQLException e) {
									System.err.println("Aviso: Erro na escrita de movimento");
								}

								break;
							}

						}

					}
				} catch (InterruptedException | SQLException e) {
					dataSource.close();
				}
			}
		}).start();

		// temperature thread

		new Thread(new Runnable() {

			@Override
			public void run() {
				try (Connection conn = dataSource.getConnection()) {

					while (true) {
						String message = temperatureQueue.take();
						JsonObject objMSG = JsonParser.parseString(message).getAsJsonObject();

						String id = objMSG.get("_id").getAsJsonObject().get("$oid").getAsString();
						String time = objMSG.get("Hora").getAsString();
						double reading = objMSG.get("Leitura").getAsDouble();
						int sensor = objMSG.get("Sensor").getAsInt();
						try {
							CallableStatement cs = conn.prepareCall("{call WriteTemp(?,?,?,?)}");
							cs.setString(1, id);
							cs.setInt(2, sensor);
							cs.setTimestamp(3, Timestamp.valueOf(time));
							cs.setDouble(4, reading);
							System.out.println("Debug Temp: " + message);

							cs.executeUpdate();
						} catch (SQLException e) {
							e.printStackTrace();
							System.err.println("Aviso: Erro escrita da temperatura");
						}
					}

				} catch (InterruptedException | SQLException e) {
					dataSource.close();
				}
			}

		}).start();

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

						// tipo alerta ligeiro vindo do mongo que usa sensores
						if (type.equals("light_temp") || type.equals("avaria")) {

							int sensor = objMSG.get("Sensor").getAsInt();

							try {
								CallableStatement cs = conn.prepareCall("{call WriteAlert(?,?,?,?,?,?,?)}");
								cs.setTimestamp(1, Timestamp.valueOf(time));
								cs.setInt(3, sensor);
								cs.setString(5, type);
								cs.setString(6, description);
								cs.executeUpdate();
								System.out.println("Debug Alert " + message);
							} catch (SQLException e) {
								System.err.println("Aviso: Não passou periodicidade alerta");
							}

						}

						// tipo alerta ligeiro vindo do mongo que usa salas
						if (type.equals("light_mov")) {

							int room = objMSG.get("Sala").getAsInt();
							try {
								CallableStatement cs = conn.prepareCall("{call WriteAlert(?,?,?,?,?,?,?)}");

								cs.setTimestamp(1, Timestamp.valueOf(time));
								cs.setInt(2, room);
								cs.setString(5, type);
								cs.setString(6, description);
								cs.executeUpdate();
							} catch (SQLException e) {
								System.err.println("Aviso: Não passou periodicidade alerta");
							}

						}

						if (type.equals("descartada") || type.equals("MongoDB_status")) {

							try {
								CallableStatement cs = conn.prepareCall("{call WriteAlert(?,?,?,?,?,?,?)}");
								cs.setTimestamp(1, Timestamp.valueOf(time));
								cs.setString(5, type);
								cs.setString(6, description);
								cs.executeUpdate();
								System.out.println("Debug Alert: " + message);
							} catch (SQLException e) {
								System.err.println("Aviso: Não passou periodicidade alerta");
							}
						}

					}
				} catch (InterruptedException | SQLException e) {
					dataSource.close();
				}
			}
		}).start();

	}

	@Override
	public void connectionLost(Throwable cause) {
		cause.printStackTrace();
	}

	@Override
	public void messageArrived(String topic, MqttMessage mqttMessage) throws Exception {
		// Display the received message and topic in the text area
		textArea.append("Received: " + mqttMessage + "\n");
		String message = new String(mqttMessage.getPayload());
		switch (topic) {
		case "readings/temps": {
			temperatureQueue.put(message);
			break;
		}
		case "readings/movs": {
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

	@Override
	public void deliveryComplete(IMqttDeliveryToken token) {
		// Not used in this example
	}
}
