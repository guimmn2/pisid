-- phpMyAdmin SQL Dump
-- version 5.2.0
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1:3307
-- Generation Time: Apr 20, 2023 at 10:51 AM
-- Server version: 10.10.2-MariaDB
-- PHP Version: 8.0.26

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `pisid`
--

DELIMITER $$
--
-- Procedures
--
DROP PROCEDURE IF EXISTS `StartNextExp`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `StartNextExp` (IN `dataInicio` TIMESTAMP)  NO SQL BEGIN

DECLARE IDExp INT;

CALL TerminateOngoingExp(dataInicio,1);

UPDATE experiencia
SET DataHoraInicio = dataInicio
-- proxima exp a decorrer
WHERE id = (SELECT id FROM experiencia WHERE DataHoraInicio is NULL LIMIT 1);

END$$

DROP PROCEDURE IF EXISTS `TerminateOngoingExp`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `TerminateOngoingExp` (IN `dataFim` TIMESTAMP, IN `id_razaofim` INT)  NO SQL BEGIN

UPDATE experiencia
SET DataHoraFim = dataFim, experiencia.IDRazaoFim = id_razaofim
WHERE experiencia.id = GetOngoingExpId();
END$$

DROP PROCEDURE IF EXISTS `WriteAlert`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `WriteAlert` (IN `hora` TIMESTAMP, IN `sala` INT, IN `sensor` INT, IN `leitura` DECIMAL(4,2), IN `tipo` VARCHAR(50), IN `mensagem` VARCHAR(50), IN `horaescrita` TIMESTAMP)   BEGIN

IF OngoingExp() THEN
	INSERT INTO alerta (id, hora, sala, sensor, leitura, tipo, mensagem, horaescrita)
	VALUES (id, hora, sala, sensor, leitura, tipo, mensagem, horaescrita);
END IF;

END$$

DROP PROCEDURE IF EXISTS `WriteMov`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `WriteMov` (IN `hora` TIMESTAMP, IN `salaentrada` INT, IN `salasaida` INT)  NO SQL BEGIN
IF OngoingExp() THEN
	INSERT INTO medicoespassagens (hora, salaentrada, salasaida)
    VALUES (hora, salaentrada, salasaida);
END IF;
END$$

DROP PROCEDURE IF EXISTS `WriteTemp`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `WriteTemp` (IN `sensor` INT, IN `hora` TIMESTAMP, IN `leitura` DECIMAL(4,2))  NO SQL BEGIN
    IF OngoingExp() THEN
        INSERT INTO medicoestemperatura (sensor, hora, leitura) VALUES (sensor, hora, leitura);
    END IF;
END$$

--
-- Functions
--
DROP FUNCTION IF EXISTS `GetOngoingExpId`$$
CREATE DEFINER=`root`@`localhost` FUNCTION `GetOngoingExpId` () RETURNS INT(11) NO SQL BEGIN
	-- id da exp a decorrer
    DECLARE ongoing_exp_id INT;
    
    SELECT id INTO ongoing_exp_id
    FROM experiencia 
    WHERE experiencia.DataHoraInicio IS NOT NULL 
    AND experiencia.DataHoraFim IS NULL;
    
    IF ongoing_exp_id IS NULL THEN
    RETURN -1;
    ELSE
    RETURN ongoing_exp_id;
    END IF;
END$$

DROP FUNCTION IF EXISTS `GetRatsInRoom`$$
CREATE DEFINER=`root`@`localhost` FUNCTION `GetRatsInRoom` (`nrSala` INT) RETURNS INT(11) NO SQL BEGIN

DECLARE nr_ratos INT;

SELECT numeroratosfinal INTO nr_ratos 
FROM medicoessala
WHERE medicoessala.sala = nrSala AND medicoessala.idexperiencia = GetOngoingExpId();

RETURN nr_ratos;

END$$

DROP FUNCTION IF EXISTS `OngoingExp`$$
CREATE DEFINER=`root`@`localhost` FUNCTION `OngoingExp` () RETURNS TINYINT(1) NO SQL BEGIN-- id da exp a decorrer
    DECLARE ongoing_exp_id INT;
    SELECT id INTO ongoing_exp_id
    FROM experiencia 
    WHERE experiencia.datahorainicio IS NOT NULL 
    AND experiencia.datahorafim IS NULL;
    
    IF ongoing_exp_id IS NULL THEN
    RETURN FALSE;
    ELSE
    RETURN TRUE;
    END IF;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `alerta`
--

DROP TABLE IF EXISTS `alerta`;
CREATE TABLE IF NOT EXISTS `alerta` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `hora` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `sala` int(11) DEFAULT NULL,
  `sensor` int(11) DEFAULT NULL,
  `leitura` decimal(4,2) DEFAULT NULL,
  `tipo` varchar(20) NOT NULL DEFAULT 'light',
  `mensagem` varchar(100) NOT NULL,
  `horaescrita` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=1314 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

--
-- Dumping data for table `alerta`
--

INSERT INTO `alerta` (`id`, `hora`, `sala`, `sensor`, `leitura`, `tipo`, `mensagem`, `horaescrita`) VALUES
(1307, '2023-04-20 10:37:20', NULL, 1, '20.10', 'light_descartada', 'Rápida variação de temp registada no sensor 1', '2023-04-20 10:37:20'),
(1308, '2023-04-20 10:37:21', NULL, 2, '20.10', 'light_descartada', 'Rápida variação de temp registada no sensor 2', '2023-04-20 10:37:21'),
(1309, '2023-04-20 10:37:51', NULL, 2, '20.10', 'light_descartada', 'Rápida variação de temp registada no sensor 2', '2023-04-20 10:37:51'),
(1310, '2023-04-20 10:37:54', NULL, 1, '20.10', 'light_descartada', 'Rápida variação de temp registada no sensor 1', '2023-04-20 10:37:54'),
(1311, '2023-04-20 10:47:51', NULL, 2, '80.00', 'urgent_temp', 'Temperatura muito alta', '2023-04-20 10:47:51'),
(1312, '2023-04-20 10:48:40', NULL, 1, '92.02', 'urgent_temp', 'Temperatura muito alta', '2023-04-20 10:48:40'),
(1313, '2023-04-20 10:50:03', 2, NULL, NULL, 'urgent_mov', 'Excedeu numero de ratos', '2023-04-20 10:50:03');

--
-- Triggers `alerta`
--
DROP TRIGGER IF EXISTS `TerminateExpUrgentAlert`;
DELIMITER $$
CREATE TRIGGER `TerminateExpUrgentAlert` AFTER INSERT ON `alerta` FOR EACH ROW BEGIN

IF NEW.tipo = 'urgent_mov' THEN
        -- alerta dos movimentos
    CALL TerminateOngoingExp(NEW.hora,3);
END IF;

IF NEW.tipo = 'urgent_temp' THEN
        -- alerta da temperatura
    CALL TerminateOngoingExp(NEW.hora,2);
END IF;

END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `experiencia`
--

DROP TABLE IF EXISTS `experiencia`;
CREATE TABLE IF NOT EXISTS `experiencia` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `descricao` text NOT NULL,
  `investigador` varchar(50) DEFAULT NULL,
  `DataHoraInicio` timestamp NULL DEFAULT NULL,
  `DataHoraFim` timestamp NULL DEFAULT NULL,
  `numeroratos` int(11) NOT NULL,
  `limiteratossala` int(11) NOT NULL,
  `segundossemmovimento` int(11) NOT NULL,
  `temperaturaideal` decimal(4,2) NOT NULL,
  `variacaotemperaturamaxima` decimal(4,2) NOT NULL,
  `IDRazaoFim` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `investigador` (`investigador`),
  KEY `IDRazaoFim` (`IDRazaoFim`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

--
-- Dumping data for table `experiencia`
--

INSERT INTO `experiencia` (`id`, `descricao`, `investigador`, `DataHoraInicio`, `DataHoraFim`, `numeroratos`, `limiteratossala`, `segundossemmovimento`, `temperaturaideal`, `variacaotemperaturamaxima`, `IDRazaoFim`) VALUES
(1, 'ww', NULL, '2023-03-17 21:34:58', '2023-03-17 21:35:04', 3, 3, 3, '22.00', '10.00', NULL),
(2, 'ww', NULL, '2023-04-05 18:33:58', '2023-04-05 18:33:58', 3, 3, 3, '22.22', '10.22', NULL),
(6, '', NULL, '2023-04-06 18:10:35', '2023-04-06 18:10:57', 2, 50, 2, '2.00', '2.00', 2),
(7, '', NULL, '2023-04-06 18:11:33', '2023-04-06 18:11:51', 2, 50, 2, '2.00', '2.00', 1),
(8, '', NULL, '2023-04-06 18:11:51', '2023-04-20 10:50:03', 2, 2, 2, '2.00', '2.00', 3);

-- --------------------------------------------------------

--
-- Table structure for table `medicoespassagens`
--

DROP TABLE IF EXISTS `medicoespassagens`;
CREATE TABLE IF NOT EXISTS `medicoespassagens` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `hora` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `salaentrada` int(11) NOT NULL,
  `salasaida` int(11) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=210 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

--
-- Dumping data for table `medicoespassagens`
--

INSERT INTO `medicoespassagens` (`id`, `hora`, `salaentrada`, `salasaida`) VALUES
(196, '2023-04-06 17:27:37', 2, 1),
(197, '2023-04-06 17:27:45', 2, 1),
(198, '2023-04-06 17:27:53', 2, 1),
(199, '2023-04-06 17:33:04', 0, 0),
(200, '2023-04-06 17:33:44', 0, 0),
(201, '2023-04-06 17:35:11', 0, 0),
(202, '2023-04-06 17:35:21', 0, 0),
(203, '2023-04-06 17:44:10', 2, 1),
(204, '2023-04-06 17:47:41', 2, 1),
(205, '2023-04-06 18:02:23', 2, 1),
(206, '2023-04-06 18:11:51', 0, 0),
(207, '2023-04-06 18:12:18', 2, 1),
(208, '2023-04-07 10:42:05', 2, 1),
(209, '2023-04-20 10:50:03', 2, 1);

--
-- Triggers `medicoespassagens`
--
DROP TRIGGER IF EXISTS `RatsCount`;
DELIMITER $$
CREATE TRIGGER `RatsCount` AFTER INSERT ON `medicoespassagens` FOR EACH ROW BEGIN

DECLARE expID, salaEntradaExiste, salaSaidaExiste, nr_ratos, max_ratos INT;
SET expID = GetOngoingExpId();

IF NEW.salaentrada <> NEW.salasaida THEN 

SELECT COUNT(1) into salaEntradaExiste
FROM medicoessala
WHERE medicoessala.idexperiencia = expID and medicoessala.sala = NEW.salaentrada;

SELECT COUNT(1) into salaSaidaExiste
FROM medicoessala
WHERE medicoessala.idexperiencia = expID and medicoessala.sala = NEW.salasaida;

IF salaEntradaExiste = 1 THEN
    UPDATE medicoessala
    SET medicoessala.numeroratosfinal = GetRatsInRoom(NEW.salaentrada) + 1
    WHERE medicoessala.idexperiencia = expID and medicoessala.sala = NEW.salaentrada;
ELSE
    INSERT INTO medicoessala (idexperiencia, numeroratosfinal, sala)
    VALUES (expID, 1, NEW.salaentrada);
END IF;

IF salaSaidaExiste = 1 THEN
    UPDATE medicoessala
    SET medicoessala.numeroratosfinal = GetRatsInRoom(NEW.salasaida) - 1
    WHERE medicoessala.idexperiencia = expID and medicoessala.sala = NEW.salasaida;
ELSE
    INSERT INTO medicoessala (idexperiencia, numeroratosfinal, sala)
    VALUES (expID, -1, NEW.salasaida);
END IF;

SET nr_ratos = GetRatsInRoom(NEW.salaentrada);

SELECT experiencia.limiteratossala INTO max_ratos
FROM experiencia
WHERE experiencia.id = GetOngoingExpId();

IF (nr_ratos > max_ratos) THEN
    INSERT INTO alerta (hora,sala,sensor,leitura,tipo,mensagem,horaescrita)
    VALUES (NEW.hora,NEW.salaentrada,null,null,'urgent_mov','Excedeu numero de ratos',CURRENT_TIMESTAMP());
    
END IF;

END IF;

END
$$
DELIMITER ;
DROP TRIGGER IF EXISTS `StartExp`;
DELIMITER $$
CREATE TRIGGER `StartExp` AFTER INSERT ON `medicoespassagens` FOR EACH ROW BEGIN

IF ((NEW.salaentrada + NEW.salasaida) = 0) THEN
	CALL StartNextExp(NEW.hora);
END IF;

END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `medicoessala`
--

DROP TABLE IF EXISTS `medicoessala`;
CREATE TABLE IF NOT EXISTS `medicoessala` (
  `idexperiencia` int(11) NOT NULL,
  `numeroratosfinal` int(11) NOT NULL,
  `sala` int(11) NOT NULL,
  PRIMARY KEY (`idexperiencia`,`sala`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

--
-- Dumping data for table `medicoessala`
--

INSERT INTO `medicoessala` (`idexperiencia`, `numeroratosfinal`, `sala`) VALUES
(8, -9, 1),
(8, 9, 2);

-- --------------------------------------------------------

--
-- Table structure for table `medicoestemperatura`
--

DROP TABLE IF EXISTS `medicoestemperatura`;
CREATE TABLE IF NOT EXISTS `medicoestemperatura` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `hora` timestamp NOT NULL DEFAULT current_timestamp(),
  `leitura` decimal(4,2) NOT NULL,
  `sensor` int(11) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=1221 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

--
-- Dumping data for table `medicoestemperatura`
--

INSERT INTO `medicoestemperatura` (`id`, `hora`, `leitura`, `sensor`) VALUES
(1209, '2023-04-05 18:38:33', '5.00', 1),
(1210, '2023-04-05 19:09:20', '60.00', 1),
(1211, '2023-04-05 19:09:40', '60.00', 1),
(1212, '2023-04-06 17:29:25', '80.00', 1),
(1213, '2023-04-06 17:30:00', '-20.00', 1),
(1214, '2023-04-06 17:50:51', '80.00', 1),
(1215, '2023-04-06 18:10:57', '60.00', 1),
(1216, '2023-04-06 18:19:06', '50.00', 1),
(1217, '2023-04-07 10:42:52', '60.00', 1),
(1218, '2023-04-07 10:43:56', '3.90', 1),
(1219, '2023-04-20 10:47:51', '80.00', 2),
(1220, '2023-04-20 10:48:40', '92.02', 1);

--
-- Triggers `medicoestemperatura`
--
DROP TRIGGER IF EXISTS `CreateAlertTemp`;
DELIMITER $$
CREATE TRIGGER `CreateAlertTemp` AFTER INSERT ON `medicoestemperatura` FOR EACH ROW BEGIN
  DECLARE ongoing_exp_id INT;
  DECLARE temp_ideal DECIMAL(4,2);
  DECLARE var_max_temp DECIMAL(4,2);

  IF OngoingExp() THEN
    SET ongoing_exp_id = GetOngoingExpId();

    -- obter temp ideal
    SELECT temperaturaideal INTO temp_ideal 
    FROM experiencia 
    WHERE id = ongoing_exp_id;

    -- obter variação máxima da temperatura
    SELECT variacaotemperaturamaxima INTO var_max_temp
    FROM experiencia
    WHERE id = ongoing_exp_id;

    IF ((NEW.leitura) >  temp_ideal + var_max_temp) THEN
      INSERT INTO alerta (hora, sala, sensor, leitura, tipo, mensagem, horaescrita)
      VALUES (NEW.hora, NULL, NEW.sensor, NEW.leitura, 'urgent_temp', 'Temperatura muito alta', CURRENT_TIMESTAMP());
    ELSEIF ((NEW.leitura) < temp_ideal - var_max_temp) THEN
      INSERT INTO alerta (hora, sala, sensor, leitura, tipo, mensagem, horaescrita)
      VALUES (NEW.hora, NULL, NEW.sensor, NEW.leitura, 'urgent_temp', 'Temperatura muito baixa', CURRENT_TIMESTAMP());
    ELSEIF ((NEW.leitura) > temp_ideal + var_max_temp * 0.9) THEN
      INSERT INTO alerta (hora, sala, sensor, leitura, tipo, mensagem, horaescrita)
      VALUES (NEW.hora, NULL, NEW.sensor, NEW.leitura, 'light_temp', 'Temperatura perto do limite máximo', CURRENT_TIMESTAMP());
    ELSEIF ((NEW.leitura) < temp_ideal - var_max_temp * 0.9) THEN
      INSERT INTO alerta (hora, sala, sensor, leitura, tipo, mensagem, horaescrita)
      VALUES (NEW.hora, NULL, NEW.sensor, NEW.leitura, 'light_temp', 'Temperatura perto do limite mínimo', CURRENT_TIMESTAMP());
    END IF;
  END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `odoresexperiencia`
--

DROP TABLE IF EXISTS `odoresexperiencia`;
CREATE TABLE IF NOT EXISTS `odoresexperiencia` (
  `sala` int(11) NOT NULL,
  `idexperiencia` int(11) NOT NULL,
  `codigoodor` int(11) NOT NULL,
  PRIMARY KEY (`sala`,`idexperiencia`),
  KEY `idexperiencia` (`idexperiencia`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `razaofim`
--

DROP TABLE IF EXISTS `razaofim`;
CREATE TABLE IF NOT EXISTS `razaofim` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `descricao` varchar(100) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `razaofim`
--

INSERT INTO `razaofim` (`id`, `descricao`) VALUES
(1, 'Acabou normalmente sem anomalias'),
(2, 'Acabou com anomalias (temperatura excedeu limite)'),
(3, 'Acabou com anomalias (sala excedeu número de ratos limite)');

-- --------------------------------------------------------

--
-- Table structure for table `substanciasexperiencia`
--

DROP TABLE IF EXISTS `substanciasexperiencia`;
CREATE TABLE IF NOT EXISTS `substanciasexperiencia` (
  `numeroratos` int(11) NOT NULL,
  `codigosubstancia` varchar(5) NOT NULL,
  `idexperiencia` int(11) NOT NULL,
  PRIMARY KEY (`codigosubstancia`,`idexperiencia`),
  KEY `idexperiencia` (`idexperiencia`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `utilizador`
--

DROP TABLE IF EXISTS `utilizador`;
CREATE TABLE IF NOT EXISTS `utilizador` (
  `nome` varchar(100) NOT NULL,
  `telefone` varchar(12) NOT NULL,
  `tipo` varchar(3) NOT NULL,
  `email` varchar(50) NOT NULL,
  `password` text NOT NULL,
  PRIMARY KEY (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

--
-- Dumping data for table `utilizador`
--

INSERT INTO `utilizador` (`nome`, `telefone`, `tipo`, `email`, `password`) VALUES
('ww', 'ww', 'ww', 'ww', 'ww');

--
-- Constraints for dumped tables
--

--
-- Constraints for table `experiencia`
--
ALTER TABLE `experiencia`
  ADD CONSTRAINT `experiencia_ibfk_1` FOREIGN KEY (`investigador`) REFERENCES `utilizador` (`email`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `experiencia_ibfk_2` FOREIGN KEY (`IDRazaoFim`) REFERENCES `razaofim` (`id`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Constraints for table `medicoessala`
--
ALTER TABLE `medicoessala`
  ADD CONSTRAINT `medicoessala_ibfk_1` FOREIGN KEY (`idexperiencia`) REFERENCES `experiencia` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `odoresexperiencia`
--
ALTER TABLE `odoresexperiencia`
  ADD CONSTRAINT `odoresexperiencia_ibfk_1` FOREIGN KEY (`idexperiencia`) REFERENCES `experiencia` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `substanciasexperiencia`
--
ALTER TABLE `substanciasexperiencia`
  ADD CONSTRAINT `substanciasexperiencia_ibfk_1` FOREIGN KEY (`idexperiencia`) REFERENCES `experiencia` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
