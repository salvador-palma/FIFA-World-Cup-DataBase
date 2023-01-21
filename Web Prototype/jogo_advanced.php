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
        <form class="input-fields-container" name="formEdicao" method="post" action="jogo_advanced.php">
            <div class="input-fields">
                <label class="input-label" for="sel_1">Seleção 1</label>
                <input class="input-field" name="sel_1" id="sel_1">
            </div>
            <div class="input-fields">
                <label class="input-label" for="sel_2">Seleção 2</label>
                <input class="input-field" name="sel_2" id="sel_2">
            </div>
            <div class="input-fields">
                <label class="input-label" for="num_jogador">Nome Jogador</label>
                <input class="input-field" name="num_jogador" id="num_jogador">
            </div>
            <div class="input-fields">
                <label class="input-label" for="num_golos">Qnt. Golos</label>
                <input class="input-field" type="number" name="num_golos" id="num_golos">
            </div>
            <p>&nbsp;</p>

            
            <p>
                <input class="submit-button" style="width:125px;" type="submit" name="Submit" id="Submit" value="Search">
            </p>
        </form>
        <div>
                <?php

                function get_table()
                {
                    $con = mysqli_connect('localhost', 'root', '', 'fifa');

                    // get the post records
                    $sel_1 = $_POST['sel_1'];
                    $sel_2 = $_POST['sel_2'];
                    $num_jogador = $_POST['num_jogador'];
                    $num_golos = $_POST['num_golos'];

                    $sql = "";
                    // database insert SQL code


                    if (!empty($num_jogador)) {
                        if (!empty($sel_1) and !empty($sel_2)) {
                            if (!empty($num_golos)) {//tudo
                                $sql = "SELECT j.Numero as Game_ID, j.Selecao1_Pais as Selecao_1, j.Selecao2_Pais as Selecao_2, 
                                (SELECT COUNT(*) FROM penalizacao p WHERE p.Penalizacao_Jogo_numero = j.Numero) as Num_Penalizacoes,
                                (SELECT COUNT(*) FROM golo g WHERE g.Jogo_Numero = j.Numero) as Num_Golos
                                FROM jogadorjogo jj, pessoa p, jogo j 
                                WHERE p.Nome = '$num_jogador'
                                AND p.Pessoa_ID = jj.JogadorSelecao_ID
                                AND jj.Jogo_numero = j.Numero
                                AND ((j.Selecao1_Pais = '$sel_1' AND j.Selecao2_Pais = '$sel_2')
                                OR  (j.Selecao2_Pais = '$sel_1' AND j.Selecao1_Pais = '$sel_2'))
                                GROUP BY Game_ID
                                HAVING Num_Golos = $num_golos;";
                            }else{//nome selecoes
                                $sql = "SELECT j.Numero as Game_ID, j.Selecao1_Pais as Selecao_1, j.Selecao2_Pais as Selecao_2, 
                                (SELECT COUNT(*) FROM penalizacao p WHERE p.Penalizacao_Jogo_numero = j.Numero) as Num_Penalizacoes,
                                (SELECT COUNT(*) FROM golo g WHERE g.Jogo_Numero = j.Numero) as Num_Golos
                                FROM jogadorjogo jj, pessoa p, jogo j 
                                WHERE p.Nome = '$num_jogador'
                                AND p.Pessoa_ID = jj.JogadorSelecao_ID
                                AND jj.Jogo_numero = j.Numero
                                AND ((j.Selecao1_Pais = '$sel_1' AND j.Selecao2_Pais = '$sel_2')
                                OR  (j.Selecao2_Pais = '$sel_1' AND j.Selecao1_Pais = '$sel_2'));";
                            }

                        }else{

                            if (!empty($num_golos)) { //nome golos
                                $sql = "SELECT j.Numero as Game_ID, j.Selecao1_Pais as Selecao_1, j.Selecao2_Pais as Selecao_2, 
                                (SELECT COUNT(*) FROM penalizacao p WHERE p.Penalizacao_Jogo_numero = j.Numero) as Num_Penalizacoes,
                                (SELECT COUNT(*) FROM golo g WHERE g.Jogo_Numero = j.Numero) as Num_Golos
                                FROM jogadorjogo jj, pessoa p, jogo j 
                                WHERE p.Nome = '$num_jogador'
                                AND p.Pessoa_ID = jj.JogadorSelecao_ID
                                AND jj.Jogo_numero = j.Numero
                                GROUP BY Game_ID
                                HAVING Num_Golos = $num_golos;";
                            }else{ //nome
                                $sql = "SELECT j.Numero as Game_ID, j.Selecao1_Pais as Selecao_1, j.Selecao2_Pais as Selecao_2, 
                                (SELECT COUNT(*) FROM penalizacao p WHERE p.Penalizacao_Jogo_numero = j.Numero) as Num_Penalizacoes,
                                (SELECT COUNT(*) FROM golo g WHERE g.Jogo_Numero = j.Numero) as Num_Golos
                                FROM jogadorjogo jj, pessoa p, jogo j 
                                WHERE p.Nome = '$num_jogador'
                                AND p.Pessoa_ID = jj.JogadorSelecao_ID
                                AND jj.Jogo_numero = j.Numero;";
                            }


                        }
                    }
                    else if (!empty($sel_1) and !empty($sel_2)) {
                        if (!empty($num_golos)) { //selecoes golos 
                            $sql = " SELECT j.Numero as Game_ID, j.Selecao1_Pais as Selecao_1, j.Selecao2_Pais as Selecao_2, 
                            (SELECT COUNT(*) FROM penalizacao p WHERE p.Penalizacao_Jogo_numero = j.Numero) as Num_Penalizacoes,
                            (SELECT COUNT(*) FROM golo g WHERE g.Jogo_Numero = j.Numero) as Num_Golos
                            FROM jogo j
                            WHERE (j.Selecao1_Pais = '$sel_1' AND j.Selecao2_Pais = '$sel_2')
                            OR  (j.Selecao2_Pais = '$sel_1' AND j.Selecao1_Pais = '$sel_2')
                            GROUP BY Game_ID
                            HAVING Num_Golos = $num_golos;";
                        }else{ //selecoes
                            $sql = " SELECT j.Numero as Game_ID, j.Selecao1_Pais as Selecao_1, j.Selecao2_Pais as Selecao_2, 
                            (SELECT COUNT(*) FROM penalizacao p WHERE p.Penalizacao_Jogo_numero = j.Numero) as Num_Penalizacoes,
                            (SELECT COUNT(*) FROM golo g WHERE g.Jogo_Numero = j.Numero) as Num_Golos
                            FROM jogo j
                            WHERE (j.Selecao1_Pais = '$sel_1' AND j.Selecao2_Pais = '$sel_2')
                            OR  (j.Selecao2_Pais = '$sel_1' AND j.Selecao1_Pais = '$sel_2')";
                        }
                    }
                    else if (!empty($num_golos)) { //golos
                        $sql = "SELECT j.Numero as Game_ID, j.Selecao1_Pais as Selecao_1, j.Selecao2_Pais as Selecao_2, 
                        (SELECT COUNT(*) FROM penalizacao p WHERE p.Penalizacao_Jogo_numero = j.Numero) as Num_Penalizacoes,
                        (SELECT COUNT(*) FROM golo g WHERE g.Jogo_Numero = j.Numero) as Num_Golos         
                        FROM jogo j
                        GROUP BY Game_ID
                        HAVING Num_Golos = $num_golos;";
                    }

                    // insert in database 
                    if ($sql != "") {
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
                    } else {
                        echo "<img width=20 height=20 src='https://cdn-icons-png.flaticon.com/512/190/190406.png' >";
                        echo "<p style='color:red; font-family: sans-serif'>Nenhum jogo encontrado</p>";
                    }
                }
                if (isset($_POST['Submit'])) {
                    get_table();
                } else{
                    echo " ";
                }
                ?>
            </div>
    </div>
    <div>
        <p style="padding-top:2px;">
            <a style="font-family:sans-serif;font-size:22px;color:white;" href="/jogo.php">Pesquisa Básica</a>
        </p>
    </div>

</body>

</html>