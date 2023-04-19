package mongos;

import javax.swing.*;
import java.awt.*;
import java.awt.event.*;
import org.eclipse.paho.client.mqttv3.*;

public class MqttSender extends JFrame {

    private JLabel label;
    private JTextField textField;
    private JButton button;
    private JTextArea textArea;
    private MqttClient client;

    public MqttSender() {
        setTitle("MQTT Sender");
        setLayout(new BorderLayout());
        setSize(400, 500); // increased height to fit larger text area
        setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);

        JPanel topPanel = new JPanel(new FlowLayout());
        label = new JLabel("Enter message:");
        topPanel.add(label);

        textField = new JTextField(20);
        textField.addActionListener(new ActionListener() { // allow sending message by pressing Enter
            public void actionPerformed(ActionEvent ae) {
                sendMessage();
            }
        });
        topPanel.add(textField);

        button = new JButton("Send");
        button.addActionListener(new ActionListener() {
            public void actionPerformed(ActionEvent ae) {
                sendMessage();
            }
        });
        topPanel.add(button);

        add(topPanel, BorderLayout.NORTH);

        textArea = new JTextArea();
        textArea.setEditable(false);
        textArea.setLineWrap(true); // enable word wrapping
        textArea.setWrapStyleWord(true); // wrap at word boundaries
        JScrollPane scrollPane = new JScrollPane(textArea);
        scrollPane.setVerticalScrollBarPolicy(JScrollPane.VERTICAL_SCROLLBAR_ALWAYS); // always show vertical scrollbar
        add(scrollPane, BorderLayout.CENTER);

        String broker = "tcp://broker.mqtt-dashboard.com:1883";
        String clientId = MqttClient.generateClientId();
        try {
            client = new MqttClient(broker, clientId);
            client.connect();
        } catch (MqttException e) {
            e.printStackTrace();
        }
    }

    private void sendMessage() {
        String message = textField.getText();
        try {
            MqttMessage mqttMessage = new MqttMessage(message.getBytes());
            mqttMessage.setQos(2);
            client.publish("test_rats", mqttMessage);
            textArea.append("Sent: " + message + "\n");
            textField.setText("");
        } catch (MqttException e) {
            e.printStackTrace();
        }
    }

    public static void main(String[] args) {
        MqttSender mqttSender = new MqttSender();
        mqttSender.setVisible(true);
    }
}