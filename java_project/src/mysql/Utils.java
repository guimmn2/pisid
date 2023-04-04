package mysql;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;

public class Utils {

	public static ArrayList<Pair> resultSetToList(ResultSet rs) throws SQLException {
		ArrayList<Pair> list = new ArrayList<>();
		while (rs.next()) {
			Pair pair = new Pair(rs.getString(1), rs.getString(2));
			list.add(pair);
		}
		return list;
	}

	public static class Pair {
		public final String first;
		public final String second;

		public Pair(String first, String second) {
			this.first = first;
			this.second = second;
		}
		
	    @Override
	    public String toString() {
	        return "(" + first + ", " + second + ")";
	    }
	}

}
