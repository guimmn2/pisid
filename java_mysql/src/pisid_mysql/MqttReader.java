package pisid_mysql;

import java.io.FileInputStream;
import java.util.Arrays;
import java.util.Properties;
import java.util.Random;

import org.eclipse.paho.client.mqttv3.*;

public class MqttReader implements MqttCallback {
	
	private MqttClient client;
	//eventualmente de um parser de Json
	private String server;
	private String[] topics;
	
	public static void main(String[] args) {
		MqttReader reader = new MqttReader();
		reader.connectToCloud();
	}
	
	public MqttReader() {
		try {
            Properties p = new Properties();
            p.load(new FileInputStream("assets/ReceiveCloud.ini"));
            server = p.getProperty("cloud_server");
            topics = p.getProperty("cloud_topic").split(",");
        } catch (Exception e) {
            System.out.println("Error reading ReceiveCloud.ini file " + e);
        }
	}
	
	public void connectToCloud() {
		int i;
        try {
			i = new Random().nextInt(100000);
            client = new MqttClient(server, "ReceiveCloud"+String.valueOf(i)+"_" + Arrays.toString(topics));
            client.connect();
            client.setCallback(this);
            client.subscribe(topics);
        } catch (MqttException e) {
            e.printStackTrace();
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
	public void messageArrived(String topic, MqttMessage message) throws Exception {
		System.out.println("topic: " + topic + ", message: " + message.toString());
	}

}
