package mqttvolumemsg;

import java.io.FileInputStream;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Properties;
import java.util.UUID;
import org.eclipse.paho.client.mqttv3.IMqttDeliveryToken;
import org.eclipse.paho.client.mqttv3.MqttCallback;
import org.eclipse.paho.client.mqttv3.MqttClient;
import org.eclipse.paho.client.mqttv3.MqttException;
import org.eclipse.paho.client.mqttv3.MqttMessage;
import org.eclipse.paho.client.mqttv3.MqttPersistenceException;

public class MqttSender implements MqttCallback {

	static MqttClient mqttclient;
	static String cloud_server = new String();
	static String[] cloud_topics;

	public MqttSender() {
		try {
			Properties p = new Properties();
			p.load(new FileInputStream("config_files/ReceiveCloud.ini"));
			cloud_server = p.getProperty("cloud_server");
			cloud_topics = p.getProperty("cloud_topic").split(",");
		} catch (Exception e) {
			System.out.println("Error reading SendCloud.ini file " + e);
		}
	}

	public void connectToMqtt() {
		try {
			mqttclient = new MqttClient(cloud_server, "SimulateSensor" + cloud_topics);
			mqttclient.connect();
			mqttclient.setCallback(this);
			mqttclient.subscribe(cloud_topics);
		} catch (MqttException e) {
			e.printStackTrace();
		}
	}

	public static void fakeMessage(String message, String topic) throws MqttPersistenceException, MqttException {
		MqttMessage mqtt_message = new MqttMessage();
		mqtt_message.setPayload(message.getBytes());
		mqttclient.publish(topic, mqtt_message);
	}

	public static void main(String[] args) throws MqttPersistenceException, MqttException {
		MqttSender mongoSender = new MqttSender();
		mongoSender.connectToMqtt();
		
		boolean começou = false;
		
		for (int i = 0; i < 10000; i++) {

			LocalDateTime currentDateTime = LocalDateTime.now();

			// Define a formatter for the timestamp string
			DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss.SSS");

			// Format the timestamp as a string
			String timestampString = currentDateTime.format(formatter);

			double temperature = Math.random() * 15;

			
			
			
			double random = Math.random();
			String randomString = UUID.randomUUID().toString();
			
		/*
				if(random <= 0.33) {
					String message = "{Tipo: \"" +"light_descartada" + "\", Hora: \"" + timestampString + "\", Leitura: 20.1, Sensor: 1, Mensagem: \"" + "Rápida variação de temp registada no sensor 1"+ "\"}";
					MqttMessage mqtt_message = new MqttMessage();
					mqtt_message.setPayload(message.getBytes());
					mqttclient.publish("lightWarnings", mqtt_message);
				}else if(random <= 0.66){
					String message = "{Tipo: \"" +"light_descartada" + "\", Hora: \"" + timestampString + "\", Leitura: 20.1, Sensor: 2, Mensagem: \"" + "Rápida variação de temp registada no sensor 1"+ "\"}";
					MqttMessage mqtt_message = new MqttMessage();
					mqtt_message.setPayload(message.getBytes());
					mqttclient.publish("lightWarnings", mqtt_message);
				} else {
					String message = "{_id: \"" + randomString + "\", Hora: \"" + timestampString + "\", SalaEntrada: 0, SalaSaida: 0}";
					MqttMessage mqtt_message = new MqttMessage();
					mqtt_message.setPayload(message.getBytes());
					mqttclient.publish("readings/mov", mqtt_message);
				}
				
			*/
			
			
			/*
			if(random <= 0.5) {
				String message = "{Tipo: \"" +"light_descartada" + "\", Hora: \"" + timestampString + "\", Leitura: 20.1, Sensor: 1, Mensagem: \"" + "Rápida variação de temp registada no sensor 1"+ "\"}";
				MqttMessage mqtt_message = new MqttMessage();
				mqtt_message.setPayload(message.getBytes());
				mqttclient.publish("lightWarnings", mqtt_message);
			}else {
				String message = "{Tipo: \"" +"light_descartada" + "\", Hora: \"" + timestampString + "\", Leitura: 20.1, Sensor: 2, Mensagem: \"" + "Rápida variação de temp registada no sensor 2"+ "\"}";
				MqttMessage mqtt_message = new MqttMessage();
				mqtt_message.setPayload(message.getBytes());
				mqttclient.publish("lightWarnings", mqtt_message);
			}
			
			/* String message = "{_id: \"" + randomString+ "\", Hora: \"" + timestampString + "\", Leitura: 20.01, Sensor: 1}";
				MqttMessage mqtt_message = new MqttMessage();
				mqtt_message.setPayload(message.getBytes());
				mqttclient.publish("readings/temp", mqtt_message);*/
			
			
			/*
			if(random < 0.33) {
				String message = "{Tipo: \"" +"Rápida variação temp" + "\", Hora: \"" + timestampString + "\", Sensor: 1, Mensagem: \"" + "Rápida variação de temp registada no sensor 1"+ "\"}";
				MqttMessage mqtt_message = new MqttMessage();
				mqtt_message.setPayload(message.getBytes());
				mqttclient.publish("lightWarnings", mqtt_message);
			}else if(random < 0.66) {
				String message = "{Tipo: \"" +"Entrada mov ratos" + "\", Hora: \"" + timestampString + "\", Sala: 2, Mensagem: \"" + "Rápida entrada na sala 2"+ "\"}";
				MqttMessage mqtt_message = new MqttMessage();
				mqtt_message.setPayload(message.getBytes());
				mqttclient.publish("lightWarnings", mqtt_message);
			}else {
				String message = "{Tipo: \"" +"Mensagem descartada" + "\", Hora: \"" + timestampString + "\", Leitura: 9.6, Mensagem: \"" + "Peguntar a syntax deste tipo de msg aos outros"+ "\"}";
				MqttMessage mqtt_message = new MqttMessage();
				mqtt_message.setPayload(message.getBytes());
				mqttclient.publish("lightWarnings", mqtt_message);
			} 
			*/
			
			if(random < 0.05) {
				String message = "{_id: \"" + randomString + "\", Hora: \"" + timestampString + "\", SalaEntrada: 0, SalaSaida: 0}";
				MqttMessage mqtt_message = new MqttMessage();
				mqtt_message.setPayload(message.getBytes());
				mqttclient.publish("readings/mov", mqtt_message);
				}else if (random <= 0.5) {
				
				String message = "{_id: \"" + randomString+ "\", Hora: \"" + timestampString + "\", Leitura: 20.01, Sensor: 1}";
				MqttMessage mqtt_message = new MqttMessage();
				mqtt_message.setPayload(message.getBytes());
				mqttclient.publish("readings/temp", mqtt_message);
			}else {
					String message = "{_id: \"" + randomString + "\", Hora: \"" + timestampString + "\", SalaEntrada: 2, SalaSaida: 1}";
					MqttMessage mqtt_message = new MqttMessage();
					mqtt_message.setPayload(message.getBytes());
					mqttclient.publish("readings/mov", mqtt_message);
			}
				/*
				String message = "{_id: \"" + randomString + "\", Hora: \"" + timestampString + "\", SalaEntrada: 2, SalaSaida: 1}";
				MqttMessage mqtt_message = new MqttMessage();
				mqtt_message.setPayload(message.getBytes());
				mqttclient.publish("readings/mov", mqtt_message);
				*/
				
			
			
				
			try {
				Thread.sleep(1000);
			} catch (InterruptedException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
		}
	}

	@Override
	public void connectionLost(Throwable arg0) {
		// TODO Auto-generated method stub

	}

	@Override
	public void deliveryComplete(IMqttDeliveryToken arg0) {
		// TODO Auto-generated method stub

	}

	@Override
	public void messageArrived(String arg0, MqttMessage arg1) throws Exception {
		// TODO Auto-generated method stub

	}

}
