<?php

include_once('db_conn_class.php');
include ('constants.php');

#session_start();

$servername = "localhost";
$username = "root";
$password = "";
$database = "pisid";
$conn = mysqli_connect($servername, $username, $password, $database);


$name = $_POST['name'];
$phone = $_POST['phone'];
$email = $_POST['email'];
$type = $_POST['type'];

$sql_query = "CREATE USER '$name'@'localhost' IDENTIFIED BY 'test';
                        GRANT SELECT, INSERT, UPDATE ON `pisid`.* TO '$name'@'localhost';
                        GRANT ALL PRIVILEGES ON `utilizador`.* TO '$name'@'localhost';
                        GRANT SELECT, INSERT, UPDATE ON `pisid`.`experiencia` TO '$name'@'localhost';
                        GRANT SELECT, INSERT, UPDATE ON `pisid`.`substanciasexperiencia` TO '$name'@'localhost';
                        GRANT SELECT, INSERT, UPDATE ON `pisid`.`odoresexperiencia` TO '$name'@'localhost';";

mysqli_multi_query($conn, "SET sql_mode=''");
mysqli_multi_query($conn, $sql_query);

if (mysqli_multi_query($conn, $sql_query)) {
        print ("User created");
} else {
        print ("Error when trying to create a user: " . mysqli_error($conn));
}

mysqli_close($conn);
?>