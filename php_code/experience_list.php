<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Your Experiences</title>
    <link rel="stylesheet" type="text/css" href="style.css">
</head>
<body>
    <?php
    include('utils/init.php');
    include ('navbar.php');
    echo "<br><br>";
    $dbConn = new DbConn(DB, HOST, $_SESSION['email'], $_SESSION['password']);
    $conn = $dbConn->getConn();

    //get experiences and show list of experiences
    if ($stmt = $conn->prepare('SELECT * FROM experiencia WHERE investigador = ?')) {
        $stmt->bind_param('s', $_SESSION['email']);
        $stmt->execute();
        $results = $stmt->get_result();
    } else {
        //TODO
        //handle this better
        die('something went wrong...');
    }

    if ($results->num_rows == 0) {
        echo "Nenhuma experiencia associada ao utilizador";
    } else {
        // display the list of experiences, por motivos de maldição tive q criar um container diferente para a lista de exp
        echo "<div class='table-container'>";
        echo "<h2 class='exp-detail-title'>Your Experiences</h2>";
        echo "<table>";
        echo "<tr><th>ID</th><th>Descrição</th><th>Data de Registro</th><th>Número de Ratos</th><th>Limite de Ratos na Sala</th><th>Segundos sem Movimento</th><th>Temperatura Ideal</th><th>Variação Máxima de Temperatura</th></tr>";
        while ($row = $results->fetch_assoc()) {
            echo "<tr>";
            echo "<td>" . $row['id'] . "</td>";
            echo "<td>" . $row['descricao'] . "</td>";
            echo "<td>" . $row['DataRegisto'] . "</td>";
            echo "<td>" . $row['numeroratos'] . "</td>";
            echo "<td>" . $row['limiteratossala'] . "</td>";
            echo "<td>" . $row['segundossemmovimento'] . "</td>";
            echo "<td>" . $row['temperaturaideal'] . "</td>";
            echo "<td>" . $row['variacaotemperaturamaxima'] . "</td>";
            echo "<td><a href='experience_details.php?id=" . $row['id'] . "' class='pain_link'>Details</a></td>";
            echo "</tr>";
            echo "</div>";
        }
        echo "</table>";
    }

    //close connection here ???
    $conn->close();

    //show button to create experience
    echo "<a href='ui_create_exp.php'><button>Create Experience</button></a>
";
    ?>
</body>
</html>
