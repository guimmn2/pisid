<!DOCTYPE html>
<html>

<head>
    <title>Criar Experiência</title>
    <link rel="stylesheet" type="text/css" href="style.css">
</head>

<body>
    <?php include ('navbar.php'); ?>
    <h1>Criar Experiência</h1>
    <form method="post" action="bd_create_exp.php">
        <label for="numeroratos">Número de ratos</label>
        <input type="number" id="numeroratos" name="numeroratos" required>
        <br>
        <label for="limiteratossala">Limite de ratos por sala</label>
        <input type="number" id="limiteratossala" name="limiteratossala" required>
        <br>
        <label for="segundossemmovimento">Segundos sem movimento</label>
        <input type="number" id="segundossemmovimento" name="segundossemmovimento" required>
        <br>
        <label for="temperaturaideal">Temperatura Ideal</label>
        <input type="number" id="temperaturaideal" name="temperaturaideal" required>
        <br>
        <label for="variacaotemperaturamaxima">Variação temperatura máxima</label>
        <input type="number" id="variacaotemperaturamaxima" name="variacaotemperaturamaxima" required>
        <br>
        <label for="descricao">Descrição</label>
        <textarea id="descricao" name="descricao"></textarea>
        <label for="descricao">Substâncias</label>
        <div id="substances">
            <input type="text" name="substance" id="substance" placeholder="Substância">
            <input type="number" name="ratsCount" id="ratsCount" placeholder="Número de ratos">
        </div>
        <button type="button" id="substance-btn">Adicionar mais substâncias</button>
        <br><br>
        <label for="descricao">Odores</label>
        <div id="odors">
            <input type="text" name="odor" id="odor" placeholder="Odor">
            <input type="number" name="room" id="room" placeholder="Sala">
        </div>
        <button type="button" id="odor-btn">Adicionar mais odores</button>
        <br><br><br>
        <input type="submit" name="submit" value="Criar Experiência">
    </form>
</body>
    <script>

        const substanceBtn = document.getElementById('substance-btn');
        const odorBtn = document.getElementById('odor-btn');
        const substanceToDuplicate = document.getElementById('substances');
        const odorToDuplicate = document.getElementById('odors');

        substanceBtn.addEventListener('click', function () {
            duplicateElement(substanceToDuplicate.id);
        });

        odorBtn.addEventListener('click', function () {
            duplicateElement(odorToDuplicate.id);
        });

        function duplicateElement(id) {
            const elementToDuplicate = document.getElementById(id);
            if (elementToDuplicate) {
                const newElement = elementToDuplicate.cloneNode(true);
                elementToDuplicate.parentNode.insertBefore(newElement, elementToDuplicate.nextSibling);
            }
        }

    </script>

</html>