package mqttvolumemsg;

import java.io.FileInputStream;
import java.util.Properties;

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
            mqttclient = new MqttClient(cloud_server, "SimulateSensor"+cloud_topics);
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
		for(int i = 0; i < 10000; i++) {
			String mov = "{hour:2023-01-09 10:43:49.816173, from:1, to:3}";
			String temp = "{1, 2023-01-09 10:48:26.220914, 9}";
			String alert = "{Alerta_type=1, hour:2023-01-09 10:43:49.816173, High_temp}";
			double random = Math.random();
			if(random < 0.33) fakeMessage(mov, "readings/mov");
			else if (random < 0.66) fakeMessage(temp, "readings/temp");
			else fakeMessage(alert, "lightWarnings");
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
