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
import java.net.Socket;
import java.net.UnknownHostException;

import javax.swing.*;
import java.awt.*;
import java.awt.event.*;

public class MongoToServer {
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
	private static final String serverHost = "127.0.0.1";
    private static final int serverPort = 1234;
    private static ObjectOutputStream outputStream= null;

	public static void publishData() {

		System.out.println("Connecting to Server");
	
		Socket socket = null;
	//	ObjectOutputStream outputStream= null;
		try {
			socket = new Socket(serverHost, serverPort);
		} catch (UnknownHostException e1) {
			// TODO Auto-generated catch block
			e1.printStackTrace();
		} catch (IOException e1) {
			// TODO Auto-generated catch block
			e1.printStackTrace();
		}
		System.out.println("Connected");
		try {
			 outputStream = new ObjectOutputStream(socket.getOutputStream());
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		
		
		Thread thread1 = new Thread(() -> {
			while(true) {
				System.out.println("TEMPS");
				MongoCursor<Document> cursor = db.getCollection(mongo_collection).find(eq("sent",0)).iterator();	            
				while (cursor.hasNext()) {
					Document doc = cursor.next();
				//	doc.remove("createdAt");
					doc.remove("sent");
					String payload = doc.toJson();
					documentLabel.append(payload.toString() + "\n");	
					DocumentMessage documentMessage = new DocumentMessage(topic_temps, doc.toJson());
					try {
						System.out.println("TEMPS DOC: " + documentMessage.getDocument() + " TOPIC "+ documentMessage.getTopic() );
						outputStream.writeObject(documentMessage);
					} catch (IOException e) {
						// TODO Auto-generated catch block
						e.printStackTrace();
					}
//                    try {
//						outputStream.flush();
//					} catch (IOException e) {
//						// TODO Auto-generated catch block
//						e.printStackTrace();
//					}
					doc.put("sent", 1);
					db.getCollection(mongo_collection).replaceOne(eq("_id", doc.getObjectId("_id")), doc);
					
				}
				try {
					TimeUnit.SECONDS.sleep(periodicity);
				} catch (InterruptedException e) {
					System.err.println("Interrupted publish data to mqtt");
				}
			}});


		Thread thread2 = new Thread(() -> {
			while(true) {
				System.out.println("MOVS");
				MongoCursor<Document> cursor_1 = db.getCollection(mongo_collection_1).find(eq("sent", 0)).iterator();
				while (cursor_1.hasNext()) {
					Document doc = cursor_1.next();
					//doc.remove("createdAt");
					doc.remove("sent");
					
					DocumentMessage documentMessage = new DocumentMessage(topic_movs, doc.toJson());
					try {
						outputStream.writeObject(documentMessage);
					} catch (IOException e) {
						// TODO Auto-generated catch block
						e.printStackTrace();
					}
//                    try {
//						outputStream.flush();
//					} catch (IOException e) {
//						// TODO Auto-generated catch block
//						e.printStackTrace();
//					}
                    
                    doc.put("sent", 1);
                    db.getCollection(mongo_collection_1).replaceOne(eq("_id", doc.getObjectId("_id")), doc);
					
				}
				try {
					TimeUnit.SECONDS.sleep(periodicity);
				} catch (InterruptedException e) {
					System.err.println("Interrupted publish data to mqtt");
				}
			}});

		Thread thread3 = new Thread(() -> {
			while(true) {
				
				MongoCursor<Document> cursor_2 = db.getCollection(mongo_collection_2).find(eq("sent", 0)).iterator();
				while (cursor_2.hasNext()) {
					
					System.out.println("LIGHT");
					Document doc = cursor_2.next();
					//doc.remove("createdAt");
					doc.remove("sent");

					if(doc.get("Tipo").equals("MongoDB_status") && cursor_2.hasNext()) {
						cursor_2.next();
					} else {
						
						DocumentMessage documentMessage = new DocumentMessage(topic_lightWarnings, doc.toJson());
						
						documentLabel.append(documentMessage.getDocument().toString()+ "\n");
						
						try {
							outputStream.writeObject(documentMessage);
						} catch (IOException e) {
							// TODO Auto-generated catch block
							e.printStackTrace();
						}
//	                    try {
//							outputStream.flush();
//						} catch (IOException e) {
//							// TODO Auto-generated catch block
//							e.printStackTrace();
//						}
	                    doc.put("sent", 1);
	                    db.getCollection(mongo_collection_2).replaceOne(eq("_id", doc.getObjectId("_id")), doc);
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
	//	thread2.start();
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
		
		createWindow();
		
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

			publishData();
	}

}