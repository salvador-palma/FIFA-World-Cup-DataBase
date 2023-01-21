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
        <h2 class="titulo">Procurar Jogo</h2>
        <img src="https://i.imgur.com/CTZkndC.png" height="100" width="100">
        <form class="input-fields-container" name="formEdicao" method="post" action="jogo.php">
            <div class="input-fields">
                <label class="input-label" for="game_num">Numero do Jogo</label>
                <input class="input-field" type="number" name="game_num" id="game_num" required>
            </div>
            <p>&nbsp;</p>
            
           
            <p>
                <button class="submit-button" style="width:125px;" onclick="window.location.href='/menu.php';">Voltar</button>
                <input class="submit-button" style="width:125px;" type="submit" name="Submit" id="Submit" value="Search">
               
            </p>
        </form>
        <div>
        <?php

        function get_table()
        {
            $con = mysqli_connect('localhost', 'root', '', 'fifa');

            // get the post records
            $game_num = $_POST['game_num'];
            
            // database insert SQL code
            $sql = "SELECT j.Numero as Game_ID, j.Selecao1_Pais as Selecao_1, j.Selecao2_Pais as Selecao_2, (SELECT COUNT(*) FROM penalizacao p 
            WHERE p.Penalizacao_Jogo_numero = j.Numero) as Num_Penalizacoes ,
           (SELECT COUNT(*) FROM golo g 
            WHERE g.Jogo_Numero = j.Numero) as Num_Golos 
FROM jogo j
WHERE j.Numero = $game_num
GROUP BY Game_ID;";

            // insert in database 

            $rs = false;
            
            $rs = mysqli_query($con, $sql) or die("Erro na query");

            if( mysqli_num_rows($rs)==0){
                echo "<img width=20 height=20 src='https://cdn-icons-png.flaticon.com/512/190/190406.png' >";
                echo "<p style='color:red; font-family: sans-serif'>Nenhum jogo encontrado</p>";
            }else{
                echo"<table border='1' style='border-collapse:collapse; border-color:white; border-width:0px;width:100%; '>";
                echo"<tr style='border:none white;color:white;border-width:0px; border-color:rgb(53, 157, 183); background-color:rgb(53, 157, 183); font-family:sans-serif; '><td>ID</td><td>Seleção 1</td><td>Seleção 2</td><td>Penalizações</td><td>Golos</td><td>Detalhes</td><tr>";
                while($row = mysqli_fetch_assoc($rs)){
                    echo"<tr style='border:none white;border-width:0px; border-color:#bfe8fa; background-color:#bfe8fa';><td>{$row['Game_ID']}</td><td>{$row['Selecao_1']}</td><td>{$row['Selecao_2']}</td><td>{$row['Num_Penalizacoes']}</td><td>{$row['Num_Golos']}</td><form action='detalhes.php' method=post><td><input type=hidden name=codigo value='{$row['Game_ID']}'><input type=submit name=Detalhes value=Detalhes></td></form><tr>";     
                }
                echo"</table>";
            }
        }
        if (isset($_POST['Submit'])) {
            get_table();
        }else{
            echo"";
        }
        ?>
    </div>
    </div>
    <div>
        <p style="padding-top:2px;">
        <a style="font-family:sans-serif;font-size:22px;color:white;" href="/jogo_advanced.php" >Pesquisa Avançada</a>
        </p>
    </div>
    
</body>

</html>