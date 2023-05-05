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
    include('navbar.php');
    echo "<br><br>";
    $dbConn = new DbConn(DB, HOST, $_SESSION['email'], $_SESSION['password']);
    $conn = $dbConn->getConn();

    //get experiences and show list of experiences
    if ($_SESSION['role'] == INVESTIGATOR) {
        if ($stmt = $conn->prepare('SELECT * FROM experiencia WHERE investigador = ?')) {
            $stmt->bind_param('s', $_SESSION['email']);
            $stmt->execute();
            $results = $stmt->get_result();
            $stmt->close();
        } else {
            //TODO
            //handle this better
            die('something went wrong...');
        }
    }
    //se for admin_app obter todas as experiências
    else if ($_SESSION['role'] == ADMIN_APP) {
        if ($stmt = $conn->prepare('SELECT * FROM experiencia')) {
            $stmt->execute();
            $results = $stmt->get_result();
            $stmt->close();
        } else {
            //TODO
            //handle this better
            die('something went wrong...');
        }
        //fetch users and their ids (emails)
        if ($inv_stmt = $conn->prepare("SELECT * FROM utilizador WHERE tipo = ?")) {
            $inv_code = INVESTIGATOR;
            $inv_stmt->bind_param('s', $inv_code);
            $inv_stmt->execute();
            $investigators = $inv_stmt->get_result();
        }
    }

    if ($results->num_rows == 0) {
        echo "Nenhuma experiencia a mostrar";
    } else {
        // display the list of experiences, por motivos de maldição tive q criar um container diferente para a lista de exp
        echo "<div class='table-container'>";
        echo "<h2 class='exp-detail-title'>Your Experiences</h2>";
        echo "<table>";
        echo "<tr><th>ID</th><th>Descrição</th><th>Investigador</th><th>Data de Registro</th><th>Número de Ratos</th><th>Limite de Ratos na Sala</th><th>Segundos sem Movimento</th><th>Temperatura Ideal</th><th>Variação Máxima de Temperatura</th><th>Detalhe</th></tr>";
        while ($row = $results->fetch_assoc()) {
            echo "<tr>";
            echo "<td>" . $row['id'] . "</td>";
            echo "<td>" . $row['descricao'] . "</td>";
            if ($row['investigador'] == null && $_SESSION['role'] == ADMIN_APP) {
                echo "<form method=\"post\" action=\"assign.php\" >";
                echo "<td>";
                echo "<select name=\"investigator\">";
                echo "<option value=\"null\"></option>";
                while ($inv_row = $investigators->fetch_assoc()) {
                    $exp_id = $row['id'];
                    $name = $inv_row['nome'];
                    $email = $inv_row['email'];
                    echo "<option value=\"$email\">$name</option>";
                }
                echo "</select>";
                echo "<button type=\"submit\">Assignar</button>";
                echo "<input hidden name=\"exp_id\" value=\"$exp_id\"></input>";
                echo "</td></form>";
            } else {
                echo "<td>" . $row['investigador'] . "</td>";
            }
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