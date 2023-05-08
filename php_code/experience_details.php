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
                                    WHERE experiencia.id = ? AND parametrosadicionais.IDExperiencia = ? AND experiencia.investigador = ?')) {
        $stmt1->bind_param('iis', $id, $id, $email);
        $stmt1->execute();
        $result2 = $stmt1->get_result();
        } else {
            die('something went wrong ' . $stmt1->error);
        } 

        // query medicoessala
        if ($stmt2 = $conn->prepare('SELECT experiencia.*, medicoessala.numeroratosfinal, medicoessala.sala, odoresexperiencia.codigoodor
                                    FROM experiencia
                                    INNER JOIN medicoessala ON experiencia.id = medicoessala.IDExperiencia
                                    LEFT JOIN (
                                    SELECT sala, MIN(codigoodor) AS codigoodor
                                    FROM odoresexperiencia
                                    WHERE IDExperiencia = ?
                                    GROUP BY sala
                                    LIMIT 10
                                    ) odoresexperiencia ON medicoessala.sala = odoresexperiencia.sala
                                    WHERE experiencia.id = ? AND experiencia.investigador = ?
                                    LIMIT 10
                                    ')) {
        $stmt2->bind_param('iis', $id, $id, $email);
        $stmt2->execute();
        $result3 = $stmt2->get_result();
        } else {
            die('something went wrong ' . $conn->error);
        } 

        // query substanciasexperiencia
        if ($stmt3 = $conn->prepare('SELECT experiencia.id, substanciasexperiencia.numeroratos, substanciasexperiencia.codigosubstancia
                                    FROM experiencia, substanciasexperiencia
                                    WHERE experiencia.id = ? AND substanciasexperiencia.IDExperiencia = ? AND experiencia.investigador = ?')) {
        $stmt3->bind_param('iis', $id, $id, $email);
        $stmt3->execute();
        $result4 = $stmt3->get_result();
        } else {
            die('something went wrong ' . $stmt3->error);
        } 
    } else if ($_SESSION['role'] == ADMIN_APP) {
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
        if ($result4->num_rows == 0) {
            // n sei se isto é mt provavel de acontecer já que é um link baseado numa experiência vindo da lista de
            // experiências mas por via das dúvidas vou validar ja q foi feito para os outros statements
            echo "not found";
        }
    } else {
        
        echo "<div class='table-container'>";
        
        // experiencia
        $row = $result->fetch_assoc();
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
        $row1 = $result2->fetch_assoc();
        echo "<h2 class='exp-detail-title'>Parametros Adicionais</h2>";
        echo "<table>";
        echo "<tr><th>Data de início da experiência</th><th>Data de fim da experiência</th><th>Motivo de termino</th><th>Data em que as portas externas foram abertas</th><th>Periodicidade de alerta";
        echo "<tr>";
        if (is_null($row1['DataHoraInicio'])) {
            echo "<td>Experiência ainda não começou</td>";
            echo "<td>Experiência ainda não começou</td>";
            echo "<td>Experiência ainda não começou</td>";
            echo "<td>N/A</td>";
        } else {
            echo "<td>" . $row1['DataHoraInicio'] . "</td>";
            if (is_null($row1['DataHoraFim'])) {
                echo "<td>Experiência ainda não acabou</td>";
                echo "<td>Experiência ainda não acabou</td>";
                echo "<td>N/A</td>";
            } else {
                echo "<td>" . $row1['DataHoraFim'] . "</td>";
                if (is_null($row1['MotivoTermino']) || $row1['MotivoTermino'] == "") { // acho q a exp nunca pode acabar sem preencher o campo motivo mas se por algum motivo houver erros a preencer a pagina mostra "Sem Motivo"
                    echo "<td>Sem motivo</td>";
                } else {
                    echo "<td>" . $row1['MotivoTermino'] . "</td>";
                }
                if (is_null($row1['DataHoraPortasExtAbertas'])) {
                    echo "<td>N/A</td>";
                } else {
                    echo "<td>" . $row1['DataHoraPortasExtAbertas'] . "</td>";
                }
            }
        }
        
        echo "<td>" . $row1['PeriodicidadeAlerta'] . "</td>";
        echo "</tr>";
        echo "</table>";

        // medicoessala e odoresexperiencia
        echo "<h2 class='exp-detail-title'>Medições sala e odores experiência</h2>";
        echo "<table>";
        echo "<tr><th>Sala</th><th>Código Odor</th><th>Número de ratos final</th></tr>";
        if ($result3->num_rows > 0) {
            //$row2 = $result->fetch_assoc();
            while ($row2 = $result3->fetch_assoc()) {
                echo "<tr>";
                echo "<td>" . $row2['sala'] . "</td>";
                // mesmo q na criação da exp o utilizador não escolha odores pra outras salas temos que escrever na bd como a NULL
                if (!is_null($row2['codigoodor'])) {
                    echo "<td>" . $row2['codigoodor'] . "</td>";
                } else {
                    echo "<td>Não foi escolhido um odor para esta sala</td>";
                }
                if (is_null($row2['numeroratosfinal']) || $row2['numeroratosfinal'] == 0) {
                    echo "<td>0</td>";
                } else {
                    echo "<td>" . $row2['numeroratosfinal'] . "</td>";
                }
                echo "</tr>";
            }
        } 
        echo "</table>";

        // TODO
        // substanciasexperiencia
        echo "<h2 class='exp-detail-title'>Substâncias Experiência</h2>";
        echo "<table>";
        echo "<tr><th>Código da Substância</th><th>Número Ratos</th></tr>";
        if ($result4->num_rows > 0) {
            //$row2 = $result->fetch_assoc();
            while ($row3 = $result4->fetch_assoc()) {
                echo "<tr>";
                if (!is_null($row3['codigosubstancia'])) {
                    echo "<td>" . $row3['codigosubstancia'] . "</td>";
                } else {
                    echo "<td>N/A</td>";
                }
                if (is_null($row3['numeroratos']) || $row3['numeroratos'] == 0) {
                    echo "<td>Substância não aplicada</td>";
                } else {
                    echo "<td>" . $row3['numeroratos'] . "</td>";
                }
                echo "</tr>";
            }
        } 
        echo "</table>";

        if (is_null($row1['DataHoraInicio']) || is_null($row1['DataHoraFim'])) {
            // TODO
            // adicionar aqui um pop up ou uma info a dizer o pq do ivnestigador n poder abrir as portas exteriores
            echo "<script>alert('Não é possível abrir as portas exteriores se a experiência ainda não começou ou está a decorrer!');</script>";
        } else {
            if (is_null($row1['DataHoraPortasExtAbertas'])) {
                // botão para abrir as portas exteriores
                echo "<a href='open_ext_doors.php?id=". $id ."'><button>Abrir portas exteriores</button></a>";
            } else {
                // TODO
                // adicionar aqui um pop up ou uma info a dizer o pq do investigador n poder abrir as portas exteriores
                echo "<button disabled>Abrir portas exteriores</button>";
                echo "<script>alert('Não é abrir as portas se esta já foi aberta!');</script>";
            }
        }

        // TODO
        // botão para editar experiência (a principio so edita os dados q ele meteu na criação da exp)
        // n sei se volta para a pagina da criação de exp com os dados para preencher outra vez ou algo mais sofisticado
        // acho que o mais facil seria ele simplesmente ir pra ui_create_exp.php ou uma parecida e simplesmente fazer uma query de update da exp em questão, mas tem q se validar na mesma
        // como se fosse a primeira vez a criar a exp
        if (is_null($row1['DataHoraInicio'])) {
            // pode editar
            echo "<button>Editar experiência</button>"; 
        } else {
            // TODO
            // exp ja começou então não pode editar (no caso do botao de editar, podemos ou meter disable ou simplesmente não mostrar)
            // adicionamos também um pop up ou uma msg ao user a dizer q n pode editar pq a exp ja acabou/começou
            echo "<button disabled>Editar experiência</button>";
            echo "<script>alert('A experiência já acabou ou está a decorrer!');</script>";
        }
        // fim da div
        echo "</div>";
    }
    $conn->close();
    
    ?>
</body>

</html>
