package mongos;

import java.awt.BorderLayout;
import java.awt.Dimension;
import java.io.FileInputStream;
import java.io.IOException;
import java.util.Properties;
import java.util.Queue;
import java.util.Random;
import java.util.concurrent.LinkedBlockingQueue;

import javax.swing.*;
import javax.swing.text.DefaultCaret;

import org.eclipse.paho.client.mqttv3.*;
import java.util.Timer;
import java.util.TimerTask;

@SuppressWarnings("serial")
public class Backup extends JFrame implements MqttCallback {

	private static Backup instance;
	private JTextArea textArea;
	private static LinkedBlockingQueue<Message> messagesReceived;
	MqttClient mqttclient;
	static String cloud_server = new String();
	static String cloud_topic = new String();
	private static CloudToMongo ctm;
    private Timer timer;
    private static Queue<Message> messagesSaved; 

	public static Backup getInstance() {
		if (instance == null) {
			instance = new Backup();
		}
		return instance;
	}
	
	private Backup() {
		super("Backup Cloud To Mongo");
		setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
		setSize(400, 300);

		// Create the text area
		textArea = new JTextArea();

		JScrollPane scrollPane = new JScrollPane(textArea,JScrollPane.VERTICAL_SCROLLBAR_ALWAYS,
				JScrollPane.HORIZONTAL_SCROLLBAR_ALWAYS);
		add(scrollPane);
		JLabel textLabel = new JLabel("Backup: ", SwingConstants.CENTER);
		textLabel.setPreferredSize(new Dimension(600, 15));
		add(textLabel, BorderLayout.PAGE_START);
		// Get the text area's caret
		DefaultCaret caret = (DefaultCaret) textArea.getCaret();

		// Set the caret to always scroll to the bottom of the text area
		caret.setUpdatePolicy(DefaultCaret.ALWAYS_UPDATE);
		
		
		Properties p = new Properties();
		try {
			p.load(new FileInputStream("config_files/CloudToMongo.ini"));
			cloud_server = p.getProperty("cloud_server");
			cloud_topic = p.getProperty("cloud_topic");
		} catch (IOException e1) {
			System.out.println("Error reading CloudToMongo.ini file " + e1);
			JOptionPane.showMessageDialog(null, "The CloudToMongo.inifile wasn't found.", "CloudToMongo",
					JOptionPane.ERROR_MESSAGE);
		}
		
		messagesReceived = new LinkedBlockingQueue<Message>();
		ctm = CloudToMongo.getInstance();
		messagesSaved = ctm.getMessagesSaved();
		int i;
		try {
			i = new Random().nextInt(100000);
			mqttclient = new MqttClient(cloud_server, "BackupCloudToMongo_" + String.valueOf(i) + "_" + cloud_topic);
			mqttclient.connect();
			mqttclient.setCallback(this);
			mqttclient.subscribe(cloud_topic.split(","));
			System.out.println("Connect Cloud ");
		} catch (MqttException e) {
			e.printStackTrace();
		}
		

		setVisible(true);
		
		 timer = new Timer();
	        timer.schedule(new TimerTask() {
	            @Override
	            public void run() {
	            	
	            	textArea.append("Messages Received Before Backup: ");
	            	messagesReceived.forEach((n)->{textArea.append(n.getMessage().toString()+" | ");});
	            	textArea.append("\n");
	            	
	            	textArea.append("Messages Saved: ");
	            	messagesSaved.forEach((n)->{textArea.append(n.getMessage().toString()+" | ");});
	            	textArea.append("\n");
	            	
	                if (messagesSaved.isEmpty() && !messagesReceived.isEmpty()) {
	                    // Assume that the CloudToMongo instance is dead and restart it
	                	textArea.append("O MONGO MORREU!\n");
	            		textArea.append("---------------------------\n");
	                	restartCloudToMongo();
	                }else {
	                	messagesReceived.removeAll(messagesSaved);
	                	messagesSaved.clear();
	                	textArea.append("Messages Received After Backup: ");
		            	messagesReceived.forEach((n)->{textArea.append(n.getMessage().toString()+" | ");});
		            	textArea.append("\n");
	                }
	                
	            }
	        }, 10000, 10000);
	}

	@Override
	public void connectionLost(Throwable cause) {
		cause.printStackTrace();
	}

	@Override
	public void messageArrived(String topic, MqttMessage message) throws Exception {
		// Display the received message and topic in the text area
		String text = new String(message.getPayload());
		messagesReceived.put(new Message(topic, message));
		textArea.append("Message received: " + text + " from topic: " + topic + "\n");
		textArea.append("Added to backup queue\n");
		textArea.append("---------------------------\n");
	}

	@Override
	public void deliveryComplete(IMqttDeliveryToken token) {
		// Not used in this example
	}
	
	private void restartCloudToMongo() {
		ctm = CloudToMongo.getInstance();
		ctm.addMessagesReceived(messagesReceived);
	}

	public static void main(String[] args) {
		getInstance();	
	}

}
