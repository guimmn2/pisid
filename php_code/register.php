<?php
include('utils/init.php');

//TODO
//find a way to not even show this page to someone that's not admin_app

//only admin_app users can access this page
if ($_SESSION['role'] != ADMIN_APP) {
        echo "not allowed";
        die();
}

$dbConn = new DbConn(DB, HOST, $_SESSION['email'], $_SESSION['password']);
$conn = $dbConn->getConn();

$name = $_POST['name'];
$role = $_POST['role'];
$phone = $_POST['phone'];
$email = $_POST['email'];

$random_password = random_str(8);
//call DB SP according to role
if ($role == 'investigador') {
        if ($stmt = $conn->prepare("CALL CreateInvestigator(?, ?, ? ,?)")) {
                print_r("pass: $random_password ");
                $stmt->bind_param('ssss', $name, $phone, $email, $random_password);
                if ($stmt->execute()) {
                        echo "registered investigator successfully";
                        header('Location: experience_list.php');
                } else {
                        echo "not able to register investigator, try again later";
                }
        }
} else if ($role == 'tecnico') {
        if ($stmt = $conn->prepare("CALL CreateTechnician(?, ?, ? ,?)")) {
                $stmt->bind_param('ssss', $name, $phone, $email, $random_password);
                if ($stmt->execute()) {
                        echo "registered technician successfully";
                        //TODO
                        //send email to user with creds
                } else {
                        echo "not able to register technician, try again later";
                }
        }
}
header('Location: investigator_list.php');

?>