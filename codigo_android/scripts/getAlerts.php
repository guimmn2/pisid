<?php
	$url="127.0.0.1";
	$database="pisid"; // Alterar nome da BD se necessario
     #$conn = mysqli_connect($url,"root","",$database);	
	       $conn = mysqli_connect($url,$_POST['username'],$_POST['password'],$database);
	 $sql = "SELECT mensagem, leitura, sala, sensor, tipo, hora, horaescrita 
	from alerta where hora >= now() - interval 60 minute ORDER BY Hora DESC";

	$result = mysqli_query($conn, $sql);
	$response["alerts"] = array();
	if ($result){
		if (mysqli_num_rows($result)>0){
			while($r=mysqli_fetch_assoc($result)){
				$ad = array();
				// Alterar nome dos campos da tabela se necessario
				$ad["mensagem"] = $r['mensagem'];				
				$ad["leitura"] = $r['leitura'];
				$ad["sala"] = $r['sala'];
				$ad["sensor"] = $r['sensor'];				
				$ad["tipo"] = $r['tipo'];
				$ad["hora"] = $r['hora'];
				$ad["horaescrita"] = $r['horaescrita'];
				array_push($response["alerts"], $ad);
			}
		}
	}
	mysqli_close ($conn);
	
	header('Content-Type: application/json');
	// tell browser that its a json data
	echo json_encode($response);
	//converting array to JSON string
?>