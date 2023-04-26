<!DOCTYPE html>
<html>
<head>
    <title>Experiencia</title>
</head>
<body>
    <h1>Experiencia</h1>
    <table>
        <tr>
            <th>ID</th>
        </tr>
        
        <?php
        $servername = "localhost";
        $username = "root";
        $password = "";
        $database = "pisid";

        $conn = mysqli_connect($servername, $username, $password, $database);

        if (!$conn) {
            die("Connection failed: " . mysqli_connect_error()); 
        }

        $sql_query = "SELECT * FROM experiencia";
        $result = mysqli_query($conn, $sql_query);

        if (mysqli_num_rows($result) > 0) {
            while ($row = mysqli_fetch_assoc($result)) {
                echo "<tr>";
                echo "<td>" . $row["id"] . "</td>";
                echo "</tr>";
            }
        } else {
            echo "<tr><td colspan='3'>No data found</td></tr>";
        }

        mysqli_close($conn);
        ?>
    </table>
</body>
</html>
