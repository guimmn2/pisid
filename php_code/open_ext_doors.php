<?php

    include('utils/init.php');
    $dbConn = new DbConn(DB, HOST, $_SESSION['email'], $_SESSION['password']);
    $conn = $dbConn->getConn();

    $id = $_GET['id'];
    $current_timestamp = date('Y-m-d H:i:s');

    // abrir porta 
    if ($stmt = $conn->prepare('UPDATE
                                parametrosadicionais 
                                SET DataHoraPortasExtAbertas = ? 
                                WHERE IDExperiencia = ?')) {
        $stmt->bind_param('si', $current_timestamp, $id);
        $stmt->execute();
        $stmt->close();
    } else {
        die('somethind went wrong...' . $conn->error);
    }

    header('Location: experience_details.php?id=' . $id);

    mysqli_close($conn);

?>