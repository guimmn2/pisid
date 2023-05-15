<?php
include('utils/init.php');
$dbConn = new DbConn(DB, HOST, $_SESSION['email'], $_SESSION['password']);
$conn = $dbConn->getConn();

$email = $_GET['email'];

if ($stmt = $conn->prepare('DELETE FROM utilizador WHERE email = ?')) {
    $stmt->bind_param('s', $email);
    $stmt->execute();
    $stmt->close();
} else {
    die('something went wrong...');
}

header('Location: investigator_list.php');

?>