package mysql;
import java.io.Serializable;

import org.bson.Document;

public class DocumentMessage implements Serializable {
    private String topic;
    private Document document;

    public DocumentMessage(String topic, Document document) {
        this.topic = topic;
        this.document = document;
    }

    public String getTopic() {
        return topic;
    }

    public Document getDocument() {
        return document;
    }

    // You can add other methods and variables as needed
}