package mongos;
import com.mongodb.MongoClient;
import com.mongodb.MongoClientURI;
import com.mongodb.client.MongoCollection;
import com.mongodb.client.MongoDatabase;
import org.bson.Document;

import java.text.SimpleDateFormat;
import java.util.*;

public class DataGenerator {

	private static final String DB_NAME = "ratosTeste";
	private static final String TEMPERATURE_READINGS_COLLECTION = "temps";
	private static final String MOVEMENT_READINGS_COLLECTION = "movs";

	public static void main(String[] args) {
		// Connect to the MongoDB instance
		String mongoURI = new String();
		mongoURI = "mongodb://";				
		mongoURI = mongoURI + "localhot:27027,localhost:25017,localhost:23017";		
		if (true) 
			mongoURI = mongoURI + "/?replicaSet=" + "replicaRatos";		
		MongoClient mongoClient = new MongoClient(new MongoClientURI(mongoURI));
		// Select the database to use
		MongoDatabase database = mongoClient.getDatabase(DB_NAME);

		// Generate and insert 10 temperature readings
		MongoCollection<Document> temperatureCollection = database.getCollection(TEMPERATURE_READINGS_COLLECTION);
		for (int i = 0; i < 30; i++) {
			Document temperatureReading = generateTemperatureReading();
			temperatureCollection.insertOne(temperatureReading);
		}

		// Generate and insert 10 movement readings
		MongoCollection<Document> movementCollection = database.getCollection(MOVEMENT_READINGS_COLLECTION);
		for (int i = 0; i < 30; i++) {
			Document movementReading = generateMovementReading();
			movementCollection.insertOne(movementReading);
		}

		// Close the MongoDB client
		mongoClient.close();
	}

	private static Document generateTemperatureReading() {
		// Generate a random temperature between 10 and 40 degrees Celsius
		double temperature = Math.floor(Math.random() * 31) + 10;

		// Generate a random sensor ID (1 or 2)
		int sensorId = new Random().nextInt(2) + 1;

		// Generate a timestamp for the current date and time
		long timestamp = new Date().getTime();
		SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss.SSSSSS");
		String oneSS = sdf.format(timestamp);
		System.out.println("ONESS ->" + oneSS);

		// Return the temperature reading object as a Document
		return new Document("Sensor", sensorId)
				.append("Hora", oneSS)
				.append("Leitura", temperature);
	}

	private static Document generateMovementReading() {
		// Define an array of possible room IDs
		String[] roomIds = {"1", "2", "3", "4","5", "6", "7", "8"};

		// Generate a random fromRoomId and toRoomId
		String fromRoomId = roomIds[new Random().nextInt(roomIds.length)];
		String toRoomId = fromRoomId;
		while (toRoomId.equals(fromRoomId)) {
			toRoomId = roomIds[new Random().nextInt(roomIds.length)];
		}

		// Generate a timestamp for the current date and time
		long timestamp = new Date().getTime();
		SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss.SSSSSS");
		String oneSS = sdf.format(timestamp);


		// Return the movement reading object as a Document
		return new Document("Hora", oneSS)
				.append("SalaEntrada", fromRoomId)
				.append("SalaSaída", toRoomId);
	}
}
