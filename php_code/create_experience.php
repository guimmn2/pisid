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

//TODO
//Fazer validações !!! e mudar código para usar instancia $conn e prepared statements
$sql_query = "INSERT INTO experiencia (descricao, numeroratos, limiteratossala, segundossemmovimento, temperaturaideal, variacaotemperaturamaxima, investigador) VALUES ('$descricao', '$numeroratos', '$limiteratossala', '$segundossemmovimento', '$temperaturaideal', '$variacaotemperaturamaxima', '$email')";

if (mysqli_query($conn, $sql_query)) {
    print("Experience created");
    header('Location: experience_list.php');
    die();
} else {
    print("Error when trying to create experience: " . mysqli_error($conn));
}

mysqli_close($conn);

?>