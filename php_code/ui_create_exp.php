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
        <h1>Substâncias</h1>
        <div class="subs_div">
            <label for="php">PHP<br><input type="number" id="php_rats" name="php_rats" placeholder="Número de ratos"></label>
            <label for="peste">Peste<br><input type="number" id="peste_rats" name="peste_rats" placeholder="Número de ratos"></label>
            <label for="covid">Covid<br><input type="number" id="covid_rats" name="covid_rats" placeholder="Número de ratos"></label>
            <label for="lepra">Lepra<br><input type="number" id="lepra_rats" name="lepra_rats" placeholder="Número de ratos"></label>
            <label for="raiva">Raiva<br><input type="number" id="raiva_rats" name="raiva_rats" placeholder="Número de ratos"></label>           
        </div>
        <br><br>
        <h1>Odores</h1>
        <div id="odors">
            <select name="odor[]">
                <option value ="" selected disabled>--Escolha um odor--</option>
                <option value ="1005">1005</option>
                <option value ="2005">2005</option>
                <option value ="3005">3005</option>
                <option value ="4005">4005</option>
                <option value ="6005">6005</option>
            </select>
            <select name="room[]">
                <option value ="" selected disabled>--Escolha uma sala--</option>
                <option value ="1">1</option>
                <option value ="2">2</option>
                <option value ="3">3</option>
                <option value ="4">4</option>
                <option value ="5">5</option>
                <option value ="6">6</option>
                <option value ="7">7</option>
                <option value ="8">8</option>
                <option value ="9">9</option>
                <option value ="10">10</option>
            </select>
        </div>
        <button type="button" id="odor-btn">Adicionar mais odores</button>
        <br><br><br>
        <input type="submit" name="submit" value="Criar Experiência">
    </form>
</body>
    <script>
        const odorBtn = document.getElementById('odor-btn');
        const odorToDuplicate = document.getElementById('odors');

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
            const php_rats = document.getElementById('php_rats').value;
            const peste_rats = document.getElementById('peste_rats').value;
            const covid_rats = document.getElementById('covid_rats').value;
            const lepra_rats = document.getElementById('lepra_rats').value;
            const raiva_rats = document.getElementById('raiva_rats').value;


        });

    </script>
</html>