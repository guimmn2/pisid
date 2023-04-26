<?php
include_once('db_conn_class.php');
include('constants.php');

session_start();

$email = $_POST['email'];
$password = $_POST['password'];

$dbConn = new DbConn(DB, HOST, $email, $password);
$conn = $dbConn->getConn();

//validate if role is assigned to person
if ($result = $conn->query("SELECT current_role()")) {
    $role = $result->fetch_assoc()['current_role()'];
}

if ($role == "investigador" || $role == "tecnico_manutencao" || $role == "admin_app" || $role == "admin") { // change role if necessary
    //redirect to home if so
    session_start();
    $_SESSION['role'] = $role;
    $_SESSION['email'] = $email;
    $_SESSION['password'] = $password;
    header('Location: home.php');
    die();

} else {
    echo "Failed to authenticate.";
    die();
}
//--

?>