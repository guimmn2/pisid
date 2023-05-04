package mongos;

import java.awt.Color;
import java.io.FileInputStream;
import java.io.IOException;
import java.util.Properties;
import java.util.Random;

import javax.swing.*;
import org.eclipse.paho.client.mqttv3.*;
import org.eclipse.paho.client.mqttv3.persist.MemoryPersistence;

public class Backup extends JFrame implements MqttCallback {

	private JTextArea textArea;
	MqttClient mqttclient;
	static String cloud_server = new String();
	static String cloud_topic = new String();

	public Backup() {
		super("MQTT Receiver");
		setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
		setSize(400, 300);

		// Create the text area
		textArea = new JTextArea();

		JScrollPane scrollPane = new JScrollPane(textArea);
		add(scrollPane);

		// Connect to the MQTT broker
		String broker = "tcp://broker.mqtt-dashboard.com:1883";
		
		MemoryPersistence persistence = new MemoryPersistence();
		Properties p = new Properties();
		try {
			p.load(new FileInputStream("config_files/CloudToMongo.ini"));
			cloud_server = p.getProperty("cloud_server");
			cloud_topic = p.getProperty("cloud_topic");
		} catch (IOException e1) {
			// TODO Auto-generated catch block
			e1.printStackTrace();
		}
		
		
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
		

		setVisible(true);
	}

	public static void main(String[] args) {
		new Backup();
		
	}

	@Override
	public void connectionLost(Throwable cause) {
		cause.printStackTrace();
	}

	@Override
	public void messageArrived(String topic, MqttMessage message) throws Exception {
		// Display the received message and topic in the text area
		String text = new String(message.getPayload());

		textArea.append("Message received: " + text + " from topic: " + topic + "\n");
	}

	@Override
	public void deliveryComplete(IMqttDeliveryToken token) {
		// Not used in this example
	}



}
