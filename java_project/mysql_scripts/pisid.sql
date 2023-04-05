-- phpMyAdmin SQL Dump
-- version 5.2.0
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1:3307
-- Generation Time: Apr 05, 2023 at 07:12 PM
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

SELECT COUNT(1) INTO IDExp 
FROM experiencia
WHERE experiencia.id = GetOngoingExpId();

IF IDExp = 1 THEN
CALL TerminateOngoingExp(CURRENT_TIMESTAMP);
END IF;

UPDATE experiencia
SET DataHoraInicio = dataInicio
-- proxima exp a decorrer
WHERE id = (SELECT id FROM experiencia WHERE DataHoraInicio is NULL LIMIT 1);

END$$

DROP PROCEDURE IF EXISTS `TerminateOngoingExp`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `TerminateOngoingExp` (IN `dataFim` TIMESTAMP)  NO SQL BEGIN

UPDATE experiencia
SET DataHoraFim = dataFim
WHERE experiencia.id = GetOngoingExpId();

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
) ENGINE=InnoDB AUTO_INCREMENT=1025 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

--
-- Dumping data for table `alerta`
--

INSERT INTO `alerta` (`id`, `hora`, `sala`, `sensor`, `leitura`, `tipo`, `mensagem`, `horaescrita`) VALUES
(1022, '2023-04-05 18:38:33', NULL, 1, '5.00', 'URGENT', 'PLS STOP', '2023-04-05 18:38:33'),
(1023, '2023-04-05 19:06:33', 1, NULL, NULL, 'URGENT', 'PLS STOP', '2023-04-05 19:06:33'),
(1024, '2023-04-05 19:09:40', NULL, 1, '60.00', 'URGENT', 'Temperatura muito alta', '2023-04-05 19:09:40');

--
-- Triggers `alerta`
--
DROP TRIGGER IF EXISTS `TerminateExpUrgentAlert`;
DELIMITER $$
CREATE TRIGGER `TerminateExpUrgentAlert` AFTER INSERT ON `alerta` FOR EACH ROW BEGIN

IF NEW.tipo = 'URGENT' THEN
	CALL TerminateOngoingExp(NEW.hora);
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
  `DataHoraInicio` timestamp NULL DEFAULT NULL ON UPDATE current_timestamp(),
  `DataHoraFim` timestamp NULL DEFAULT NULL,
  `numeroratos` int(11) NOT NULL,
  `limiteratossala` int(11) NOT NULL,
  `segundossemmovimento` int(11) NOT NULL,
  `temperaturaideal` decimal(4,2) NOT NULL,
  `variacaotemperaturamaxima` decimal(4,2) NOT NULL,
  `idrazaofim` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `investigador` (`investigador`),
  KEY `idrazaofim` (`idrazaofim`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

--
-- Dumping data for table `experiencia`
--

INSERT INTO `experiencia` (`id`, `descricao`, `investigador`, `DataHoraInicio`, `DataHoraFim`, `numeroratos`, `limiteratossala`, `segundossemmovimento`, `temperaturaideal`, `variacaotemperaturamaxima`, `idrazaofim`) VALUES
(1, 'ww', NULL, '2023-03-17 21:34:58', '2023-03-17 21:35:04', 3, 3, 3, '22.00', '10.00', NULL),
(2, 'ww', NULL, '2023-04-05 18:33:58', '2023-04-05 18:33:58', 3, 3, 3, '22.22', '10.22', NULL),
(6, '', NULL, '2023-04-05 18:34:33', '2023-04-05 18:34:33', 2, 2, 2, '2.00', '2.00', NULL),
(7, '', NULL, '2023-04-05 18:34:56', '2023-04-05 18:34:50', 2, 2, 2, '2.00', '2.00', NULL),
(8, '', NULL, '2023-04-05 19:09:40', '2023-04-05 19:09:40', 2, 2, 2, '2.00', '2.00', NULL);

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
) ENGINE=InnoDB AUTO_INCREMENT=187 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

--
-- Dumping data for table `medicoespassagens`
--

INSERT INTO `medicoespassagens` (`id`, `hora`, `salaentrada`, `salasaida`) VALUES
(155, '2023-04-05 17:43:03', 0, 0),
(157, '2023-04-05 17:43:20', 2, 2),
(159, '2023-04-05 17:45:57', 1, 1),
(162, '2023-04-05 17:54:09', 22, 22),
(164, '2023-04-05 17:55:35', 1, 1),
(168, '2023-04-05 17:59:28', 6, 4),
(169, '2023-04-05 18:02:01', 1, 1),
(171, '2023-04-05 18:33:58', 0, 0),
(172, '2023-04-05 18:34:33', 0, 0),
(173, '2023-04-05 18:35:10', 0, 0),
(174, '2023-04-05 18:36:13', 0, 0),
(175, '2023-04-05 18:56:23', 6, 4),
(176, '2023-04-05 18:56:52', 6, 4),
(177, '2023-04-05 18:57:21', 4, 6),
(178, '2023-04-05 18:57:48', 2, 1),
(179, '2023-04-05 18:58:06', 2, 1),
(180, '2023-04-05 19:00:27', 1, 2),
(181, '2023-04-05 19:00:42', 1, 2),
(182, '2023-04-05 19:01:06', 1, 2),
(183, '2023-04-05 19:04:25', 1, 2),
(184, '2023-04-05 19:04:28', 1, 2),
(186, '2023-04-05 19:06:33', 1, 2);

--
-- Triggers `medicoespassagens`
--
DROP TRIGGER IF EXISTS `CreateAlertFullRoom`;
DELIMITER $$
CREATE TRIGGER `CreateAlertFullRoom` AFTER INSERT ON `medicoespassagens` FOR EACH ROW BEGIN

DECLARE nr_ratos, max_ratos INT;
SET nr_ratos = GetRatsInRoom(NEW.salaentrada);

SELECT experiencia.limiteratossala INTO max_ratos
FROM experiencia
WHERE experiencia.id = GetOngoingExpId();

IF (nr_ratos > max_ratos) THEN
	INSERT INTO alerta (hora,sala,sensor,leitura,tipo,mensagem,horaescrita)
    VALUES (NEW.hora,NEW.salaentrada,null,null,'URGENT','Excedeu numero de ratos',CURRENT_TIMESTAMP());
END IF;

END
$$
DELIMITER ;
DROP TRIGGER IF EXISTS `RatsCount`;
DELIMITER $$
CREATE TRIGGER `RatsCount` AFTER INSERT ON `medicoespassagens` FOR EACH ROW BEGIN

DECLARE expID, salaEntradaExiste, salaSaidaExiste INT;
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
(2, -1, 4),
(2, 1, 6),
(8, 3, 1),
(8, -3, 2);

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
) ENGINE=InnoDB AUTO_INCREMENT=1212 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

--
-- Dumping data for table `medicoestemperatura`
--

INSERT INTO `medicoestemperatura` (`id`, `hora`, `leitura`, `sensor`) VALUES
(1209, '2023-04-05 18:38:33', '5.00', 1),
(1210, '2023-04-05 19:09:20', '60.00', 1),
(1211, '2023-04-05 19:09:40', '60.00', 1);

--
-- Triggers `medicoestemperatura`
--
DROP TRIGGER IF EXISTS `CreateAlert`;
DELIMITER $$
CREATE TRIGGER `CreateAlert` AFTER INSERT ON `medicoestemperatura` FOR EACH ROW BEGIN
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
      VALUES (NEW.hora, NULL, NEW.sensor, NEW.leitura, 'URGENT', 'Temperatura muito alta', CURRENT_TIMESTAMP());
    ELSEIF ((NEW.leitura) < temp_ideal - var_max_temp) THEN
      INSERT INTO alerta (hora, sala, sensor, leitura, tipo, mensagem, horaescrita)
      VALUES (NEW.hora, NULL, NEW.sensor, NEW.leitura, 'URGENT', 'Temperatura muito baixa', CURRENT_TIMESTAMP());
    ELSEIF ((NEW.leitura) > temp_ideal + var_max_temp * 0.9) THEN
      INSERT INTO alerta (hora, sala, sensor, leitura, tipo, mensagem, horaescrita)
      VALUES (NEW.hora, NULL, NEW.sensor, NEW.leitura, 'LIGHT', 'Temperatura perto do limite máximo', CURRENT_TIMESTAMP());
    ELSEIF ((NEW.leitura) < temp_ideal - var_max_temp * 0.9) THEN
      INSERT INTO alerta (hora, sala, sensor, leitura, tipo, mensagem, horaescrita)
      VALUES (NEW.hora, NULL, NEW.sensor, NEW.leitura, 'LIGHT', 'Temperatura perto do limite mínimo', CURRENT_TIMESTAMP());
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
  `id` int(11) NOT NULL,
  `descricao` varchar(50) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

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
  ADD CONSTRAINT `experiencia_ibfk_2` FOREIGN KEY (`idrazaofim`) REFERENCES `razaofim` (`id`) ON DELETE SET NULL ON UPDATE CASCADE;

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
