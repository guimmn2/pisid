<?php
include('utils/init.php');
print_r($_POST);
$investigator_email = $_POST['investigator'];
$exp_id = $_POST['exp_id'];
$dbConn = new DbConn(DB, HOST, $_SESSION['email'], $_SESSION['password']);
$conn = $dbConn->getConn();

if ($stmt = $conn->prepare("UPDATE experiencia SET investigador = ? WHERE id = ?")) {
    $stmt->bind_param('si', $investigator_email, $exp_id);
    if ($stmt->execute()) {
        echo "assigned sucessfully, redirecting to experience detail page";
        header('Location: experience_details.php?id='.$exp_id);
    } else {
        echo "something went wrong";
    }
}

?>