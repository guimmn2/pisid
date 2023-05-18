<?php
//init session and db connection
include('utils/init.php');

//start the session
session_start();

//clear all session variables talvez isso tenha uma bulting funct para fazer isso
$_SESSION = array();

//kill the session cookies
if (ini_get("session.use_cookies")) {
    $params = session_get_cookie_params();
    setcookie(session_name(), '', time() - 42000,
        $params["path"], $params["domain"],
        $params["secure"], $params["httponly"]
    );
}

//kill the session
session_destroy();


//redirect to the login.html
header("Location: login.html");
die();
?>
