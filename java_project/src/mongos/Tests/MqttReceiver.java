package mongos.Tests;

import java.awt.Color;

import javax.swing.*;
import org.eclipse.paho.client.mqttv3.*;
import org.eclipse.paho.client.mqttv3.persist.MemoryPersistence;

public class MqttReceiver extends JFrame implements MqttCallback {

    private JTextArea textArea;

    public MqttReceiver() {
        super("MQTT Receiver");
        setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        setSize(400, 300);

        // Create the text area
        textArea = new JTextArea();
        
        JScrollPane scrollPane = new JScrollPane(textArea);
        add(scrollPane);

        // Connect to the MQTT broker
        String broker = "tcp://broker.mqtt-dashboard.com:1883";
        String clientId = "JavaClient";
        MemoryPersistence persistence = new MemoryPersistence();
        try {
            MqttClient mqttClient = new MqttClient(broker, clientId, persistence);
            mqttClient.setCallback(this);
            mqttClient.connect();

            // Subscribe to three MQTT topics
            mqttClient.subscribe("lightWarnings");
            mqttClient.subscribe("readings/temps");
            mqttClient.subscribe("readings/movs");
            mqttClient.subscribe("test_rats");
        } catch (MqttException e) {
            e.printStackTrace();
        }

        setVisible(true);
    }

    public static void main(String[] args) {
        new MqttReceiver();
    }

    @Override
    public void connectionLost(Throwable cause) {
        cause.printStackTrace();
    }

    @Override
    public void messageArrived(String topic, MqttMessage message) throws Exception {
        // Display the received message and topic in the text area
        String text = new String(message.getPayload());
        
        switch(topic) {
        case "lightWarnings": textArea.setForeground(Color.MAGENTA);
        case "readings/temps": textArea.setForeground(Color.CYAN);
        case "reading/movs": textArea.setForeground(Color.GREEN);
        case "test_rats": textArea.setForeground(Color.ORANGE);
        }
        
        textArea.append("Message received: " + text + " from topic: " + topic + "\n");
    }

    @Override
    public void deliveryComplete(IMqttDeliveryToken token) {
        // Not used in this example
    }
}
