<!DOCTYPE html>
<html>
<head>
    <title>Create Experience</title>
    <link rel="stylesheet" type="text/css" href="style.css">
</head>
<body>
    <?php include ('navbar.php'); ?>
    <h1>Create Experience</h1>
    <form method="post" action="bd_create_exp.php">
        <label for="numeroratos">Number of rats</label>
        <input type="number" id="numeroratos" name="numeroratos" required>
        <br>
        <label for="limiteratossala">Limit of rats per room</label>
        <input type="number" id="limiteratossala" name="limiteratossala" required>
        <br>
        <label for="segundossemmovimento">Seconds without movement</label>
        <input type="number" id="segundossemmovimento" name="segundossemmovimento" required>
        <br>
        <label for="temperaturaideal">Ideal temperature</label>
        <input type="number" id="temperaturaideal" name="temperaturaideal" required>
        <br>
        <label for="variacaotemperaturamaxima">Maximum temperature variaton</label>
        <input type="number" id="variacaotemperaturamaxima" name="variacaotemperaturamaxima" required>
        <br>
        <label for="descricao">Description</label>
        <textarea id="descricao" name="descricao"></textarea>
        <br>
        <input type="submit" name="submit" value="Submit">
    </form>
</body>
</html>