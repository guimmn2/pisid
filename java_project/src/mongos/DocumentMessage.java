package mongos;
import java.io.Serializable;

import org.bson.Document;

public class DocumentMessage implements Serializable {
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