package mongos;

import java.util.concurrent.LinkedBlockingQueue;

public class SharedResource {
    private static final SharedResource instance = new SharedResource();
    private static final LinkedBlockingQueue<Message> queue = new LinkedBlockingQueue<>();

    private SharedResource() {
        // Initialize shared resources here
        System.out.println("Blocking Queue initiated");
    }

    public static SharedResource getInstance() {
        return instance;
    }

    public LinkedBlockingQueue<Message> getQueue() {
        return queue;
    }

    public void add(Message m) {
        queue.add(m);
        queue.forEach((n) -> System.out.print(n.getMessage().toString()));
    }
}
