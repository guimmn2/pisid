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
        if ($stmt = $conn->prepare('SELECT * FROM experiencia WHERE id = ? AND investigador = ?')) {
            $stmt->bind_param('is', $id, $email);
            $stmt->execute();
            $result = $stmt->get_result();
        } else {
            die('something went wrong');
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
        echo "<div class='container'>";
        echo "<h2 class='exp-detail-title'>Experience Detail</h2>";
        echo "<div class='exp-detail'>";
        echo "<p class='exp-detail-label'>ID:</p><p class='exp-detail-value'>" . $row['id'] . "</p>";
        echo "<p class='exp-detail-label'>Email do Investigador:</p><p class='exp-detail-value'><strong>" . $row['investigador'] . "</strong></p>";
        echo "<p class='exp-detail-label'>Descrição:</p><p class='exp-detail-value'>" . $row['descricao'] . "</p>";
        echo "<p class='exp-detail-label'>Data de Registro:</p><p class='exp-detail-value'>" . $row['DataRegisto'] . "</p>";
        echo "<p class='exp-detail-label'>Número de ratos:</p><p class='exp-detail-value'>" . $row['numeroratos'] . "</p>";
        echo "<p class='exp-detail-label'>Limite de ratos por sala:</p><p class='exp-detail-value'>" . $row['limiteratossala'] . "</p>";
        echo "<p class='exp-detail-label'>Segundos sem Moviment:</p><p class='exp-detail-value'>" . $row['segundossemmovimento'] . "</p>";
        echo "<p class='exp-detail-label'>Temperatura Ideal:</p><p class='exp-detail-value'>" . $row['temperaturaideal'] . "</p>";
        echo "<p class='exp-detail-label'>Variação Máxima de Temperatura:</p><p class='exp-detail-value'>" . $row['variacaotemperaturamaxima'] . "</p>";
        echo "</div>";
        echo "</div>";
    }
    $conn->close();
    ?>
</body>

</html>