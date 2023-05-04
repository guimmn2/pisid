package mongos;

import org.bson.Document;
import org.eclipse.paho.client.mqttv3.IMqttDeliveryToken;
import org.eclipse.paho.client.mqttv3.IMqttToken;
import org.eclipse.paho.client.mqttv3.MqttCallback;
import org.eclipse.paho.client.mqttv3.MqttClient;
import org.eclipse.paho.client.mqttv3.MqttConnectOptions;
import org.eclipse.paho.client.mqttv3.MqttException;
import org.eclipse.paho.client.mqttv3.MqttMessage;
import org.eclipse.paho.client.mqttv3.MqttPersistenceException;
import com.mongodb.BasicDBObject;
import com.mongodb.DBObject;
import com.mongodb.MongoClient;
import com.mongodb.MongoClientURI;
import com.mongodb.client.MongoCollection;
import com.mongodb.client.MongoCursor;
import com.mongodb.client.MongoDatabase;
import static com.mongodb.client.model.Filters.eq;


import java.util.*;
import java.util.concurrent.TimeUnit;
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
	static MongoCollection<Document> temps;
	static MongoCollection<Document> movs;
	static MongoCollection<Document> lightWarnings;
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
	static int periodicity = 2;
	static MqttConnectOptions mqttConnectOptions = new MqttConnectOptions();
	public static void publishData() throws MqttPersistenceException, MqttException {

		Document lightWarning = new Document();
		SimpleDateFormat format = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss.SSSSSS");
		String str = format.format(new Date());
		lightWarning.put("Hora", str);
		lightWarning.put("Tipo", "MongoDB_status");
		lightWarning.put("Mensagem", "MongoDB is up!");
		lightWarning.put("createdAt", new Date());

		lightWarnings.insertOne(lightWarning);
		lightWarning.remove("_id");
		lightWarning.remove("createdAt");
		documentLabel.append(lightWarning.toJson().toString() + "\n");
		mqttclient.publish(topic_lightWarnings, lightWarning.toJson().toString().getBytes(), 2, true);



		//	while (true) {
		// Select the database to use


		//	MongoCursor<Document> cursor = db.getCollection(mongo_collection).find(eq("sent", 0)).iterator();
		//	MongoCursor<Document> cursor_1 = db.getCollection(mongo_collection_1).find(eq("sent", 0)).iterator();
		//	MongoCursor<Document> cursor_2 = db.getCollection(mongo_collection_2).find(eq("sent", 0)).iterator();

		//send temps
		//			while (cursor.hasNext()) {
		//				Document doc = cursor.next();
		//				doc.remove("createdAt");
		//				doc.remove("sent");
		//				String payload = doc.toJson();
		//				documentLabel.append(payload.toString() + "\n");
		//				mqttclient.publish(topic_temps, payload.getBytes(), 1, false);
		//				doc.put("sent", 1);
		//				db.getCollection(mongo_collection).replaceOne(eq("_id", doc.getObjectId("_id")), doc);
		//			}

		Thread thread1 = new Thread(() -> {
			while(true) {
				MongoCursor<Document> cursor = db.getCollection(mongo_collection).find(eq("sent",0)).iterator();	            
				while (cursor.hasNext()) {
					Document doc = cursor.next();
					doc.remove("createdAt");
					doc.remove("sent");
					String payload = doc.toJson();
					documentLabel.append(payload.toString() + "\n");
					try {
						mqttclient.publish(topic_temps, payload.getBytes(), 1, false);
						doc.put("sent", 1);
						db.getCollection(mongo_collection).replaceOne(eq("_id", doc.getObjectId("_id")), doc);
					} catch (MqttPersistenceException e) {
						
						e.printStackTrace();
					} catch (MqttException e) {
						try {
							mqttclient.connect(mqttConnectOptions);
							Document lightWarningT1 = new Document();
							SimpleDateFormat formatT1 = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss.SSSSSS");
							String strT1 = formatT1.format(new Date());
							lightWarningT1.put("Hora", strT1);
							lightWarningT1.put("Tipo", "MongoDB_status");
							lightWarningT1.put("Mensagem", "MongoDB is up!");
							lightWarningT1.put("createdAt", new Date());

							lightWarnings.insertOne(lightWarningT1);
							lightWarningT1.remove("_id");
							lightWarningT1.remove("createdAt");
							documentLabel.append(lightWarningT1.toJson().toString() + "\n");
							mqttclient.publish(topic_lightWarnings, lightWarningT1.toJson().toString().getBytes(), 2, true);
							
						} catch (MqttException e1) {
							// TODO Auto-generated catch block
							e1.printStackTrace();
						}
						System.out.println(doc.toString());
						e.printStackTrace();
					}
					
				}
				try {
					TimeUnit.SECONDS.sleep(periodicity);
				} catch (InterruptedException e) {
					System.err.println("Interrupted publish data to mqtt");
				}
			}});

		//send movs
		//			while (cursor_1.hasNext()) {
		//				Document doc = cursor_1.next();
		//				doc.remove("createdAt");
		//				doc.remove("sent");
		//				if(Integer.parseInt(doc.get("SalaEntrada").toString()) == 0 && Integer.parseInt(doc.get("SalaSaida").toString()) == 0) {
		//					String payload = doc.toJson();
		//					documentLabel.append(payload.toString() + "\n");
		//					mqttclient.publish(topic_movs, payload.getBytes(), 1, true);
		//				} else {
		//					String payload = doc.toJson();
		//					documentLabel.append(payload.toString() + "\n");
		//					mqttclient.publish(topic_movs, payload.getBytes(), 1, false);
		//				}
		//				doc.put("sent", 1);
		//				db.getCollection(mongo_collection_1).replaceOne(eq("_id", doc.getObjectId("_id")), doc);
		//			}


		Thread thread2 = new Thread(() -> {
			while(true) {
				MongoCursor<Document> cursor_1 = db.getCollection(mongo_collection_1).find(eq("sent", 0)).iterator();
				while (cursor_1.hasNext()) {
					Document doc = cursor_1.next();
					doc.remove("createdAt");
					doc.remove("sent");
					if(Integer.parseInt(doc.get("SalaEntrada").toString()) == 0 && Integer.parseInt(doc.get("SalaSaida").toString()) == 0) {
						String payload = doc.toJson();
						documentLabel.append(payload.toString() + "\n");
						try {
							mqttclient.publish(topic_movs, payload.getBytes(), 1, true);
							doc.put("sent", 1);
							db.getCollection(mongo_collection_1).replaceOne(eq("_id", doc.getObjectId("_id")), doc);
						} catch (MqttPersistenceException e) {
							
							// TODO Auto-generated catch block
							e.printStackTrace();
						} catch (MqttException e) {
							try {
								mqttclient.connect(mqttConnectOptions);
								
								Document lightWarningT21 = new Document();
								SimpleDateFormat formatT21 = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss.SSSSSS");
								String strT21 = formatT21.format(new Date());
								lightWarningT21.put("Hora", strT21);
								lightWarningT21.put("Tipo", "MongoDB_status");
								lightWarningT21.put("Mensagem", "MongoDB is up!");
								lightWarningT21.put("createdAt", new Date());

								lightWarnings.insertOne(lightWarningT21);
								lightWarningT21.remove("_id");
								lightWarningT21.remove("createdAt");
								documentLabel.append(lightWarningT21.toJson().toString() + "\n");
								mqttclient.publish(topic_lightWarnings, lightWarningT21.toJson().toString().getBytes(), 2, true);
							} catch (MqttException e1) {
								// TODO Auto-generated catch block
								e1.printStackTrace();
							}
							System.out.println(doc.toString());
							// TODO Auto-generated catch block
							e.printStackTrace();
						}
					} else {
						String payload = doc.toJson();
						documentLabel.append(payload.toString() + "\n");
						try {
							mqttclient.publish(topic_movs, payload.getBytes(), 1, false);
							doc.put("sent", 1);
							db.getCollection(mongo_collection_1).replaceOne(eq("_id", doc.getObjectId("_id")), doc);
						} catch (MqttPersistenceException e) {
							
							// TODO Auto-generated catch block
							e.printStackTrace();
						} catch (MqttException e) {
							try {
								mqttclient.connect(mqttConnectOptions);
								Document lightWarningT22 = new Document();
								SimpleDateFormat formatT22 = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss.SSSSSS");
								String strT22 = formatT22.format(new Date());
								lightWarningT22.put("Hora", strT22);
								lightWarningT22.put("Tipo", "MongoDB_status");
								lightWarningT22.put("Mensagem", "MongoDB is up!");
								lightWarningT22.put("createdAt", new Date());

								lightWarnings.insertOne(lightWarningT22);
								lightWarningT22.remove("_id");
								lightWarningT22.remove("createdAt");
								documentLabel.append(lightWarningT22.toJson().toString() + "\n");
								mqttclient.publish(topic_lightWarnings, lightWarningT22.toJson().toString().getBytes(), 2, true);
							} catch (MqttException e1) {
								// TODO Auto-generated catch block
								e1.printStackTrace();
							}
							System.out.println(doc.toString());
							// TODO Auto-generated catch block
							e.printStackTrace();
						}
					}
					
				}
				try {
					TimeUnit.SECONDS.sleep(periodicity);
				} catch (InterruptedException e) {
					System.err.println("Interrupted publish data to mqtt");
				}
			}});

		//send lightWarnings
		//			while (cursor_2.hasNext()) {
		//				Document doc = cursor_2.next();
		//				doc.remove("createdAt");
		//				doc.remove("sent");
		//
		//				if(doc.get("Tipo").equals("MongoDB_status") && cursor_2.hasNext()) {
		//					cursor_2.next();
		//				} else {
		//					String payload = doc.toJson();
		//					documentLabel.append(payload.toString() + "\n");
		//					mqttclient.publish(topic_lightWarnings, payload.getBytes(), 2, false);
		//				}
		//				doc.put("sent", 1);
		//				db.getCollection(mongo_collection_2).replaceOne(eq("_id", doc.getObjectId("_id")), doc);
		//				
		//			}

		Thread thread3 = new Thread(() -> {
			while(true) {
				MongoCursor<Document> cursor_2 = db.getCollection(mongo_collection_2).find(eq("sent", 0)).iterator();
				while (cursor_2.hasNext()) {
					Document doc = cursor_2.next();
					doc.remove("createdAt");
					doc.remove("sent");

					if(doc.get("Tipo").equals("MongoDB_status") && cursor_2.hasNext()) {
						cursor_2.next();
					} else {
						String payload = doc.toJson();
						documentLabel.append(payload.toString() + "\n");

						try {
							mqttclient.publish(topic_lightWarnings, payload.getBytes(), 2, false);
							doc.put("sent", 1);
							db.getCollection(mongo_collection_2).replaceOne(eq("_id", doc.getObjectId("_id")), doc);
						} catch (MqttPersistenceException e) {
							
							// TODO Auto-generated catch block
							e.printStackTrace();
						} catch (MqttException e) {
							try {
								mqttclient.connect(mqttConnectOptions);
								Document lightWarningT3 = new Document();
								SimpleDateFormat formatT3 = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss.SSSSSS");
								String strT3 = formatT3.format(new Date());
								lightWarningT3.put("Hora", strT3);
								lightWarningT3.put("Tipo", "MongoDB_status");
								lightWarningT3.put("Mensagem", "MongoDB is up!");
								lightWarningT3.put("createdAt", new Date());

								lightWarnings.insertOne(lightWarningT3);
								lightWarningT3.remove("_id");
								lightWarningT3.remove("createdAt");
								documentLabel.append(lightWarningT3.toJson().toString() + "\n");
								mqttclient.publish(topic_lightWarnings, lightWarningT3.toJson().toString().getBytes(), 2, true);
							} catch (MqttException e1) {
								// TODO Auto-generated catch block
								e1.printStackTrace();
							}
							System.out.println(doc.toString());
							// TODO Auto-generated catch block
							e.printStackTrace();
						}

					}
					

				}
				try {
					TimeUnit.SECONDS.sleep(periodicity);
				} catch (InterruptedException e) {
					System.err.println("Interrupted publish data to mqtt");
				}
			}
		});

		thread1.start();
		thread2.start();
		thread3.start();


		// Wait for 1 second before retrieving the newest readings and sensor status again

		//}
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
			topic_lightWarnings = aux[2];

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

			mqttclient = new MqttClient(cloud_server, "1001");

			
			mqttConnectOptions.setUserName("Mongo");
			String aux = "Rats404";
			mqttConnectOptions.setPassword(aux.toCharArray());
			mqttConnectOptions.setCleanSession(true);

			DBObject lightWarning = new BasicDBObject();
			SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss.SSSSSS");
			String str = sdf.format(new Date());
			lightWarning.put("Hora", str);
			lightWarning.put("Tipo", "MongoDB_status");
			lightWarning.put("Mensagem", "MongoDB is down!");
			String lastWill = lightWarning.toString();
			mqttConnectOptions.setWill(topic_lightWarnings, lastWill.getBytes(), 2, true);



			//mqttclient.connect(mqttConnectOptions);

			IMqttToken token = mqttclient.connectWithResult(mqttConnectOptions);
			System.out.println(token);
			token.waitForCompletion();

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
			db = mongoClient.getDatabase(mongo_database);
			temps =db.getCollection(mongo_collection); 
			movs = db.getCollection(mongo_collection_1);
			lightWarnings = db.getCollection(mongo_collection_2);

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