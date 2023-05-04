<?php
//init session and db connection
include('utils/init.php');

$email = $_POST['email'];
$password = $_POST['password'];

$dbConn = new DbConn(DB, HOST, $email, $password);
$conn = $dbConn->getConn();

//validate if role is assigned to person
if ($stmt = $conn->prepare("SELECT * FROM utilizador WHERE email = ?")) {
    $stmt->bind_param('s', $email);
    $stmt->execute();
    $role = $stmt->get_result()->fetch_assoc()['tipo'];
}
$_SESSION['role'] = $role;
$_SESSION['email'] = $email;
$_SESSION['password'] = $password;

if ($role == INVESTIGATOR || $role == TECHNICIAN) {
    header('Location: home.php');
    die();

} else if ($role == ADMIN_APP || $role == ADMIN) {
    header('Location: register.html');
    die();
} else {
    echo "Failed to authenticate.";
    die();
}
//--

?>