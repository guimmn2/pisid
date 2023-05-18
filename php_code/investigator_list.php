<!DOCTYPE html>
<html>

<head>
    <meta charset="UTF-8">
    <title>User list</title>
    <link rel="stylesheet" type="text/css" href="style.css">
</head>

    <?php
    include('utils/init.php');
    include('navbar.php');
    echo "<br><br>";
    $dbConn = new DbConn(DB, HOST, $_SESSION['email'], $_SESSION['password']);
    $conn = $dbConn->getConn();

    if ($stmt = $conn->prepare('SELECT * FROM utilizador WHERE tipo = ? OR tipo = ?') ) {
        $inv = INVESTIGATOR;
        $tec = TECHNICIAN;
        $stmt->bind_param('ss', $inv, $tec);
        $stmt->execute();
        $results = $stmt->get_result();
        $stmt->close();
    } else {
        //TODO
        //handle this better
        die('something went wrong...');
    }

    if ($results->num_rows == 0) {
        echo "Nenhum investigador ou técnico a mostrar";
    } else {
        echo "<div class='table-container'>";
        echo "<h2 class='exp-detail-title'>Lista de investigadores</h2>";
        echo "<table>";
        echo "<tr><th>Nome</th><th>Email</th><th>Tipo</th><th>";  
        while ($row = $results->fetch_assoc()) {
            echo "<tr>";
            echo "<td>" . $row['nome'] . "</td>";
            echo "<td>" . $row['email'] . "</td>";
            echo "<td>" . $row['tipo'] . "</td>";
            // TODO 
            // o BUTAO de apagar user
            echo "<td><a href='delete_investigator.php?email=" . $row['email'] . "' class='pain_link'>Apagar</a></td>";
            echo "</tr>";
        }
        echo "</div>";
    }
    echo "</table>";
    //close connection here ???
    $conn->close();
    
    echo "<a href='register.html'><button>Registar Utilizador</button></a>";
    ?>
</body>
</html>