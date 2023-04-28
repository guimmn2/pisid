package mongos;

import org.eclipse.paho.client.mqttv3.IMqttDeliveryToken;
import org.eclipse.paho.client.mqttv3.MqttCallback;
import org.eclipse.paho.client.mqttv3.MqttClient;
import org.eclipse.paho.client.mqttv3.MqttException;
import org.eclipse.paho.client.mqttv3.MqttMessage;

import com.mongodb.*;
import com.mongodb.util.JSON;

import java.util.*;
import java.io.File;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.io.*;
import javax.swing.*;
import java.awt.*;
import java.awt.event.*;

public class CloudToMongo implements MqttCallback {
	MqttClient mqttclient;
	static MongoClient mongoClient;
	static DB db;
	static DBCollection temps;
	static DBCollection movs;
	static DBCollection lightWarnings;
	static String mongo_user = new String();
	static String mongo_password = new String();
	static String mongo_address = new String();
	static String cloud_server = new String();
	static String cloud_topic = new String();
	static String mongo_host = new String();
	static String mongo_replica = new String();
	static String mongo_database = new String();
	static String mongo_collection = new String();
	static String mongo_collection_1 = new String();
	static String mongo_collection_2 = new String();
	static String mongo_authentication = new String();
	static JTextArea documentLabel = new JTextArea("\n");

	private DBObject lastTempsMessageSensor1;
	private DBObject lastTempsMessageSensor2;
	private DBObject lastMovsMessage;
	//hora em que é iniciado o programa
	private String mostRecentDate =LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss.SSSSSS"));
	private int[] discardCounters = new int[3];

	private static final long RESET_TIME_MS = 4000;
	private int[]varRooms = new int[14];
	private long[]lastUpdateTime = new long[14];
	private double[]varSensors = new double[2];

	private static void createWindow() {
		JFrame frame = new JFrame("Cloud to Mongo");
		frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
		JLabel textLabel = new JLabel("Data from broker: ", SwingConstants.CENTER);
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
			Properties p = new Properties();
			p.load(new FileInputStream("config_files/CloudToMongo.ini"));
			mongo_address = p.getProperty("mongo_address");
			mongo_user = p.getProperty("mongo_user");
			mongo_password = p.getProperty("mongo_password");
			mongo_replica = p.getProperty("mongo_replica");
			cloud_server = p.getProperty("cloud_server");
			cloud_topic = p.getProperty("cloud_topic");
			//cloud_topic = "test_rats";
			mongo_host = p.getProperty("mongo_host");
			mongo_database = p.getProperty("mongo_database");
			mongo_authentication = p.getProperty("mongo_authentication");
			mongo_collection = p.getProperty("mongo_collection");
			mongo_collection_1 = p.getProperty("mongo_collection_1");
			mongo_collection_2 = p.getProperty("mongo_collection_2");

		} catch (Exception e) {
			System.out.println("Error reading CloudToMongo.ini file " + e);
			JOptionPane.showMessageDialog(null, "The CloudToMongo.inifile wasn't found.", "CloudToMongo",
					JOptionPane.ERROR_MESSAGE);
		}
		new CloudToMongo().connectMongo();
		new CloudToMongo().connecCloud();
	}

	public void connecCloud() {
		int i;
		try {
			i = new Random().nextInt(100000);
			mqttclient = new MqttClient(cloud_server, "CloudToMongo_" + String.valueOf(i) + "_" + cloud_topic);
			mqttclient.connect();
			mqttclient.setCallback(this);
			mqttclient.subscribe(cloud_topic.split(","));
			System.out.println("Connect Cloud ");
		} catch (MqttException e) {
			e.printStackTrace();
		}
	}

	public void connectMongo() {
		String mongoURI = new String();
		mongoURI = "mongodb://";
		if (mongo_authentication.equals("true"))
			mongoURI = mongoURI + mongo_user + ":" + mongo_password + "@";
		mongoURI = mongoURI + mongo_address;
		if (!mongo_replica.equals("false"))
			if (mongo_authentication.equals("true"))
				mongoURI = mongoURI + "/?replicaSet=" + mongo_replica + "&authSource=admin";
			else
				mongoURI = mongoURI + "/?replicaSet=" + mongo_replica;
		else if (mongo_authentication.equals("true"))
			mongoURI = mongoURI + "/?authSource=admin";
		System.out.println(mongoURI);
		MongoClient mongoClient = new MongoClient(new MongoClientURI(mongoURI));
		db = mongoClient.getDB(mongo_database);
		temps = db.getCollection(mongo_collection);
		movs = db.getCollection(mongo_collection_1);
		lightWarnings = db.getCollection(mongo_collection_2);
		BasicDBObject index = new BasicDBObject("createdAt", 1);
		BasicDBObject options = new BasicDBObject("expireAfterSeconds", 604800);
		temps.createIndex(index, options);
		movs.createIndex(index, options);
		lightWarnings.createIndex(index, options);
		// ratsCount.start();

	}

	@Override
	public void messageArrived(String topic, MqttMessage c) throws ParseException {
		documentLabel.append("-----------------------------------------------------\n");
		documentLabel.append("Message received:"+c.toString()+" \n");

		validateMessage(topic, c.toString());
	}

	/**
	 * Validates the message given
	 * @param topic the topic from which the message came from
	 * @param message the message that will be validated
	 */
	private void validateMessage(String topic, String message) {


		//cleanMsg - mensagem limpa sem as chavetas e espaços
		String cleanMsg  = message.replace("{", "");
		cleanMsg  = cleanMsg.replace("}", "");


		//fields - array de strings em que
		// Temperaturas    | Movimentos
		// [0] - Hora      | (preencher de acordo)
		// [1] - Sensor    |
		// [2] - Leitura   |
		String[] fields = cleanMsg.split(",");


		//Se não existir 3 campos exclusivamente então a mensagem está errada e será descartada
		if(fields.length == 3) {

			//Validações comuns aos tópicos
			//Hora

			// Mensagem do tempo -> Hora: "2023-01-09 10:43:49.816173"
			// Damos split pelos dois pontos e ficamos com a parte da data e da hora. De seguida passamos de string para o formato LocalDateTime para mais tarde
			// podermos comparar com outras datas

			//if(message.contains("Hora")) {
			// Validações comuns aos tópicos
			// Hora

			// Mensagem do tempo -> Hora: "2023-01-09 10:43:49.816173"
			// Damos split pelos dois pontos e ficamos com a parte da data e da hora. De
			// seguida passamos de string para o formato LocalDateTime para mais tarde
			// podermos comparar com outras datas
			if (message.contains("Hora")) { 

				String[] hour = fields[0].split(":", 2);
				DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss.SSSSSS");
				String dateAndTime = hour[1].replace("\"", "").trim().replace("'","");

				if (!dateAndTime.matches("^[0-9: -\\.]*$")) {
					documentLabel.append("A Hora cont�m letras\n");
					String newMessage = "{Hora: \"" + mostRecentDate + "\", " + fields[1].trim() + ", " + fields[2].trim() + "}";
					documentLabel.append(
							"New Message com hora atualizada devido �exist�ncia de letras: " + newMessage + "\n");
					message = newMessage;
				}else {
					// criamos o objeto dateTime do tipo LocalDateTime para poder mais tarde fazer
					// comparações entre datas
					try {
						LocalDateTime dateTime = LocalDateTime.parse(dateAndTime, formatter);

						// verifica primeiro se existe algo associado à var mostRecentDate. De seguida
						// vai verificar se a hora da mensagemr recebida se encontra no futuro
						// Se for esse o caso, ent vamos alterar a data dessa mensagem para a
						// mostRecentDate.
						// Atribui à var mostRecentDate a hora atual, ou seja, a hora em que é iniciado
						// o programa.
						if (mostRecentDate != null) {
							LocalDateTime now = LocalDateTime.now();
							if (dateTime.compareTo(now) > 2) {
								documentLabel.append("Encontra-se no futuro\n");
								String newMessage = "{Hora: \"" + mostRecentDate + "\", " + fields[1].trim() + ", " + fields[2].trim() + "}";
								documentLabel.append("New Message com hora atualizada: " + newMessage + "\n");
								message = newMessage;
							}

							LocalDateTime recentDate = LocalDateTime.parse(mostRecentDate, formatter);

							// Comparamos a data da mensagem com a data da ultima mensagem mais recente
							// recebida.
							// Caso a data da mensagem atual seja anterior à da ultima mensagem recebida,
							// entao substituímos
							if (dateTime.compareTo(recentDate) < 2) {
								documentLabel.append("A data da mensagem � anterior �da mais recente que temos\n");
								String newMessage = "{Hora: \"" + mostRecentDate + "\", " + fields[1].trim() + ", " + fields[2].trim() + "}";
								documentLabel.append("New Message com hora atualizada: " + newMessage + "\n");
								message=newMessage;
							}
						}
					}catch (Exception e) {
						String newMessage = "{Hora: \"" + mostRecentDate + "\", " + fields[1].trim() + ", " + fields[2].trim() + "}";
						documentLabel.append(
								"New Message com hora atualizada devido �exist�ncia de letras: " + newMessage + "\n");
						message = newMessage;
					}
				}
			}
			cleanMsg="";
			cleanMsg  = message.replace("{", "");
			cleanMsg  = cleanMsg.replace("}", "");
			cleanMsg  = cleanMsg.replaceAll(" ", "");
			//Validações para o tópico "pisid_mazetemp"
			if(topic.equals("pisid_mazetemp")) {
				validateTemps(cleanMsg, message);

			}else if(topic.equals("pisid_mazemov")) {
				validateMovs(cleanMsg, message);
			}

		}else {
			documentLabel.append("Message Discarded INVALID NR OF FIELDS\n");
			return;
		}

	}

	private void validateMovs(String cleanMsg, String message) {
		String fields[] = cleanMsg.split(",");
		//Verificar se tem os 3 campos certos necessÃ¡rios
		if(cleanMsg.contains("SalaEntrada") && cleanMsg.contains("SalaSaida") && cleanMsg.contains("Hora")) {
			String[] salaSaida = fields[1].split(":");
			String[] salaEntrada = fields[2].split(":");

			if(salaSaida[1].equals(salaEntrada[1]) && (!salaSaida[1].equals("0") && !salaEntrada[1].equals("0"))) {

				documentLabel.append("Message Discarded ROOM\n");
				discardMessage(0, message);
				return;

			}


			if(!salaSaida[1].matches("^-?[0-9]+(\\.[0-9]+)?$") || !salaEntrada[1].matches("^-?[0-9]+(\\.[0-9]+)?$")) {
				documentLabel.append("Message Discarded ROOM\n");
				discardMessage(0, message);
				return;
			}

			if(Integer.parseInt(salaSaida[1]) < 0 || Integer.parseInt(salaEntrada[1]) < 0) {
				documentLabel.append("Message Discarded ROOM\n");
				discardMessage(0, message);
				return;
			}




			DBObject document_json;

			document_json = (DBObject) JSON.parse(message);

			saveToMongo("movs", document_json);

		}else {

			documentLabel.append("Message Discarded NOT VALID FIELDS\n");
			return;
		}
	}

	private void validateTemps(String cleanMsg, String message) {
		String fields[] = cleanMsg.split(",");
		//Verificar se tem os 3 campos certos necessários
		if(cleanMsg.contains("Leitura") && cleanMsg.contains("Sensor") && cleanMsg.contains("Hora")){
			String[] sensor = fields[2].split(":");
			String[] leitura = fields[1].split(":");


			if(!sensor[1].equals("1") && !sensor[1].equals("2") ) {
				documentLabel.append("Message Discarded SENSOR\n");
				return;
			}

			//Se passar neste if existem letras na temperatura!
			if(!leitura[1].matches("^-?[0-9]+(\\.[0-9]+)?$") ) {

				//Damos split à temperatura pelo primeiro ponto que aparecer, todos os subsequentes serão considerados letras.
				String[] temperatura = leitura[1].split("[.]", 2);

				//Verificar se existe alguma letra na primeira parte da leitura

				if(!temperatura[0].matches("^-?[0-9]+(\\.[0-9]+)?$") ) {
					documentLabel.append("Message Discarded READING WITH LETTER BEFORE DOT\n");
					discardMessage(Integer.parseInt(sensor[1]), message);
					return;
				}

				//Verificar se existe alguma letra na segunda parte da leitura, se sim então fazer a média retirando as letras
				//e deixando só os números existentes (se não houverem numeros existentes a media é 5).
				//Substituir todas as letras pela média.

				if(!temperatura[1].matches("^-?[0-9]+(\\.[0-9]+)?$") ) {
					String aux = temperatura[1];
					String[] numbersArray = aux.replaceAll("[^0-9]","").split("");
					int average;
					if(numbersArray.length == 1)
						average = 5;
					else {

						int sum = 0;
						int count = numbersArray.length;

						for (String numberStr : numbersArray) {
							int number = Integer.parseInt(numberStr);
							sum += number;
						}


						average = sum / count;

					}

					aux = aux.replaceAll("[^0-9]", Integer.toString(average));

					//Criar nova mensagem com a temperatura alterada

					fields[0] = fields[0].replaceFirst(":", ": ");
					fields[1] = fields[1].replace(":", ": ");
					fields[2] = fields[2].replace(":", ": ");

					String newMessage = "{" + fields[0]+", "+fields[1]+", Leitura: "+temperatura[0]+"."+aux+"}";
					documentLabel.append("New Message: " + newMessage+ "\n");

					//Substituímos a mensagem recebida pela nova mensagem correta
					message = newMessage;


				}
			}

			//No final criamos um DBObject com a mensagem (Caso esta tenha sido alterada nos passos acima será a newMessage)
			DBObject document_json;
			document_json = (DBObject) JSON.parse(message);


			//Validar se temos dados da última mensagem do sensor da mensagem recebida, se tivermos então validar se a variação em relação a essa última leitura é superior a 4.
			//Se sim descarta
			if ((lastTempsMessageSensor1 != null && (int) document_json.get("Sensor") == 1 
					&& Math.abs(Double.valueOf(lastTempsMessageSensor1.get("Leitura").toString()) - Double.valueOf(document_json.get("Leitura").toString())) >= 4)
					|| (lastTempsMessageSensor2 != null && (int) document_json.get("Sensor") == 2
					&& Math.abs(Double.valueOf(lastTempsMessageSensor2.get("Leitura").toString()) - Double.valueOf(document_json.get("Leitura").toString())) >= 4)) {

				documentLabel.append("Message Discarded IMPOSSIBLE TEMP VAR\n");
				discardMessage((int)(document_json.get("Sensor")), message);
				return;
			}


			//Caso o código chegue aqui significa que a mensagem está neste momento boa para guardar na BD, 
			//Por isso chamamos a função saveToMongo para guardar na coleção temps.
			System.out.println("SAVE");
			saveToMongo("temps", document_json);

		}else {

			documentLabel.append("Message Discarded NOT VALID FIELDS\n");
			return;
		}
	}

	/** 
	 * Discards a message.
	 * <p>
	 * If it isn't the third in a row from the given type, it creates a lightWarning 'Mensagem Descartada' else it creates a 'Possível Avaria' one.
	 *	@param type 0 - Rats Movement; 1 - Sensor 1; 2 - Sensor 2
	 *	@param message The message that's supposed to be discarded
	 *				
	 */
	private void discardMessage(int type, String message) {
		if(discardCounters[type] < 3) {
			createLightWarning("disc", message, 0);
			discardCounters[type]++;
		}else {
			createLightWarning("probAv", "", type);
			discardCounters[type] = 0;
		}
	}

	/** This function creates a DBObject 'lightWarning' with the given type.
	 * <br>
	 * 	If the type is 'disc' then the only param looked at is the message which must be filled, otherwise it can be just blank.
	 * <br>
	 *  For the other types the param SensorOrRoom needs to be filled with the sensor or room in question.
	 * 
	 * @param type rapVar - Rápida Variação temp at SensorOrRoom
	 * 			   <br>entMov - Rápida entrada de ratos at SensorOrRoom
	 * 			   <br>saidaMov - Rápida Saida de ratos at SensorOrRoom
	 * 			   <br>disc - param message was discarded
	 * 			   <br>provAv - Provável Avaria at SensorOrRoom
	 * 
	 * @param message The message that was discarted. Is only need if type is "disc", otherwise can be blank
	 * @param SensorOrRoom The Sensor or Room, depending on the type, that the lightWarning refers to
	 */
	private void createLightWarning(String type, String message, int SensorOrRoom) {

		DBObject lightWarning = new BasicDBObject();
		SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss.SSSSSS");
		String str = sdf.format(new Date());
		lightWarning.put("Hora", str);

		switch(type) {
		case "rapVar":
			lightWarning.put("Tipo", "light_temp");		
			lightWarning.put("Sensor", SensorOrRoom);
			lightWarning.put("Mensagem", "R�pida varia��o da temperatura registada no sensor " + SensorOrRoom +".");
			documentLabel.append("Created LightWarning light_temp\n");
			break;

		case "entMov":
			lightWarning.put("Tipo", "light_mov");
			lightWarning.put("Sala", SensorOrRoom);
			lightWarning.put("Mensagem", "R�pida entrada de ratos registada na sala " + SensorOrRoom+".");
			documentLabel.append("Created LightWarning light_mov\n");
			break;

		case "saidaMov":
			lightWarning.put("Tipo", "light_mov");
			lightWarning.put("Sala", SensorOrRoom);
			lightWarning.put("Mensagem", "R�pida sa�da de ratos registada na sala " + SensorOrRoom+".");
			documentLabel.append("Created LightWarning light_mov\n");
			break;

		case "disc":
			lightWarning.put("Tipo", "descartada");
			lightWarning.put("Mensagem", message);
			documentLabel.append("Created LightWarning descartada\n");
			break;

		case "probAv":
			lightWarning.put("Tipo", "avaria");
			lightWarning.put("Sensor", SensorOrRoom);
			lightWarning.put("Mensagem", "Prov�vel avaria no sensor "+ SensorOrRoom + ".");
			documentLabel.append("Created LightWarning avaria\n");
			break;

		}

		saveToMongo("lightWarnings", lightWarning);
	}

	/**
	 * Void function that saves to document_json to the given collection.
	 * <br>
	 * Will reset the corresponding discard counter if it exists!
	 * 
	 * @param collection "temps", "movs" or "lightWarnings"
	 * @param document_json The DBObject to save to the collection
	 */
	private void saveToMongo(String collection, DBObject document_json) {
		mostRecentDate = document_json.get("Hora").toString();
		document_json.put("createdAt", new Date());
		document_json.put("sent",0);

		switch(collection) {

		case "temps":
			discardCounters[(int)document_json.get("Sensor")] = 0;
			alterVarCounters("sensor", document_json);

			if((int) document_json.get("Sensor") == 1) {
				lastTempsMessageSensor1 = document_json;
			}else
				lastTempsMessageSensor2 = document_json;
			temps.insert(document_json);

			break;

		case "movs": 

			movs.insert(document_json);


			discardCounters[0] = 0;	
			if(document_json.get("SalaEntrada").equals(0) && document_json.get("SalaSaida").equals(0)) {
				lastMovsMessage = document_json;
				break;
			}

			alterVarCounters("room", document_json);
			lastMovsMessage = document_json;
			break;

		case "lightWarnings": lightWarnings.insert(document_json);	
		break;
		}

		documentLabel.append("Saved to Mongo\n");
	}

	private void alterVarCounters(String type, DBObject document_json) {
		switch(type) {
		case "sensor":
			double diff = 0;
			if(document_json.get("Sensor").equals(1)) {
				if(lastTempsMessageSensor1 == null) break;
				diff = Double.valueOf(document_json.get("Leitura").toString()) - Double.valueOf(lastTempsMessageSensor1.get("Leitura").toString());
			}else {
				if(lastTempsMessageSensor2 == null) break;
				diff =  Double.valueOf(document_json.get("Leitura").toString() )- Double.valueOf(lastTempsMessageSensor2.get("Leitura").toString());
			}
			documentLabel.append("Depois de verificar cenas dos sensores\n");

			if(diff>=1 || diff<=-1)
				varSensors[(int)document_json.get("Sensor")-1] += diff ;
			else if(varSensors[(int)document_json.get("Sensor")-1] > 0) {
				varSensors[(int)document_json.get("Sensor")-1] --;
			}else if(varSensors[(int)document_json.get("Sensor")-1] < 0) {
				varSensors[(int)document_json.get("Sensor")-1] ++;
			}

			if(varSensors[(int)document_json.get("Sensor")-1] >= 5 || varSensors[(int)document_json.get("Sensor")-1] <= -5) {
				createLightWarning("rapVar", "", (int)document_json.get("Sensor"));
				varSensors[(int)document_json.get("Sensor")-1] = 0;
			}

			break;

		case "room":
			long currentTime = System.currentTimeMillis();
			for (int i = 0; i < 14; i++) {
				//System.out.println("i: "+lastUpdateTime[i]);
				if (varRooms[i] > 0 && currentTime - lastUpdateTime[i] > RESET_TIME_MS) {
					varRooms[i] = 0;
					//System.out.printf("Counter for index %d has been reset.%n", i);
				}
			}

			varRooms[(int)document_json.get("SalaEntrada")-1]++;
			//System.out.println(varRooms[(int)document_json.get("SalaEntrada")-1]);
			varRooms[(int)document_json.get("SalaSaida")-1]--;
			//System.out.println(varRooms[(int)document_json.get("SalaSaida")-1]);

			lastUpdateTime[(int)document_json.get("SalaEntrada")-1] = System.currentTimeMillis();
			lastUpdateTime[(int)document_json.get("SalaSaida")-1] = System.currentTimeMillis();

			if(varRooms[(int)document_json.get("SalaEntrada")-1] >= 5) {
				createLightWarning("entMov","",(int)document_json.get("SalaEntrada"));
				varRooms[(int)document_json.get("SalaEntrada")-1]=0;
			}

			if(varRooms[(int)document_json.get("SalaSaida")-1] <= -5) {
				createLightWarning("saidaMov","",(int)document_json.get("SalaSaida"));
				varRooms[(int)document_json.get("SalaSaida")-1] = 0;
			}

			break;
		}
	}

	@Override
	public void connectionLost(Throwable cause) {
	}

	@Override
	public void deliveryComplete(IMqttDeliveryToken token) {
	}
}