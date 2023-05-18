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
            //print("Experience created");
            $exp_created_id = $stmt->insert_id;
            //die();
        } else {
            print("Error when trying to create experience: ");
        }
    }
    
    // escrever na odoresexperiencia
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
    //print_r($odors);
    //print_r($rooms);
    foreach($odors as $odor) {
        $room_key = array_search($odor, $odors);
        if (isset($rooms[$room_key])) {
            $room = $rooms[$room_key];
            if ($odor_stmt = $conn->prepare("INSERT INTO odoresexperiencia (sala, IDExperiencia, codigoodor) VALUES (?, ?, ?)")) {
                $odor_stmt->bind_param('iii', $room, $exp_created_id, $odor);
                //print_r("PLS WORK!!");
                $odor_stmt->execute();
            }
        } else {
            echo "Não foi possível achar a sala para o odor " . $odor . "<br>";
        }
    }


    // escrever na substanciaexperiencia
    $php_rats = $_POST['php_rats'];
    $peste_rats = $_POST['peste_rats'];
    $covid_rats = $_POST['covid_rats'];
    $lepra_rats = $_POST['lepra_rats'];
    $raiva_rats = $_POST['raiva_rats'];

    if ($subs_stmt = $conn->prepare("INSERT INTO substanciasexperiencia (numeroratos, codigosubstancia, IDExperiencia) VALUES (?, ?, ?)")) {
        $php = 'PHP';
        $subs_stmt->bind_param('isi', $php_rats, $php, $exp_created_id);
        $subs_stmt->execute();
        print_r('PLS WORK!!');

        $peste = 'Peste';
        $subs_stmt->bind_param('isi', $peste_rats, $peste, $exp_created_id);
        $subs_stmt->execute();
        print_r('PLS WORK!!');
        
        $covid = 'Covid';
        $subs_stmt->bind_param('isi', $covid_rats, $covid, $exp_created_id);
        $subs_stmt->execute();
        print_r('PLS WORK!!');
        
        $lepra = 'Lepra';
        $subs_stmt->bind_param('isi', $lepra_rats, $lepra, $exp_created_id);
        $subs_stmt->execute();
        print_r('PLS WORK!!');
        
        $raiva = 'Raiva';
        $subs_stmt->bind_param('isi', $raiva_rats, $raiva, $exp_created_id);
        $subs_stmt->execute();
        print_r('PLS WORK!!');

    }
    header('Location: experience_list.php');
    mysqli_close($conn);
    ?>