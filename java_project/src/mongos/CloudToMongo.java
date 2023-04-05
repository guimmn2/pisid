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
import java.util.Date;
import java.util.Locale;

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
	private String mostRecentDate;
	private boolean isValid;

	private RatsCount ratsCount;

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
		new CloudToMongo().connecCloud();
		new CloudToMongo().connectMongo();
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

		// ratsCount.start();

	}

	@Override
	public void messageArrived(String topic, MqttMessage c) throws Exception {
		try {
			System.out.println("Mnesagem C " + topic);
			DBObject document_json;
			document_json = (DBObject) JSON.parse(c.toString());
			checkMessages(topic, document_json);
			documentLabel.append(c.toString() + "\n");
		} catch (Exception e) {
			System.out.println(e);
		}
	}

	public void checkMessages(String topic, DBObject document_json) throws ParseException {
		SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss.SSSSSS");

		Date doc_json = sdf.parse((String) document_json.get("Hora"));

		if (mostRecentDate != null) {
			Date mostRecent = sdf.parse(mostRecentDate);

			String str = sdf.format(new Date());
			Date curr_time = sdf.parse(str);

			if (doc_json.before(mostRecent) || doc_json.after(curr_time) || document_json.get("Hora").toString().matches("[a-zA-Z]+")) {
				document_json.put("Hora", mostRecentDate);
			}
		}

		if (topic.equals("pisid_mazetemp")) {
			if ((int) document_json.get("Sensor") != 1 && (int) document_json.get("Sensor") != 2) {
				discardMessage();
				return;
			}

			if (!document_json.get("Leitura").toString().matches("^-?[0-9]+(\\.[0-9]+)?$")) {
				discardMessage();
				return;
			}

			if ((lastTempsMessageSensor1 != null && (int) document_json.get("Sensor") == 1 && Math.abs((double) lastTempsMessageSensor1.get("Leitura")
					- (double) document_json.get("Leitura")) >= 4) || (lastTempsMessageSensor2 != null && (int) document_json.get("Sensor") == 2
					&& Math.abs((double) lastTempsMessageSensor2.get("Leitura") - (double) document_json.get("Leitura")) >= 4)) {

				discardMessage();
				return;
			}

			if((int) document_json.get("Sensor") == 1)
				lastTempsMessageSensor1 = document_json;
			else
				lastTempsMessageSensor2 = document_json;


			temps.insert(document_json);
		} else {
			if(((int) document_json.get("SalaEntrada")) < 0 || (int)document_json.get("SalaSaida") <0 
					|| document_json.get("SalaEntrada").toString().matches("[a-zA-Z]+") || document_json.get("SalaSaida").toString().matches("[a-zA-Z]+")) {
				discardMessage();
				return;
			}
			if (document_json.containsField("SalaEntrada") && document_json.containsField("SalaSaida")) {
				int salaEntra = (int) document_json.get("SalaEntrada");
				int salaSaida = (int) document_json.get("SalaSaida");
				if (salaEntra == 0 && salaSaida == 0) {
					long timestamp = new Date().getTime();
					String oneSS = sdf.format(timestamp);
					document_json.put("Hora", oneSS);
					System.out.println("Sala Entrada 0 e Sala Saída 0" + oneSS);
				}
			}
			lastMovsMessage = document_json;
			movs.insert(document_json);

		}
		if(mostRecentDate!= null) {
			Date mostRecent = sdf.parse(mostRecentDate);
			if(doc_json.after(mostRecent))
				mostRecentDate = doc_json.toString();
		}

	}

	public void discardMessage() {

	}

	@Override
	public void connectionLost(Throwable cause) {
	}

	@Override
	public void deliveryComplete(IMqttDeliveryToken token) {
	}
}
