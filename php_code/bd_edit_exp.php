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

    $id = $_GET['id'];

    if ($stmt = $conn->prepare("UPDATE experiencia SET descricao = ?, numeroratos = ?, limiteratossala = ?, segundossemmovimento = ?, temperaturaideal = ?, variacaotemperaturamaxima = ? WHERE id = ?")) {
        $stmt->bind_param('siiiddi', $descricao, $numeroratos, $limiteratossala, $segundossemmovimento, $temperaturaideal, $variacaotemperaturamaxima, $id);
        if ($stmt->execute()) {
            header('Location: experience_list.php?=' . $id);
        } else {
            echo "Error";
        }
    }
    
    // escrever na substanciasexperiencia
    if (isset($_POST['odor'])) {
        $odors = $_POST['odor'];
    } else {
        $odors = array();
    }
    if (isset($_POST['room'])) {
        $rooms = $_POST['room'];
    } else {
        $rooms = array();
    }

    // escrever na substanciaexperiencia
    $php_rats = $_POST['php_rats'];
    $peste_rats = $_POST['peste_rats'];
    $covid_rats = $_POST['covid_rats'];
    $lepra_rats = $_POST['lepra_rats'];
    $raiva_rats = $_POST['raiva_rats'];

    if ($subs_stmt = $conn->prepare("UPDATE substanciasexperiencia SET numeroratos = ?, codigosubstancia = ?, IDExperiencia = ?")) {
        $php = 'PHP';
        $subs_stmt->bind_param('isi', $php_rats, $php, $id);
        $subs_stmt->execute();
        print_r('PLS WORK!!');

        $peste = 'Peste';
        $subs_stmt->bind_param('isi', $peste_rats, $peste, $id);
        $subs_stmt->execute();
        print_r('PLS WORK!!');
        
        $covid = 'Covid';
        $subs_stmt->bind_param('isi', $covid_rats, $covid, $id);
        $subs_stmt->execute();
        print_r('PLS WORK!!');
        
        $lepra = 'Lepra';
        $subs_stmt->bind_param('isi', $lepra_rats, $lepra, $id);
        $subs_stmt->execute();
        print_r('PLS WORK!!');
        
        $raiva = 'Raiva';
        $subs_stmt->bind_param('isi', $raiva_rats, $raiva, $id);
        $subs_stmt->execute();
        print_r('PLS WORK!!');

    }

    mysqli_close($conn);
?>