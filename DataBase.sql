-- phpMyAdmin SQL Dump
-- version 5.2.0
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Tempo de geração: 12-Dez-2022 às 15:37
-- Versão do servidor: 10.4.25-MariaDB
-- versão do PHP: 8.1.10

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Banco de dados: `fifa`
--

DELIMITER $$
--
-- Procedimentos
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `is_Edition_Valid` (IN `year` INT)   BEGIN

IF(SELECT COUNT(*) FROM comitiva c 
   WHERE c.Ano = year) < 24 THEN
   	SELECT 'Menos de 24 Comitivas' AS 'Edição Invalida:' ;


ELSEIF(SELECT COUNT(*) FROM (SELECT s.Pais, (SELECT COUNT(*) 
                                         FROM jogadorselecao js
                                         WHERE js.Selecao_Pais=s.Pais 
                                         AND js.Selecao_Ano = 	year) as players
	FROM selecao s 
	WHERE s.Ano = year
	GROUP BY s.Pais
	HAVING players < 26) AS res) <> 0 THEN
    
    SELECT 'Seleções sem o minimo de jogadores' AS 'Edição Invalida:' ;
    SELECT s.Pais as Selecoes_sem_26_jogadores, (SELECT COUNT(*) FROM jogadorselecao js WHERE js.Selecao_Pais=s.Pais AND js.Selecao_Ano = year) as Total_jogadores
	FROM selecao s 
	WHERE s.Ano = year
	GROUP BY s.Pais
	HAVING Total_jogadores < 26;

ELSEIF (SELECT COUNT(*) FROM grupo g
	WHERE g.Edicao_Ano = year) <> 8 THEN
    
    SELECT 'Menos ou Mais de 8 Grupos Definidos'  AS 'Edição Invalida:' ;


ELSEIF (SELECT COUNT(*) FROM selecao s 
    WHERE s.Ano = year
   GROUP BY s.Grupo_Letter
   HAVING COUNT(*) = 4) <> 8 THEN
   
	 SELECT 'Grupos mal definidos na tabela selecao'  AS 'Edição Invalida:' ;
ELSE
     SELECT 'Todos os critérios cumpridos'  AS 'Edição Valida:' ;

END IF;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `Relatorio_Golos_Edicao` (IN `year` INT)   BEGIN

SELECT js.Selecao_Pais AS Selecao, p.Nome AS Marcador FROM jogadorselecao js, golo g, pessoa p
WHERE js.Jogador_ID = g.Marcador_JogadorEmCampo_ID
AND js.Pessoa_ID = p.Pessoa_ID
AND js.Selecao_Ano = year
ORDER BY js.Jogador_ID;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `Relatorio_Melhores_Marcadores` (IN `year` INT)   BEGIN

SELECT p.Nome 
FROM golo g, jogadorselecao js, pessoa p
WHERE g.Marcador_JogadorEmCampo_ID = js.Jogador_ID
AND js.Pessoa_ID = p.Pessoa_ID
AND js.Selecao_Ano = year
GROUP BY g.Marcador_JogadorEmCampo_ID
HAVING COUNT(g.Marcador_JogadorEmCampo_ID) >= ALL(SELECT COUNT(g.Marcador_JogadorEmCampo_ID) AS Tot_Golos 
											FROM golo g, jogadorselecao js, pessoa p
                                            WHERE g.Marcador_JogadorEmCampo_ID = js.Jogador_ID
                                            AND js.Pessoa_ID = p.Pessoa_ID
                                            AND js.Selecao_Ano = year
                                            GROUP BY g.Marcador_JogadorEmCampo_ID);

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `Update_Edicao_TotalSelections` (IN `year` INT)   BEGIN

UPDATE edicao e
SET e.totalSelecoes = Get_Total_Selections(year)
WHERE e.Ano = year;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `Update_Player_Assists` (IN `player_ID` INT, IN `qnt` INT)   BEGIN 

UPDATE jogadorselecao j
SET j.num_of_assists = j.num_of_assists + qnt
WHERE j.Jogador_ID = player_ID;



END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `Update_Player_Goals` (IN `player_id` INT, IN `qnt` INT)   BEGIN 

UPDATE jogadorselecao j
SET j.num_of_goals = j.num_of_goals + qnt
WHERE j.Jogador_ID = player_ID;



END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `Update_Player_PerfectGame` (IN `game_ID` INT, IN `qnt` INT, IN `selection` VARCHAR(60))   BEGIN 




UPDATE jogadorselecao j
SET j.num_of_perfect_games = j.num_of_perfect_games + qnt
WHERE j.Jogador_ID = ANY(SELECT g.JogadorSelecao_ID 
                         FROM jogadorjogo g)
AND j.Selecao_Pais = selection;




END$$

--
-- Funções
--
CREATE DEFINER=`root`@`localhost` FUNCTION `Get_Game_Winner` (`game_num` INT(11)) RETURNS VARCHAR(100) CHARSET latin1 COLLATE latin1_bin  BEGIN

DECLARE tot_goals integer;
DECLARE i integer;
DECLARE marcador_ID integer;
DECLARE selecao1 varchar(60);
DECLARE selecao2 varchar(60);
DECLARE goals_selecao_1 integer;
DECLARE goals_selecao_2 integer;
DECLARE selecao_marcador varchar(60);
DECLARE autogolo integer;
DECLARE res varchar(200);
DECLARE is_perfect integer;


    IF(SELECT COUNT(*) FROM jogo j
       WHERE j.Numero = game_num) = 0 THEN

       SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 
       'O Jogo pretendido não existe';

    END IF;


    SET goals_selecao_1 = Get_Selection1_Goals(game_num);
	SET goals_selecao_2 = Get_Selection2_Goals(game_num);



    IF (goals_selecao_1 > goals_selecao_2) THEN
     RETURN (SELECT j.Selecao1_Pais FROM jogo j
     WHERE j.Numero = game_num);
    ELSEIF (goals_selecao_1 < goals_selecao_2) THEN
        RETURN (SELECT j.Selecao2_Pais FROM jogo j
     WHERE j.Numero = game_num);
    ELSE 
        RETURN "Empate";
    END IF;
    

/*RETURN CONCAT(selecao1 , ":" , goals_selecao_1 , " - " , selecao2 , ":" , goals_selecao_2);*/


END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `Get_Scoring_Team` (`game_num` INT, `goal_num` INT) RETURNS VARCHAR(60) CHARSET latin1 COLLATE latin1_bin  BEGIN
DECLARE selecao1 varchar(60);
DECLARE selecao2 varchar(60);
DECLARE marcador_selecao varchar(60);
DECLARE autogolo integer;
SET selecao1 = (SELECT j.Selecao1_Pais FROM jogo j
				WHERE j.Numero = game_num);
SET selecao2 = (SELECT j.Selecao2_Pais FROM jogo j
				WHERE j.Numero = game_num);

SET marcador_selecao = (SELECT js.Selecao_Pais FROM jogadorselecao js
						WHERE js.Jogador_ID = (SELECT g.Marcador_JogadorEmCampo_ID FROM golo g
                                               WHERE g.Jogo_Numero = game_num
                                               AND g.Golo_Numero = goal_num));
SET autogolo = (SELECT g.Autogolo FROM golo g 
                WHERE g.Jogo_Numero = game_num
                AND g.Golo_Numero = goal_num);
                

IF (marcador_selecao = selecao1 AND autogolo IS NULL) THEN
	RETURN selecao1;
ELSEIF (marcador_selecao = selecao1 AND autogolo IS NOT NULL) THEN
	RETURN selecao2;
ELSEIF (marcador_selecao = selecao2 AND autogolo IS NULL) THEN
	RETURN selecao2;
ELSEIF (marcador_selecao = selecao2 AND autogolo IS NOT NULL) THEN
	RETURN selecao1;
END IF;
RETURN "";
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `Get_Selection1_Goals` (`game_num` INT) RETURNS INT(11)  BEGIN

   
   RETURN (SELECT COUNT(*) FROM jogadorselecao js, golo g, jogo j
   WHERE g.Jogo_Numero = game_num AND
   ((g.Marcador_JogadorEmCampo_ID=js.Jogador_ID 
   AND g.Jogo_Numero = j.Numero
   AND js.Selecao_Pais = j.Selecao1_Pais AND g.Autogolo IS NULL) OR 
   (g.Marcador_JogadorEmCampo_ID=js.Jogador_ID 
   AND g.Jogo_Numero = j.Numero
   AND js.Selecao_Pais = j.Selecao2_Pais AND g.Autogolo IS NOT NULL)));



END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `Get_Selection2_Goals` (`game_num` INT) RETURNS INT(11)  BEGIN

   
   RETURN (SELECT COUNT(*) FROM jogadorselecao js, golo g, jogo j
   WHERE g.Jogo_Numero = game_num AND
   ((g.Marcador_JogadorEmCampo_ID=js.Jogador_ID 
   AND g.Jogo_Numero = j.Numero
   AND js.Selecao_Pais = j.Selecao2_Pais AND g.Autogolo IS NULL) OR 
   (g.Marcador_JogadorEmCampo_ID=js.Jogador_ID 
   AND g.Jogo_Numero = j.Numero
   AND js.Selecao_Pais = j.Selecao1_Pais AND g.Autogolo IS NOT NULL)));



END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `Get_Total_Selections` (`year` INT) RETURNS INT(11)  BEGIN
RETURN (SELECT COUNT(*) FROM selecao s 
WHERE s.Ano = year);
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `Is_PerfectGame` (`game_id` INT) RETURNS VARCHAR(60) CHARSET latin1 COLLATE latin1_bin  BEGIN

DECLARE res integer;
DECLARE a integer;
DECLARE b integer;

SET a = Get_Selection1_Goals(game_id);
SET b = Get_Selection2_Goals(game_id);

IF a>0 AND b>0 THEN
RETURN "None";
ELSEIF a>0 AND b=0 THEN
RETURN (SELECT j.Selecao1_Pais FROM jogo j
       WHERE j.Numero = game_id);
ELSEIF a=0 AND b>0 THEN
RETURN (SELECT j.Selecao2_Pais FROM jogo j
       WHERE j.Numero = game_id);
END IF;
RETURN "None";
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Estrutura stand-in para vista `biggest_sponsor_main_sponsor`
-- (Veja abaixo para a view atual)
--
CREATE TABLE `biggest_sponsor_main_sponsor` (
`Pais` varchar(60)
,`Ano` smallint(6)
,`Patrocinador_Oficial_sigla` char(4)
);

-- --------------------------------------------------------

--
-- Estrutura da tabela `clubefutebol`
--

CREATE TABLE `clubefutebol` (
  `NomeClube` varchar(60) COLLATE latin1_bin NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_bin;

--
-- Extraindo dados da tabela `clubefutebol`
--

INSERT INTO `clubefutebol` (`NomeClube`) VALUES
('Ajax'),
('Barcelona'),
('Bayern Munich'),
('Benfica'),
('Borussia Dortmund'),
('Chelsea'),
('Juventus'),
('Liverpool'),
('Manchester City'),
('Manchester United'),
('Milan'),
('PSG'),
('Porto'),
('Real Madrid');

-- --------------------------------------------------------

--
-- Estrutura da tabela `comitiva`
--

CREATE TABLE `comitiva` (
  `Pais` varchar(60) COLLATE latin1_bin NOT NULL,
  `Ano` smallint(6) NOT NULL,
  `Mascote` varchar(60) COLLATE latin1_bin DEFAULT NULL,
  `Patrocinador_Oficial_sigla` char(4) COLLATE latin1_bin NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_bin;

--
-- Extraindo dados da tabela `comitiva`
--

INSERT INTO `comitiva` (`Pais`, `Ano`, `Mascote`, `Patrocinador_Oficial_sigla`) VALUES
('Alemanha', 2022, 'Águia', 'FILA'),
('Argentina', 2022, 'Messi', 'FILA'),
('Arábia Saudita', 2022, NULL, 'VANS'),
('Austrália', 2022, 'Aranha', 'ADID'),
('Brasil', 2022, 'Tatu', 'YAMA'),
('Bélgica', 2022, NULL, 'SPTY'),
('Camarões', 2022, 'Gui Olhão', 'NIKE'),
('Canadá', 2022, 'Urso', 'SPTY'),
('Coreia do Sul', 2022, NULL, 'VANS'),
('Costa Rica', 2022, NULL, 'ADID'),
('Croácia', 2022, NULL, 'PUMA'),
('Dinamarca', 2022, NULL, 'BURG'),
('EUA', 2022, NULL, 'MCDO'),
('Equador', 2022, 'Joy', 'NIKE'),
('Espanha', 2022, 'Leão', 'TNFC'),
('França', 2018, 'Galo', 'PUMA'),
('França', 2022, 'Galo', 'PUMA'),
('Gana', 2022, 'Ganha', 'SHOP'),
('Inglaterra', 2022, 'Leão', 'VANS'),
('Irão', 2022, NULL, 'VANS'),
('Itália', 2022, 'Cão', 'ADID'),
('Japão', 2022, 'Steins Gate', 'SPTY'),
('Marrocos', 2022, 'Vaca', 'TNFC'),
('México', 2022, 'Taco', 'BURG'),
('País de Gales', 2022, NULL, 'TNFC'),
('Países Baixos', 2022, NULL, 'COKE'),
('Polónia', 2022, NULL, 'BURG'),
('Portugal', 2022, 'Caravela', 'NIKE'),
('Qatar', 2022, 'Keffiyeh', 'FILA'),
('Senegal', 2022, 'Estrela', 'TNFC'),
('Suíça', 2022, NULL, 'COKE'),
('Sérvia', 2022, 'Águia', 'TNFC'),
('Tunísia', 2022, 'Lua', 'BURG'),
('Uruguai', 2022, 'Sol', 'VANS');

--
-- Acionadores `comitiva`
--
DELIMITER $$
CREATE TRIGGER `TR_Insert_Comitiva` AFTER INSERT ON `comitiva` FOR EACH ROW BEGIN 

INSERT INTO patrocinio
VALUES (new.Pais, new.Ano, new.Patrocinador_Oficial_sigla, NULL);



END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `TR_Update_Comitiva` AFTER UPDATE ON `comitiva` FOR EACH ROW BEGIN

UPDATE patrocinio p 
SET p.Patrocinador_Sigla_ = new.Patrocinador_Oficial_sigla
WHERE p.Comitiva_Pais_ = new.Pais
AND p.Comitiva_Ano_ = new.Ano
AND p.Patrocinador_Sigla_ = old.Patrocinador_Oficial_sigla;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estrutura da tabela `edicao`
--

CREATE TABLE `edicao` (
  `Ano` smallint(6) NOT NULL,
  `Designacao` varchar(60) COLLATE latin1_bin DEFAULT NULL,
  `Orcamento` int(11) DEFAULT NULL,
  `paisOrganizador1` varchar(60) COLLATE latin1_bin DEFAULT NULL,
  `paisOrganizador2` varchar(60) COLLATE latin1_bin DEFAULT NULL,
  `totalSelecoes` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_bin;

--
-- Extraindo dados da tabela `edicao`
--

INSERT INTO `edicao` (`Ano`, `Designacao`, `Orcamento`, `paisOrganizador1`, `paisOrganizador2`, `totalSelecoes`) VALUES
(2018, 'FIFA Spain World Cup', 54000000, 'Espanha', NULL, 0),
(2022, 'FIFA Qatar World Cup', 2000000000, 'Qatar', NULL, 32);

--
-- Acionadores `edicao`
--
DELIMITER $$
CREATE TRIGGER `Validate_World_Cup_Organizers_Insert` BEFORE INSERT ON `edicao` FOR EACH ROW BEGIN
IF new.paisOrganizador1 = "" THEN SET new.paisOrganizador1=NULL; END IF;
IF new.paisOrganizador2 = "" THEN SET new.paisOrganizador2=NULL; END IF;
IF	new.paisOrganizador1 IS NULL  AND new.paisOrganizador2 IS NULL THEN
SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Obrigatorio preencher pelo menos um Pais Organizador';
END IF;	
IF new.paisOrganizador1 = new.paisOrganizador2 THEN
	SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Paises Organizadores Repetidos';

END IF;

IF ((SELECT COUNT(pais.Nome_Federacao) FROM pais
WHERE pais.Nome = new.paisOrganizador1)=0 AND new.paisOrganizador1 IS NOT NULL) THEN
SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Pais Organizador 1 sem Federacao definida';
END IF;

IF ((SELECT COUNT(pais.Nome_Federacao) FROM pais
WHERE pais.Nome = new.paisOrganizador2)=0  AND new.paisOrganizador2 IS NOT NULL) THEN
SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Pais Organizador 2 sem Federacao definida';
END IF;

END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `Validate_World_Cup_Organizers_Update` BEFORE UPDATE ON `edicao` FOR EACH ROW BEGIN
IF new.paisOrganizador1 = "" THEN SET new.paisOrganizador1=NULL; END IF;
IF new.paisOrganizador2 = "" THEN SET new.paisOrganizador2=NULL; END IF;
IF	new.paisOrganizador1 IS NULL  AND new.paisOrganizador2 IS NULL THEN
SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Obrigatorio preencher pelo menos um Pais Organizador';
END IF;	
IF new.paisOrganizador1 = new.paisOrganizador2 THEN
	SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Paises Organizadores Repetidos';

END IF;

IF ((SELECT COUNT(pais.Nome_Federacao) FROM pais
WHERE pais.Nome = new.paisOrganizador1)=0 AND new.paisOrganizador1 IS NOT NULL) THEN
SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Pais Organizador 1 sem Federacao definida';
END IF;

IF ((SELECT COUNT(pais.Nome_Federacao) FROM pais
WHERE pais.Nome = new.paisOrganizador2)=0  AND new.paisOrganizador2 IS NOT NULL) THEN
SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Pais Organizador 2 sem Federacao definida';
END IF;

END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estrutura stand-in para vista `editions_with_most_members`
-- (Veja abaixo para a view atual)
--
CREATE TABLE `editions_with_most_members` (
`Ano` smallint(6)
,`Tot_Members` bigint(21)
);

-- --------------------------------------------------------

--
-- Estrutura da tabela `elementocomitiva`
--

CREATE TABLE `elementocomitiva` (
  `NumeroSerie` smallint(6) NOT NULL,
  `Comitiva_Pais` varchar(60) COLLATE latin1_bin NOT NULL,
  `Comitiva_Ano` smallint(6) NOT NULL,
  `Pessoa_ID` int(11) NOT NULL,
  `Especificacao` enum('PresidenteFederacao','Tecnico','Outros','Jogador') COLLATE latin1_bin NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_bin;

--
-- Extraindo dados da tabela `elementocomitiva`
--

INSERT INTO `elementocomitiva` (`NumeroSerie`, `Comitiva_Pais`, `Comitiva_Ano`, `Pessoa_ID`, `Especificacao`) VALUES
(1, 'Portugal', 2022, 85, 'PresidenteFederacao'),
(2, 'Portugal', 2022, 84, 'Outros'),
(3, 'Portugal', 2022, 86, 'Outros'),
(4, 'Portugal', 2022, 88, 'Tecnico'),
(5, 'Portugal', 2022, 1, 'Jogador'),
(6, 'Portugal', 2022, 2, 'Jogador'),
(7, 'Portugal', 2022, 3, 'Jogador'),
(8, 'Portugal', 2022, 4, 'Jogador'),
(9, 'Espanha', 2022, 5, 'Jogador'),
(10, 'Espanha', 2022, 6, 'Jogador'),
(11, 'Espanha', 2022, 7, 'Jogador'),
(12, 'Espanha', 2022, 8, 'Jogador'),
(13, 'Alemanha', 2022, 9, 'Jogador'),
(14, 'Alemanha', 2022, 10, 'Jogador'),
(15, 'Alemanha', 2022, 11, 'Jogador'),
(16, 'Alemanha', 2022, 12, 'Jogador'),
(17, 'França', 2022, 13, 'Jogador'),
(18, 'França', 2022, 14, 'Jogador'),
(19, 'França', 2022, 15, 'Jogador'),
(20, 'França', 2022, 16, 'Jogador'),
(21, 'Inglaterra', 2022, 17, 'Jogador'),
(22, 'Inglaterra', 2022, 18, 'Jogador'),
(23, 'Inglaterra', 2022, 19, 'Jogador'),
(24, 'Inglaterra', 2022, 20, 'Jogador'),
(25, 'Itália', 2022, 21, 'Jogador'),
(26, 'Itália', 2022, 22, 'Jogador'),
(27, 'Itália', 2022, 23, 'Jogador'),
(28, 'Itália', 2022, 24, 'Jogador'),
(29, 'Qatar', 2022, 25, 'Jogador'),
(30, 'Qatar', 2022, 26, 'Jogador'),
(31, 'Qatar', 2022, 27, 'Jogador'),
(32, 'Qatar', 2022, 28, 'Jogador'),
(33, 'Portugal', 2022, 29, 'Tecnico'),
(34, 'Portugal', 2022, 30, 'Tecnico'),
(35, 'Portugal', 2022, 31, 'Jogador'),
(36, 'Portugal', 2022, 32, 'Jogador'),
(37, 'Portugal', 2022, 33, 'Jogador'),
(38, 'Portugal', 2022, 34, 'Jogador'),
(39, 'Portugal', 2022, 35, 'Jogador'),
(40, 'Portugal', 2022, 36, 'Jogador'),
(41, 'Portugal', 2022, 37, 'Jogador'),
(42, 'Portugal', 2022, 38, 'Jogador'),
(43, 'Portugal', 2022, 39, 'Jogador'),
(44, 'Portugal', 2022, 40, 'Jogador'),
(45, 'Portugal', 2022, 41, 'Jogador'),
(46, 'Portugal', 2022, 42, 'Jogador'),
(47, 'Portugal', 2022, 43, 'Jogador'),
(48, 'Portugal', 2022, 44, 'Jogador'),
(49, 'Portugal', 2022, 45, 'Jogador'),
(50, 'Portugal', 2022, 46, 'Jogador'),
(51, 'Portugal', 2022, 47, 'Jogador'),
(52, 'Portugal', 2022, 48, 'Jogador'),
(53, 'Portugal', 2022, 49, 'Jogador'),
(54, 'Portugal', 2022, 50, 'Jogador'),
(55, 'Portugal', 2022, 51, 'Jogador'),
(56, 'Portugal', 2022, 52, 'Jogador'),
(57, 'Brasil', 2022, 53, 'Jogador'),
(58, 'Brasil', 2022, 54, 'Jogador'),
(59, 'Brasil', 2022, 55, 'Jogador'),
(60, 'Brasil', 2022, 56, 'Jogador'),
(61, 'Brasil', 2022, 57, 'Jogador'),
(62, 'Brasil', 2022, 58, 'Jogador'),
(63, 'Brasil', 2022, 59, 'Jogador'),
(64, 'Brasil', 2022, 60, 'Jogador'),
(65, 'Brasil', 2022, 61, 'Jogador'),
(66, 'Brasil', 2022, 62, 'Jogador'),
(67, 'Brasil', 2022, 63, 'Jogador'),
(68, 'Brasil', 2022, 64, 'Jogador'),
(69, 'Brasil', 2022, 65, 'Jogador'),
(70, 'Brasil', 2022, 66, 'Jogador'),
(71, 'Brasil', 2022, 67, 'Jogador'),
(72, 'Brasil', 2022, 68, 'Jogador'),
(73, 'Brasil', 2022, 69, 'Jogador'),
(74, 'Brasil', 2022, 70, 'Jogador'),
(75, 'Brasil', 2022, 71, 'Jogador'),
(76, 'Brasil', 2022, 72, 'Jogador'),
(77, 'Brasil', 2022, 73, 'Jogador'),
(78, 'Brasil', 2022, 74, 'Jogador'),
(79, 'Brasil', 2022, 75, 'Jogador'),
(80, 'Brasil', 2022, 76, 'Jogador'),
(81, 'Brasil', 2022, 77, 'Jogador'),
(82, 'Brasil', 2022, 78, 'Jogador'),
(83, 'França', 2022, 92, 'Jogador'),
(84, 'França', 2022, 93, 'Jogador'),
(85, 'França', 2022, 94, 'Jogador'),
(86, 'França', 2022, 95, 'Jogador'),
(87, 'França', 2022, 96, 'Jogador'),
(88, 'França', 2022, 97, 'Jogador'),
(89, 'França', 2022, 98, 'Jogador'),
(90, 'França', 2022, 99, 'Jogador'),
(91, 'França', 2022, 100, 'Jogador'),
(92, 'França', 2022, 101, 'Jogador'),
(93, 'França', 2022, 102, 'Jogador'),
(94, 'França', 2022, 103, 'Jogador'),
(95, 'França', 2022, 104, 'Jogador'),
(96, 'França', 2018, 105, 'Jogador'),
(97, 'França', 2022, 106, 'Jogador'),
(98, 'França', 2022, 107, 'Jogador'),
(99, 'França', 2022, 108, 'Jogador'),
(100, 'França', 2022, 109, 'Jogador'),
(101, 'França', 2022, 110, 'Jogador'),
(102, 'França', 2022, 111, 'Jogador'),
(103, 'França', 2022, 112, 'Jogador'),
(104, 'França', 2022, 113, 'Jogador'),
(105, 'França', 2022, 114, 'Jogador'),
(106, 'França', 2022, 115, 'Jogador'),
(107, 'França', 2022, 116, 'Jogador'),
(108, 'França', 2022, 117, 'Jogador'),
(109, 'Inglaterra', 2022, 118, 'Jogador'),
(110, 'Inglaterra', 2022, 119, 'Jogador'),
(111, 'Inglaterra', 2022, 120, 'Jogador'),
(112, 'Inglaterra', 2022, 121, 'Jogador'),
(113, 'Inglaterra', 2022, 122, 'Jogador'),
(114, 'Inglaterra', 2022, 123, 'Jogador'),
(115, 'Inglaterra', 2022, 124, 'Jogador'),
(116, 'Inglaterra', 2022, 125, 'Jogador'),
(117, 'Inglaterra', 2022, 126, 'Jogador'),
(118, 'Inglaterra', 2022, 127, 'Jogador'),
(119, 'Inglaterra', 2022, 128, 'Jogador'),
(120, 'Inglaterra', 2022, 129, 'Jogador'),
(121, 'Inglaterra', 2022, 130, 'Jogador'),
(122, 'Inglaterra', 2022, 131, 'Jogador'),
(123, 'Inglaterra', 2022, 132, 'Jogador'),
(124, 'Inglaterra', 2022, 133, 'Jogador'),
(125, 'Inglaterra', 2022, 134, 'Jogador'),
(126, 'Inglaterra', 2022, 135, 'Jogador'),
(127, 'Inglaterra', 2022, 136, 'Jogador'),
(128, 'Inglaterra', 2022, 137, 'Jogador'),
(129, 'Inglaterra', 2022, 138, 'Jogador'),
(130, 'Inglaterra', 2022, 139, 'Jogador'),
(131, 'Inglaterra', 2022, 140, 'Jogador'),
(132, 'Inglaterra', 2022, 141, 'Jogador'),
(133, 'Inglaterra', 2022, 142, 'Jogador'),
(134, 'Inglaterra', 2022, 143, 'Jogador'),
(135, 'Portugal', 2022, 144, 'Jogador');

--
-- Acionadores `elementocomitiva`
--
DELIMITER $$
CREATE TRIGGER `Check_Generalization_Insert` BEFORE INSERT ON `elementocomitiva` FOR EACH ROW BEGIN
IF (SELECT COUNT(*) FROM elementocomitiva e
    WHERE new.Comitiva_Pais = e.Comitiva_Pais
    AND new.Comitiva_Ano = e.Comitiva_Ano
     AND new.Pessoa_ID = e.Pessoa_ID) <> 0 THEN
     
     SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'O ID desta pessoa já existe nesta comitiva e neste ano';
     
END IF;


END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `Check_Generalization_Update` BEFORE UPDATE ON `elementocomitiva` FOR EACH ROW BEGIN

IF (SELECT COUNT(*) FROM elementocomitiva e
    WHERE new.Comitiva_Pais = e.Comitiva_Pais
    AND new.Comitiva_Ano = e.Comitiva_Ano
     AND new.Pessoa_ID = e.Pessoa_ID 
   AND new.NumeroSerie <> e.NumeroSerie) <> 0 THEN
     
     SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'O ID desta pessoa já existe nesta comitiva e neste ano';
     
     
END IF;


END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estrutura da tabela `estadio`
--

CREATE TABLE `estadio` (
  `Nome` varchar(60) COLLATE latin1_bin NOT NULL,
  `Pais_nome` varchar(60) COLLATE latin1_bin NOT NULL,
  `Localidade` varchar(60) COLLATE latin1_bin DEFAULT NULL,
  `Lotacao` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_bin;

--
-- Extraindo dados da tabela `estadio`
--

INSERT INTO `estadio` (`Nome`, `Pais_nome`, `Localidade`, `Lotacao`) VALUES
('Ahmad Bin Ali', 'Qatar', 'Qatar', 45000),
('Al Bayt ', 'Qatar', 'Qatar', 67000),
('Al Janoub', 'Qatar', 'Qatar', 44000),
('Al Thumama', 'Qatar', 'Qatar', 44000),
('Lusail', 'Qatar', 'Qatar', 88000);

-- --------------------------------------------------------

--
-- Estrutura da tabela `funcao`
--

CREATE TABLE `funcao` (
  `funcao` varchar(60) COLLATE latin1_bin NOT NULL,
  `TipoFuncao` enum('Outra','Tecnica') COLLATE latin1_bin NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_bin;

--
-- Extraindo dados da tabela `funcao`
--

INSERT INTO `funcao` (`funcao`, `TipoFuncao`) VALUES
('', ''),
('Analista', 'Tecnica'),
('CameraMan', 'Outra'),
('Enfermeiro', 'Outra'),
('Rapaz das Águas', 'Outra'),
('Segurança', 'Outra'),
('Selecionador', 'Tecnica'),
('Treinador', 'Tecnica');

-- --------------------------------------------------------

--
-- Estrutura stand-in para vista `game_with_most_penalizations`
-- (Veja abaixo para a view atual)
--
CREATE TABLE `game_with_most_penalizations` (
`Jogo_ID` int(11)
);

-- --------------------------------------------------------

--
-- Estrutura da tabela `golo`
--

CREATE TABLE `golo` (
  `Jogo_Numero` int(11) NOT NULL,
  `Golo_Numero` tinyint(4) NOT NULL,
  `Marcador_JogadorEmCampo_Jogo_numero` int(11) NOT NULL,
  `Marcador_JogadorEmCampo_ID` int(11) NOT NULL,
  `Assistencia_JogadorEmCampo_Jogo_numero` int(11) DEFAULT NULL,
  `Assistencia_JogadorID` int(11) DEFAULT NULL,
  `Momento` time DEFAULT NULL,
  `Autogolo` tinyint(1) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_bin;

--
-- Extraindo dados da tabela `golo`
--

INSERT INTO `golo` (`Jogo_Numero`, `Golo_Numero`, `Marcador_JogadorEmCampo_Jogo_numero`, `Marcador_JogadorEmCampo_ID`, `Assistencia_JogadorEmCampo_Jogo_numero`, `Assistencia_JogadorID`, `Momento`, `Autogolo`) VALUES
(1, 1, 1, 1, 1, 2, '00:06:39', NULL),
(1, 2, 1, 1, 1, 7, '00:38:39', NULL),
(1, 3, 1, 27, NULL, NULL, '01:04:22', 1),
(2, 1, 2, 93, 2, 96, '00:15:35', NULL),
(2, 2, 2, 118, 2, 125, '00:55:01', NULL),
(3, 1, 3, 1, 3, 8, '00:05:05', NULL),
(3, 2, 3, 1, NULL, NULL, '01:20:05', NULL),
(4, 1, 4, 27, 4, 31, '00:37:11', NULL),
(5, 1, 5, 1, 5, 10, '00:12:49', NULL),
(5, 2, 5, 2, 5, 8, '01:23:49', NULL),
(6, 1, 6, 27, 6, 31, '00:53:45', NULL),
(6, 2, 6, 121, 6, 123, '00:34:45', NULL);

--
-- Acionadores `golo`
--
DELIMITER $$
CREATE TRIGGER `TR_Delete_Golo` BEFORE DELETE ON `golo` FOR EACH ROW BEGIN
DECLARE goals_sel_1 integer;
DECLARE goals_sel_2 integer;
DECLARE perfect_sel varchar(60);
DECLARE game_id integer;
DECLARE sel_1 varchar(60);
DECLARE sel_2 varchar(60);
DECLARE scoring_sel varchar(60);
DECLARE marcador_sel varchar(60);
DECLARE suffering_sel varchar(60);
SET game_id = old.Jogo_Numero;
SET sel_1 = (SELECT j.Selecao1_Pais FROM jogo j 
             WHERE j.Numero = game_id);
SET sel_2 = (SELECT j.Selecao2_Pais FROM jogo j 
             WHERE j.Numero = game_id);
             
/*UPDATE GOALS*/
CALL Update_Player_Goals(old.Marcador_JogadorEmCampo_ID, -1);


/*UPDATE ASSISTS*/
IF old.Assistencia_JogadorID IS NOT NULL THEN

CALL Update_Player_Assists(old.Assistencia_JogadorID, -1);

END IF;


/*UPDATE PERFECT GAMES*/
SET perfect_sel = is_PerfectGame(game_id);


    SET marcador_sel = (SELECT js.Selecao_Pais FROM jogadorselecao 						js WHERE js.Jogador_ID =  old.Marcador_JogadorEmCampo_ID);

    IF(old.Autogolo IS NULL) THEN
        SET scoring_sel = marcador_sel;
        IF marcador_sel = sel_1 THEN
            SET suffering_sel = sel_2;
        ELSE
            SET suffering_sel = sel_1;
        END IF;
    ELSE 
        SET suffering_sel = marcador_sel;
        IF marcador_sel = sel_1 THEN
            SET scoring_sel = sel_2;
        ELSE
            SET scoring_sel = sel_1;
        END IF;
    END IF;


    SET goals_sel_1 = Get_Selection1_Goals(game_id);
    SET goals_sel_2 = Get_Selection2_Goals(game_id);
    
    
IF perfect_sel = sel_1 THEN 
   	IF goals_sel_1 - 1 = 0 THEN
    	CALL Update_Player_PerfectGame(game_id, -1, sel_1);
    END IF;
ELSEIF perfect_sel = sel_2 THEN 
   	IF goals_sel_2 - 1 = 0 THEN
    	CALL Update_Player_PerfectGame(game_id, -1, sel_2);
    END IF;
ELSE /* NO TEAM IS AT ZERO GOALS*/
	IF scoring_sel = sel_1 THEN
    	IF goals_sel_1 - 1 = 0 THEN
        	CALL Update_Player_PerfectGame(game_id, 1, sel_2);
        END IF; 
    ELSEIF scoring_sel=sel_2 THEN
    	IF goals_sel_2 - 1 = 0 THEN
        	CALL Update_Player_PerfectGame(game_id, 1, sel_1);
        END IF; 
    END IF;
END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `TR_Delete_Golo_2` AFTER DELETE ON `golo` FOR EACH ROW BEGIN


UPDATE jogo j
SET j.Winner_Pais = Get_Game_Winner(old.Jogo_Numero)
WHERE j.Numero = old.Jogo_Numero;

END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `TR_Insert_Golo` BEFORE INSERT ON `golo` FOR EACH ROW BEGIN
DECLARE goals_sel_1 integer;
DECLARE goals_sel_2 integer;
DECLARE perfect_sel varchar(60);
DECLARE game_id integer;
DECLARE sel_1 varchar(60);
DECLARE sel_2 varchar(60);
DECLARE scoring_sel varchar(60);
DECLARE marcador_sel varchar(60);
DECLARE suffering_sel varchar(60);
SET game_id = new.Jogo_Numero;
SET sel_1 = (SELECT j.Selecao1_Pais FROM jogo j 
             WHERE j.Numero = game_id);
SET sel_2 = (SELECT j.Selecao2_Pais FROM jogo j 
             WHERE j.Numero = game_id);

/*UPDATE GOLOS*/
CALL Update_Player_Goals(new.Marcador_JogadorEmCampo_ID, 1);

/*UPDATE ASSIST*/
IF new.Assistencia_JogadorID IS NOT NULL THEN
CALL Update_Player_Assists(new.Assistencia_JogadorID, 1);
END IF;

/*UPDATE PERFECT GAMES*/
SET perfect_sel = is_PerfectGame(game_id);

SET marcador_sel = (SELECT js.Selecao_Pais FROM jogadorselecao 						js WHERE js.Jogador_ID =  new.Marcador_JogadorEmCampo_ID);

IF(new.Autogolo IS NULL) THEN
	SET scoring_sel = marcador_sel;
	IF marcador_sel = sel_1 THEN
    	SET suffering_sel = sel_2;
    ELSE
   		SET suffering_sel = sel_1;
   	END IF;
ELSE 
	SET suffering_sel = marcador_sel;
	IF marcador_sel = sel_1 THEN
    	SET scoring_sel = sel_2;
    ELSE
   		SET scoring_sel = sel_1;
   	END IF;
END IF;

 
SET goals_sel_1 = Get_Selection1_Goals(game_id);
SET goals_sel_2 = Get_Selection2_Goals(game_id);

IF (goals_sel_1 = 0 AND goals_sel_2 = 0) THEN
	CALL Update_Player_PerfectGame(game_id,1,scoring_sel);
ELSEIF (perfect_sel <> scoring_sel) THEN
	CALL Update_Player_PerfectGame(game_id,-1,suffering_sel);
END IF;


END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `TR_Insert_Golo_2` AFTER INSERT ON `golo` FOR EACH ROW BEGIN

UPDATE jogo j
SET j.Winner_Pais = Get_Game_Winner(new.Jogo_Numero)
WHERE j.Numero = new.Jogo_Numero;

END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `TR_Update_Golo` BEFORE UPDATE ON `golo` FOR EACH ROW BEGIN

SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Nao é permitido atualizar um golo, opte por apagar e adicionar um golo novo';

END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `TR_Update_Golo_2` AFTER UPDATE ON `golo` FOR EACH ROW BEGIN

UPDATE jogo j
SET j.Winner_Pais = Get_Game_Winner(old.Jogo_Numero)
WHERE j.Numero = old.Jogo_Numero;

UPDATE jogo j
SET j.Winner_Pais = Get_Game_Winner(new.Jogo_Numero)
WHERE j.Numero = new.Jogo_Numero;

END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estrutura da tabela `grupo`
--

CREATE TABLE `grupo` (
  `Edicao_Ano` smallint(6) NOT NULL,
  `Letra` char(1) COLLATE latin1_bin NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_bin;

--
-- Extraindo dados da tabela `grupo`
--

INSERT INTO `grupo` (`Edicao_Ano`, `Letra`) VALUES
(2022, 'A'),
(2022, 'B'),
(2022, 'C'),
(2022, 'D'),
(2022, 'E'),
(2022, 'F'),
(2022, 'G'),
(2022, 'H');

-- --------------------------------------------------------

--
-- Estrutura da tabela `jogador`
--

CREATE TABLE `jogador` (
  `Pessoa_ID` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_bin;

--
-- Extraindo dados da tabela `jogador`
--

INSERT INTO `jogador` (`Pessoa_ID`) VALUES
(1),
(2),
(3),
(4),
(5),
(6),
(7),
(8),
(9),
(10),
(11),
(12),
(13),
(14),
(15),
(16),
(17),
(18),
(19),
(20),
(21),
(22),
(23),
(24),
(25),
(26),
(27),
(28),
(31),
(32),
(33),
(34),
(35),
(36),
(37),
(38),
(39),
(40),
(41),
(42),
(43),
(44),
(45),
(46),
(47),
(48),
(49),
(50),
(51),
(52),
(53),
(54),
(55),
(56),
(57),
(58),
(59),
(60),
(61),
(62),
(63),
(64),
(65),
(66),
(67),
(68),
(69),
(70),
(71),
(72),
(73),
(74),
(75),
(76),
(77),
(78),
(92),
(93),
(94),
(95),
(96),
(97),
(98),
(99),
(100),
(101),
(102),
(103),
(104),
(105),
(106),
(107),
(108),
(109),
(110),
(111),
(112),
(113),
(114),
(115),
(116),
(117),
(118),
(119),
(120),
(121),
(122),
(123),
(124),
(125),
(126),
(127),
(128),
(129),
(130),
(131),
(132),
(133),
(134),
(135),
(136),
(137),
(138),
(139),
(140),
(141),
(142),
(143),
(144);

-- --------------------------------------------------------

--
-- Estrutura da tabela `jogadoremcampo`
--

CREATE TABLE `jogadoremcampo` (
  `Jogador_ID` int(11) NOT NULL,
  `Jogo_numero` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_bin;

--
-- Extraindo dados da tabela `jogadoremcampo`
--

INSERT INTO `jogadoremcampo` (`Jogador_ID`, `Jogo_numero`) VALUES
(1, 1),
(1, 3),
(1, 5),
(2, 1),
(2, 3),
(2, 5),
(3, 1),
(3, 3),
(3, 5),
(4, 1),
(4, 3),
(4, 5),
(5, 1),
(5, 3),
(5, 5),
(6, 1),
(6, 3),
(6, 5),
(7, 1),
(7, 3),
(7, 5),
(8, 1),
(8, 3),
(8, 5),
(9, 1),
(9, 3),
(9, 5),
(10, 1),
(10, 3),
(10, 5),
(11, 1),
(11, 3),
(11, 5),
(12, 1),
(12, 3),
(12, 5),
(13, 1),
(13, 3),
(13, 5),
(14, 1),
(14, 3),
(14, 5),
(27, 1),
(27, 4),
(27, 6),
(28, 1),
(28, 4),
(28, 6),
(29, 1),
(29, 4),
(29, 6),
(30, 1),
(30, 4),
(30, 6),
(31, 1),
(31, 4),
(31, 6),
(32, 1),
(32, 4),
(32, 6),
(33, 1),
(33, 4),
(33, 6),
(34, 1),
(34, 4),
(34, 6),
(35, 1),
(35, 4),
(35, 6),
(36, 1),
(36, 4),
(36, 6),
(37, 1),
(37, 4),
(37, 6),
(38, 1),
(38, 4),
(38, 6),
(39, 1),
(39, 4),
(39, 6),
(40, 1),
(40, 4),
(40, 6),
(92, 2),
(92, 4),
(92, 5),
(93, 2),
(93, 4),
(93, 5),
(94, 2),
(94, 4),
(94, 5),
(95, 2),
(95, 4),
(95, 5),
(96, 2),
(96, 4),
(96, 5),
(97, 2),
(97, 4),
(97, 5),
(98, 2),
(98, 4),
(98, 5),
(99, 2),
(99, 4),
(99, 5),
(100, 2),
(100, 4),
(100, 5),
(101, 2),
(101, 4),
(101, 5),
(102, 2),
(102, 4),
(102, 5),
(103, 2),
(103, 4),
(103, 5),
(104, 2),
(104, 4),
(104, 5),
(105, 2),
(105, 4),
(105, 5),
(118, 2),
(118, 3),
(118, 6),
(119, 2),
(119, 3),
(119, 6),
(120, 2),
(120, 3),
(120, 6),
(121, 2),
(121, 3),
(121, 6),
(122, 2),
(122, 3),
(122, 6),
(123, 2),
(123, 3),
(123, 6),
(124, 2),
(124, 3),
(124, 6),
(125, 2),
(125, 3),
(125, 6),
(126, 2),
(126, 3),
(126, 6),
(127, 2),
(127, 3),
(127, 6),
(128, 2),
(128, 3),
(128, 6),
(129, 2),
(129, 3),
(129, 6),
(130, 2),
(130, 3),
(130, 6),
(131, 2),
(131, 3),
(131, 6);

-- --------------------------------------------------------

--
-- Estrutura da tabela `jogadorjogo`
--

CREATE TABLE `jogadorjogo` (
  `JogadorSelecao_ID` int(11) NOT NULL,
  `Jogo_numero` int(11) NOT NULL,
  `EstadoJogador` enum('convocado','dispensado','lesionado','castigado') COLLATE latin1_bin DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_bin;

--
-- Extraindo dados da tabela `jogadorjogo`
--

INSERT INTO `jogadorjogo` (`JogadorSelecao_ID`, `Jogo_numero`, `EstadoJogador`) VALUES
(1, 1, NULL),
(1, 3, NULL),
(1, 5, NULL),
(2, 1, NULL),
(2, 3, NULL),
(2, 5, NULL),
(3, 1, NULL),
(3, 3, NULL),
(3, 5, NULL),
(4, 1, NULL),
(4, 3, NULL),
(4, 5, NULL),
(5, 1, NULL),
(5, 3, NULL),
(5, 5, NULL),
(6, 1, NULL),
(6, 3, NULL),
(6, 5, NULL),
(7, 1, NULL),
(7, 3, NULL),
(7, 5, NULL),
(8, 1, NULL),
(8, 3, NULL),
(8, 5, NULL),
(9, 1, NULL),
(9, 3, NULL),
(9, 5, NULL),
(10, 1, NULL),
(10, 3, NULL),
(10, 5, NULL),
(11, 1, NULL),
(11, 3, NULL),
(11, 5, NULL),
(12, 1, NULL),
(12, 3, NULL),
(12, 5, NULL),
(13, 1, NULL),
(13, 3, NULL),
(13, 5, NULL),
(14, 1, NULL),
(14, 3, NULL),
(14, 5, NULL),
(15, 1, NULL),
(15, 3, NULL),
(15, 5, NULL),
(16, 3, NULL),
(16, 5, NULL),
(17, 3, NULL),
(17, 5, NULL),
(18, 3, NULL),
(18, 5, NULL),
(19, 3, NULL),
(19, 5, NULL),
(20, 3, NULL),
(20, 5, NULL),
(21, 3, NULL),
(21, 5, NULL),
(22, 3, NULL),
(22, 5, NULL),
(23, 3, NULL),
(23, 5, NULL),
(24, 3, NULL),
(24, 5, NULL),
(25, 3, NULL),
(25, 5, NULL),
(26, 3, NULL),
(26, 5, NULL),
(27, 1, NULL),
(27, 4, NULL),
(27, 6, NULL),
(28, 1, NULL),
(28, 4, NULL),
(28, 6, NULL),
(29, 1, NULL),
(29, 4, NULL),
(29, 6, NULL),
(30, 1, NULL),
(30, 4, NULL),
(30, 6, NULL),
(31, 1, NULL),
(31, 4, NULL),
(31, 6, NULL),
(32, 1, NULL),
(32, 4, NULL),
(32, 6, NULL),
(33, 1, NULL),
(33, 4, NULL),
(33, 6, NULL),
(34, 1, NULL),
(34, 4, NULL),
(34, 6, NULL),
(35, 1, NULL),
(35, 4, NULL),
(35, 6, NULL),
(36, 1, NULL),
(36, 4, NULL),
(36, 6, NULL),
(37, 1, NULL),
(37, 4, NULL),
(37, 6, NULL),
(38, 1, NULL),
(38, 4, NULL),
(38, 6, NULL),
(39, 1, NULL),
(39, 4, NULL),
(39, 6, NULL),
(40, 1, NULL),
(40, 4, NULL),
(40, 6, NULL),
(41, 1, NULL),
(41, 4, NULL),
(41, 6, NULL),
(42, 4, NULL),
(42, 6, NULL),
(43, 4, NULL),
(43, 6, NULL),
(44, 4, NULL),
(44, 6, NULL),
(45, 4, NULL),
(45, 6, NULL),
(46, 4, NULL),
(46, 6, NULL),
(47, 4, NULL),
(47, 6, NULL),
(48, 4, NULL),
(48, 6, NULL),
(49, 4, NULL),
(49, 6, NULL),
(50, 4, NULL),
(50, 6, NULL),
(51, 4, NULL),
(51, 6, NULL),
(52, 4, NULL),
(52, 6, NULL),
(92, 2, NULL),
(92, 4, NULL),
(92, 5, NULL),
(93, 2, NULL),
(93, 4, NULL),
(93, 5, NULL),
(94, 2, NULL),
(94, 4, NULL),
(94, 5, NULL),
(95, 2, NULL),
(95, 4, NULL),
(95, 5, NULL),
(96, 2, NULL),
(96, 4, NULL),
(96, 5, NULL),
(97, 2, NULL),
(97, 4, NULL),
(97, 5, NULL),
(98, 2, NULL),
(98, 4, NULL),
(98, 5, NULL),
(99, 2, NULL),
(99, 4, NULL),
(99, 5, NULL),
(100, 2, NULL),
(100, 4, NULL),
(100, 5, NULL),
(101, 2, NULL),
(101, 4, NULL),
(101, 5, NULL),
(102, 2, NULL),
(102, 4, NULL),
(102, 5, NULL),
(103, 2, NULL),
(103, 4, NULL),
(103, 5, NULL),
(104, 2, NULL),
(104, 4, NULL),
(104, 5, NULL),
(105, 2, NULL),
(105, 4, NULL),
(105, 5, NULL),
(106, 2, NULL),
(106, 4, NULL),
(106, 5, NULL),
(107, 2, NULL),
(107, 4, NULL),
(107, 5, NULL),
(108, 2, NULL),
(108, 4, NULL),
(108, 5, NULL),
(109, 2, NULL),
(109, 4, NULL),
(109, 5, NULL),
(110, 2, NULL),
(110, 4, NULL),
(110, 5, NULL),
(111, 2, NULL),
(111, 4, NULL),
(111, 5, NULL),
(112, 2, NULL),
(112, 4, NULL),
(112, 5, NULL),
(113, 2, NULL),
(113, 4, NULL),
(113, 5, NULL),
(114, 2, NULL),
(114, 4, NULL),
(114, 5, NULL),
(115, 2, NULL),
(115, 4, NULL),
(115, 5, NULL),
(116, 2, NULL),
(116, 4, NULL),
(116, 5, NULL),
(117, 2, NULL),
(117, 4, NULL),
(117, 5, NULL),
(118, 2, NULL),
(118, 3, NULL),
(118, 6, NULL),
(119, 2, NULL),
(119, 3, NULL),
(119, 6, NULL),
(120, 2, NULL),
(120, 3, NULL),
(120, 6, NULL),
(121, 2, NULL),
(121, 3, NULL),
(121, 6, NULL),
(122, 2, NULL),
(122, 3, NULL),
(122, 6, NULL),
(123, 2, NULL),
(123, 3, NULL),
(123, 6, NULL),
(124, 2, NULL),
(124, 3, NULL),
(124, 6, NULL),
(125, 2, NULL),
(125, 3, NULL),
(125, 6, NULL),
(126, 2, NULL),
(126, 3, NULL),
(126, 6, NULL),
(127, 2, NULL),
(127, 3, NULL),
(127, 6, NULL),
(128, 2, NULL),
(128, 3, NULL),
(128, 6, NULL),
(129, 2, NULL),
(129, 3, NULL),
(129, 6, NULL),
(130, 2, NULL),
(130, 3, NULL),
(130, 6, NULL),
(131, 2, NULL),
(131, 3, NULL),
(131, 6, NULL),
(132, 2, NULL),
(132, 3, NULL),
(132, 6, NULL),
(133, 2, NULL),
(133, 3, NULL),
(133, 6, NULL),
(134, 2, NULL),
(134, 3, NULL),
(134, 6, NULL),
(135, 2, NULL),
(135, 3, NULL),
(135, 6, NULL),
(136, 2, NULL),
(136, 3, NULL),
(136, 6, NULL),
(137, 2, NULL),
(137, 3, NULL),
(137, 6, NULL),
(138, 2, NULL),
(138, 3, NULL),
(138, 6, NULL),
(139, 2, NULL),
(139, 3, NULL),
(139, 6, NULL),
(140, 2, NULL),
(140, 3, NULL),
(140, 6, NULL),
(141, 2, NULL),
(141, 3, NULL),
(141, 6, NULL),
(142, 2, NULL),
(142, 3, NULL),
(142, 6, NULL),
(143, 2, NULL),
(143, 3, NULL),
(143, 6, NULL);

-- --------------------------------------------------------

--
-- Estrutura da tabela `jogadorselecao`
--

CREATE TABLE `jogadorselecao` (
  `Jogador_ID` int(11) NOT NULL,
  `ElementoComitiva_Numero` smallint(6) NOT NULL,
  `ClubeFutebol_NomeClube` varchar(60) COLLATE latin1_bin DEFAULT NULL,
  `Pessoa_ID` int(11) NOT NULL,
  `Selecao_Pais` varchar(60) COLLATE latin1_bin NOT NULL,
  `Selecao_Ano` smallint(6) NOT NULL,
  `NumCamisola` tinyint(4) NOT NULL,
  `NumInternacionalizacoes` smallint(6) DEFAULT NULL,
  `EstadoJogador` enum('Convocado','Dispensado','Lesionado','Castigado') COLLATE latin1_bin DEFAULT NULL,
  `PosicaoJogo` enum('guarda-redes','defesa','medio','avancado') COLLATE latin1_bin DEFAULT NULL,
  `num_of_goals` int(11) DEFAULT NULL,
  `num_of_assists` int(11) DEFAULT NULL,
  `num_of_perfect_games` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_bin;

--
-- Extraindo dados da tabela `jogadorselecao`
--

INSERT INTO `jogadorselecao` (`Jogador_ID`, `ElementoComitiva_Numero`, `ClubeFutebol_NomeClube`, `Pessoa_ID`, `Selecao_Pais`, `Selecao_Ano`, `NumCamisola`, `NumInternacionalizacoes`, `EstadoJogador`, `PosicaoJogo`, `num_of_goals`, `num_of_assists`, `num_of_perfect_games`) VALUES
(27, 31, 'Benfica', 53, 'Brasil', 2022, 1, NULL, NULL, NULL, 3, 0, 1),
(28, 32, 'Barcelona', 54, 'Brasil', 2022, 2, NULL, NULL, NULL, 0, 0, 1),
(29, 33, 'Porto', 55, 'Brasil', 2022, 3, NULL, NULL, NULL, 0, 0, 1),
(30, 34, 'Milan', 56, 'Brasil', 2022, 4, NULL, NULL, NULL, 0, 0, 1),
(31, 35, 'Real Madrid', 57, 'Brasil', 2022, 5, NULL, NULL, NULL, 0, 2, 1),
(32, 36, 'Borussia Dortmund', 58, 'Brasil', 2022, 6, NULL, NULL, NULL, 0, 0, 1),
(33, 37, 'Real Madrid', 59, 'Brasil', 2022, 7, NULL, NULL, NULL, 0, 0, 1),
(34, 38, 'Chelsea', 60, 'Brasil', 2022, 8, NULL, NULL, NULL, 0, 0, 1),
(35, 39, 'Milan', 61, 'Brasil', 2022, 9, NULL, NULL, NULL, 0, 0, 1),
(36, 40, 'Real Madrid', 62, 'Brasil', 2022, 10, NULL, NULL, NULL, 0, 0, 1),
(37, 41, 'Bayern Munich', 63, 'Brasil', 2022, 11, NULL, NULL, NULL, 0, 0, 1),
(38, 42, 'Chelsea', 64, 'Brasil', 2022, 12, NULL, NULL, NULL, 0, 0, 1),
(39, 43, 'Milan', 65, 'Brasil', 2022, 13, NULL, NULL, NULL, 0, 0, 1),
(40, 44, 'Juventus', 66, 'Brasil', 2022, 14, NULL, NULL, NULL, 0, 0, 1),
(41, 45, 'Juventus', 67, 'Brasil', 2022, 15, NULL, NULL, NULL, 0, 0, 1),
(42, 46, 'Juventus', 68, 'Brasil', 2022, 16, NULL, NULL, NULL, 0, 0, 1),
(43, 47, 'PSG', 69, 'Brasil', 2022, 17, NULL, NULL, NULL, 0, 0, 1),
(44, 48, 'Ajax', 70, 'Brasil', 2022, 18, NULL, NULL, NULL, 0, 0, 1),
(45, 49, 'PSG', 71, 'Brasil', 2022, 19, NULL, NULL, NULL, 0, 0, 1),
(46, 50, 'PSG', 72, 'Brasil', 2022, 20, NULL, NULL, NULL, 0, 0, 1),
(47, 51, 'Chelsea', 73, 'Brasil', 2022, 21, NULL, NULL, NULL, 0, 0, 1),
(48, 52, 'Manchester City', 74, 'Brasil', 2022, 22, NULL, NULL, NULL, 0, 0, 1),
(49, 53, 'Chelsea', 75, 'Brasil', 2022, 23, NULL, NULL, NULL, 0, 0, 1),
(50, 54, 'Real Madrid', 76, 'Brasil', 2022, 24, NULL, NULL, NULL, 0, 0, 1),
(51, 55, 'Barcelona', 77, 'Brasil', 2022, 25, NULL, NULL, NULL, 0, 0, 1),
(52, 56, 'Ajax', 78, 'Brasil', 2022, 26, NULL, NULL, NULL, 0, 0, 1),
(92, 83, NULL, 92, 'França', 2022, 1, NULL, NULL, NULL, 0, 0, 0),
(93, 84, NULL, 93, 'França', 2022, 2, NULL, NULL, NULL, 1, 0, 0),
(94, 85, NULL, 94, 'França', 2022, 3, NULL, NULL, NULL, 0, 0, 0),
(95, 86, NULL, 95, 'França', 2022, 4, NULL, NULL, NULL, 0, 0, 0),
(96, 87, NULL, 96, 'França', 2022, 5, NULL, NULL, NULL, 0, 1, 0),
(97, 88, NULL, 97, 'França', 2022, 6, NULL, NULL, NULL, 0, 0, 0),
(98, 89, NULL, 98, 'França', 2022, 7, NULL, NULL, NULL, 0, 0, 0),
(99, 90, NULL, 99, 'França', 2022, 8, NULL, NULL, NULL, 0, 0, 0),
(100, 91, NULL, 100, 'França', 2022, 9, NULL, NULL, NULL, 0, 0, 0),
(101, 92, NULL, 101, 'França', 2022, 10, NULL, NULL, NULL, 0, 0, 0),
(102, 93, NULL, 102, 'França', 2022, 11, NULL, NULL, NULL, 0, 0, 0),
(103, 94, NULL, 103, 'França', 2022, 12, NULL, NULL, NULL, 0, 0, 0),
(104, 95, NULL, 104, 'França', 2022, 13, NULL, NULL, NULL, 0, 0, 0),
(105, 96, NULL, 105, 'França', 2022, 14, NULL, NULL, NULL, 0, 0, 0),
(106, 97, NULL, 106, 'França', 2022, 15, NULL, NULL, NULL, 0, 0, 0),
(107, 98, NULL, 107, 'França', 2022, 16, NULL, NULL, NULL, 0, 0, 0),
(108, 99, NULL, 108, 'França', 2022, 17, NULL, NULL, NULL, 0, 0, 0),
(109, 100, NULL, 109, 'França', 2022, 18, NULL, NULL, NULL, 0, 0, 0),
(110, 101, NULL, 110, 'França', 2022, 19, NULL, NULL, NULL, 0, 0, 0),
(111, 102, NULL, 111, 'França', 2022, 20, NULL, NULL, NULL, 0, 0, 0),
(112, 103, NULL, 112, 'França', 2022, 21, NULL, NULL, NULL, 0, 0, 0),
(113, 104, NULL, 113, 'França', 2022, 22, NULL, NULL, NULL, 0, 0, 0),
(114, 105, NULL, 114, 'França', 2022, 23, NULL, NULL, NULL, 0, 0, 0),
(115, 106, NULL, 115, 'França', 2022, 24, NULL, NULL, NULL, 0, 0, 0),
(116, 107, NULL, 116, 'França', 2022, 25, NULL, NULL, NULL, 0, 0, 0),
(117, 108, NULL, 117, 'França', 2022, 26, NULL, NULL, NULL, 0, 0, 0),
(118, 109, NULL, 118, 'Inglaterra', 2022, 1, NULL, NULL, NULL, 1, 0, 0),
(119, 110, NULL, 119, 'Inglaterra', 2022, 2, NULL, NULL, NULL, 0, 0, 0),
(120, 111, NULL, 120, 'Inglaterra', 2022, 3, NULL, NULL, NULL, 0, 0, 0),
(121, 112, NULL, 121, 'Inglaterra', 2022, 4, NULL, NULL, NULL, 1, 0, 0),
(122, 113, NULL, 122, 'Inglaterra', 2022, 5, NULL, NULL, NULL, 0, 0, 0),
(123, 114, NULL, 123, 'Inglaterra', 2022, 6, NULL, NULL, NULL, 0, 1, 0),
(124, 115, NULL, 124, 'Inglaterra', 2022, 7, NULL, NULL, NULL, 0, 0, 0),
(125, 116, NULL, 125, 'Inglaterra', 2022, 8, NULL, NULL, NULL, 0, 1, 0),
(126, 117, NULL, 126, 'Inglaterra', 2022, 9, NULL, NULL, NULL, 0, 0, 0),
(127, 118, NULL, 127, 'Inglaterra', 2022, 10, NULL, NULL, NULL, 0, 0, 0),
(128, 119, NULL, 128, 'Inglaterra', 2022, 11, NULL, NULL, NULL, 0, 0, 0),
(129, 120, NULL, 129, 'Inglaterra', 2022, 13, NULL, NULL, NULL, 0, 0, 0),
(130, 121, NULL, 130, 'Inglaterra', 2022, 14, NULL, NULL, NULL, 0, 0, 0),
(131, 122, NULL, 131, 'Inglaterra', 2022, 15, NULL, NULL, NULL, 0, 0, 0),
(132, 123, NULL, 132, 'Inglaterra', 2022, 16, NULL, NULL, NULL, 0, 0, 0),
(133, 124, NULL, 133, 'Inglaterra', 2022, 17, NULL, NULL, NULL, 0, 0, 0),
(134, 125, NULL, 134, 'Inglaterra', 2022, 18, NULL, NULL, NULL, 0, 0, 0),
(135, 126, NULL, 135, 'Inglaterra', 2022, 19, NULL, NULL, NULL, 0, 0, 0),
(136, 127, NULL, 136, 'Inglaterra', 2022, 20, NULL, NULL, NULL, 0, 0, 0),
(137, 128, NULL, 137, 'Inglaterra', 2022, 21, NULL, NULL, NULL, 0, 0, 0),
(138, 129, NULL, 138, 'Inglaterra', 2022, 22, NULL, NULL, NULL, 0, 0, 0),
(139, 130, NULL, 139, 'Inglaterra', 2022, 23, NULL, NULL, NULL, 0, 0, 0),
(140, 131, NULL, 140, 'Inglaterra', 2022, 24, NULL, NULL, NULL, 0, 0, 0),
(141, 132, NULL, 141, 'Inglaterra', 2022, 25, NULL, NULL, NULL, 0, 0, 0),
(142, 133, NULL, 142, 'Inglaterra', 2022, 26, NULL, NULL, NULL, 0, 0, 0),
(143, 134, NULL, 143, 'Inglaterra', 2022, 27, NULL, NULL, NULL, 0, 0, 0),
(6, 10, 'Benfica', 32, 'Portugal', 2022, 1, NULL, NULL, NULL, 0, 0, 3),
(7, 11, 'Juventus', 33, 'Portugal', 2022, 2, NULL, NULL, NULL, 0, 1, 3),
(8, 12, 'Juventus', 34, 'Portugal', 2022, 4, NULL, NULL, NULL, 0, 2, 3),
(1, 5, 'Manchester City', 1, 'Portugal', 2022, 7, 0, 'Convocado', 'avancado', 5, 0, 3),
(2, 6, 'Benfica', 2, 'Portugal', 2022, 11, 1, 'Convocado', 'avancado', 1, 1, 3),
(15, 19, 'Barcelona', 41, 'Portugal', 2022, 20, NULL, NULL, NULL, 0, 0, 3),
(16, 20, 'Manchester City', 42, 'Portugal', 2022, 21, NULL, NULL, NULL, 0, 0, 3),
(17, 21, 'Real Madrid', 43, 'Portugal', 2022, 24, NULL, NULL, NULL, 0, 0, 3),
(18, 22, 'Manchester City', 44, 'Portugal', 2022, 25, NULL, NULL, NULL, 0, 0, 3),
(19, 23, 'Bayern Munich', 45, 'Portugal', 2022, 26, NULL, NULL, NULL, 0, 0, 3),
(20, 24, 'Juventus', 46, 'Portugal', 2022, 27, NULL, NULL, NULL, 0, 0, 3),
(21, 25, 'Manchester City', 47, 'Portugal', 2022, 28, NULL, NULL, NULL, 0, 0, 3),
(22, 26, 'Bayern Munich', 48, 'Portugal', 2022, 29, NULL, NULL, NULL, 0, 0, 3),
(23, 27, 'Benfica', 49, 'Portugal', 2022, 30, NULL, NULL, NULL, 0, 0, 3),
(24, 28, 'Juventus', 50, 'Portugal', 2022, 32, NULL, NULL, NULL, 0, 0, 3),
(25, 29, 'Juventus', 51, 'Portugal', 2022, 33, NULL, NULL, NULL, 0, 0, 3),
(12, 16, 'Barcelona', 38, 'Portugal', 2022, 35, NULL, NULL, NULL, 0, 0, 3),
(26, 30, 'PSG', 52, 'Portugal', 2022, 37, NULL, NULL, NULL, 0, 0, 3),
(3, 7, 'Ajax', 3, 'Portugal', 2022, 57, NULL, NULL, NULL, 0, 0, 3),
(13, 17, 'Barcelona', 39, 'Portugal', 2022, 65, NULL, NULL, NULL, 0, 0, 3),
(14, 18, 'Porto', 40, 'Portugal', 2022, 69, NULL, NULL, NULL, 0, 0, 3),
(9, 13, 'Borussia Dortmund', 35, 'Portugal', 2022, 76, NULL, NULL, NULL, 0, 0, 3),
(4, 8, 'Porto', 4, 'Portugal', 2022, 78, NULL, NULL, NULL, 0, 0, 3),
(10, 14, 'Chelsea', 36, 'Portugal', 2022, 89, NULL, NULL, NULL, 0, 1, 3),
(5, 9, 'Liverpool', 31, 'Portugal', 2022, 91, NULL, NULL, NULL, 0, 0, 3),
(11, 15, 'Real Madrid', 37, 'Portugal', 2022, 94, NULL, NULL, NULL, 0, 0, 3),
(144, 135, 'Porto', 144, 'Portugal', 2022, 127, 1, 'Convocado', NULL, 0, 0, 0);

--
-- Acionadores `jogadorselecao`
--
DELIMITER $$
CREATE TRIGGER `Check_Player_History_Insert` BEFORE INSERT ON `jogadorselecao` FOR EACH ROW BEGIN

IF (SELECT COUNT(*) FROM jogadorselecao j
    WHERE new.Pessoa_ID = j.Pessoa_ID 
    AND new.Selecao_Pais <> j.Selecao_Pais) <> 0 THEN
    
   SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Este Jogador já representou uma seleção diferente';
END IF;

IF (SELECT COUNT(*) FROM jogadorselecao j
    WHERE new.Pessoa_ID = j.Pessoa_ID 
    AND new.Selecao_Ano = j.Selecao_Ano
   AND new.Jogador_ID <> j.Jogador_ID) <> 0 THEN
    
   SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Este Jogador já esta representado nesta edição do Mundial';
END IF;

END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `Check_Player_History_Update` BEFORE UPDATE ON `jogadorselecao` FOR EACH ROW BEGIN

IF (SELECT COUNT(*) FROM jogadorselecao j
    WHERE new.Pessoa_ID = j.Pessoa_ID 
    AND new.Selecao_Pais <> j.Selecao_Pais) <> 0 THEN
    
   SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Este Jogador já representou uma seleção diferente';
END IF;

IF (SELECT COUNT(*) FROM jogadorselecao j
    WHERE new.Pessoa_ID = j.Pessoa_ID 
    AND new.Selecao_Ano = j.Selecao_Ano
    AND new.Jogador_ID <> j.Jogador_ID) <> 0 THEN
    
   SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Este Jogador já esta representado nesta edição do Mundial';
END IF;

END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `TR_ElementoComitiva_JS` BEFORE INSERT ON `jogadorselecao` FOR EACH ROW BEGIN 

IF (SELECT COUNT(*) FROM presidente p
    WHERE p.ElementoComitiva_Numero = new.ElementoComitiva_Numero) = 1 THEN
    
SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Esta pessoa já é Presidente';
END IF;

IF (SELECT COUNT(*) FROM tecnico t
    WHERE t.ElementoComitiva_Numero = new.ElementoComitiva_Numero) = 1 THEN
    
SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Esta pessoa já é Técnico';
END IF;

IF (SELECT COUNT(*) FROM outro o
    WHERE o.ElementoComitiva_Numero = new.ElementoComitiva_Numero) = 1 THEN
    
SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Esta pessoa já tem Outra Função';
END IF;


END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estrutura da tabela `jogo`
--

CREATE TABLE `jogo` (
  `Grupo_Edicao_Ano` smallint(6) DEFAULT NULL,
  `Grupo_Letra` char(1) COLLATE latin1_bin DEFAULT NULL,
  `Estadio_Nome` varchar(60) COLLATE latin1_bin DEFAULT NULL,
  `Numero` int(11) NOT NULL,
  `Fase` enum('Grupos','Oitavos','Quartos','Meias','Final') COLLATE latin1_bin DEFAULT NULL,
  `Data` date DEFAULT NULL,
  `Winner_Pais` varchar(60) COLLATE latin1_bin NOT NULL DEFAULT 'Empate',
  `Selecao1_Pais` varchar(60) COLLATE latin1_bin NOT NULL,
  `Selecao1_Ano` smallint(11) NOT NULL,
  `Selecao2_Pais` varchar(60) COLLATE latin1_bin NOT NULL,
  `Selecao2_Ano` smallint(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_bin;

--
-- Extraindo dados da tabela `jogo`
--

INSERT INTO `jogo` (`Grupo_Edicao_Ano`, `Grupo_Letra`, `Estadio_Nome`, `Numero`, `Fase`, `Data`, `Winner_Pais`, `Selecao1_Pais`, `Selecao1_Ano`, `Selecao2_Pais`, `Selecao2_Ano`) VALUES
(2022, 'A', 'Lusail', 1, 'Grupos', NULL, 'Portugal', 'Brasil', 2022, 'Portugal', 2022),
(2022, 'A', 'Al Janoub', 2, 'Grupos', NULL, 'Empate', 'Inglaterra', 2022, 'França', 2022),
(2022, 'A', 'Ahmad Bin Ali', 3, 'Grupos', NULL, 'Portugal', 'Portugal', 2022, 'Inglaterra', 2022),
(2022, 'A', 'Al Thumama', 4, 'Grupos', NULL, 'Brasil', 'Brasil', 2022, 'França', 2022),
(2022, 'A', 'Ahmad Bin Ali', 5, 'Grupos', NULL, 'Portugal', 'Portugal', 2022, 'França', 2022),
(2022, 'A', 'Al Bayt ', 6, 'Grupos', NULL, 'Empate', 'Brasil', 2022, 'Inglaterra', 2022);

--
-- Acionadores `jogo`
--
DELIMITER $$
CREATE TRIGGER `Check_Jogo_Insert` BEFORE INSERT ON `jogo` FOR EACH ROW BEGIN
IF (SELECT COUNT(*) FROM jogo j
    WHERE j.Grupo_Edicao_Ano = new.Grupo_Edicao_Ano
    AND j.Grupo_Letra = new.Grupo_Letra) >= 6 THEN
    
     SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Este Grupo já tem 6 jogos definidos';
    
END IF;

END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `Check_Jogo_Update` BEFORE UPDATE ON `jogo` FOR EACH ROW BEGIN
IF (SELECT COUNT(*) FROM jogo j
    WHERE j.Grupo_Edicao_Ano = new.Grupo_Edicao_Ano
    AND j.Grupo_Letra = new.Grupo_Letra) > 6 THEN
    
     SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Este Grupo já tem 6 jogos definidos';
    
END IF;

END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estrutura stand-in para vista `most_red_card_given`
-- (Veja abaixo para a view atual)
--
CREATE TABLE `most_red_card_given` (
`Ano` smallint(6)
,`Nome` varchar(60)
);

-- --------------------------------------------------------

--
-- Estrutura stand-in para vista `most_substituted_player`
-- (Veja abaixo para a view atual)
--
CREATE TABLE `most_substituted_player` (
`Nome` varchar(60)
);

-- --------------------------------------------------------

--
-- Estrutura da tabela `outro`
--

CREATE TABLE `outro` (
  `ElementoComitiva_Numero` smallint(6) NOT NULL,
  `Funcao` varchar(30) COLLATE latin1_bin NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_bin;

--
-- Extraindo dados da tabela `outro`
--

INSERT INTO `outro` (`ElementoComitiva_Numero`, `Funcao`) VALUES
(1, 'Analista');

--
-- Acionadores `outro`
--
DELIMITER $$
CREATE TRIGGER `TR_ElementoComitiva_O` BEFORE INSERT ON `outro` FOR EACH ROW BEGIN 

IF (SELECT COUNT(*) FROM presidente p
    WHERE p.ElementoComitiva_Numero = new.ElementoComitiva_Numero) = 1 THEN
    
SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Esta pessoa já é Presidente';
END IF;

IF (SELECT COUNT(*) FROM tecnico t
    WHERE t.ElementoComitiva_Numero = new.ElementoComitiva_Numero) = 1 THEN
    
SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Esta pessoa já é Técnico';
END IF;

IF (SELECT COUNT(*) FROM jogadorselecao js
    WHERE js.ElementoComitiva_Numero = new.ElementoComitiva_Numero) = 1 THEN
    
SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Esta pessoa já é um Jogador da Seleção';
END IF;


END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estrutura da tabela `pais`
--

CREATE TABLE `pais` (
  `Nome` varchar(60) COLLATE latin1_bin NOT NULL,
  `NumHabitantes` int(11) DEFAULT NULL,
  `Nome_Federacao` varchar(60) COLLATE latin1_bin DEFAULT NULL,
  `NumFederados` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_bin;

--
-- Extraindo dados da tabela `pais`
--

INSERT INTO `pais` (`Nome`, `NumHabitantes`, `Nome_Federacao`, `NumFederados`) VALUES
('Alemanha', 83000000, 'DFB', 1300000),
('Argentina', 45000000, 'AFA', 1500000),
('Arábia Saudita', 35000000, 'SAFF', 700000),
('Austrália', 25000000, 'FA', 800000),
('Brasil', 214000000, 'CBF', 5000000),
('Bélgica', 11000000, 'BNFT', 230000),
('Camarões', 27000000, 'Fecafoot', 300000),
('Canadá', 38000000, 'CSA', 600000),
('Coreia do Sul', 51000000, 'KFA', 1000000),
('Costa Rica', 5000000, 'CRFF', 90000),
('Croácia', 4000000, 'CFF', 70000),
('Dinamarca', 6000000, 'DFA', 100000),
('EUA', 330000000, 'USSF', 1800000),
('Equador', 17000000, 'FEF', 120000),
('Espanha', 47000000, 'RSFF', 900000),
('França', 67000000, 'FFF', 1100000),
('Gana', 32000000, 'GNFT', 120000),
('Inglaterra', 55000000, 'TheFA', 1200000),
('Irão', 85000000, 'FFIRI', 130000),
('Itália', 59000000, 'FIGC', 1000000),
('Japão', 125000000, 'JFA', 800000),
('Marrocos', 35000000, 'FRMF', 500000),
('Moldávia', 10000000, NULL, NULL),
('México', 130000000, 'MFF', 800000),
('País de Gales', 3000000, 'FAW', 30000),
('Países Baixos', 17500000, 'RDFA', 130000),
('Polónia', 38000000, 'PFA', 400000),
('Portugal', 10000000, 'FPF', 200000),
('Qatar', 3000000, 'QFA', 50000),
('Russia', 40000000, NULL, NULL),
('Senegal', 17000000, 'SFF', 80000),
('Suíça', 9000000, 'SFV', 100000),
('Sérvia', 7000000, 'FAS', 90000),
('Tunísia', 12000000, 'TFF', 150000),
('Uruguai', 3400000, 'UFA', 50000);

-- --------------------------------------------------------

--
-- Estrutura da tabela `patrocinador`
--

CREATE TABLE `patrocinador` (
  `Sigla` char(4) COLLATE latin1_bin NOT NULL,
  `Nome` varchar(60) COLLATE latin1_bin DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_bin;

--
-- Extraindo dados da tabela `patrocinador`
--

INSERT INTO `patrocinador` (`Sigla`, `Nome`) VALUES
('ADID', 'Adidas'),
('ASUS', 'Asus'),
('BURG', 'Burger King'),
('COKE', 'Cola-Cola'),
('FILA', 'Fila'),
('MCDO', 'Mc Donalds'),
('NIKE', 'Nike'),
('PEPS', 'Pepsi'),
('PUMA', 'Puma'),
('SAMS', 'Samsung'),
('SHOP', 'Shopee'),
('SPTY', 'Spotify'),
('SUPB', 'Super Bock'),
('TNFC', 'The North Face'),
('VANS', 'Vans'),
('YAMA', 'Yamaha');

-- --------------------------------------------------------

--
-- Estrutura da tabela `patrocinio`
--

CREATE TABLE `patrocinio` (
  `Comitiva_Pais_` varchar(60) COLLATE latin1_bin NOT NULL,
  `Comitiva_Ano_` smallint(6) NOT NULL,
  `Patrocinador_Sigla_` char(4) COLLATE latin1_bin NOT NULL,
  `Montante` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_bin;

--
-- Extraindo dados da tabela `patrocinio`
--

INSERT INTO `patrocinio` (`Comitiva_Pais_`, `Comitiva_Ano_`, `Patrocinador_Sigla_`, `Montante`) VALUES
('Alemanha', 2022, 'ASUS', 20000000),
('Alemanha', 2022, 'FILA', 200000000),
('Alemanha', 2022, 'PEPS', 40000000),
('Espanha', 2022, 'COKE', 45000000),
('Espanha', 2022, 'SHOP', 25000000),
('Espanha', 2022, 'TNFC', 150000000),
('França', 2022, 'PUMA', 250000000),
('França', 2022, 'SAMS', 32000000),
('França', 2022, 'YAMA', 30000000),
('Inglaterra', 2022, 'BURG', 15000000),
('Inglaterra', 2022, 'SPTY', 25000000),
('Inglaterra', 2022, 'VANS', 180000000),
('Itália', 2022, 'ADID', 300000000),
('Itália', 2022, 'MCDO', 30000000),
('Itália', 2022, 'YAMA', 20000000),
('Portugal', 2022, 'NIKE', 290000000),
('Portugal', 2022, 'SAMS', 30000000),
('Portugal', 2022, 'SPTY', 24000000),
('Portugal', 2022, 'SUPB', 9000000),
('Qatar', 2022, 'COKE', 15000000),
('Qatar', 2022, 'FILA', 100000000),
('Qatar', 2022, 'SHOP', 10000000);

-- --------------------------------------------------------

--
-- Estrutura da tabela `penalizacao`
--

CREATE TABLE `penalizacao` (
  `Penalizacao_Jogo_numero` int(11) NOT NULL,
  `Penalizacao_NumeroCartao` tinyint(4) NOT NULL,
  `Momento` time NOT NULL,
  `TipoCartao` enum('Vermelho','Amarelo') COLLATE latin1_bin NOT NULL,
  `JogadorEmCampo_Jogo_numero` int(11) NOT NULL,
  `JogadorEmCampo_ID` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_bin;

--
-- Extraindo dados da tabela `penalizacao`
--

INSERT INTO `penalizacao` (`Penalizacao_Jogo_numero`, `Penalizacao_NumeroCartao`, `Momento`, `TipoCartao`, `JogadorEmCampo_Jogo_numero`, `JogadorEmCampo_ID`) VALUES
(1, 1, '00:15:35', 'Amarelo', 1, 33),
(1, 2, '01:17:21', 'Amarelo', 1, 33),
(1, 3, '01:10:25', 'Vermelho', 1, 8),
(2, 1, '00:36:21', 'Amarelo', 2, 118),
(2, 2, '00:45:21', 'Amarelo', 2, 119),
(3, 1, '00:38:13', 'Vermelho', 3, 11),
(4, 1, '00:18:49', 'Amarelo', 4, 29),
(5, 1, '00:51:22', 'Amarelo', 5, 10),
(6, 1, '00:28:19', 'Amarelo', 6, 31),
(6, 2, '00:40:19', 'Amarelo', 6, 32);

--
-- Acionadores `penalizacao`
--
DELIMITER $$
CREATE TRIGGER `TR_Penalizacao_Insert` BEFORE INSERT ON `penalizacao` FOR EACH ROW BEGIN

IF new.TipoCartao = "Amarelo" THEN

IF(SELECT COUNT(*) FROM penalizacao p 
   WHERE p.TipoCartao = "Amarelo"
   AND p.JogadorEmCampo_Jogo_numero = new.JogadorEmCampo_Jogo_numero
   AND p.JogadorEmCampo_ID = new.JogadorEmCampo_ID) >= 2 THEN
   SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Este Jogador já tem 2 cartões Amarelos neste jogo';
   END IF;


ELSEIF new.TipoCartao = "Vermelho" THEN

IF(SELECT COUNT(*) FROM penalizacao p 
   WHERE p.TipoCartao = "Vermelho"
   AND p.JogadorEmCampo_Jogo_numero = new.JogadorEmCampo_Jogo_numero
   AND p.JogadorEmCampo_ID = new.JogadorEmCampo_ID) >= 1 THEN
   SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Este Jogador já tem 1 cartão Vermelho neste jogo';
   END IF;


END IF;



END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estrutura da tabela `pessoa`
--

CREATE TABLE `pessoa` (
  `Pessoa_ID` int(11) NOT NULL,
  `Nome` varchar(60) COLLATE latin1_bin DEFAULT NULL,
  `DtNasc` date DEFAULT NULL,
  `Pais_Nome` varchar(60) COLLATE latin1_bin NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_bin;

--
-- Extraindo dados da tabela `pessoa`
--

INSERT INTO `pessoa` (`Pessoa_ID`, `Nome`, `DtNasc`, `Pais_Nome`) VALUES
(1, 'Cristiano Ronaldo', '1985-02-05', 'Portugal'),
(2, 'João Félix', '1994-09-08', 'Portugal'),
(3, 'Pepe', '1983-02-26', 'Portugal'),
(4, 'Bernardo Silva', '1995-07-05', 'Portugal'),
(5, 'Koke', '1989-06-06', 'Espanha'),
(6, 'Daniel Carvajal', '1993-11-05', 'Espanha'),
(7, 'Pau Torres', '1995-08-15', 'Espanha'),
(8, 'Unai Simón', '1987-05-05', 'Espanha'),
(9, 'Jamal Musiala', '1998-11-10', 'Alemanha'),
(10, 'Leroy Sané', '1993-03-08', 'Alemanha'),
(11, 'Leon Goretzka', '1993-11-03', 'Alemanha'),
(12, 'Manuel Neuer', '1986-08-31', 'Alemanha'),
(13, 'Kylian Mbappé', '1994-06-13', 'França'),
(14, 'Aurélien Tchouameni', '1988-05-04', 'França'),
(15, 'Kingsley Coman', '1992-04-07', 'França'),
(16, 'William Saliba', '1985-11-13', 'França'),
(17, 'Phil Foden', '1993-08-31', 'Inglaterra'),
(18, 'Jude Bellingham', '1988-06-11', 'Inglaterra'),
(19, 'Harry Kane', '1993-07-02', 'Inglaterra'),
(20, 'Bukayo Saka ', '1984-11-21', 'Inglaterra'),
(21, 'Nicolò Barella', '1988-09-01', 'Itália'),
(22, 'Federico Chiesa', '1999-07-06', 'Itália'),
(23, 'Alessandro Bastoni', '1982-07-08', 'Itália'),
(24, 'Marco Verratti', '1994-12-09', 'Itália'),
(25, 'Mohammed Habibi', '1995-09-09', 'Qatar'),
(26, 'Mohammed Salvini', '1982-07-21', 'Qatar'),
(27, 'Mohammed Tomini', '2000-09-12', 'Qatar'),
(28, 'Mohammed Cauanini', '1993-06-04', 'Qatar'),
(29, 'Mário Fantasma', '1992-09-17', 'Portugal'),
(30, 'Ivo Magalhães', '1978-04-11', 'Portugal'),
(31, 'Rui Patricio', NULL, 'Portugal'),
(32, 'Anthony Lopes', NULL, 'Portugal'),
(33, 'Diogo Dalot', NULL, 'Portugal'),
(34, 'Ruben Dias', NULL, 'Portugal'),
(35, 'Rafael Guerreiro', NULL, 'Portugal'),
(36, 'Nelson Semedo', NULL, 'Portugal'),
(37, 'Danilo', NULL, 'Portugal'),
(38, 'João Cancelo', NULL, 'Portugal'),
(39, 'João Moutinho', NULL, 'Portugal'),
(40, 'João Palhinha', NULL, 'Portugal'),
(41, 'William Carvalho', NULL, 'Portugal'),
(42, 'Renato Sanches', NULL, 'Portugal'),
(43, 'Ruben Neves', NULL, 'Portugal'),
(44, 'Otávio', NULL, 'Portugal'),
(45, 'André Silva', NULL, 'Portugal'),
(46, 'Rafael Leão', NULL, 'Portugal'),
(47, 'Diogo Jota', NULL, 'Portugal'),
(48, 'Gonçalo Guedes', NULL, 'Portugal'),
(49, 'Pedro Neto', NULL, 'Portugal'),
(50, 'Gonçalo Ramos', NULL, 'Portugal'),
(51, 'José Fonte', NULL, 'Portugal'),
(52, 'Cédric', NULL, 'Portugal'),
(53, 'Vinicius Junior', '1981-11-26', 'Brasil'),
(54, 'Rodrygo', '1992-10-14', 'Brasil'),
(55, 'Neymar', '1984-07-11', 'Brasil'),
(56, 'Gabriel Jesus', NULL, 'Brasil'),
(57, 'Antony', NULL, 'Brasil'),
(58, 'Marquinhos', NULL, 'Brasil'),
(59, 'Éder Militão', NULL, 'Brasil'),
(60, 'Bruno Guimarães', NULL, 'Brasil'),
(61, 'Gabriel Martinelli', NULL, 'Brasil'),
(62, 'Fabinho', NULL, 'Brasil'),
(63, 'Casemiro', NULL, 'Brasil'),
(64, 'Allison', NULL, 'Brasil'),
(65, 'Richarlison', NULL, 'Brasil'),
(66, 'Raphinha', NULL, 'Brasil'),
(67, 'Ederson', NULL, 'Brasil'),
(68, 'Lucas Paquetá', NULL, 'Brasil'),
(69, 'Bremer', NULL, 'Brasil'),
(70, 'Fred', NULL, 'Brasil'),
(71, 'Alex Telles', NULL, 'Brasil'),
(72, 'Danilo', NULL, 'Brasil'),
(73, 'Pedro', NULL, 'Brasil'),
(74, 'Éverton Ribeiro', NULL, 'Brasil'),
(75, 'Alex Sandro', NULL, 'Brasil'),
(76, 'Weverton', NULL, 'Brasil'),
(77, 'Thiago Silva', NULL, 'Brasil'),
(78, 'Dani Alves', NULL, 'Brasil'),
(79, 'João Guedes', NULL, 'Brasil'),
(80, 'Marco Silva', NULL, 'Brasil'),
(81, 'Bernardo Poste', NULL, 'Brasil'),
(82, 'Tiago Pereira', NULL, 'Brasil'),
(83, 'Martim Martins', NULL, 'Brasil'),
(84, 'Fernando Fernandes', NULL, 'Portugal'),
(85, 'Paulo Pedro', NULL, 'Portugal'),
(86, 'Joana Conceição', NULL, 'Portugal'),
(87, 'Nuno Guerreiro', NULL, 'Portugal'),
(88, 'António Lança', NULL, 'Portugal'),
(89, 'Joao Costa', NULL, 'Inglaterra'),
(90, 'Miguel Meneses', NULL, 'França'),
(91, 'Jairson Soares', NULL, 'Gana'),
(92, 'Kylian Mbappé', NULL, 'França'),
(93, 'Aurélien Tchouameni', NULL, 'França'),
(94, 'Kingsley Coman', NULL, 'França'),
(95, 'Ousmane Dembélé', NULL, 'França'),
(96, 'Jules Koundé', NULL, 'França'),
(97, 'Theo Hernández', NULL, 'França'),
(98, 'Lucas Hernández', NULL, 'França'),
(99, 'Dayot Upamecano', NULL, 'França'),
(100, 'William Saliba', NULL, 'França'),
(101, 'Eduardo Camavinga', NULL, 'França'),
(102, 'Raphaël Varane', NULL, 'França'),
(103, 'Karim Benzema', NULL, 'França'),
(104, 'Benjamin Pavard', NULL, 'França'),
(105, 'Ibrahima Konaté', NULL, 'França'),
(106, 'Marcus Thuram', NULL, 'França'),
(107, 'Randal Kolo Muani', NULL, 'França'),
(108, 'Antoine Griezmann', NULL, 'França'),
(109, 'Axel Disasi', NULL, 'França'),
(110, 'Mattéo Guendouzi', NULL, 'França'),
(111, 'Youssouf Fofana', NULL, 'França'),
(112, 'Adrien Rabiot', NULL, 'França'),
(113, 'Jordan Veretout', NULL, 'França'),
(114, 'Alphonse Areola', NULL, 'França'),
(115, 'Hugo Lloris', NULL, 'França'),
(116, 'Olivier Giroud', NULL, 'França'),
(117, 'Steve Mandanda', NULL, 'França'),
(118, 'Phil Foden', NULL, 'Inglaterra'),
(119, 'Jude Bellingham', NULL, 'Inglaterra'),
(120, 'Harry Kane', NULL, 'Inglaterra'),
(121, 'Bukayo Saka', NULL, 'Inglaterra'),
(122, 'Declan Rice', NULL, 'Inglaterra'),
(123, 'Mason Mount', NULL, 'Inglaterra'),
(124, 'Raheem Sterling', NULL, 'Inglaterra'),
(125, 'Jack Grealish', NULL, 'Inglaterra'),
(126, 'Trent Alexander-Arnold', NULL, 'Inglaterra'),
(127, 'Marcus Rashford', NULL, 'Inglaterra'),
(128, 'James Maddison', NULL, 'Inglaterra'),
(129, 'Ben White', NULL, 'Inglaterra'),
(130, 'Kalvin Phillips', NULL, 'Inglaterra'),
(131, 'Conor Gallagher', NULL, 'Inglaterra'),
(132, 'Eric Dier', NULL, 'Inglaterra'),
(133, 'Harry Maguire', NULL, 'Inglaterra'),
(134, NULL, NULL, 'Inglaterra'),
(135, 'John Stones', NULL, 'Inglaterra'),
(136, 'Aaron Ramsdale', NULL, 'Inglaterra'),
(137, 'Jordan Pickford', NULL, 'Inglaterra'),
(138, 'Luke Shaw', NULL, 'Inglaterra'),
(139, 'Callum Wilson', NULL, 'Inglaterra'),
(140, 'Conor Coady', NULL, 'Inglaterra'),
(141, 'Nick Pope', NULL, 'Inglaterra'),
(142, 'Jordan Henderson', NULL, 'Inglaterra'),
(143, 'Kyle Walker', NULL, 'Inglaterra'),
(144, 'Salvador Palma', '2022-12-07', 'Portugal');

-- --------------------------------------------------------

--
-- Estrutura stand-in para vista `players_without_participations`
-- (Veja abaixo para a view atual)
--
CREATE TABLE `players_without_participations` (
`Selecao_Ano` smallint(6)
,`Selecao_Pais` varchar(60)
,`NumCamisola` tinyint(4)
);

-- --------------------------------------------------------

--
-- Estrutura da tabela `presidente`
--

CREATE TABLE `presidente` (
  `ElementoComitiva_Numero` smallint(6) NOT NULL,
  `AnoNomeacao` smallint(6) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_bin;

--
-- Acionadores `presidente`
--
DELIMITER $$
CREATE TRIGGER `TR_ElementoComitiva_P` BEFORE INSERT ON `presidente` FOR EACH ROW BEGIN 

IF (SELECT COUNT(*) FROM jogadorselecao js
    WHERE js.ElementoComitiva_Numero = new.ElementoComitiva_Numero) = 1 THEN
    
SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Esta pessoa já é um Jogador da Seleção';
END IF;

IF (SELECT COUNT(*) FROM tecnico t
    WHERE t.ElementoComitiva_Numero = new.ElementoComitiva_Numero) = 1 THEN
    
SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Esta pessoa já é Técnico';
END IF;

IF (SELECT COUNT(*) FROM outro o
    WHERE o.ElementoComitiva_Numero = new.ElementoComitiva_Numero) = 1 THEN
    
SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Esta pessoa já tem Outra Função';
END IF;


END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estrutura da tabela `selecao`
--

CREATE TABLE `selecao` (
  `Pais` varchar(60) COLLATE latin1_bin NOT NULL,
  `Ano` smallint(6) NOT NULL,
  `Grupo_Letter` char(1) COLLATE latin1_bin NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_bin;

--
-- Extraindo dados da tabela `selecao`
--

INSERT INTO `selecao` (`Pais`, `Ano`, `Grupo_Letter`) VALUES
('Brasil', 2022, 'A'),
('França', 2022, 'A'),
('Inglaterra', 2022, 'A'),
('Portugal', 2022, 'A'),
('Alemanha', 2022, 'B'),
('Argentina', 2022, 'B'),
('Arábia Saudita', 2022, 'B'),
('Austrália', 2022, 'B'),
('Bélgica', 2022, 'C'),
('Camarões', 2022, 'C'),
('Canadá', 2022, 'C'),
('Coreia do Sul', 2022, 'C'),
('Costa Rica', 2022, 'D'),
('Croácia', 2022, 'D'),
('Dinamarca', 2022, 'D'),
('EUA', 2022, 'D'),
('Equador', 2022, 'E'),
('Espanha', 2022, 'E'),
('Gana', 2022, 'E'),
('Irão', 2022, 'E'),
('Japão', 2022, 'F'),
('Marrocos', 2022, 'F'),
('México', 2022, 'F'),
('Senegal', 2022, 'F'),
('País de Gales', 2022, 'G'),
('Países Baixos', 2022, 'G'),
('Polónia', 2022, 'G'),
('Qatar', 2022, 'G'),
('Itália', 2022, 'H'),
('Suíça', 2022, 'H'),
('Tunísia', 2022, 'H'),
('Uruguai', 2022, 'H');

--
-- Acionadores `selecao`
--
DELIMITER $$
CREATE TRIGGER `TR_Delete_Selecao` AFTER DELETE ON `selecao` FOR EACH ROW BEGIN

CALL Update_Edicao_TotalSelections(old.Ano);

END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `TR_Insert_Selecao` AFTER INSERT ON `selecao` FOR EACH ROW BEGIN

CALL Update_Edicao_TotalSelections(new.Ano);

END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `TR_Update_Selecao` AFTER UPDATE ON `selecao` FOR EACH ROW BEGIN
CALL Update_Edicao_TotalSelections(old.Ano);
CALL Update_Edicao_TotalSelections(new.Ano);

END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estrutura stand-in para vista `selecoes_por_grupo`
-- (Veja abaixo para a view atual)
--
CREATE TABLE `selecoes_por_grupo` (
`Ano` smallint(6)
,`Grupo_Letter` char(1)
,`Pais` varchar(60)
);

-- --------------------------------------------------------

--
-- Estrutura stand-in para vista `sponsor_contribuiton_percentage`
-- (Veja abaixo para a view atual)
--
CREATE TABLE `sponsor_contribuiton_percentage` (
`Pais` varchar(60)
,`Ano` smallint(6)
,`Patrocinador_Sigla_` char(4)
,`percentagem_contribuicao` decimal(17,4)
);

-- --------------------------------------------------------

--
-- Estrutura da tabela `substituicao`
--

CREATE TABLE `substituicao` (
  `Substituido_JogadorSelecao_ID` int(11) NOT NULL,
  `Substituido_Jogo_numero` int(11) NOT NULL,
  `Substituto_JogadorSelecao_ID` int(11) NOT NULL,
  `Substituto_Jogo_numero` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_bin;

--
-- Extraindo dados da tabela `substituicao`
--

INSERT INTO `substituicao` (`Substituido_JogadorSelecao_ID`, `Substituido_Jogo_numero`, `Substituto_JogadorSelecao_ID`, `Substituto_Jogo_numero`) VALUES
(5, 1, 12, 1),
(6, 1, 13, 1),
(29, 1, 40, 1),
(93, 2, 104, 2),
(100, 2, 103, 2),
(118, 2, 129, 2),
(5, 3, 12, 3),
(120, 3, 129, 3),
(119, 3, 130, 3),
(30, 4, 39, 4),
(100, 4, 103, 4),
(99, 4, 104, 4),
(6, 5, 12, 5),
(2, 5, 13, 5),
(100, 5, 104, 5),
(27, 6, 39, 6),
(29, 6, 40, 6),
(122, 6, 130, 6);

-- --------------------------------------------------------

--
-- Estrutura da tabela `tecnico`
--

CREATE TABLE `tecnico` (
  `ElementoComitiva_Numero` smallint(6) NOT NULL,
  `Funcao` varchar(30) COLLATE latin1_bin NOT NULL,
  `AnosExperiencia` tinyint(4) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_bin;

--
-- Acionadores `tecnico`
--
DELIMITER $$
CREATE TRIGGER `TR_ElementoComitiva_T` BEFORE INSERT ON `tecnico` FOR EACH ROW BEGIN 

IF (SELECT COUNT(*) FROM presidente p
    WHERE p.ElementoComitiva_Numero = new.ElementoComitiva_Numero) = 1 THEN
    
SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Esta pessoa já é Presidente';
END IF;

IF (SELECT COUNT(*) FROM jogadorselecao js
    WHERE js.ElementoComitiva_Numero = new.ElementoComitiva_Numero) = 1 THEN
    
SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Esta pessoa já é um Jogador da Seleção';
END IF;

IF (SELECT COUNT(*) FROM outro o
    WHERE o.ElementoComitiva_Numero = new.ElementoComitiva_Numero) = 1 THEN
    
SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Esta pessoa já tem Outra Função';
END IF;


END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estrutura para vista `biggest_sponsor_main_sponsor`
--
DROP TABLE IF EXISTS `biggest_sponsor_main_sponsor`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `biggest_sponsor_main_sponsor`  AS SELECT c.Pais AS Pais, c.Ano AS Ano, c.Patrocinador_Oficial_sigla AS Patrocinador_Oficial_sigla 
    FROM patrocinio p , comitiva c 
    WHERE p.Montante = (select max(p.Montante) 
                        from patrocinio p) 
    AND c.Pais = p.Comitiva_Pais_ 
    AND c.Ano = p.Comitiva_Ano_;

-- --------------------------------------------------------

--
-- Estrutura para vista `editions_with_most_members`
--
DROP TABLE IF EXISTS `editions_with_most_members`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `editions_with_most_members`  AS SELECT `e`.`Ano` AS `Ano`, count(0) AS `Tot_Members` 
    FROM (`edicao` `e`, `elementocomitiva` `c`)
    WHERE `e`.`Ano` = `c`.`Comitiva_Ano` 
    GROUP BY `e`.`Ano` 
    HAVING `Tot_Members` >= all (select count(0) AS `Tot_Members` from (`edicao` `e` , `elementocomitiva` `c`) where `e`.`Ano` = `c`.`Comitiva_Ano` group by `e`.`Ano`);

-- --------------------------------------------------------

--
-- Estrutura para vista `game_with_most_penalizations`
--
DROP TABLE IF EXISTS `game_with_most_penalizations`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `game_with_most_penalizations`  AS SELECT `p`.`Penalizacao_Jogo_numero` AS `Jogo_ID` 
    FROM `penalizacao` AS `p` 
    GROUP BY `p`.`Penalizacao_Jogo_numero` 
    HAVING count(0) >= all (select count(0) from `penalizacao` `p` group by `p`.`Penalizacao_Jogo_numero`);

-- --------------------------------------------------------

--
-- Estrutura para vista `most_red_card_given`
--
DROP TABLE IF EXISTS `most_red_card_given`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `most_red_card_given`  AS SELECT `e`.`Ano` AS `Ano`, `p`.`Nome` AS `Nome` 
    FROM (`edicao` `e` , `penalizacao` `pen` , `jogadorselecao` `js` , `pessoa` `p`)
    WHERE `e`.`Ano` = (select max(`e2`.`Ano`) from `edicao` `e2`) 
    AND `pen`.`TipoCartao` = 'Vermelho' 
    AND `js`.`Jogador_ID` = `pen`.`JogadorEmCampo_ID` 
    AND `js`.`Selecao_Ano` = `e`.`Ano` 
    AND `js`.`Pessoa_ID` = `p`.`Pessoa_ID` 
    GROUP BY `p`.`Nome` 
    HAVING count(0) >= all (select count(0) from (`edicao` `e` , `penalizacao` `pen` , `jogadorselecao` `js` , `pessoa` `p`) 
                            where `e`.`Ano` = (select max(`e2`.`Ano`) from `edicao` `e2`) 
                            AND `pen`.`TipoCartao` = 'Vermelho' AND `js`.`Jogador_ID` = `pen`.`JogadorEmCampo_ID` 
                            AND `js`.`Selecao_Ano` = `e`.`Ano` AND `js`.`Pessoa_ID` = `p`.`Pessoa_ID` 
                            group by `p`.`Nome`);

-- --------------------------------------------------------

--
-- Estrutura para vista `most_substituted_player`
--
DROP TABLE IF EXISTS `most_substituted_player`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `most_substituted_player`  AS SELECT `p`.`Nome` AS `Nome` 
    FROM (`pessoa` `p` , `substituicao` `s`, `jogadorselecao` `js`) 
    WHERE `s`.`Substituido_JogadorSelecao_ID` = `js`.`Jogador_ID` 
    AND `js`.`Pessoa_ID` = `p`.`Pessoa_ID` 
    GROUP BY `p`.`Nome` 
    HAVING count(0) >= all (select count(0) from (`pessoa` `p` , `substituicao` `s` , `jogadorselecao` `js`) 
                            where `s`.`Substituido_JogadorSelecao_ID` = `js`.`Jogador_ID` 
                            AND `js`.`Pessoa_ID` = `p`.`Pessoa_ID` group by `p`.`Nome`);

-- --------------------------------------------------------

--
-- Estrutura para vista `players_without_participations`
--
DROP TABLE IF EXISTS `players_without_participations`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `players_without_participations`  AS SELECT `sel`.`Selecao_Ano` AS `Selecao_Ano`, `sel`.`Selecao_Pais` AS `Selecao_Pais`, `sel`.`NumCamisola` AS `NumCamisola` 
    FROM `jogadorselecao` AS `sel` 
    WHERE (select count(0) from `jogadorjogo` `jj` 
        where `jj`.`JogadorSelecao_ID` = `sel`.`Jogador_ID`) = 0;

-- --------------------------------------------------------

--
-- Estrutura para vista `selecoes_por_grupo`
--
DROP TABLE IF EXISTS `selecoes_por_grupo`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `selecoes_por_grupo`  AS SELECT s.Ano, s.Grupo_Letter, s.Pais FROM selecao s
ORDER BY s.Ano, s.Grupo_Letter, s.Pais;

-- --------------------------------------------------------

--
-- Estrutura para vista `sponsor_contribuiton_percentage`
--
DROP TABLE IF EXISTS `sponsor_contribuiton_percentage`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `sponsor_contribuiton_percentage`  AS SELECT `c`.`Pais` AS `Pais`, `c`.`Ano` AS `Ano`, `p`.`Patrocinador_Sigla_` AS `Patrocinador_Sigla_`, `p`.`Montante`* 100 / (select sum(`p1`.`Montante`) 
                                                                                                                            from (`patrocinio` `p1` , `comitiva` `c1`)
                                                                                                                            where `c1`.`Pais` = `p1`.`Comitiva_Pais_` 
                                                                                                                            and `c1`.`Ano` = `p1`.`Comitiva_Ano_` 
                                                                                                                            and `c`.`Pais` = `c1`.`Pais` 
                                                                                                                            and `c`.`Ano` = `c1`.`Ano`) AS `percentagem_contribuicao` 
                                                                                                                            FROM (`comitiva` `c` , `patrocinio` `p`) 
    WHERE `c`.`Pais` = `p`.`Comitiva_Pais_` AND `c`.`Ano` = `p`.`Comitiva_Ano_` 
    GROUP BY `c`.`Pais`, c.Ano, p.Patrocinador_Sigla_;

--
-- Índices para tabelas despejadas
--

--
-- Índices para tabela `clubefutebol`
--
ALTER TABLE `clubefutebol`
  ADD PRIMARY KEY (`NomeClube`);

--
-- Índices para tabela `comitiva`
--
ALTER TABLE `comitiva`
  ADD PRIMARY KEY (`Pais`,`Ano`),
  ADD KEY `FK_Comitiva___Edicao` (`Ano`),
  ADD KEY `FK_Comitiva__PatrocinadorOficial___Patrocinador` (`Patrocinador_Oficial_sigla`);

--
-- Índices para tabela `edicao`
--
ALTER TABLE `edicao`
  ADD PRIMARY KEY (`Ano`),
  ADD KEY `edicao_ibfk_1` (`paisOrganizador1`),
  ADD KEY `edicao_ibfk_2` (`paisOrganizador2`);

--
-- Índices para tabela `elementocomitiva`
--
ALTER TABLE `elementocomitiva`
  ADD PRIMARY KEY (`NumeroSerie`),
  ADD KEY `FK_ElementoComitiva___Comitiva` (`Comitiva_Pais`,`Comitiva_Ano`),
  ADD KEY `FK_ElementoComitiva___Pessoa` (`Pessoa_ID`);

--
-- Índices para tabela `estadio`
--
ALTER TABLE `estadio`
  ADD PRIMARY KEY (`Nome`),
  ADD KEY `FK_Estadio___Pais` (`Pais_nome`);

--
-- Índices para tabela `funcao`
--
ALTER TABLE `funcao`
  ADD PRIMARY KEY (`funcao`);

--
-- Índices para tabela `golo`
--
ALTER TABLE `golo`
  ADD PRIMARY KEY (`Jogo_Numero`,`Golo_Numero`),
  ADD KEY `FK_Golo___Marcador_JogadorEmCampo` (`Marcador_JogadorEmCampo_Jogo_numero`),
  ADD KEY `FK_Golo___Assitencia_JogadorEmCampo` (`Assistencia_JogadorEmCampo_Jogo_numero`),
  ADD KEY `Assistencia_ID` (`Assistencia_JogadorID`,`Assistencia_JogadorEmCampo_Jogo_numero`),
  ADD KEY `Marcador_JogadorEmCampo_ID` (`Marcador_JogadorEmCampo_ID`,`Assistencia_JogadorEmCampo_Jogo_numero`),
  ADD KEY `Marcador_JogadorEmCampo_ID_2` (`Marcador_JogadorEmCampo_ID`,`Marcador_JogadorEmCampo_Jogo_numero`);

--
-- Índices para tabela `grupo`
--
ALTER TABLE `grupo`
  ADD PRIMARY KEY (`Edicao_Ano`,`Letra`);

--
-- Índices para tabela `jogador`
--
ALTER TABLE `jogador`
  ADD PRIMARY KEY (`Pessoa_ID`);

--
-- Índices para tabela `jogadoremcampo`
--
ALTER TABLE `jogadoremcampo`
  ADD PRIMARY KEY (`Jogador_ID`,`Jogo_numero`),
  ADD KEY `Jogador_ID` (`Jogador_ID`,`Jogo_numero`);

--
-- Índices para tabela `jogadorjogo`
--
ALTER TABLE `jogadorjogo`
  ADD PRIMARY KEY (`JogadorSelecao_ID`,`Jogo_numero`),
  ADD KEY `FK_JogadorJogo___Jogo` (`Jogo_numero`);

--
-- Índices para tabela `jogadorselecao`
--
ALTER TABLE `jogadorselecao`
  ADD PRIMARY KEY (`Selecao_Pais`,`Selecao_Ano`,`NumCamisola`),
  ADD UNIQUE KEY `Jogador_ID` (`Jogador_ID`),
  ADD KEY `FK_JogadorSelecao_ElementoComitiva` (`ElementoComitiva_Numero`),
  ADD KEY `FK_JogadorSelecao___ClubeFutebol` (`ClubeFutebol_NomeClube`),
  ADD KEY `FK_JogadorSelecao___Jogador` (`Pessoa_ID`);

--
-- Índices para tabela `jogo`
--
ALTER TABLE `jogo`
  ADD PRIMARY KEY (`Numero`),
  ADD KEY `FK_Jogo___Grupo` (`Grupo_Edicao_Ano`,`Grupo_Letra`),
  ADD KEY `FK_Jogo___Estadio` (`Estadio_Nome`),
  ADD KEY `Winner_Pais` (`Winner_Pais`),
  ADD KEY `Selecao1_Ano` (`Selecao1_Ano`,`Selecao1_Pais`),
  ADD KEY `Selecao2_Ano` (`Selecao2_Ano`,`Selecao2_Pais`);

--
-- Índices para tabela `outro`
--
ALTER TABLE `outro`
  ADD PRIMARY KEY (`ElementoComitiva_Numero`),
  ADD KEY `FK_Outro___OutraFuncao` (`Funcao`);

--
-- Índices para tabela `pais`
--
ALTER TABLE `pais`
  ADD PRIMARY KEY (`Nome`),
  ADD UNIQUE KEY `Nome_Federacao` (`Nome_Federacao`);

--
-- Índices para tabela `patrocinador`
--
ALTER TABLE `patrocinador`
  ADD PRIMARY KEY (`Sigla`);

--
-- Índices para tabela `patrocinio`
--
ALTER TABLE `patrocinio`
  ADD PRIMARY KEY (`Comitiva_Pais_`,`Comitiva_Ano_`,`Patrocinador_Sigla_`),
  ADD KEY `FK_Patrocinador_Patrocinio_Comitiva_` (`Patrocinador_Sigla_`);

--
-- Índices para tabela `penalizacao`
--
ALTER TABLE `penalizacao`
  ADD PRIMARY KEY (`Penalizacao_Jogo_numero`,`Penalizacao_NumeroCartao`),
  ADD KEY `JogadorEmCampo_Jogo_numero` (`JogadorEmCampo_Jogo_numero`),
  ADD KEY `JogadorEmCampo_ID` (`JogadorEmCampo_ID`,`JogadorEmCampo_Jogo_numero`);

--
-- Índices para tabela `pessoa`
--
ALTER TABLE `pessoa`
  ADD PRIMARY KEY (`Pessoa_ID`),
  ADD KEY `FK_Pessoa_Naturalidade_Pais` (`Pais_Nome`);

--
-- Índices para tabela `presidente`
--
ALTER TABLE `presidente`
  ADD PRIMARY KEY (`ElementoComitiva_Numero`);

--
-- Índices para tabela `selecao`
--
ALTER TABLE `selecao`
  ADD PRIMARY KEY (`Pais`,`Ano`),
  ADD KEY `FK_Selecao___edicao` (`Ano`),
  ADD KEY `Ano` (`Ano`,`Grupo_Letter`);

--
-- Índices para tabela `substituicao`
--
ALTER TABLE `substituicao`
  ADD KEY `substituicao_ibfk_1` (`Substituido_JogadorSelecao_ID`,`Substituido_Jogo_numero`),
  ADD KEY `Substituto_JogadorSelecao_ID` (`Substituto_JogadorSelecao_ID`,`Substituto_Jogo_numero`);

--
-- Índices para tabela `tecnico`
--
ALTER TABLE `tecnico`
  ADD PRIMARY KEY (`ElementoComitiva_Numero`),
  ADD KEY `Funcao` (`Funcao`);

--
-- AUTO_INCREMENT de tabelas despejadas
--

--
-- AUTO_INCREMENT de tabela `jogo`
--
ALTER TABLE `jogo`
  MODIFY `Numero` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- Restrições para despejos de tabelas
--

--
-- Limitadores para a tabela `comitiva`
--
ALTER TABLE `comitiva`
  ADD CONSTRAINT `FK_Comitiva__PatrocinadorOficial___Patrocinador` FOREIGN KEY (`Patrocinador_Oficial_sigla`) REFERENCES `patrocinador` (`Sigla`) ON UPDATE CASCADE,
  ADD CONSTRAINT `FK_Comitiva___Edicao` FOREIGN KEY (`Ano`) REFERENCES `edicao` (`Ano`) ON UPDATE CASCADE,
  ADD CONSTRAINT `FK_Comitiva___Pais` FOREIGN KEY (`Pais`) REFERENCES `pais` (`Nome`) ON UPDATE CASCADE;

--
-- Limitadores para a tabela `edicao`
--
ALTER TABLE `edicao`
  ADD CONSTRAINT `edicao_ibfk_1` FOREIGN KEY (`paisOrganizador1`) REFERENCES `pais` (`Nome`),
  ADD CONSTRAINT `edicao_ibfk_2` FOREIGN KEY (`paisOrganizador2`) REFERENCES `pais` (`Nome`);

--
-- Limitadores para a tabela `elementocomitiva`
--
ALTER TABLE `elementocomitiva`
  ADD CONSTRAINT `FK_ElementoComitiva___Comitiva` FOREIGN KEY (`Comitiva_Pais`,`Comitiva_Ano`) REFERENCES `comitiva` (`Pais`, `Ano`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `FK_ElementoComitiva___Pessoa` FOREIGN KEY (`Pessoa_ID`) REFERENCES `pessoa` (`Pessoa_ID`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Limitadores para a tabela `estadio`
--
ALTER TABLE `estadio`
  ADD CONSTRAINT `FK_Estadio___Pais` FOREIGN KEY (`Pais_nome`) REFERENCES `pais` (`Nome`) ON UPDATE CASCADE;

--
-- Limitadores para a tabela `golo`
--
ALTER TABLE `golo`
  ADD CONSTRAINT `golo_ibfk_1` FOREIGN KEY (`Assistencia_JogadorID`,`Assistencia_JogadorEmCampo_Jogo_numero`) REFERENCES `jogadoremcampo` (`Jogador_ID`, `Jogo_numero`) ON DELETE CASCADE,
  ADD CONSTRAINT `golo_ibfk_2` FOREIGN KEY (`Marcador_JogadorEmCampo_ID`,`Marcador_JogadorEmCampo_Jogo_numero`) REFERENCES `jogadoremcampo` (`Jogador_ID`, `Jogo_numero`) ON DELETE CASCADE,
  ADD CONSTRAINT `golo_ibfk_3` FOREIGN KEY (`Jogo_Numero`) REFERENCES `jogo` (`Numero`) ON DELETE CASCADE;

--
-- Limitadores para a tabela `grupo`
--
ALTER TABLE `grupo`
  ADD CONSTRAINT `FK_Grupo___Edicao` FOREIGN KEY (`Edicao_Ano`) REFERENCES `edicao` (`Ano`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Limitadores para a tabela `jogador`
--
ALTER TABLE `jogador`
  ADD CONSTRAINT `FK_Jogador_Pessoa` FOREIGN KEY (`Pessoa_ID`) REFERENCES `pessoa` (`Pessoa_ID`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Limitadores para a tabela `jogadoremcampo`
--
ALTER TABLE `jogadoremcampo`
  ADD CONSTRAINT `jogadoremcampo_ibfk_1` FOREIGN KEY (`Jogador_ID`,`Jogo_numero`) REFERENCES `jogadorjogo` (`JogadorSelecao_ID`, `Jogo_numero`) ON DELETE CASCADE;

--
-- Limitadores para a tabela `jogadorjogo`
--
ALTER TABLE `jogadorjogo`
  ADD CONSTRAINT `jogadorjogo_ibfk_1` FOREIGN KEY (`JogadorSelecao_ID`) REFERENCES `jogadorselecao` (`Jogador_ID`),
  ADD CONSTRAINT `jogadorjogo_ibfk_2` FOREIGN KEY (`Jogo_numero`) REFERENCES `jogo` (`Numero`) ON DELETE CASCADE;

--
-- Limitadores para a tabela `jogadorselecao`
--
ALTER TABLE `jogadorselecao`
  ADD CONSTRAINT `FK_JogadorSelecao_ElementoComitiva` FOREIGN KEY (`ElementoComitiva_Numero`) REFERENCES `elementocomitiva` (`NumeroSerie`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `FK_JogadorSelecao___ClubeFutebol` FOREIGN KEY (`ClubeFutebol_NomeClube`) REFERENCES `clubefutebol` (`NomeClube`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `FK_JogadorSelecao___Jogador` FOREIGN KEY (`Pessoa_ID`) REFERENCES `jogador` (`Pessoa_ID`) ON UPDATE CASCADE,
  ADD CONSTRAINT `FK_JogadorSelecao___Selecao` FOREIGN KEY (`Selecao_Pais`,`Selecao_Ano`) REFERENCES `selecao` (`Pais`, `Ano`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Limitadores para a tabela `jogo`
--
ALTER TABLE `jogo`
  ADD CONSTRAINT `FK_Jogo___Estadio` FOREIGN KEY (`Estadio_Nome`) REFERENCES `estadio` (`Nome`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `FK_Jogo___Grupo` FOREIGN KEY (`Grupo_Edicao_Ano`,`Grupo_Letra`) REFERENCES `grupo` (`Edicao_Ano`, `Letra`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `jogo_ibfk_2` FOREIGN KEY (`Selecao1_Ano`,`Selecao1_Pais`) REFERENCES `selecao` (`Ano`, `Pais`),
  ADD CONSTRAINT `jogo_ibfk_3` FOREIGN KEY (`Selecao2_Ano`,`Selecao2_Pais`) REFERENCES `selecao` (`Ano`, `Pais`);

--
-- Limitadores para a tabela `outro`
--
ALTER TABLE `outro`
  ADD CONSTRAINT `FK_Outro___ElementoComitiva` FOREIGN KEY (`ElementoComitiva_Numero`) REFERENCES `elementocomitiva` (`NumeroSerie`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `FK_Outro___OutraFuncao` FOREIGN KEY (`Funcao`) REFERENCES `funcao` (`funcao`) ON UPDATE CASCADE;

--
-- Limitadores para a tabela `patrocinio`
--
ALTER TABLE `patrocinio`
  ADD CONSTRAINT `FK_Comitiva_Patrocinio_Patrocinador_` FOREIGN KEY (`Comitiva_Pais_`,`Comitiva_Ano_`) REFERENCES `comitiva` (`Pais`, `Ano`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `FK_Patrocinador_Patrocinio_Comitiva_` FOREIGN KEY (`Patrocinador_Sigla_`) REFERENCES `patrocinador` (`Sigla`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Limitadores para a tabela `penalizacao`
--
ALTER TABLE `penalizacao`
  ADD CONSTRAINT `penalizacao_ibfk_2` FOREIGN KEY (`JogadorEmCampo_ID`,`JogadorEmCampo_Jogo_numero`) REFERENCES `jogadoremcampo` (`Jogador_ID`, `Jogo_numero`) ON DELETE CASCADE,
  ADD CONSTRAINT `penalizacao_ibfk_3` FOREIGN KEY (`Penalizacao_Jogo_numero`) REFERENCES `jogo` (`Numero`) ON DELETE CASCADE;

--
-- Limitadores para a tabela `pessoa`
--
ALTER TABLE `pessoa`
  ADD CONSTRAINT `FK_Pessoa_Naturalidade_Pais` FOREIGN KEY (`Pais_Nome`) REFERENCES `pais` (`Nome`) ON UPDATE CASCADE;

--
-- Limitadores para a tabela `presidente`
--
ALTER TABLE `presidente`
  ADD CONSTRAINT `FK_Presidente___ElementoComitiva` FOREIGN KEY (`ElementoComitiva_Numero`) REFERENCES `elementocomitiva` (`NumeroSerie`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Limitadores para a tabela `selecao`
--
ALTER TABLE `selecao`
  ADD CONSTRAINT `FK_Selecao___Pais` FOREIGN KEY (`Pais`) REFERENCES `pais` (`Nome`) ON UPDATE CASCADE,
  ADD CONSTRAINT `selecao_ibfk_1` FOREIGN KEY (`Ano`,`Grupo_Letter`) REFERENCES `grupo` (`Edicao_Ano`, `Letra`);

--
-- Limitadores para a tabela `substituicao`
--
ALTER TABLE `substituicao`
  ADD CONSTRAINT `substituicao_ibfk_1` FOREIGN KEY (`Substituido_JogadorSelecao_ID`,`Substituido_Jogo_numero`) REFERENCES `jogadoremcampo` (`Jogador_ID`, `Jogo_numero`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `substituicao_ibfk_2` FOREIGN KEY (`Substituto_JogadorSelecao_ID`,`Substituto_Jogo_numero`) REFERENCES `jogadoremcampo` (`Jogador_ID`, `Jogo_numero`) ON DELETE CASCADE;

--
-- Limitadores para a tabela `tecnico`
--
ALTER TABLE `tecnico`
  ADD CONSTRAINT `FK_Tecnico___ElementoComitiva` FOREIGN KEY (`ElementoComitiva_Numero`) REFERENCES `elementocomitiva` (`NumeroSerie`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `tecnico_ibfk_1` FOREIGN KEY (`Funcao`) REFERENCES `funcao` (`funcao`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
