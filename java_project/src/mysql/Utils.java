package mysql;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.Objects;

public class Utils {
	
	public static void main(String[] args) {
		ArrayList<Pair> test = new ArrayList<>();
		test.add(new Pair(1,2));
		test.add(new Pair(2,3));
		test.add(new Pair(2,4));
		
		System.out.println(existsPair(new Pair(1,2), test));
		System.out.println(existsPair(new Pair(2,1), test));
	}

	public static ArrayList<Pair> resultSetToList(ResultSet rs) throws SQLException {
		ArrayList<Pair> list = new ArrayList<>();
		while (rs.next()) {
			Pair pair = new Pair(rs.getInt(1), rs.getInt(2));
			list.add(pair);
		}
		return list;
	}
	
	public static boolean existsPair(Pair pair, ArrayList<Pair> pairs) {
		if (pair.equals(new Pair(0, 0))) return true;

		for (Pair p: pairs) {
			if (p.equals(pair)) {
				return true;
			}
		}
		return false;
	}
	
	public static class Pair {
		public final int first;
		public final int second;

		public Pair(int entry, int exit) {
			this.first = entry;
			this.second = exit;
		}
		
	    @Override
	    public String toString() {
	        return "(" + first + ", " + second + ")";
	    }

	    @Override
	    public boolean equals(Object o) {
	        if (this == o) return true;
	        if (o == null || getClass() != o.getClass()) return false;
	        Pair pair = (Pair) o;
	        return Objects.equals(first, pair.first) &&
	                Objects.equals(second, pair.second);
	    }

	    @Override
	    public int hashCode() {
	        return Objects.hash(first, second);
	    }
	}

}
