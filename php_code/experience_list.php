<!DOCTYPE html>
<html>

<head>
    <meta charset="UTF-8">
    <title>Lista de Experiências</title>
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
        if ($stmt = $conn->prepare('SELECT experiencia.*, parametrosadicionais.DataHoraInicio, parametrosadicionais.DataHoraFim 
                                    FROM experiencia 
                                    INNER JOIN parametrosadicionais ON experiencia.id = parametrosadicionais.IDExperiencia
                                    WHERE experiencia.investigador = ?')) {
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
        if ($stmt = $conn->prepare('SELECT * FROM experiencia, parametrosadicionais WHERE experiencia.id = parametrosadicionais.IDExperiencia')) {
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

    if ($_SESSION['role'] == TECHNICIAN) {
        if ($stmt = $conn->prepare('SELECT * FROM experiencia, parametrosadicionais WHERE experiencia.id = parametrosadicionais.IDExperiencia')) {
            $stmt->execute();
            $results = $stmt->get_result();
            $stmt->close();
        } else {
            //TODO
            //handle this better
            die('You do not have the permissions my man...');
        }
    }

    if ($results->num_rows == 0) {
        echo "Nenhuma experiencia a mostrar";
    } else {
        // display the list of experiences, por motivos de maldição tive q criar um container diferente para a lista de exp
        echo "<div class='table-container'>";
        echo "<h2 class='exp-detail-title'>Experiências</h2>";
        echo "<table>";
        echo "<tr><th>ID</th><th>Descrição</th><th>Investigador</th><th>Data de Registo</th><th>Número de Ratos</th><th>Limite de Ratos na Sala</th><th>Segundos sem Movimento</th><th>Temperatura Ideal</th><th>Variação Máxima de Temperatura</th><th>Estado da Experiência</th><th>Detalhe</th></tr>";
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
            if (is_null($row['DataHoraInicio']) && is_null($row['DataHoraFim'])) {
                echo "<td>Experiência na fila de espera</td>";
            } else if (!is_null($row['DataHoraInicio']) && is_null($row['DataHoraFim'])) {
                echo "<td>Experiência a decorrer</td>";
            } else {
                echo "<td>Experiência acabou</td>";
            }
            echo "<td><a href='experience_details.php?id=" . $row['id'] . "' class='pain_link'>Detalhes</a></td>";
            echo "</tr>";
            echo "</div>";
        }
        echo "</table>";
    }

    //close connection here ???
    $conn->close();

    if ($_SESSION['role'] == INVESTIGATOR) {
        //show button to create experience
        echo "<a href='ui_create_exp.php'><button>Criar Experiência</button></a>";
    } else {
        // go to register.html
        echo "<a href='register.html'><button>Registar Utilizador</button></a>";
    }
    ?>
</body>

</html>