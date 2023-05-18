package mongos;
import java.io.Serializable;

import org.bson.Document;

public class DocumentMessage implements Serializable {
    /**
	 * 
	 */
	private static final long serialVersionUID = -7838311410388840339L;
	private String topic;
    private String document;

    public DocumentMessage(String topic, String document) {
        this.topic = topic;
        this.document = document;
    }

    public String getTopic() {
        return topic;
    }

    public String getDocument() {
        return document;
    }
}