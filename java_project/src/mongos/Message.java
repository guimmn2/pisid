package mongos;

import org.eclipse.paho.client.mqttv3.MqttMessage;

public class Message {
	private String topic;
	private MqttMessage message;

	public Message(String topic, MqttMessage message) {
		this.topic = topic;
		this.message = message;
	}

	public String getTopic() {
		return topic;
	}

	public MqttMessage getMessage() {
		return message;
	}

	@Override
	public String toString() {
		return message.toString() + " from " + topic;
	}

	@Override
	public boolean equals(Object anObject) {    
		if (this == anObject) {    
			return true;    
		}    
		if (anObject instanceof Message) {    
			Message m =(Message)anObject;
			if(this.getTopic().equals(m.getTopic()) && this.getMessage().toString().equals(m.getMessage().toString())) {
				return true;
			}    
		}
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
	}  
}
