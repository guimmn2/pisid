package mongos;

import org.bson.Document;
import org.eclipse.paho.client.mqttv3.IMqttDeliveryToken;
import org.eclipse.paho.client.mqttv3.MqttCallback;
import org.eclipse.paho.client.mqttv3.MqttClient;
import org.eclipse.paho.client.mqttv3.MqttConnectOptions;
import org.eclipse.paho.client.mqttv3.MqttException;
import org.eclipse.paho.client.mqttv3.MqttMessage;
import org.eclipse.paho.client.mqttv3.MqttPersistenceException;
import org.eclipse.paho.client.mqttv3.persist.MemoryPersistence;

import com.mongodb.DB;
import com.mongodb.DBCollection;
import com.mongodb.MongoClient;
import com.mongodb.MongoClientURI;
import com.mongodb.client.MongoCollection;
import com.mongodb.client.MongoCursor;
import com.mongodb.client.MongoDatabase;

import java.util.*;
import java.util.List;
import java.time.*;
import java.time.format.DateTimeFormatter;
import java.util.concurrent.TimeUnit;
import java.io.File;
import java.text.SimpleDateFormat;
import java.io.*;
import javax.swing.*;
import java.awt.*;
import java.awt.event.*;

public class MongoToMqtt implements MqttCallback {
	static MqttClient mqttclient;
	static MongoDatabase db;
	static String cloud_server = new String();
	static String cloud_topic = new String();
	static String topic_temps = new String();
	static String topic_movs = new String();
	static String topic_lightWarnings = new String();
	static DBCollection temps;
	static DBCollection movs;
	static DBCollection lightWarnings;
	static String mongo_user = new String();
	static String mongo_password = new String();
	static String mongo_address = new String();
	static String mongo_host = new String();
	static String mongo_replica = new String();
	static String mongo_database = new String();
	static String mongo_collection = new String();
	static String mongo_collection_1 = new String();
	static String mongo_collection_2 = new String();
	static String mongo_authentication = new String();
	static JTextArea documentLabel = new JTextArea("\n");
	static int periodicity = 1;


	public static void publishSensor(String leitura) {
		try {
			MqttMessage mqtt_message = new MqttMessage();
			mqtt_message.setPayload(leitura.getBytes());
			mqttclient.publish(cloud_topic, mqtt_message);
		} catch (MqttException e) {
			e.printStackTrace();
		}
	}

	public static void publishData() throws MqttPersistenceException, MqttException {
		String mongoURI = new String();
		mongoURI = "mongodb://";		
		if (mongo_authentication.equals("true")) mongoURI = mongoURI + mongo_user + ":" + mongo_password + "@";		
		mongoURI = mongoURI + mongo_address;		
		if (!mongo_replica.equals("false")) 
			if (mongo_authentication.equals("true")) mongoURI = mongoURI + "/?replicaSet=" + mongo_replica+"&authSource=admin";
			else mongoURI = mongoURI + "/?replicaSet=" + mongo_replica;		
		else
			if (mongo_authentication.equals("true")) mongoURI = mongoURI  + "/?authSource=admin";
		MongoClient mongoClient = new MongoClient(new MongoClientURI(mongoURI));


		while (true) {
			// Select the database to use
			db = mongoClient.getDatabase(mongo_database);
			
			Date currentDate = new Date();
			Calendar cal = Calendar.getInstance();
			cal.setTime(currentDate);
			cal.add(Calendar.SECOND, -periodicity);
			Date oneSecondAgo = cal.getTime();
			SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss.SSSSSS");
			String oneSS = sdf.format(oneSecondAgo);
	        Document query = new Document("Hora", new Document("$gte", oneSS));
	        System.out.println("Second ago -> " + oneSS);
	        MongoCursor<Document> cursor = db.getCollection(mongo_collection).find(query).iterator();
	        MongoCursor<Document> cursor_1 = db.getCollection(mongo_collection_1).find(query).iterator();
	        MongoCursor<Document> cursor_2 = db.getCollection(mongo_collection_2).find().iterator();
	      
	        //send temps
	        while (cursor.hasNext()) {
	            Document doc = cursor.next();
	            doc.remove("_id");
	            String payload = doc.toJson();
	            MqttMessage message = new MqttMessage(payload.getBytes());
	            documentLabel.append(message.toString() + "\n");
	            mqttclient.publish(topic_temps, message);
	        }
	        //send movs
	        while (cursor_1.hasNext()) {
	            Document doc = cursor_1.next();
	            doc.remove("_id");
	            String payload = doc.toJson();
	            MqttMessage message = new MqttMessage(payload.getBytes());
	            documentLabel.append(message.toString() + "\n");
	            mqttclient.publish(topic_movs, message);
	        }
	        //send lightWarnings
	        while (cursor_2.hasNext()) {
	            Document doc = cursor_2.next();
	            doc.remove("_id");
	            String payload = doc.toJson();
	            MqttMessage message = new MqttMessage(payload.getBytes());
	            documentLabel.append(message.toString() + "\n");
	            mqttclient.publish(topic_lightWarnings, message);
	        }

			// Retrieve the newest temperature reading
//			MongoCollection<Document> temperatureCollection = db.getCollection(mongo_collection);
//			Document newestTemperatureReading = temperatureCollection.find().sort(new Document("date", -1)).first();
//
//			// Retrieve the newest movement reading
//			MongoCollection<Document> movementCollection = db.getCollection(mongo_collection_1);
//			Document newestMovementReading = movementCollection.find().sort(new Document("date", -1)).first();

			// Retrieve the newest sensor status
			//MongoCollection<Document> sensorStatusCollection = db.getCollection(mongo_collection_2);
			//Document newestSensorStatus = sensorStatusCollection.find().sort(new Document("date", -1)).first();

			// Convert the documents to JSON strings
//			String temperatureJson = newestTemperatureReading.toJson();
//			String movementJson = newestMovementReading.toJson();
			
//			String temperatureJson = results.toJson();
//			//String lightWarningsJson = newestSensorStatus.toJson();
//
//			// Create MQTT messages from the JSON strings
//			MqttMessage temperatureMessage = new MqttMessage(temperatureJson.getBytes());
//			documentLabel.append(temperatureMessage.toString()+"\n");				
//			MqttMessage movementMessage = new MqttMessage(movementJson.getBytes());
//			documentLabel.append(movementMessage.toString()+"\n");				
//			//MqttMessage lightWarningsMessage = new MqttMessage(lightWarningsJson.getBytes());
//			//documentLabel.append(lightWarningsMessage.toString()+"\n");				
//
//
//			// Publish the MQTT messages to the respective topics
			System.out.println("Temps -> " + topic_temps);
			System.out.println("Movs -> " + topic_movs);
//			mqttclient.publish(topic_temps, temperatureMessage);
//			mqttclient.publish(topic_movs, movementMessage);
//			//mqttclient.publish(topic_lightWarnings, lightWarningsMessage);

			// Wait for 1 second before retrieving the newest readings and sensor status again
			try {
				TimeUnit.SECONDS.sleep(periodicity*5);
			} catch (InterruptedException e) {
				System.err.println("Interrupted publish data to mqtt");
			}
		}
	}

	private static void createWindow() {
		JFrame frame = new JFrame("Send Cloud");    
		frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);       
		JLabel textLabel = new JLabel("Data from broker: ",SwingConstants.CENTER);       
		textLabel.setPreferredSize(new Dimension(600, 30));   
		JScrollPane scroll = new JScrollPane (documentLabel, JScrollPane.VERTICAL_SCROLLBAR_ALWAYS, JScrollPane.HORIZONTAL_SCROLLBAR_ALWAYS);	
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

	public static void main(String[] args) throws MqttPersistenceException, MqttException {

		try {
			Properties p = new Properties();
			p.load(new FileInputStream("config_files/SendCloud.ini"));
			cloud_server = p.getProperty("cloud_server");
			cloud_topic = p.getProperty("cloud_topic");
			mongo_address = p.getProperty("mongo_address");
			mongo_user = p.getProperty("mongo_user");
			mongo_password = p.getProperty("mongo_password");
			mongo_replica = p.getProperty("mongo_replica");
			mongo_host = p.getProperty("mongo_host");
			mongo_database = p.getProperty("mongo_database");
			mongo_authentication = p.getProperty("mongo_authentication");
			mongo_collection = p.getProperty("mongo_collection");
			mongo_collection_1 = p.getProperty("mongo_collection_1");
			mongo_collection_2 = p.getProperty("mongo_collection_2");
			String [] aux = cloud_topic.split(",");
			topic_temps = aux[0];
			topic_movs = aux[1];

		} catch (Exception e) {

			System.out.println("Error reading SendCloud.ini file " + e);
			JOptionPane.showMessageDialog(null, "The SendCloud.ini file wasn't found.", "Send Cloud",
					JOptionPane.ERROR_MESSAGE);
		}
		new MongoToMqtt().connecCloud();
		createWindow();
		publishData();

	}

	public void connecCloud() {
		try {

			mqttclient = new MqttClient(cloud_server, MqttClient.generateClientId(), new MemoryPersistence());
			MqttConnectOptions mqttConnectOptions = new MqttConnectOptions();
			// mqttConnectOptions.setUserName(MQTT_USER_NAME);
			// mqttConnectOptions.setPassword(MQTT_PASSWORD.toCharArray());
			mqttclient.connect(mqttConnectOptions);
		} catch (MqttException e) {
			e.printStackTrace();
		}
	}

	@Override
	public void connectionLost(Throwable cause) {
	}

	@Override
	public void deliveryComplete(IMqttDeliveryToken token) {
	}

	@Override
	public void messageArrived(String topic, MqttMessage message) {
	}

}