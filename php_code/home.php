<?php
include('constants.php');
include_once('db_conn_class.php');

session_start();
$dbConn = new DbConn(DB, HOST, $_SESSION['email'], $_SESSION['password']);
$conn = $dbConn->getConn();

//get experiences and show list of experiences
if ($stmt = $conn->prepare('SELECT * FROM experiencia WHERE investigador = ?')) {
    $stmt->bind_param('s', $_SESSION['email']);
    $stmt->execute();
    $results = $stmt->get_result();
} else {
    //TODO
    //handle this better
    die('something went wrong...');
}

if ($results->num_rows == 0) {
    echo "Nenhuma experiencia associada ao utilizador";
}

//each experience should redirect to the experience detail page
while ($row = $results->fetch_assoc()) {
    print_r($row);
    echo "<br>";
}


//show button to create experience
echo "<a href='create_exp.php'><button>Criar Experiência</button></a>";
?>