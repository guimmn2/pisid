<?php
    include('utils/init.php');
    $dbConn = new DbConn(DB, HOST, $_SESSION['email'], $_SESSION['password']);
    $conn = $dbConn->getConn();


    $numeroratos = $_POST['numeroratos'];
    $limiteratossala = $_POST['limiteratossala'];
    $segundossemmovimento = $_POST['segundossemmovimento'];
    $temperaturaideal = $_POST['temperaturaideal'];
    $variacaotemperaturamaxima = $_POST['variacaotemperaturamaxima'];
    $descricao = $_POST['descricao'];
    $email = $_SESSION['email'];

    if ($stmt = $conn->prepare("INSERT INTO experiencia (descricao, numeroratos, limiteratossala, segundossemmovimento, temperaturaideal, variacaotemperaturamaxima, investigador) VALUES (?, ?, ?, ?, ?, ?, ?)")) {
        $stmt->bind_param('siiidds', $descricao, $numeroratos, $limiteratossala, $segundossemmovimento, $temperaturaideal, $variacaotemperaturamaxima, $email);
        if ($stmt->execute()) {
            print("Experience created");
            header('Location: experience_list.php');
            die();
        } else {
            print("Error when trying to create experience: ");
        }
    }

    mysqli_close($conn);
    ?>