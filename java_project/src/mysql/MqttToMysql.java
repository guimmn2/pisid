package mysql;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.LinkedBlockingQueue;

import org.eclipse.paho.client.mqttv3.IMqttDeliveryToken;
import org.eclipse.paho.client.mqttv3.MqttCallback;
import org.eclipse.paho.client.mqttv3.MqttClient;
import org.eclipse.paho.client.mqttv3.MqttMessage;

import com.zaxxer.hikari.HikariConfig;
import com.zaxxer.hikari.HikariDataSource;

public class MqttToMysql {
    
    private static final String MQTT_BROKER = "tcp://localhost:1883";
    private static final String MQTT_TOPIC = "mytopic";
    private static final String MYSQL_URL = "jdbc:mysql://localhost:3306/mydatabase";
    private static final String MYSQL_USER = "myuser";
    private static final String MYSQL_PASSWORD = "mypassword";
    private static final int THREAD_POOL_SIZE = 10;
    private static final int CONNECTION_POOL_SIZE = 10;
    
    public static void main(String[] args) throws Exception {
        // Set up MQTT client
        MqttClient client = new MqttClient(MQTT_BROKER, MqttClient.generateClientId());
        client.connect();
        client.subscribe(MQTT_TOPIC);
        
        // Set up HikariCP connection pool
        HikariConfig config = new HikariConfig();
        config.setJdbcUrl(MYSQL_URL);
        config.setUsername(MYSQL_USER);
        config.setPassword(MYSQL_PASSWORD);
        config.setMaximumPoolSize(CONNECTION_POOL_SIZE);
        HikariDataSource dataSource = new HikariDataSource(config);
        
        // Set up thread pool and message queue
        ExecutorService executor = Executors.newFixedThreadPool(THREAD_POOL_SIZE);
        BlockingQueue<String> messageQueue = new LinkedBlockingQueue<>();
        
        // Set up message listener
        client.setCallback(new MqttCallback() {
            public void connectionLost(Throwable throwable) {}
            public void messageArrived(String s, MqttMessage mqttMessage) {
                String message = new String(mqttMessage.getPayload());
                messageQueue.add(message);
                System.out.println("Received message: " + message);
            }
            public void deliveryComplete(IMqttDeliveryToken iMqttDeliveryToken) {}
        });
        
        // Start thread to handle database insertions
        executor.execute(() -> {
            while (true) {
                try {
                    String message = messageQueue.take();
                    Timestamp timestamp = new Timestamp(System.currentTimeMillis());
                    
                    try (Connection conn = dataSource.getConnection()) {
                        String insertQuery = "INSERT INTO mytable (timestamp, message) VALUES (?, ?)";
                        PreparedStatement stmt = conn.prepareStatement(insertQuery);
                        stmt.setTimestamp(1, timestamp);
                        stmt.setString(2, message);
                        stmt.executeUpdate();
                    }
                    
                    System.out.println("Inserted message: " + message);
                } catch (InterruptedException | SQLException e) {
                    e.printStackTrace();
                }
            }
        });
        
        // Wait for messages
        while (true) {
            Thread.sleep(1000);
        }
    }
}
