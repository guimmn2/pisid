<?php
$db = "pisid"; //database name
$dbhost = "localhost"; //database host
$email = $_POST["email"];
$password = $_POST["password"];

try {
    $mysqli = new mysqli($dbhost, $email, $password, $db);

    //check connection
    if ($mysqli->connect_errno) {
        echo "Failed to connect to MySQL: " . $mysqli->connect_error;
        exit();
    }

    //check associated role
    if($result = $mysqli->query("SELECT current_role()")) {
        $role = $result->fetch_assoc()['current_role()'];
    }

    //verify if user has assigned role
    if ($role == "investigador" || $role == "tecnico_manutencao" || $role == "admin_app" || $role == "admin") { // change role if necessary
        //redirect to home if so
        session_start();
        $_SESSION['role'] = $role;
        $_SESSION['email'] = $email;
        print_r($_SESSION);
        header('Location: home.php');
        die();

    } else {
        echo "Failed to authenticate.";
        exit();
    }

    //converting array to JSON string
} catch (Exception $e) {
    $return["message"] = "The login failed. Check if the user exists in the database.";

    header('Content-Type: application/json');
    // tell browser that its a json data
    echo json_encode($return);
    //converting array to JSON string
}
?>