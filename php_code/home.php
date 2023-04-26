<?php
include('login.php');
session_start();
print_r($_SESSION);

//get experiences and show list of experiences
if ($stmt = $mysqli->prepare('SELECT * FROM experiencia WHERE investigador = ?')) {
    $stmt->bind_param('s', $_SESSION['email']);
    $stmt->execute();
    $stmt->store_result();
    print_r($mysqli->use_result());
}

//each experience should redirect to the experience detail page

//show button to create experience
?>