<!DOCTYPE html>
<html>

<head>
    <meta charset="UTF-8">
    <title>Experience Detail</title>
    <link rel="stylesheet" type="text/css" href="style.css">
</head>

<body>
    <?php
    include('utils/init.php');
    include('navbar.php');
    echo "<br><br>";
    $email = $_SESSION['email'];
    $password = $_SESSION['password'];
    $dbConn = new DbConn(DB, HOST, $email, $password);
    $conn = $dbConn->getConn();

    // get the id of the experience
    $id = $_GET['id'];

    // get the detail of the experience of the id from the link in the previous page and the currentuser
    if ($_SESSION['role'] == INVESTIGATOR) {
        if ($stmt = $conn->prepare('SELECT * 
                                    FROM experiencia
                                    INNER JOIN parametrosadicionais ON experiencia.id = parametrosadicionais.IDExperiencia
                                    INNER JOIN medicoessala ON experiencia.id = medicoessala.IDExperiencia
                                    WHERE experiencia.id = ? AND experiencia.investigador = ?')) {
            $stmt->bind_param('is', $id, $email);
            $stmt->execute();
            $result = $stmt->get_result();
            print_r($result);
        } else {
            die('something went wrong ' . $stmt->error);
        } 
    }
    else if ($_SESSION['role'] == ADMIN_APP) {
        if ($stmt = $conn->prepare('SELECT * FROM experiencia WHERE id = ?')) {
            $stmt->bind_param('i', $id);
            $stmt->execute();
            $result = $stmt->get_result();
        } else {
            die('something went wrong');
        }
    }
    if ($result->num_rows == 0) {
        // n sei se isto é mt provavel de acontecer já que é um link baseado numa experiência vindo da lista de
        // experiências mas por via das dúvidas vou validar ja q foi feito para os outros statements
        echo "not found";
    } else {
        $row = $result->fetch_assoc();
        print_r($row);

        
        echo "<div class='table-container'>";
        // experiencia
        echo "<h2 class='exp-detail-title'>Detail 1</h2>";
        echo "<table>";
        echo "<tr><th>ID</th><th>Email do Investigador</th><th>Descrição</th><th>Data de Registro</th><th>Número de Ratos</th><th>Limite de Ratos na Sala</th><th>Segundos sem Movimento</th><th>Temperatura Ideal</th><th>Variação Máxima de Temperatura</th><th>";
        echo "<tr>";
        echo "<td>" . $row['id'] . "</td>";
        echo "<td>" . $row['investigador'] . "</td>";
        echo "<td>" . $row['descricao'] . "</td>";
        echo "<td>" . $row['DataRegisto'] . "</td>";
        echo "<td>" . $row['numeroratos'] . "</td>";
        echo "<td>" . $row['limiteratossala'] . "</td>";
        echo "<td>" . $row['segundossemmovimento'] . "</td>";
        echo "<td>" . $row['temperaturaideal'] . "</td>";
        echo "<td>" . $row['variacaotemperaturamaxima'] . "</td>"; 
        echo "</tr>";
        echo "</table>";
        
        // parametrosadicionais
        echo "<h2 class='exp-detail-title'>Detail 2</h2>";
        echo "<table>";
        echo "<tr><th>Data de início da experiência</th><th>Data de fim da experiência</th><th>Descrição</th><th>Motivo de termino</th><th>Data em que as portas externas foram abertas</th><th>Periodicidade de alerta</th><th>";
        echo "<tr>";
        echo "<td>" . $row['DataHoraInicio'] . "</td>";
        echo "<td>" . $row['DataHoraFim'] . "</td>";
        echo "<td>" . $row['MotivoTermino'] . "</td>";
        echo "<td>" . $row['DataHoraPortasExtAbertas'] . "</td>";
        echo "<td>" . $row['PeriodicidadeAlerta'] . "</td>";
        echo "</tr>";
        echo "</table>";

        // fim da div
        echo "</div>";
    }
    $conn->close();
    ?>
</body>

</html>
