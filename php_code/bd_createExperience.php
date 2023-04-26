<?php
$servername = "localhost";
$username = "root";
$password = "";
$database = "pisid";

$conn = mysqli_connect($servername, $username, $password, $database);

if (!$conn) {
    die("Connection failed: " . mysqli_connect_error()); 
}

$numeroratos = $_POST['numeroratos'];
$limiteratossala = $_POST['limiteratossala'];
$segundossemmovimento = $_POST['segundossemmovimento'];
$temperaturaideal = $_POST['temperaturaideal'];
$variacaotemperaturamaxima = $_POST['variacaotemperaturamaxima'];
$descricao = $_POST['descricao'];

$sql_query = "INSERT INTO experiencia (descricao, numeroratos, limiteratossala, segundossemmovimento, temperaturaideal, variacaotemperaturamaxima) VALUES ('$descricao', '$numeroratos', '$limiteratossala', '$segundossemmovimento', '$temperaturaideal', '$variacaotemperaturamaxima')";

if (mysqli_query($conn, $sql_query)) {
    print("Experience created");
} else {
    print("Error when trying to create experience: " . mysqli_error($conn));
}

mysqli_close($conn);

?>