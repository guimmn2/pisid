<!DOCTYPE html>
<html>

<head>
    <title>Criar Experiência</title>
    <link rel="stylesheet" type="text/css" href="style.css">
</head>

<body>
    <?php include ('navbar.php'); ?>
    <h1>Criar Experiência</h1>
    <form method="post" action="bd_create_exp.php" id="validate-form">
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
        <input type="text" id="temperaturaideal" name="temperaturaideal" pattern="^\d{1,2}(\.\d{1,2})?$|^\d{1}(\.\d{1})?$|^\d{2}(\.\d{1,2})?$" required>
        <br>
        <label for="variacaotemperaturamaxima">Variação temperatura máxima</label>
        <input type="text" id="variacaotemperaturamaxima" name="variacaotemperaturamaxima" pattern="^\d{1,2}(\.\d{1,2})?$|^\d{1}(\.\d{1})?$|^\d{2}(\.\d{1,2})?$" required>
        <br>
        <label for="descricao">Descrição</label>
        <textarea id="descricao" name="descricao"></textarea>
        <label for="descricao">Substâncias</label>
        <div id="substances">
            <select name="substance">
                <option value ="" selected disabled>--Escolha uma substância--</option>
                <option value ="colera">Cólera</option>
                <option value ="peste">Peste</option>
                <option value ="covid">Covid</option>
                <option value ="lepra">Lepra</option>
                <option value ="raiva">Raiva</option>
            </select>
            <input type="number" name="ratsCount" id="ratsCount" placeholder="Número de ratos">
        </div>
        <button type="button" id="substance-btn">Adicionar mais substâncias</button>
        <br><br>
        <label for="descricao">Odores</label>
        <div id="odors">
            <select name="odor">
                <option value ="" selected disabled>--Escolha um odor--</option>
                <option value ="flores">Flores</option>
                <option value ="cheiro_a_php">O mal cheiro do PHP</option>
                <option value ="soja">Soja</option>
                <option value ="hortela">Hortelã</option>
                <option value ="ovo">Ovo</option>
            </select>
            <select name="room">
                <option value ="" selected disabled>--Escolha uma sala--</option>
                <option value ="room1">1</option>
                <option value ="room2">2</option>
                <option value ="room3">3</option>
                <option value ="room4">4</option>
                <option value ="room5">5</option>
                <option value ="room6">6</option>
                <option value ="room7">7</option>
                <option value ="room8">8</option>
                <option value ="room8">9</option>
                <option value ="room10">10</option>
            </select>
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

    <!-- validações do form, caso pensem em mais adicionem aqui -->
    <script>

        const form = document.getElementById('validate-form');
        form.addEventListener('submit', function(event) {
            const numeroratos = document.getElementById('numeroratos').value;
            const limiteratossala = document.getElementById('limiteratossala').value;
            const temperaturaideal = document.getElementById('temperaturaideal').value;
            const variacaotemperaturamaxima = document.getElementById('variacaotemperaturamaxima').value;
            const temp_format = /^(\d+|\d+.\d+)$/;
            if (limiteratossala > numeroratos) {
                alert('O limite de ratos por sala não pode ser maior que o número de ratos.');
                event.preventDefault(); 
            }

            if (!temp_format.test(temperaturaideal) || !temp_format.test(variacaotemperaturamaxima)) {
                alert('Formato errado para Temperatura Ideal ou Variação máxima de temperatura.');
                event.preventDefault(); 
            }

        });

    </script>

</html>