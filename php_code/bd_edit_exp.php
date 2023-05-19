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

    $id = $_POST['id'];
    //$id = $_GET['id'];
    print_r($id);

    if ($stmt = $conn->prepare("UPDATE experiencia SET descricao = ?, numeroratos = ?, limiteratossala = ?, segundossemmovimento = ?, temperaturaideal = ?, variacaotemperaturamaxima = ? WHERE id = ?")) {
        $stmt->bind_param('siiiddi', $descricao, $numeroratos, $limiteratossala, $segundossemmovimento, $temperaturaideal, $variacaotemperaturamaxima, $id);
        if ($stmt->execute()) {
            //header('Location: experience_list.php');
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
    print_r($php_rats);
    print_r($peste_rats);
    print_r($covid_rats);
    print_r($lepra_rats);
    print_r($raiva_rats);
 
    if ($subs_stmt = $conn->prepare("UPDATE substanciasexperiencia SET numeroratos = ? WHERE IDExperiencia = ? AND codigosubstancia = ?")) {
        $php = 'PHP';
        $subs_stmt->bind_param('iis', $php_rats, $id, $php);
        $subs_stmt->execute();
        print_r('PLS WORK!!');
    }

        if($subs_stmt_peste = $conn->prepare("UPDATE substanciasexperiencia SET numeroratos = ? WHERE IDExperiencia = ? AND codigosubstancia = ?")) {
            $peste = 'Peste';
            $subs_stmt_peste->bind_param('iis', $peste_rats, $id, $peste);
            $subs_stmt_peste->execute();
            print_r('PLS WORK!!');

        }

        if ($subs_stmt_covid = $conn->prepare("UPDATE substanciasexperiencia SET numeroratos = ? WHERE IDExperiencia = ? AND codigosubstancia = ?")) {
            $covid = 'Covid';
            $subs_stmt_covid->bind_param('iis', $covid_rats, $id, $covid);
            $subs_stmt_covid->execute();
            print_r('PLS WORK!!');

        }

        if($subs_stmt_lepra = $conn->prepare("UPDATE substanciasexperiencia SET numeroratos = ? WHERE IDExperiencia = ? AND codigosubstancia = ?")) {
            $lepra = 'Lepra';
            $subs_stmt_lepra->bind_param('iis', $lepra_rats, $id, $lepra);
            $subs_stmt_lepra->execute();
            print_r('PLS WORK!!');

        }

        if ($subs_stmt_raiva = $conn->prepare("UPDATE substanciasexperiencia SET numeroratos = ? WHERE IDExperiencia = ? AND codigosubstancia = ?")) {
            $raiva = 'Raiva';
            $subs_stmt_raiva->bind_param('iis', $raiva_rats, $id, $raiva);
            $subs_stmt_raiva->execute();
            print_r('PLS WORK!!');

        }
    header('Location: experience_list.php');
    mysqli_close($conn);
?>