package mongos;


public class RatsCount extends Thread {
	
	private int [][] counters;
	
	@Override
	public void run() {
		counters = new int [9][9];
		while(true) {
			try {
				sleep(5000);
				counters = new int[9][9];
				System.out.println("Counters -> " + counters);
			} catch (InterruptedException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
		}
	}
	
	public void increment(int from, int to) {
		counters[from][to]++;
		System.out.println(	counters[from][to]);
	}

}
