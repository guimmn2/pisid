import org.eclipse.paho.client.mqttv3.IMqttDeliveryToken;
import org.eclipse.paho.client.mqttv3.MqttCallback;
import org.eclipse.paho.client.mqttv3.MqttClient;
import org.eclipse.paho.client.mqttv3.MqttException;
import org.eclipse.paho.client.mqttv3.MqttMessage;


import java.util.*;
import java.util.Vector;
import java.io.File;
import java.io.*;
import javax.swing.*;
import java.awt.*;
import java.awt.event.*;

public class ReceiveCloud  implements MqttCallback {
    MqttClient mqttclient;
    static String cloud_server = new String();
    static String cloud_topic = new String();
	static JTextArea documentLabel = new JTextArea("\n");       

	private static void createWindow() {       
	JFrame frame = new JFrame("Receive Cloud");    
	frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);       
	JLabel textLabel = new JLabel("Data from broker: ",SwingConstants.CENTER);       
	textLabel.setPreferredSize(new Dimension(600, 30));   
	documentLabel.setPreferredSize(new Dimension(600, 200)); 
	JScrollPane scroll = new JScrollPane (documentLabel, 
    JScrollPane.VERTICAL_SCROLLBAR_ALWAYS, JScrollPane.HORIZONTAL_SCROLLBAR_ALWAYS);
	frame.add(scroll);  	
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
            p.load(new FileInputStream("ReceiveCloud.ini"));
            cloud_server = p.getProperty("cloud_server");
            cloud_topic = p.getProperty("cloud_topic");
        } catch (Exception e) {
            System.out.println("Error reading ReceiveCloud.ini file " + e);
            JOptionPane.showMessageDialog(null, "The ReceiveCloud.inifile wasn't found.", "Receive Cloud", JOptionPane.ERROR_MESSAGE);
        }
        new ReceiveCloud().connecCloud();

    }

    public void connecCloud() {
		int i;
        try {
			i = new Random().nextInt(100000);
            mqttclient = new MqttClient(cloud_server, "ReceiveCloud"+String.valueOf(i)+"_"+cloud_topic);
            mqttclient.connect();
            mqttclient.setCallback(this);
            mqttclient.subscribe(cloud_topic);
        } catch (MqttException e) {
            e.printStackTrace();
        }
    }

    @Override
    public void messageArrived(String topic, MqttMessage c)
            throws Exception {
        try {
				documentLabel.append(c.toString()+"\n");	
        } catch (Exception e) {
            System.out.println(e);
        }
    }

    @Override
    public void connectionLost(Throwable cause) {
    }

    @Override
    public void deliveryComplete(IMqttDeliveryToken token) {
    }	
}