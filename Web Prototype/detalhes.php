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
        <h2 class="titulo">Detalhes do Jogo</h2>
        
            <div>
                <?php
                function get_table()
                {
                    $con = mysqli_connect('localhost', 'root', '', 'fifa');

                    // get the post records
                    $codigo = $_POST['codigo'];

                    // database insert SQL code
                    $sql = "SELECT j.Numero AS Game_ID, j.Selecao1_Pais AS Selecao_1, j.Selecao2_Pais AS Selecao_2, j.Winner_Pais AS Winner
                    FROM jogo j
                    WHERE j.Numero = $codigo;";

                    // insert in database 

                    $rs = false;

                    $rs = mysqli_query($con, $sql) or die("Erro na query");

                    if (mysqli_num_rows($rs) == 0) {
                        echo "<img width=20 height=20 src='https://cdn-icons-png.flaticon.com/512/190/190406.png' >";
                        echo "<p style='color:red; font-family: sans-serif'>Nenhum jogo encontrado</p>";
                    } else {
                        while ($row = mysqli_fetch_assoc($rs)) {
                            echo "<center><h2 class='titulo' style='font-size:24px'>{$row['Selecao_1']} vs {$row['Selecao_2']}</h2></center>";

                            echo "<center><h6 style='font-weight:bold; font-size:18px; font-family:sans-serif'>Resultado: {$row['Winner']}</h6></center>";

                            $sql = "SELECT g.Momento AS Minuto, (SELECT p.Nome FROM jogadorselecao js, pessoa p
                                                                WHERE g.Marcador_JogadorEmCampo_ID= js.Jogador_ID
                                                                AND js.Pessoa_ID = p.Pessoa_ID) AS Marcador, (SELECT p.Nome FROM jogadorselecao js, pessoa p
                                                                                                            WHERE g.Assistencia_JogadorID= js.Jogador_ID
                                                                                                            AND js.Pessoa_ID = p.Pessoa_ID) AS Assist
                                    FROM golo g
                                    WHERE g.Jogo_Numero = $codigo
                                    ORDER BY Minuto";
                            $res = mysqli_query($con, $sql) or die("Erro na query");
                            if (mysqli_num_rows($res) == 0) {
                                echo "<img width=20 height=20 src='https://cdn-icons-png.flaticon.com/512/190/190406.png' >";
                                echo "<p style='color:red; font-family: sans-serif'>Não houve golos neste jogo</p>";
                            } else {
                                echo "<table border='1' style='border-collapse:collapse; border-color:white; border-width:0px;width:100%; '>";
                                echo "<tr style='border:none white;color:white;border-width:0px; border-color:rgb(53, 157, 183); background-color:rgb(53, 157, 183); font-family:sans-serif; '><td>Minuto</td><td>Marcador</td><td>Assistência</td><tr>";
                                while ($row = mysqli_fetch_assoc($res)) {
                                    echo "<tr style='border:none white;border-width:0px; border-color:#bfe8fa; background-color:#bfe8fa';><td>{$row['Minuto']}</td><td>{$row['Marcador']}</td><td>{$row['Assist']}</td><tr>";
                                }
                                echo "</table>";
                            }
                        }
                    }
                }
                function apagar(){
                    $con = mysqli_connect('localhost', 'root', '', 'fifa');
                    $codigo = $_POST['codigo'];
                    $sql = "DELETE FROM jogo
                    WHERE Numero = $codigo;";
                    $rs = mysqli_query($con, $sql) or die("Erro na query");
                    if ($rs) {
                        echo "<img src='https://cdn-icons-png.flaticon.com/512/190/190411.png' width=20 height=20 > <p style='color:green; font-family: sans-serif'>Jogo $codigo apagado corretamente</p>";
                    }
                }
                function alterar(){
                    $con = mysqli_connect('localhost', 'root', '', 'fifa');
                    $codigo = $_POST['codigo'];
                    $data = $_POST['data'];
                    $estadio = $_POST['estadio'];
                    $fase = $_POST['fase'];
                    $sql = "UPDATE `jogo` SET `Data` = '$data', `Estadio_Nome` = '$estadio',`Fase` = '$fase' WHERE `jogo`.`Numero` = $codigo;";
                    $rs = mysqli_query($con, $sql) or die("Erro na query");
                    if ($rs) {
                        echo "<img src='https://cdn-icons-png.flaticon.com/512/190/190411.png' width=20 height=20 > <p style='color:green; font-family: sans-serif'>Jogo $codigo alterado corretamente</p>";
                    }
                }
                
                if (isset($_POST['Detalhes'])) {
                    get_table();
                } elseif (isset($_POST['Alterar'])) {
                    $cod = $_POST['codigo'];
                    echo "
                    <form action='detalhes.php' method=post>
                        <input type=hidden name=codigo value=$cod>
                        <input type=text name=fase >
                        <input type=date name=data >
                        <input type=text name=estadio >
                        <input type=submit name=AlteracaoFeita value=Alterar>
                    </form>";
                } 
                else if (isset($_POST['Apagar'])) {
                    apagar();
                    
                } 
                else if (isset($_POST['AlteracaoFeita'])) {
                    alterar();
                    
                }else {
                    echo "";
                }
                ?>
            </div>
            
        <p>
            <form action='detalhes.php' method=post>
                <?php
                if (isset($_POST['Detalhes'])) {
                    $cod = $_POST['codigo'];
                    
                    echo "<input type=hidden name=codigo value='$cod'>";
                    
                    echo "
                    <input class='submit-button' style='width:125px;' type=submit name=Apagar value=Apagar>
                    <input class='submit-button' style='width:125px;' type=submit name=Alterar value=Alterar>
                    ";
                }
                ?>
            </form>
        </p>
        
        <button class="submit-button" style="width:125px;" onclick="window.location.href='/jogo.php';">Voltar</button>
    </div>


</body>

</html>