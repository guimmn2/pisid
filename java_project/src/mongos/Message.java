package mongos;

import java.io.Serializable;

import org.eclipse.paho.client.mqttv3.MqttMessage;

public class Message implements Serializable{
	/**
	 * 
	 */
	private static final long serialVersionUID = 1L;
	private String topic;
	private byte[] payload;

	public Message(String topic, MqttMessage message) {
		this.topic = topic;
		payload = message.getPayload();
	}

	public String getTopic() {
		return topic;
	}

	private byte[] getPayload() {
		return payload;
	}

	public MqttMessage getMessage() {
		return new MqttMessage(payload);
	}
	
	@Override
	public String toString() {
		return getMessage() + " from " + topic;
	}

	@Override
	public boolean equals(Object anObject) {  
		if (this == anObject) {
			return true;    
		}   
		
		if (anObject instanceof Message) {    
			Message m =(Message)anObject;
			if(this.getTopic().equals(m.getTopic()) && this.getMessage().toString().equals(m.getMessage().toString())) {
				System.out.println("Topic and Payload equal");
				return true;
			}    
		}
		System.out.println("Not equals!");
		return false;    
	} 
	
	public static void main(String[] args) {
		MqttMessage a = new MqttMessage("Hello world!".getBytes());
		Message ma = new Message("a", a);
		
		MqttMessage b = new MqttMessage("Goodbye world!".getBytes());
		Message mb = new Message("a", b);		
		Message mc = new Message("b", a);
		Message md = new Message("b", b);
		
		System.out.println(ma.equals(ma));
		System.out.println(ma.equals(mb));
		System.out.println(mb.equals(mc));
		System.out.println(mc.equals(md));
		
		System.out.println(ma.getMessage());
		System.out.println(ma.getPayload());
	}  
}
