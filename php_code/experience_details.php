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
        // query experiencia
        if ($stmt = $conn->prepare('SELECT * 
                                    FROM experiencia
                                    WHERE experiencia.id = ? AND experiencia.investigador = ?')) {
            $stmt->bind_param('is', $id, $email);
            $stmt->execute();
            $result = $stmt->get_result();
        } else {
            die('something went wrong ' . $stmt->error);
        } 

        // query parametrosadicionais
        if ($stmt1 = $conn->prepare('SELECT * 
                                    FROM experiencia, parametrosadicionais
                                    WHERE experiencia.id = ? AND experiencia.investigador = ?')) {
        $stmt1->bind_param('is', $id, $email);
        $stmt1->execute();
        $result2 = $stmt1->get_result();
        } else {
            die('something went wrong ' . $stmt1->error);
        } 

        // query medicoessala
        if ($stmt2 = $conn->prepare('SELECT * 
                                    FROM experiencia, medicoessala
                                    WHERE experiencia.id = ? AND medicoessala.IDExperiencia = ? AND experiencia.investigador = ?')) {
        $stmt2->bind_param('iis', $id, $id, $email);
        $stmt2->execute();
        $result3 = $stmt2->get_result();
        } else {
            die('something went wrong ' . $conn->error);
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
        if ($result2->num_rows == 0) {
            // n sei se isto é mt provavel de acontecer já que é um link baseado numa experiência vindo da lista de
            // experiências mas por via das dúvidas vou validar ja q foi feito para os outros statements
            echo "not found";
        }
        if ($result3->num_rows == 0) {
            // n sei se isto é mt provavel de acontecer já que é um link baseado numa experiência vindo da lista de
            // experiências mas por via das dúvidas vou validar ja q foi feito para os outros statements
            echo "not found";
        }
    } else {
        $row = $result->fetch_assoc();
        $row1 = $result2->fetch_assoc();
        //$row2 = $result3->fetch_assoc();
        //print_r($row);
        //print_r($row1);
        //print_r($row2);

        
        echo "<div class='table-container'>";
        // experiencia
        echo "<h2 class='exp-detail-title'>Detalhes da Experiência</h2>";
        echo "<table>";
        echo "<tr><th>ID</th><th>Email do Investigador</th><th>Descrição</th><th>Data de Registro</th><th>Número de Ratos</th><th>Limite de Ratos na Sala</th><th>Segundos sem Movimento</th><th>Temperatura Ideal</th><th>Variação Máxima de Temperatura";
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
        echo "<h2 class='exp-detail-title'>Parametros Adicionais</h2>";
        echo "<table>";
        echo "<tr><th>Data de início da experiência</th><th>Data de fim da experiência</th><th>Motivo de termino</th><th>Data em que as portas externas foram abertas</th><th>Periodicidade de alerta";
        echo "<tr>";
        echo "<td>" . $row1['DataHoraInicio'] . "</td>";
        echo "<td>" . $row1['DataHoraFim'] . "</td>";
        echo "<td>" . $row1['MotivoTermino'] . "</td>";
        echo "<td>" . $row1['DataHoraPortasExtAbertas'] . "</td>";
        echo "<td>" . $row1['PeriodicidadeAlerta'] . "</td>";
        echo "</tr>";
        echo "</table>";

        // TODO 
        // medicoessala e odoresexperiencia
        echo "<h2 class='exp-detail-title'>Medições sala e odores experiência</h2>";
        echo "<table>";
        echo "<tr><th>Sala</th><th>Código Odor</th><th>Número de ratos final</th></tr>";
        if ($result3->num_rows > 0) {
            $row2 = $result->fetch_assoc();
            while ($row2 = $result3->fetch_assoc()) {
                echo "<tr>";
                echo "<td>" . $row2['sala'] . "</td>";
                echo "<td>PHP depression</td>";
                echo "<td>" . $row2['numeroratosfinal'] . "</td>";
                echo "</tr>";
            }
        } 
        echo "</table>";

        // TODO
        // substanciasexperiencia
        echo "<h2 class='exp-detail-title'>Substância experiência</h2>";
        echo "<table>";
        echo "<tr><th>Número de ratos</th><th>Código da substância</th><th>";
        echo "<tr>";
        echo "<td>21</td>";
        echo "<td>COVID</td>";
        echo "</tr>";
        echo "<tr>";
        echo "<td>12</td>";
        echo "<td>php disease</td>";
        echo "</tr>";
        echo "<tr>";
        echo "<td>12</td>";
        echo "<td>html depression</td>";
        echo "</tr>";
        echo "</table>";

        // TODO
        // botão para abrir as portas
        echo "<a href='experience_list.php'><button>Abrir portas exteriores</button></a>";
        // fim da div
        echo "</div>";
    }
    $conn->close();
    ?>
</body>

</html>
