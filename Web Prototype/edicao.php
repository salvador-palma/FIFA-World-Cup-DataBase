<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">

<head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
    <title>Mundial Database</title>
    <link rel="icon" href="https://cdn-icons-png.flaticon.com/512/616/616616.png" type="image/x-icon">
    <link rel="stylesheet" href="style.css">
</head>

<body>
    <div class="container">
        <h2 class="titulo">Adicionar Edição</h2>
        <img src="https://cdn-icons-png.flaticon.com/512/616/616616.png" class="globe">
        <form class="input-fields-container" name="formEdicao" method="post" action="edicao.php">
            <div class="input-fields">
                <label class="input-label" for="ano">Ano</label>
                <input class="input-field" type="number" name="ano" id="ano" required>
            </div>
            <div class="input-fields">
                <label class="input-label" for="designation">Designação</label>
                <input class="input-field" name="designation" id="designation">
            </div>
            <div class="input-fields">
                <label class="input-label" for="orcamento">Orçamento</label>
                <input class="input-field" type="number" name="orcamento" id="orcamento">
            </div>
            <div class="input-fields">
                <label class="input-label" for="paisOrg1">Pais Organizador 1</label>
                <input class="input-field" name="paisOrg1" id="paisOrg1">
            </div>
            <div class="input-fields">
                <label class="input-label" for="paisOrg2">Pais Organizador 2</label>
                <input class="input-field" name="paisOrg2" id="paisOrg2">
            </div>
            <p>&nbsp;</p>
            
            <div>
        <?php

        function posting()
        {
            $con = mysqli_connect('localhost', 'root', '', 'fifa');

            // get the post records
            $ano = $_POST['ano'];
            $designation = $_POST['designation'];
            $orcamento = $_POST['orcamento'];
            $paisOrg1 = $_POST['paisOrg1'];
            $paisOrg2 = $_POST['paisOrg2'];
            // database insert SQL code
            $sql = "INSERT INTO `edicao` (`Ano`, `Designacao`, `Orcamento`, `paisOrganizador1`, `paisOrganizador2`, `totalSelecoes`) VALUES ('$ano', '$designation', '$orcamento', '$paisOrg1', '$paisOrg2', '0')";

            // insert in database 

            $rs = false;
            try {
                $rs = mysqli_query($con, $sql);
            } catch (Exception $e) {
                echo "<img width=20 height=20 src='https://cdn-icons-png.flaticon.com/512/190/190406.png' >";
                $s = $e->getMessage();
                echo "<p style='color:red; font-family: sans-serif'>$s</p>";
            }
            if ($rs) {
                echo "<img src='https://cdn-icons-png.flaticon.com/512/190/190411.png' width=20 height=20 > <p style='color:green; font-family: sans-serif'>Dados Inseridos Corretamente</p>";
                
            }
        }
        if (isset($_POST['Submit'])) {
            posting();
        }else{
            echo"";
        }
        ?>
    </div>
            <p>
                <button class="submit-button" style="width:125px;" onclick="location.href='/menu.php'">Voltar</button>
                <input class="submit-button" style="width:125px;" type="reset" name="Reset" id="Reset" value="Reset">
                <input class="submit-button" style="width:125px;" type="submit" name="Submit" id="Submit" value="Submit">
            </p>
        </form>

    </div>
    
</body>

</html>