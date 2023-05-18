<?php
	$url="127.0.0.1";
	$database="pisid"; // Alterar nome da BD se necessario
    	$conn = mysqli_connect($url,$_POST['username'],$_POST['password'],$database);
	$sql = "SELECT sala, numeroratosfinal FROM medicoessala ORDER BY sala ASC";
	$result = mysqli_query($conn, $sql);
	$response["readings"] = array();
	if ($result){
		if (mysqli_num_rows($result)>0){
			while($r=mysqli_fetch_assoc($result)){
				$ad = array();
				// Alterar nome dos campos se necessario
				$ad["sala"] = $r['sala'];
				$ad["numeroratosfinal"] = $r['numeroratosfinal'];
				array_push($response["readings"], $ad);
			}
		}	
	}
	mysqli_close ($conn);
	
	header('Content-Type: application/json');
	// tell browser that its a json data
	echo json_encode($response);
	//converting array to JSON string
?>