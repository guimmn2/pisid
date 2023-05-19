<!DOCTYPE html>
<html>

    <head>
        <title>Criar Experiência</title>
        <link rel="stylesheet" type="text/css" href="style.css">
    </head>
    
<body>
    <?php 
    
    include('utils/init.php');
    include ('navbar.php'); 
    
    $dbConn = new DbConn(DB, HOST, $_SESSION['email'], $_SESSION['password']);
    $conn = $dbConn->getConn();
    
    $id = $_GET['id'];
                             
    // query experiencia
    if ($stmt = $conn->prepare('SELECT * 
                                FROM experiencia
                                WHERE experiencia.id = ?')) {
        $stmt->bind_param('i', $id);
        $stmt->execute();
        $result = $stmt->get_result();
    } else {
        die('something went wrong ' . $stmt->error);
    } 
    
    if ($result->num_rows > 0) {
        $row = $result->fetch_assoc();
        $edit_numeroratos = $row['numeroratos'];
        $edit_limiteratossala = $row['limiteratossala'];
        $edit_segundossemmovimento = $row['segundossemmovimento'];
        $edit_temperaturaideal = $row['temperaturaideal'];
        $edit_variacaotemperaturamaxima = $row['variacaotemperaturamaxima'];
        $edit_descricao = $row['descricao'];
    } else {
        die('No rows found');
    }

    $numeroRatosArray = array();
    // query substanciasexperiencia
    if ($stmt3 = $conn->prepare('SELECT experiencia.id, substanciasexperiencia.numeroratos, substanciasexperiencia.codigosubstancia
                                FROM experiencia, substanciasexperiencia
                                WHERE experiencia.id = ? AND substanciasexperiencia.IDExperiencia = ?')) {
        $stmt3->bind_param('ii', $id, $id);
        $stmt3->execute();
        $result4 = $stmt3->get_result();
    } else {
        die('something went wrong ' . $stmt3->error);
    } 

    if ($result4->num_rows > 0) {
        while ($row3 = $result4->fetch_assoc()) {
            $numeroRatosArray[] = $row3['numeroratos'];
        }
    }

    $odores_array = array();
    $num_ratos_array = array();

    if ($stmt2 = $conn->prepare('SELECT medicoessala.numeroratosfinal, medicoessala.sala, odoresexperiencia.codigoodor
                                FROM experiencia
                                INNER JOIN medicoessala ON experiencia.id = medicoessala.IDExperiencia
                                LEFT JOIN (
                                SELECT sala, MIN(codigoodor) AS codigoodor
                                FROM odoresexperiencia
                                WHERE IDExperiencia = ?
                                GROUP BY sala
                                LIMIT 10
                                ) odoresexperiencia ON medicoessala.sala = odoresexperiencia.sala
                                WHERE experiencia.id = ?
                                LIMIT 10
                                ')) {

        $stmt2->bind_param('ii', $id, $id);
        $stmt2->execute();
        $result3 = $stmt2->get_result();

    } else {
        die();
    }

    //echo isset($numeroRatosArray[0]) ? $numeroRatosArray[0] : '';
    //echo isset($numeroRatosArray[1]) ? $numeroRatosArray[1] : '';
    //echo isset($numeroRatosArray[2]) ? $numeroRatosArray[2] : '';
    //echo isset($numeroRatosArray[3]) ? $numeroRatosArray[3] : '';
    //echo isset($numeroRatosArray[4]) ? $numeroRatosArray[4] : '';
    ?>
    <h1>Editar experiência</h1>
    <form method="post" action="bd_edit_exp.php" id="validate-form">
        <label for="numeroratos">Número de ratos</label>
        <input type="number" id="numeroratos" name="numeroratos" value="<?php echo $edit_numeroratos; ?>" required>
        <br>
        <label for="limiteratossala">Limite de ratos por sala</label>
        <input type="number" id="limiteratossala" name="limiteratossala" value="<?php echo $edit_limiteratossala; ?>" required>
        <br>
        <label for="segundossemmovimento">Segundos sem movimento</label>
        <input type="number" id="segundossemmovimento" name="segundossemmovimento" value="<?php echo $edit_segundossemmovimento; ?>" required>
        <br>
        <label for="temperaturaideal">Temperatura Ideal</label>
        <input type="text" id="temperaturaideal" name="temperaturaideal" value="<?php echo $edit_temperaturaideal; ?>" pattern="^\d{1,2}(\.\d{1,2})?$|^\d{1}(\.\d{1})?$|^\d{2}(\.\d{1,2})?$" required>
        <br>
        <label for="variacaotemperaturamaxima">Variação temperatura máxima</label>
        <input type="text" id="variacaotemperaturamaxima" name="variacaotemperaturamaxima" value="<?php echo $edit_variacaotemperaturamaxima; ?>" pattern="^\d{1,2}(\.\d{1,2})?$|^\d{1}(\.\d{1})?$|^\d{2}(\.\d{1,2})?$" required>
        <br>
        <label for="descricao">Descrição</label>
        <textarea id="descricao" name="descricao"><?php echo $edit_descricao; ?></textarea>
        <h1>Substâncias</h1>
        <div class="subs_div">
            <label for="php">PHP<br><input type="number" id="php_rats" name="php_rats" placeholder="Número de ratos" value="<?php echo isset($numeroRatosArray[3]) ? $numeroRatosArray[3] : ''; ?>"></label>
            <label for="peste">Peste<br><input type="number" id="peste_rats" name="peste_rats" placeholder="Número de ratos" value="<?php echo isset($numeroRatosArray[2]) ? $numeroRatosArray[2] : ''; ?>"></label>
            <label for="covid">Covid<br><input type="number" id="covid_rats" name="covid_rats" placeholder="Número de ratos" value="<?php echo isset($numeroRatosArray[0]) ? $numeroRatosArray[0] : ''; ?>"></label>
            <label for="lepra">Lepra<br><input type="number" id="lepra_rats" name="lepra_rats" placeholder="Número de ratos" value="<?php echo isset($numeroRatosArray[1]) ? $numeroRatosArray[1] : ''; ?>"></label>
            <label for="raiva">Raiva<br><input type="number" id="raiva_rats" name="raiva_rats" placeholder="Número de ratos" value="<?php echo isset($numeroRatosArray[4]) ? $numeroRatosArray[4] : ''; ?>"></label>           
        </div>
        <input type="number" id="id" name="id" value=<?php echo $id ?> hidden>
        <br><br><br>
        <input type="submit" name="submit" value="Confirmar">
    </form>
</body>

    <!-- validações do form, caso pensem em mais adicionem aqui -->
    <script>

        const form = document.getElementById('validate-form');
        form.addEventListener('submit', function(event) {
            const numeroratos = document.getElementById('numeroratos').value;
            const limiteratossala = document.getElementById('limiteratossala').value;
            const temperaturaideal = document.getElementById('temperaturaideal').value;
            const variacaotemperaturamaxima = document.getElementById('variacaotemperaturamaxima').value;
            const php_rats = document.getElementById('php_rats').value;
            const peste_rats = document.getElementById('peste_rats').value;
            const covid_rats = document.getElementById('covid_rats').value;
            const lepra_rats = document.getElementById('lepra_rats').value;
            const raiva_rats = document.getElementById('raiva_rats').value;


        });

    </script>
</html>