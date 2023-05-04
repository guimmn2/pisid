-- phpMyAdmin SQL Dump
-- version 5.2.0
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1:3307
-- Generation Time: May 04, 2023 at 02:13 PM
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
CREATE DEFINER=`root`@`localhost` PROCEDURE `StartNextExp` (IN `startTime` TIMESTAMP)  NO SQL BEGIN

DECLARE i INT DEFAULT 2;
DECLARE nrRooms, id_exp, id_exists INT;

SELECT IDExperiencia INTO id_exp FROM parametrosadicionais 
WHERE parametrosadicionais.DataHoraInicio is NULL LIMIT 1;

UPDATE parametrosadicionais
SET parametrosadicionais.DataHoraInicio = startTime
WHERE IDExperiencia = id_exp;

SELECT numerosalas INTO nrRooms FROM configuracaolabirinto
ORDER BY IDConfiguracao DESC LIMIT 1;

SELECT COUNT(*) INTO id_exists FROM medicoessala
WHERE medicoessala.IDExperiencia = id_exp;

IF id_exists = 1 THEN
    WHILE i <= nrRooms DO
        INSERT INTO medicoessala (IDExperiencia, numeroratosfinal, sala)
        VALUES (id_exp, 0, i);  
    SET i = i + 1;
    END WHILE;
END IF;

END$$

DROP PROCEDURE IF EXISTS `TerminateOngoingExp`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `TerminateOngoingExp` (IN `endTime` TIMESTAMP, IN `endReason` VARCHAR(50))  NO SQL BEGIN

UPDATE parametrosadicionais
SET parametrosadicionais.DataHoraFim = endTime, parametrosadicionais.MotivoTermino = endReason
WHERE parametrosadicionais.IDExperiencia = GetOngoingExpId();
END$$

DROP PROCEDURE IF EXISTS `WriteAlert`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `WriteAlert` (IN `hour` TIMESTAMP, IN `room` INT, IN `sensor` INT, IN `sensor_reading` DECIMAL(4,2), IN `type` VARCHAR(50), IN `message` VARCHAR(50), IN `writtenHour` TIMESTAMP)   BEGIN

IF OngoingExp() THEN
	INSERT INTO alerta (hora, sala, sensor, leitura, tipo, mensagem, horaescrita, IDExperiencia)
	VALUES (hour, room, sensor, sensor_reading, type, message, writtenHour, GetOngoingExpId());
END IF;
END$$

DROP PROCEDURE IF EXISTS `WriteConfig`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `WriteConfig` (IN `set_temperature` DECIMAL(4,2), IN `open_doors` INT, IN `nrRooms` INT)   BEGIN

DECLARE configExists INT;

SELECT COUNT(*) INTO configExists 
FROM configuracaolabirinto;

IF configExists > 0 THEN
    UPDATE configuracaolabirinto
    SET 
    configuracaolabirinto.temperaturaprogramada = set_temperature,
    configuracaolabirinto.segundosaberturaportaexterior = open_doors,
    configuracaolabirinto.numerosalas = nrRooms
    WHERE configuracaolabirinto.IDConfiguracao = 0;
ELSE
    INSERT INTO configuracaolabirinto(IDConfiguracao, temperaturaprogramada, segundosaberturaportaexterior, numerosalas)
    VALUES(0,set_temperature, open_doors,nrRooms);
END IF;
END$$

DROP PROCEDURE IF EXISTS `WriteMov`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `WriteMov` (IN `id_mongo` VARCHAR(100), IN `hour` TIMESTAMP, IN `entryRoom` INT, IN `exitRoom` INT)  NO SQL BEGIN

DECLARE duplicate INT;

SELECT COUNT(*) into duplicate
FROM medicoespassagens
WHERE medicoespassagens.IDMongo = id_mongo;

IF duplicate = 0 THEN
    IF (entryRoom + exitRoom) = 0 THEN
        INSERT INTO medicoespassagens (IDMongo, hora, salaentrada, salasaida, IDExperiencia)
        VALUES (id_mongo, hour, entryRoom, exitRoom, NULL);
    ELSEIF OngoingExp() THEN
        INSERT INTO medicoespassagens (IDMongo, hora, salaentrada, salasaida, IDExperiencia)
        VALUES (id_mongo, hour, entryRoom, exitRoom, GetOngoingExpId());
    END IF;
END IF;
END$$

DROP PROCEDURE IF EXISTS `WriteTemp`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `WriteTemp` (IN `id_mongo` VARCHAR(100), IN `sensor` INT, IN `hour` TIMESTAMP, IN `sensor_reading` DECIMAL(4,2))  NO SQL BEGIN

DECLARE duplicate INT;

SELECT COUNT(*) into duplicate
FROM medicoestemperatura
WHERE medicoestemperatura.IDMongo = id_mongo;

IF duplicate = 0 THEN
    IF OngoingExp() THEN
        INSERT INTO medicoestemperatura (IDMongo, sensor, hora, leitura, IDExperiencia) 
        VALUES (id_mongo, sensor, hour, sensor_reading, GetOngoingExpId());
    END IF;
END IF;
END$$

--
-- Functions
--
DROP FUNCTION IF EXISTS `GetOngoingExpId`$$
CREATE DEFINER=`root`@`localhost` FUNCTION `GetOngoingExpId` () RETURNS INT(11) NO SQL BEGIN
	-- id da exp a decorrer
    DECLARE ongoing_exp_id INT;
    
    SELECT parametrosadicionais.IDExperiencia INTO ongoing_exp_id
    FROM parametrosadicionais 
    WHERE parametrosadicionais.DataHoraInicio IS NOT NULL 
    AND parametrosadicionais.DataHoraFim IS NULL;
    
    IF ongoing_exp_id IS NULL THEN
    RETURN -1;
    ELSE
    RETURN ongoing_exp_id;
    END IF;
END$$

DROP FUNCTION IF EXISTS `GetRatsInRoom`$$
CREATE DEFINER=`root`@`localhost` FUNCTION `GetRatsInRoom` (`nrRoom` INT) RETURNS INT(11) NO SQL BEGIN

DECLARE nr_rats INT;

SELECT numeroratosfinal INTO nr_rats 
FROM medicoessala
WHERE medicoessala.sala = nrRoom AND medicoessala.idexperiencia = GetOngoingExpId();

RETURN nr_rats;

END$$

DROP FUNCTION IF EXISTS `OngoingExp`$$
CREATE DEFINER=`root`@`localhost` FUNCTION `OngoingExp` () RETURNS TINYINT(1) NO SQL BEGIN-- id da exp a decorrer
    DECLARE ongoing_exp_id INT;
    SELECT parametrosadicionais.IDExperiencia INTO ongoing_exp_id
    FROM parametrosadicionais 
    WHERE parametrosadicionais.DataHoraInicio IS NOT NULL 
    AND parametrosadicionais.DataHoraFim IS NULL;
    
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
  `hora` timestamp NOT NULL DEFAULT current_timestamp(),
  `sala` int(11) DEFAULT NULL,
  `sensor` int(11) DEFAULT NULL,
  `leitura` decimal(4,2) DEFAULT NULL,
  `tipo` varchar(20) DEFAULT NULL,
  `mensagem` varchar(100) DEFAULT NULL,
  `horaescrita` timestamp NOT NULL DEFAULT current_timestamp(),
  `IDExperiencia` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `IDExperiencia` (`IDExperiencia`)
) ENGINE=InnoDB AUTO_INCREMENT=432714 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `alerta`
--

INSERT INTO `alerta` (`id`, `hora`, `sala`, `sensor`, `leitura`, `tipo`, `mensagem`, `horaescrita`, `IDExperiencia`) VALUES
(432694, '2023-05-03 22:46:35', NULL, NULL, NULL, 'MongoDB_status', 'MongoDB is up!', '2023-05-03 22:46:36', 32),
(432695, '2023-05-03 22:02:44', NULL, NULL, NULL, 'descartada', '{Leitura:3@, Sensor:2}', '2023-05-03 22:46:37', 32),
(432696, '2023-05-03 22:47:39', NULL, NULL, NULL, 'MongoDB_status', 'MongoDB is down!', '2023-05-03 22:48:42', 32),
(432697, '2023-05-03 22:49:20', NULL, NULL, NULL, 'MongoDB_status', 'MongoDB is up!', '2023-05-03 22:49:20', 32),
(432698, '2023-05-03 22:49:25', NULL, NULL, NULL, 'descartada', '{Leitura:3@, Sensor:2}', '2023-05-03 22:49:27', 32),
(432699, '2023-05-03 22:49:25', 1, NULL, NULL, 'light_mov', 'Rapida movimentacao de ratos na sala 1', '2023-05-03 22:49:29', 32),
(432700, '2023-05-03 22:49:35', 6, NULL, NULL, 'light_mov', 'Rapida movimentacao de ratos na sala 6', '2023-05-03 22:49:40', 32),
(432701, '2023-05-03 22:50:39', NULL, NULL, NULL, 'MongoDB_status', 'MongoDB is up!', '2023-05-03 22:50:39', 32),
(432702, '2023-05-03 22:50:03', 10, NULL, NULL, 'light_mov', 'Rapida movimentacao de ratos na sala 10', '2023-05-03 22:50:46', 32),
(432703, '2023-05-03 22:50:06', 6, NULL, NULL, 'light_mov', 'Rapida movimentacao de ratos na sala 6', '2023-05-03 22:50:47', 32),
(432704, '2023-05-03 22:50:06', 1, NULL, NULL, 'light_mov', 'Rapida movimentacao de ratos na sala 1', '2023-05-03 22:50:47', 32),
(432705, '2023-05-03 22:50:22', 5, NULL, NULL, 'light_mov', 'Rapida movimentacao de ratos na sala 5', '2023-05-03 22:50:49', 32),
(432706, '2023-05-03 22:49:57', NULL, NULL, NULL, 'descartada', '{Leitura:3@, Sensor:2}', '2023-05-03 22:50:52', 32),
(432707, '2023-05-03 22:50:33', NULL, NULL, NULL, 'descartada', '{Leitura:3@, Sensor:2}', '2023-05-03 22:50:53', 32),
(432708, '2023-05-03 22:50:50', 1, NULL, NULL, 'light_mov', 'Rapida movimentacao de ratos na sala 1', '2023-05-03 22:50:59', 32),
(432709, '2023-05-03 22:51:01', 7, NULL, NULL, 'light_mov', 'Rapida movimentacao de ratos na sala 7', '2023-05-03 22:51:05', 32),
(432710, '2023-05-03 22:51:01', 5, NULL, NULL, 'light_mov', 'Rapida movimentacao de ratos na sala 5', '2023-05-03 22:51:05', 32),
(432711, '2023-05-03 22:51:01', 6, NULL, NULL, 'light_mov', 'Rapida movimentacao de ratos na sala 6', '2023-05-03 22:51:05', 32),
(432712, '2023-05-03 22:51:10', NULL, NULL, NULL, 'descartada', '{Leitura:3@, Sensor:2}', '2023-05-03 22:51:12', 32),
(432713, '2023-05-03 23:56:59', NULL, NULL, NULL, 'MongoDB_status', 'MongoDB is down!', '2023-05-04 00:08:16', 32);

--
-- Triggers `alerta`
--
DROP TRIGGER IF EXISTS `AlertPeriodicity`;
DELIMITER $$
CREATE TRIGGER `AlertPeriodicity` BEFORE INSERT ON `alerta` FOR EACH ROW BEGIN

DECLARE time_alert TIMESTAMP;
DECLARE periodicity DOUBLE;
DECLARE alertExists, sensor INT;

SELECT parametrosadicionais.PeriodicidadeAlerta INTO periodicity
FROM parametrosadicionais
WHERE parametrosadicionais.IDExperiencia = GetOngoingExpId();


IF NEW.tipo = 'light_mov' THEN

SELECT COUNT(*) INTO alertExists
FROM alerta
WHERE alerta.tipo = NEW.tipo and alerta.sala = NEW.sala and alerta.IDExperiencia = GetOngoingExpId();

    IF alertExists > 0 THEN

        SELECT MAX(alerta.hora) into time_alert
        FROM alerta
        WHERE alerta.tipo = NEW.tipo and alerta.sala = NEW.sala and alerta.IDExperiencia = GetOngoingExpId();

        IF (TIMESTAMPDIFF(SECOND, time_alert, NEW.hora)) <  periodicity THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Alert periodicity';
        END IF;
    END IF;

ELSEIF NEW.tipo = 'light_temp' OR NEW.tipo = 'avaria' THEN  
    SELECT COUNT(*) INTO alertExists FROM alerta 
    WHERE alerta.tipo = NEW.tipo and alerta.sensor = NEW.sensor and alerta.IDExperiencia = GetOngoingExpId();

    IF alertExists > 0 THEN
        SELECT MAX(alerta.hora) into time_alert
        FROM alerta
        WHERE alerta.tipo = NEW.tipo and alerta.sensor = NEW.sensor and alerta.IDExperiencia = GetOngoingExpId();

        IF (TIMESTAMPDIFF(SECOND, time_alert, NEW.hora)) <  periodicity THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Alert periodicity';
        END IF;

    END IF;
       
ELSEIF NEW.tipo = 'MongoDB_status' OR NEW.tipo = 'descartada' THEN
    SELECT COUNT(*) INTO alertExists FROM alerta 
    WHERE alerta.tipo = NEW.tipo and alerta.IDExperiencia = GetOngoingExpId(); 

    IF alertExists > 0 THEN
        SELECT MAX(alerta.hora) into time_alert
        FROM alerta
        WHERE alerta.tipo = NEW.tipo and alerta.IDExperiencia = GetOngoingExpId(); 

        IF (TIMESTAMPDIFF(SECOND, time_alert, NEW.hora)) <  periodicity THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Alert periodicity';
        END IF;

    END IF;
END IF;

END
$$
DELIMITER ;
DROP TRIGGER IF EXISTS `TerminateExpUrgentAlert`;
DELIMITER $$
CREATE TRIGGER `TerminateExpUrgentAlert` AFTER INSERT ON `alerta` FOR EACH ROW BEGIN

IF NEW.tipo = 'urgent_mov' OR NEW.tipo = 'urgent_temp' THEN
    CALL TerminateOngoingExp(NEW.hora,NEW.mensagem);
END IF;

END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `configuracaolabirinto`
--

DROP TABLE IF EXISTS `configuracaolabirinto`;
CREATE TABLE IF NOT EXISTS `configuracaolabirinto` (
  `IDConfiguracao` int(11) NOT NULL DEFAULT 0,
  `temperaturaprogramada` decimal(4,2) DEFAULT NULL,
  `segundosaberturaportaexterior` int(11) DEFAULT NULL,
  `numerosalas` int(11) DEFAULT NULL,
  PRIMARY KEY (`IDConfiguracao`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `configuracaolabirinto`
--

INSERT INTO `configuracaolabirinto` (`IDConfiguracao`, `temperaturaprogramada`, `segundosaberturaportaexterior`, `numerosalas`) VALUES
(0, '18.00', 20, 10);

-- --------------------------------------------------------

--
-- Table structure for table `experiencia`
--

DROP TABLE IF EXISTS `experiencia`;
CREATE TABLE IF NOT EXISTS `experiencia` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `descricao` text CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `investigador` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `DataRegisto` timestamp NULL DEFAULT current_timestamp(),
  `numeroratos` int(11) DEFAULT NULL,
  `limiteratossala` int(11) DEFAULT NULL,
  `segundossemmovimento` int(11) DEFAULT NULL,
  `temperaturaideal` decimal(4,2) DEFAULT NULL,
  `variacaotemperaturamaxima` decimal(4,2) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `investigador` (`investigador`)
) ENGINE=InnoDB AUTO_INCREMENT=33 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `experiencia`
--

INSERT INTO `experiencia` (`id`, `descricao`, `investigador`, `DataRegisto`, `numeroratos`, `limiteratossala`, `segundossemmovimento`, `temperaturaideal`, `variacaotemperaturamaxima`) VALUES
(32, NULL, NULL, '2023-05-03 22:42:01', 40, 30, 9999, '10.00', '90.00');

--
-- Triggers `experiencia`
--
DROP TRIGGER IF EXISTS `SetParameters`;
DELIMITER $$
CREATE TRIGGER `SetParameters` AFTER INSERT ON `experiencia` FOR EACH ROW BEGIN

INSERT INTO parametrosadicionais(IDExperiencia)
VALUES(NEW.id);

INSERT INTO medicoessala(IDExperiencia, numeroratosfinal, sala) VALUES (new.id, new.numeroratos, 1);

END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `medicoespassagens`
--

DROP TABLE IF EXISTS `medicoespassagens`;
CREATE TABLE IF NOT EXISTS `medicoespassagens` (
  `IDMongo` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `hora` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `salaentrada` int(11) DEFAULT NULL,
  `salasaida` int(11) DEFAULT NULL,
  `IDExperiencia` int(11) DEFAULT NULL,
  PRIMARY KEY (`IDMongo`),
  KEY `IDExperiencia` (`IDExperiencia`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `medicoespassagens`
--

INSERT INTO `medicoespassagens` (`IDMongo`, `hora`, `salaentrada`, `salasaida`, `IDExperiencia`) VALUES
('6452e44c47ae33230301c356', '2023-05-03 22:46:31', 0, 0, NULL),
('6452e4bb47ae33230301c4da', '2023-05-03 22:48:15', 1, 2, 32),
('6452e4bb47ae33230301c4db', '2023-05-03 22:48:15', 1, 2, 32),
('6452e4bc47ae33230301c4dc', '2023-05-03 22:48:15', 2, 5, 32),
('6452e4bc47ae33230301c4df', '2023-05-03 22:48:15', 2, 5, 32),
('6452e4c147ae33230301c4f0', '2023-05-03 22:48:15', 5, 6, 32),
('6452e4c147ae33230301c4f5', '2023-05-03 22:48:15', 1, 2, 32),
('6452e4efd19d36652db8d9c8', '2023-05-03 22:49:18', 2, 4, 32),
('6452e4f0d19d36652db8d9ca', '2023-05-03 22:49:18', 5, 7, 32),
('6452e4f4d19d36652db8d9db', '2023-05-03 22:49:18', 7, 5, 32),
('6452e4f4d19d36652db8d9de', '2023-05-03 22:49:18', 1, 2, 32),
('6452e4f5d19d36652db8d9df', '2023-05-03 22:49:18', 2, 5, 32),
('6452e4f6d19d36652db8d9e6', '2023-05-03 22:49:25', 5, 6, 32),
('6452e4f7d19d36652db8d9ec', '2023-05-03 22:49:25', 4, 5, 32),
('6452e4f7d19d36652db8d9ed', '2023-05-03 22:49:25', 1, 2, 32),
('6452e4f9d19d36652db8d9f2', '2023-05-03 22:49:25', 5, 7, 32),
('6452e4f9d19d36652db8d9f3', '2023-05-03 22:49:25', 7, 5, 32),
('6452e4fad19d36652db8d9f6', '2023-05-03 22:49:25', 5, 7, 32),
('6452e4fad19d36652db8d9f7', '2023-05-03 22:49:25', 5, 6, 32),
('6452e4fad19d36652db8d9fb', '2023-05-03 22:49:25', 1, 2, 32),
('6452e4fbd19d36652db8d9fc', '2023-05-03 22:49:25', 2, 5, 32),
('6452e4fdd19d36652db8da05', '2023-05-03 22:49:25', 6, 8, 32),
('6452e4fed19d36652db8da08', '2023-05-03 22:49:25', 2, 4, 32),
('6452e4ffd19d36652db8da0b', '2023-05-03 22:49:25', 8, 10, 32),
('6452e4ffd19d36652db8da0f', '2023-05-03 22:49:25', 5, 6, 32),
('6452e500d19d36652db8da14', '2023-05-03 22:49:35', 7, 5, 32),
('6452e500d19d36652db8da16', '2023-05-03 22:49:35', 4, 5, 32),
('6452e501d19d36652db8da19', '2023-05-03 22:49:35', 5, 6, 32),
('6452e503d19d36652db8da22', '2023-05-03 22:49:35', 5, 6, 32),
('6452e506d19d36652db8da36', '2023-05-03 22:49:35', 6, 8, 32),
('6452e508d19d36652db8da3f', '2023-05-03 22:49:35', 6, 8, 32),
('6452e509d19d36652db8da42', '2023-05-03 22:49:35', 1, 2, 32),
('6452e50ad19d36652db8da47', '2023-05-03 22:49:35', 6, 8, 32),
('6452e50ed19d36652db8da52', '2023-05-03 22:49:35', 6, 8, 32),
('6452e50fd19d36652db8da5c', '2023-05-03 22:49:35', 2, 4, 32),
('6452e511d19d36652db8da66', '2023-05-03 22:49:35', 8, 10, 32),
('6452e515d19d36652db8da7a', '2023-05-03 22:49:54', 8, 10, 32),
('6452e517d19d36652db8da85', '2023-05-03 22:49:57', 8, 10, 32),
('6452e518d19d36652db8da89', '2023-05-03 22:49:57', 1, 2, 32),
('6452e51bd19d36652db8da96', '2023-05-03 22:49:57', 4, 5, 32),
('6452e51bd19d36652db8da97', '2023-05-03 22:49:57', 5, 7, 32),
('6452e51cd19d36652db8da9d', '2023-05-03 22:50:03', 8, 10, 32),
('6452e51ed19d36652db8daa7', '2023-05-03 22:50:05', 1, 2, 32),
('6452e51fd19d36652db8daaa', '2023-05-03 22:50:06', 2, 5, 32),
('6452e520d19d36652db8daae', '2023-05-03 22:50:06', 6, 8, 32),
('6452e521d19d36652db8dab2', '2023-05-03 22:50:06', 5, 7, 32),
('6452e521d19d36652db8dab3', '2023-05-03 22:50:06', 1, 2, 32),
('6452e522d19d36652db8dab7', '2023-05-03 22:50:06', 2, 4, 32),
('6452e522d19d36652db8dab9', '2023-05-03 22:50:06', 2, 4, 32),
('6452e526d19d36652db8dac7', '2023-05-03 22:50:06', 4, 5, 32),
('6452e526d19d36652db8dac9', '2023-05-03 22:50:06', 7, 5, 32),
('6452e529d19d36652db8dad3', '2023-05-03 22:50:06', 5, 7, 32),
('6452e52ad19d36652db8dad7', '2023-05-03 22:50:06', 5, 7, 32),
('6452e52ad19d36652db8dad8', '2023-05-03 22:50:06', 4, 5, 32),
('6452e52ad19d36652db8dada', '2023-05-03 22:50:06', 1, 2, 32),
('6452e52ad19d36652db8dadb', '2023-05-03 22:50:06', 1, 2, 32),
('6452e52bd19d36652db8dade', '2023-05-03 22:50:06', 5, 6, 32),
('6452e52cd19d36652db8dae1', '2023-05-03 22:50:06', 2, 5, 32),
('6452e52ed19d36652db8dae6', '2023-05-03 22:50:20', 2, 5, 32),
('6452e52ed19d36652db8dae7', '2023-05-03 22:50:20', 6, 8, 32),
('6452e52fd19d36652db8daeb', '2023-05-03 22:50:22', 8, 10, 32),
('6452e530d19d36652db8daee', '2023-05-03 22:50:22', 7, 5, 32),
('6452e530d19d36652db8daf1', '2023-05-03 22:50:22', 5, 7, 32),
('6452e530d19d36652db8daf3', '2023-05-03 22:50:22', 1, 2, 32),
('6452e531d19d36652db8daf7', '2023-05-03 22:50:22', 2, 5, 32),
('6452e531d19d36652db8daf8', '2023-05-03 22:50:22', 7, 5, 32),
('6452e532d19d36652db8dafc', '2023-05-03 22:50:22', 7, 5, 32),
('6452e532d19d36652db8dafd', '2023-05-03 22:50:22', 8, 10, 32),
('6452e532d19d36652db8dafe', '2023-05-03 22:50:22', 5, 6, 32),
('6452e533d19d36652db8db02', '2023-05-03 22:50:22', 5, 7, 32),
('6452e534d19d36652db8db07', '2023-05-03 22:50:22', 5, 6, 32),
('6452e536d19d36652db8db0d', '2023-05-03 22:50:22', 5, 6, 32),
('6452e539d19d36652db8db16', '2023-05-03 22:50:22', 7, 5, 32),
('6452e539d19d36652db8db18', '2023-05-03 22:50:22', 7, 5, 32),
('6452e539d19d36652db8db1b', '2023-05-03 22:50:33', 6, 8, 32),
('6452e53bd19d36652db8db22', '2023-05-03 22:50:33', 8, 9, 32),
('6452e53cd19d36652db8db28', '2023-05-03 22:50:33', 1, 2, 32),
('6452e53dd19d36652db8db2c', '2023-05-03 22:50:33', 2, 5, 32),
('6452e541d19d36652db8db39', '2023-05-03 22:50:33', 6, 8, 32),
('6452e541d19d36652db8db3c', '2023-05-03 22:50:33', 9, 7, 32),
('6452e542d19d36652db8db42', '2023-05-03 22:50:33', 7, 5, 32),
('6452e545d19d36652db8db4d', '2023-05-03 22:50:33', 8, 9, 32),
('6452e54ad19d36652db8db65', '2023-05-03 22:50:49', 6, 8, 32),
('6452e54ed19d36652db8db7a', '2023-05-03 22:50:50', 8, 9, 32),
('6452e551d19d36652db8db8b', '2023-05-03 22:50:50', 1, 2, 32),
('6452e554d19d36652db8db95', '2023-05-03 22:50:50', 2, 4, 32),
('6452e554d19d36652db8db97', '2023-05-03 22:50:50', 4, 5, 32),
('6452e557d19d36652db8dba3', '2023-05-03 22:51:01', 9, 7, 32),
('6452e557d19d36652db8dba4', '2023-05-03 22:51:01', 5, 6, 32),
('6452e557d19d36652db8dba5', '2023-05-03 22:51:01', 5, 7, 32),
('6452e557d19d36652db8dba7', '2023-05-03 22:51:01', 1, 2, 32),
('6452e558d19d36652db8dbaa', '2023-05-03 22:51:01', 5, 6, 32),
('6452e558d19d36652db8dbab', '2023-05-03 22:51:01', 9, 7, 32),
('6452e558d19d36652db8dbac', '2023-05-03 22:51:01', 2, 5, 32),
('6452e559d19d36652db8dbaf', '2023-05-03 22:51:01', 7, 5, 32),
('6452e559d19d36652db8dbb1', '2023-05-03 22:51:01', 5, 6, 32),
('6452e55ad19d36652db8dbb4', '2023-05-03 22:51:01', 6, 8, 32),
('6452e55ad19d36652db8dbb6', '2023-05-03 22:51:01', 5, 7, 32),
('6452e55ad19d36652db8dbb8', '2023-05-03 22:51:01', 1, 2, 32),
('6452e55cd19d36652db8dbbf', '2023-05-03 22:51:01', 7, 5, 32),
('6452e55dd19d36652db8dbc2', '2023-05-03 22:51:01', 6, 8, 32),
('6452e55dd19d36652db8dbc3', '2023-05-03 22:51:01', 5, 7, 32),
('6452e55dd19d36652db8dbc4', '2023-05-03 22:51:01', 7, 5, 32),
('6452e55ed19d36652db8dbc8', '2023-05-03 22:51:01', 2, 5, 32),
('6452e55ed19d36652db8dbc9', '2023-05-03 22:51:01', 8, 9, 32),
('6452e55fd19d36652db8dbcc', '2023-05-03 22:51:10', 8, 9, 32),
('6452e55fd19d36652db8dbce', '2023-05-03 22:51:10', 5, 6, 32),
('6452e560d19d36652db8dbd2', '2023-05-03 22:51:10', 7, 5, 32),
('6452e560d19d36652db8dbd4', '2023-05-03 22:51:10', 9, 7, 32),
('6452e560d19d36652db8dbd5', '2023-05-03 22:51:10', 5, 7, 32),
('6452e562d19d36652db8dbdd', '2023-05-03 22:51:10', 6, 8, 32),
('6452e562d19d36652db8dbde', '2023-05-03 22:51:10', 8, 10, 32),
('6452e562d19d36652db8dbe0', '2023-05-03 22:51:10', 5, 6, 32),
('6452e564d19d36652db8dbe7', '2023-05-03 22:51:10', 9, 7, 32),
('6452e565d19d36652db8dbeb', '2023-05-03 22:51:10', 5, 6, 32),
('6452e566d19d36652db8dbf1', '2023-05-03 22:51:17', 7, 5, 32),
('6452e568d19d36652db8dbf9', '2023-05-03 22:51:18', 6, 8, 32),
('6452e568d19d36652db8dbfa', '2023-05-03 22:51:18', 5, 6, 32),
('6452e569d19d36652db8dbff', '2023-05-03 22:51:18', 7, 5, 32),
('6452e569d19d36652db8dc00', '2023-05-03 22:51:18', 6, 8, 32),
('6452e569d19d36652db8dc02', '2023-05-03 22:51:18', 1, 2, 32),
('6452e56cd19d36652db8dc0c', '2023-05-03 22:51:18', 7, 5, 32),
('6452f17c9e071e5c8bcbdf0d', '2023-05-03 23:42:41', 0, 0, NULL);

--
-- Triggers `medicoespassagens`
--
DROP TRIGGER IF EXISTS `CheckRatsMov`;
DELIMITER $$
CREATE TRIGGER `CheckRatsMov` BEFORE INSERT ON `medicoespassagens` FOR EACH ROW BEGIN

DECLARE time_no_mov INT;

SELECT experiencia.segundossemmovimento INTO time_no_mov FROM experiencia 
WHERE experiencia.id = GetOngoingExpId();

IF TIMESTAMPDIFF(SECOND, (SELECT MAX(hora) FROM medicoespassagens), NOW()) > time_no_mov THEN
    INSERT INTO alerta(alerta.hora,alerta.tipo,alerta.mensagem,alerta.horaescrita)
    VALUES (CURRENT_TIMESTAMP, 'urgent_mov', "Não houve movimento dos ratos", CURRENT_TIMESTAMP);
END IF;
END
$$
DELIMITER ;
DROP TRIGGER IF EXISTS `RatsCount`;
DELIMITER $$
CREATE TRIGGER `RatsCount` AFTER INSERT ON `medicoespassagens` FOR EACH ROW BEGIN

DECLARE expID, nRoomRatLeft, nRoomRatJoin, nr_rats, max_rats INT;

SET expID = GetOngoingExpId();

IF NEW.salaentrada <> NEW.salasaida THEN 

SELECT COUNT(*) into nRoomRatLeft
FROM medicoessala
WHERE medicoessala.idexperiencia = expID and medicoessala.sala = NEW.salaentrada;

SELECT COUNT(*) into nRoomRatJoin
FROM medicoessala
WHERE medicoessala.idexperiencia = expID and medicoessala.sala = NEW.salasaida;

IF nRoomRatLeft = 1 THEN
    UPDATE medicoessala
    SET medicoessala.numeroratosfinal = GetRatsInRoom(NEW.salaentrada) - 1
    WHERE medicoessala.idexperiencia = expID and medicoessala.sala = NEW.salaentrada;
END IF;

IF nRoomRatJoin = 1 THEN
     UPDATE medicoessala
     SET medicoessala.numeroratosfinal = GetRatsInRoom(NEW.salasaida) + 1
     WHERE medicoessala.idexperiencia = expID and medicoessala.sala = NEW.salasaida;
END IF;

SET nr_rats = GetRatsInRoom(NEW.salasaida);

SELECT experiencia.limiteratossala INTO max_rats
FROM experiencia
WHERE experiencia.id = GetOngoingExpId();

IF (nr_rats > max_rats) THEN
    IF new.salasaida <> 1 THEN
        INSERT INTO alerta (hora,sala,sensor,leitura,tipo,mensagem,horaescrita)
        VALUES (NEW.hora,NEW.salasaida,null,null,'urgent_mov','Excedeu limite de ratos por sala',CURRENT_TIMESTAMP());
    END IF;
END IF;

END IF;

END
$$
DELIMITER ;
DROP TRIGGER IF EXISTS `StartExp`;
DELIMITER $$
CREATE TRIGGER `StartExp` AFTER INSERT ON `medicoespassagens` FOR EACH ROW BEGIN

DECLARE expExists, last_exp_id INT;
DECLARE end_time_last_exp, start_time_last_exp, opendoors_time_last_exp TIMESTAMP;

IF ((NEW.salaentrada + NEW.salasaida) = 0) THEN
    
    SELECT MAX(parametrosadicionais.IDExperiencia) INTO last_exp_id
    FROM parametrosadicionais
    WHERE parametrosadicionais.DataHoraInicio IS NOT NULL;
    
    SELECT parametrosadicionais.DataHoraFim INTO end_time_last_exp
    FROM parametrosadicionais
    WHERE parametrosadicionais.IDExperiencia = last_exp_id;
    
    SELECT parametrosadicionais.DataHoraInicio INTO start_time_last_exp
    FROM parametrosadicionais
    WHERE parametrosadicionais.IDExperiencia = last_exp_id;
    
    SELECT parametrosadicionais.DataHoraPortasExtAbertas INTO opendoors_time_last_exp
    FROM parametrosadicionais
    WHERE parametrosadicionais.IDExperiencia = last_exp_id;
    
    IF start_time_last_exp IS NOT NULL THEN
    	IF end_time_last_exp IS NULL THEN
        	CALL TerminateOngoingExp(NEW.hora,"Acabou sem anomalias");
    	ELSEIF opendoors_time_last_exp IS NOT NULL THEN
         	CALL StartNextExp(NEW.hora);
         END IF;
    ELSE
    	CALL StartNextExp(NEW.hora);
    END IF;
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
  `IDExperiencia` int(11) NOT NULL,
  `numeroratosfinal` int(11) DEFAULT NULL,
  `sala` int(11) NOT NULL,
  PRIMARY KEY (`IDExperiencia`,`sala`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `medicoessala`
--

INSERT INTO `medicoessala` (`IDExperiencia`, `numeroratosfinal`, `sala`) VALUES
(32, 22, 1),
(32, 1, 2),
(32, 0, 3),
(32, 0, 4),
(32, 4, 5),
(32, 2, 6),
(32, 1, 7),
(32, 2, 8),
(32, 0, 9),
(32, 8, 10);

--
-- Triggers `medicoessala`
--
DROP TRIGGER IF EXISTS `CreateMovAlert`;
DELIMITER $$
CREATE TRIGGER `CreateMovAlert` AFTER UPDATE ON `medicoessala` FOR EACH ROW BEGIN

DECLARE room_limit, nr_rats, alertExists INT;
DECLARE periodicity DOUBLE;
DECLARE time_last_alert TIMESTAMP;

SELECT parametrosadicionais.PeriodicidadeAlerta INTO periodicity
FROM parametrosadicionais
WHERE parametrosadicionais.IDExperiencia = NEW.IDExperiencia;

SELECT experiencia.limiteratossala INTO room_limit
FROM experiencia
WHERE experiencia.id = NEW.IDExperiencia;

SELECT medicoessala.numeroratosfinal INTO nr_rats
FROM medicoessala
WHERE medicoessala.sala = NEW.sala and medicoessala.IDExperiencia = NEW.IDExperiencia;

SELECT COUNT(*) INTO alertExists
FROM alerta
WHERE alerta.tipo = 'light_mov' and alerta.sala = NEW.sala;

IF NEW.sala <> 1 THEN
    IF nr_rats >= room_limit * 0.8 THEN
        IF alertExists > 0 THEN
            SELECT MAX(alerta.hora) INTO time_last_alert
            FROM alerta
            WHERE alerta.tipo = 'light_mov' and alerta.sala = NEW.sala;
            IF (TIMESTAMPDIFF(SECOND, time_last_alert, CURRENT_TIMESTAMP)) >= periodicity THEN
                INSERT INTO alerta(alerta.hora, alerta.sala, alerta.tipo,alerta.mensagem,alerta.horaescrita)
                VALUES(CURRENT_TIMESTAMP, NEW.sala, 'light_mov', 'Número de ratos na sala perto do limite', CURRENT_TIMESTAMP);
            END IF;
        ELSE
            INSERT INTO alerta(alerta.hora, alerta.sala, alerta.tipo,alerta.mensagem,alerta.horaescrita)
            VALUES(CURRENT_TIMESTAMP, NEW.sala, 'light_mov', 'Número de ratos na sala perto do limite', CURRENT_TIMESTAMP);
        END IF;    
    END IF;
END IF;
    
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `medicoestemperatura`
--

DROP TABLE IF EXISTS `medicoestemperatura`;
CREATE TABLE IF NOT EXISTS `medicoestemperatura` (
  `IDMongo` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `hora` timestamp NOT NULL DEFAULT current_timestamp(),
  `leitura` decimal(4,2) DEFAULT NULL,
  `sensor` int(11) DEFAULT NULL,
  `IDExperiencia` int(11) DEFAULT NULL,
  PRIMARY KEY (`IDMongo`),
  KEY `IDExperiencia` (`IDExperiencia`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `medicoestemperatura`
--

INSERT INTO `medicoestemperatura` (`IDMongo`, `hora`, `leitura`, `sensor`, `IDExperiencia`) VALUES
('6452da03b94a67144705c0b9', '2023-05-03 22:02:43', '14.00', 1, 32),
('6452e44847ae33230301c34b', '2023-05-03 22:46:31', '9.20', 1, 32),
('6452e44847ae33230301c34c', '2023-05-03 22:46:31', '14.00', 2, 32),
('6452e44947ae33230301c34d', '2023-05-03 22:46:31', '8.90', 1, 32),
('6452e44947ae33230301c34e', '2023-05-03 22:46:31', '14.00', 2, 32),
('6452e44a47ae33230301c34f', '2023-05-03 22:46:31', '8.60', 1, 32),
('6452e44a47ae33230301c350', '2023-05-03 22:46:31', '14.00', 2, 32),
('6452e44b47ae33230301c351', '2023-05-03 22:46:31', '8.30', 1, 32),
('6452e44b47ae33230301c352', '2023-05-03 22:46:31', '14.00', 2, 32),
('6452e44c47ae33230301c353', '2023-05-03 22:46:31', '8.00', 1, 32),
('6452e44c47ae33230301c354', '2023-05-03 22:46:31', '14.00', 2, 32),
('6452e44d47ae33230301c357', '2023-05-03 22:46:31', '8.00', 1, 32),
('6452e44d47ae33230301c358', '2023-05-03 22:46:31', '14.00', 2, 32),
('6452e4b347ae33230301c4b3', '2023-05-03 22:48:15', '9.50', 2, 32),
('6452e4b447ae33230301c4b8', '2023-05-03 22:48:15', '11.00', 1, 32),
('6452e4b447ae33230301c4b9', '2023-05-03 22:48:15', '9.20', 2, 32),
('6452e4b547ae33230301c4bb', '2023-05-03 22:48:15', '11.00', 1, 32),
('6452e4b547ae33230301c4bc', '2023-05-03 22:48:15', '9.20', 2, 32),
('6452e4b647ae33230301c4c1', '2023-05-03 22:48:15', '11.00', 1, 32),
('6452e4b647ae33230301c4c2', '2023-05-03 22:48:15', '9.20', 2, 32),
('6452e4b747ae33230301c4c7', '2023-05-03 22:48:15', '11.00', 1, 32),
('6452e4b747ae33230301c4c8', '2023-05-03 22:48:15', '9.20', 2, 32),
('6452e4b847ae33230301c4ca', '2023-05-03 22:48:15', '11.00', 1, 32),
('6452e4b847ae33230301c4cb', '2023-05-03 22:48:15', '9.20', 2, 32),
('6452e4b947ae33230301c4cf', '2023-05-03 22:48:15', '11.00', 1, 32),
('6452e4b947ae33230301c4d0', '2023-05-03 22:48:15', '9.20', 2, 32),
('6452e4ba47ae33230301c4d3', '2023-05-03 22:48:15', '11.00', 1, 32),
('6452e4ba47ae33230301c4d4', '2023-05-03 22:48:15', '9.20', 2, 32),
('6452e4bb47ae33230301c4d7', '2023-05-03 22:48:15', '10.70', 1, 32),
('6452e4bb47ae33230301c4d8', '2023-05-03 22:48:15', '9.20', 2, 32),
('6452e4bc47ae33230301c4dd', '2023-05-03 22:48:15', '10.40', 1, 32),
('6452e4bc47ae33230301c4de', '2023-05-03 22:48:15', '9.20', 2, 32),
('6452e4bd47ae33230301c4e0', '2023-05-03 22:48:15', '10.10', 1, 32),
('6452e4bd47ae33230301c4e1', '2023-05-03 22:48:15', '8.90', 2, 32),
('6452e4be47ae33230301c4e2', '2023-05-03 22:48:15', '9.80', 1, 32),
('6452e4be47ae33230301c4e3', '2023-05-03 22:48:15', '8.60', 2, 32),
('6452e4bf47ae33230301c4e6', '2023-05-03 22:48:15', '9.50', 1, 32),
('6452e4bf47ae33230301c4e7', '2023-05-03 22:48:15', '8.30', 2, 32),
('6452e4c047ae33230301c4ec', '2023-05-03 22:48:15', '9.20', 1, 32),
('6452e4c047ae33230301c4ed', '2023-05-03 22:48:15', '8.00', 2, 32),
('6452e4c147ae33230301c4f1', '2023-05-03 22:48:15', '8.90', 1, 32),
('6452e4c147ae33230301c4f2', '2023-05-03 22:48:15', '7.70', 2, 32),
('6452e4eed19d36652db8d9c4', '2023-05-03 22:49:18', '12.20', 2, 32),
('6452e4efd19d36652db8d9c6', '2023-05-03 22:49:18', '14.00', 1, 32),
('6452e4efd19d36652db8d9c7', '2023-05-03 22:49:18', '12.50', 2, 32),
('6452e4f0d19d36652db8d9cb', '2023-05-03 22:49:18', '14.00', 1, 32),
('6452e4f0d19d36652db8d9cc', '2023-05-03 22:49:18', '12.80', 2, 32),
('6452e4f1d19d36652db8d9cf', '2023-05-03 22:49:18', '14.00', 1, 32),
('6452e4f1d19d36652db8d9d0', '2023-05-03 22:49:18', '13.10', 2, 32),
('6452e4f2d19d36652db8d9d2', '2023-05-03 22:49:18', '14.00', 1, 32),
('6452e4f2d19d36652db8d9d3', '2023-05-03 22:49:18', '13.40', 2, 32),
('6452e4f3d19d36652db8d9d6', '2023-05-03 22:49:18', '14.00', 1, 32),
('6452e4f3d19d36652db8d9d7', '2023-05-03 22:49:18', '13.70', 2, 32),
('6452e4f4d19d36652db8d9d9', '2023-05-03 22:49:18', '14.00', 1, 32),
('6452e4f4d19d36652db8d9da', '2023-05-03 22:49:18', '14.00', 2, 32),
('6452e4f5d19d36652db8d9e3', '2023-05-03 22:49:18', '14.00', 1, 32),
('6452e4f6d19d36652db8d9e7', '2023-05-03 22:49:25', '14.00', 1, 32),
('6452e4f6d19d36652db8d9e8', '2023-05-03 22:49:25', '14.00', 2, 32),
('6452e4f7d19d36652db8d9ea', '2023-05-03 22:49:25', '14.00', 1, 32),
('6452e4f7d19d36652db8d9eb', '2023-05-03 22:49:25', '14.00', 2, 32),
('6452e4f8d19d36652db8d9ef', '2023-05-03 22:49:25', '14.00', 1, 32),
('6452e4f8d19d36652db8d9f1', '2023-05-03 22:49:25', '14.00', 2, 32),
('6452e4f9d19d36652db8d9f4', '2023-05-03 22:49:25', '14.00', 1, 32),
('6452e4f9d19d36652db8d9f5', '2023-05-03 22:49:25', '14.00', 2, 32),
('6452e4fad19d36652db8d9f9', '2023-05-03 22:49:25', '14.00', 1, 32),
('6452e4fad19d36652db8d9fa', '2023-05-03 22:49:25', '14.00', 2, 32),
('6452e4fbd19d36652db8d9fd', '2023-05-03 22:49:25', '14.00', 1, 32),
('6452e4fbd19d36652db8d9fe', '2023-05-03 22:49:25', '14.00', 2, 32),
('6452e4fcd19d36652db8da00', '2023-05-03 22:49:25', '14.00', 1, 32),
('6452e4fcd19d36652db8da01', '2023-05-03 22:49:25', '14.00', 2, 32),
('6452e4fdd19d36652db8da06', '2023-05-03 22:49:25', '14.00', 1, 32),
('6452e4fdd19d36652db8da07', '2023-05-03 22:49:25', '14.00', 2, 32),
('6452e4fed19d36652db8da09', '2023-05-03 22:49:25', '14.00', 1, 32),
('6452e4fed19d36652db8da0a', '2023-05-03 22:49:25', '14.00', 2, 32),
('6452e4ffd19d36652db8da10', '2023-05-03 22:49:25', '14.00', 1, 32),
('6452e500d19d36652db8da13', '2023-05-03 22:49:35', '14.00', 1, 32),
('6452e500d19d36652db8da15', '2023-05-03 22:49:35', '14.00', 2, 32),
('6452e501d19d36652db8da1a', '2023-05-03 22:49:35', '14.00', 1, 32),
('6452e501d19d36652db8da1c', '2023-05-03 22:49:35', '14.00', 2, 32),
('6452e502d19d36652db8da20', '2023-05-03 22:49:35', '14.00', 1, 32),
('6452e502d19d36652db8da21', '2023-05-03 22:49:35', '14.00', 2, 32),
('6452e503d19d36652db8da27', '2023-05-03 22:49:35', '14.00', 1, 32),
('6452e503d19d36652db8da28', '2023-05-03 22:49:35', '14.00', 2, 32),
('6452e504d19d36652db8da2a', '2023-05-03 22:49:35', '14.00', 1, 32),
('6452e504d19d36652db8da2b', '2023-05-03 22:49:35', '14.00', 2, 32),
('6452e505d19d36652db8da30', '2023-05-03 22:49:35', '14.00', 1, 32),
('6452e505d19d36652db8da31', '2023-05-03 22:49:35', '14.00', 2, 32),
('6452e506d19d36652db8da34', '2023-05-03 22:49:35', '14.00', 1, 32),
('6452e506d19d36652db8da3b', '2023-05-03 22:49:35', '14.00', 2, 32),
('6452e507d19d36652db8da3d', '2023-05-03 22:49:35', '14.00', 1, 32),
('6452e507d19d36652db8da3e', '2023-05-03 22:49:35', '14.00', 2, 32),
('6452e508d19d36652db8da40', '2023-05-03 22:49:35', '14.00', 1, 32),
('6452e508d19d36652db8da41', '2023-05-03 22:49:35', '14.00', 2, 32),
('6452e509d19d36652db8da43', '2023-05-03 22:49:35', '14.00', 1, 32),
('6452e509d19d36652db8da46', '2023-05-03 22:49:35', '14.00', 2, 32),
('6452e50ad19d36652db8da48', '2023-05-03 22:49:35', '14.00', 1, 32),
('6452e50ad19d36652db8da49', '2023-05-03 22:49:35', '14.00', 2, 32),
('6452e50bd19d36652db8da4a', '2023-05-03 22:49:35', '13.70', 1, 32),
('6452e50bd19d36652db8da4b', '2023-05-03 22:49:35', '14.00', 2, 32),
('6452e50cd19d36652db8da4e', '2023-05-03 22:49:35', '13.40', 1, 32),
('6452e50cd19d36652db8da4f', '2023-05-03 22:49:35', '14.00', 2, 32),
('6452e50dd19d36652db8da50', '2023-05-03 22:49:35', '13.10', 1, 32),
('6452e50dd19d36652db8da51', '2023-05-03 22:49:35', '13.70', 2, 32),
('6452e50ed19d36652db8da56', '2023-05-03 22:49:35', '12.80', 1, 32),
('6452e50ed19d36652db8da57', '2023-05-03 22:49:35', '13.40', 2, 32),
('6452e50fd19d36652db8da5d', '2023-05-03 22:49:35', '12.50', 1, 32),
('6452e50fd19d36652db8da5e', '2023-05-03 22:49:35', '13.10', 2, 32),
('6452e510d19d36652db8da61', '2023-05-03 22:49:35', '12.20', 1, 32),
('6452e510d19d36652db8da62', '2023-05-03 22:49:35', '12.80', 2, 32),
('6452e511d19d36652db8da68', '2023-05-03 22:49:35', '11.90', 1, 32),
('6452e511d19d36652db8da69', '2023-05-03 22:49:35', '12.50', 2, 32),
('6452e512d19d36652db8da6d', '2023-05-03 22:49:35', '11.60', 1, 32),
('6452e513d19d36652db8da71', '2023-05-03 22:49:54', '11.30', 1, 32),
('6452e513d19d36652db8da72', '2023-05-03 22:49:54', '11.90', 2, 32),
('6452e514d19d36652db8da76', '2023-05-03 22:49:54', '11.00', 1, 32),
('6452e514d19d36652db8da77', '2023-05-03 22:49:54', '11.60', 2, 32),
('6452e515d19d36652db8da7d', '2023-05-03 22:49:54', '11.00', 1, 32),
('6452e516d19d36652db8da82', '2023-05-03 22:49:57', '11.00', 1, 32),
('6452e516d19d36652db8da83', '2023-05-03 22:49:57', '11.60', 2, 32),
('6452e517d19d36652db8da87', '2023-05-03 22:49:57', '11.00', 1, 32),
('6452e517d19d36652db8da88', '2023-05-03 22:49:57', '11.60', 2, 32),
('6452e518d19d36652db8da8c', '2023-05-03 22:49:57', '11.00', 1, 32),
('6452e518d19d36652db8da8d', '2023-05-03 22:49:57', '11.60', 2, 32),
('6452e519d19d36652db8da8f', '2023-05-03 22:49:57', '11.00', 1, 32),
('6452e519d19d36652db8da90', '2023-05-03 22:49:57', '11.60', 2, 32),
('6452e51ad19d36652db8da93', '2023-05-03 22:49:57', '11.00', 1, 32),
('6452e51ad19d36652db8da94', '2023-05-03 22:49:57', '11.60', 2, 32),
('6452e51bd19d36652db8da9a', '2023-05-03 22:49:57', '11.00', 1, 32),
('6452e51cd19d36652db8da9e', '2023-05-03 22:50:03', '11.00', 1, 32),
('6452e51cd19d36652db8da9f', '2023-05-03 22:50:03', '11.60', 2, 32),
('6452e51dd19d36652db8daa4', '2023-05-03 22:50:03', '11.00', 1, 32),
('6452e51ed19d36652db8daa8', '2023-05-03 22:50:05', '11.00', 1, 32),
('6452e51fd19d36652db8daab', '2023-05-03 22:50:06', '11.30', 1, 32),
('6452e51fd19d36652db8daac', '2023-05-03 22:50:06', '10.70', 2, 32),
('6452e520d19d36652db8dab0', '2023-05-03 22:50:06', '11.60', 1, 32),
('6452e520d19d36652db8dab1', '2023-05-03 22:50:06', '10.40', 2, 32),
('6452e521d19d36652db8dab5', '2023-05-03 22:50:06', '11.90', 1, 32),
('6452e521d19d36652db8dab6', '2023-05-03 22:50:06', '10.10', 2, 32),
('6452e522d19d36652db8daba', '2023-05-03 22:50:06', '12.20', 1, 32),
('6452e522d19d36652db8dabb', '2023-05-03 22:50:06', '9.80', 2, 32),
('6452e523d19d36652db8dabe', '2023-05-03 22:50:06', '12.50', 1, 32),
('6452e523d19d36652db8dabf', '2023-05-03 22:50:06', '9.50', 2, 32),
('6452e524d19d36652db8dac2', '2023-05-03 22:50:06', '12.80', 1, 32),
('6452e524d19d36652db8dac3', '2023-05-03 22:50:06', '9.20', 2, 32),
('6452e525d19d36652db8dac4', '2023-05-03 22:50:06', '13.10', 1, 32),
('6452e525d19d36652db8dac5', '2023-05-03 22:50:06', '9.20', 2, 32),
('6452e526d19d36652db8daca', '2023-05-03 22:50:06', '13.40', 1, 32),
('6452e526d19d36652db8dacb', '2023-05-03 22:50:06', '9.20', 2, 32),
('6452e527d19d36652db8dacd', '2023-05-03 22:50:06', '13.70', 1, 32),
('6452e527d19d36652db8dace', '2023-05-03 22:50:06', '9.20', 2, 32),
('6452e528d19d36652db8dad1', '2023-05-03 22:50:06', '14.00', 1, 32),
('6452e528d19d36652db8dad2', '2023-05-03 22:50:06', '9.20', 2, 32),
('6452e529d19d36652db8dad4', '2023-05-03 22:50:06', '14.00', 1, 32),
('6452e529d19d36652db8dad5', '2023-05-03 22:50:06', '9.20', 2, 32),
('6452e52ad19d36652db8dadc', '2023-05-03 22:50:06', '14.00', 1, 32),
('6452e52ad19d36652db8dadd', '2023-05-03 22:50:06', '9.20', 2, 32),
('6452e52bd19d36652db8dadf', '2023-05-03 22:50:06', '14.00', 1, 32),
('6452e52bd19d36652db8dae0', '2023-05-03 22:50:06', '9.20', 2, 32),
('6452e52cd19d36652db8dae2', '2023-05-03 22:50:06', '14.00', 1, 32),
('6452e52dd19d36652db8dae4', '2023-05-03 22:50:20', '14.00', 1, 32),
('6452e52dd19d36652db8dae5', '2023-05-03 22:50:20', '9.50', 2, 32),
('6452e52ed19d36652db8dae8', '2023-05-03 22:50:20', '14.00', 1, 32),
('6452e52fd19d36652db8daec', '2023-05-03 22:50:22', '14.00', 1, 32),
('6452e52fd19d36652db8daed', '2023-05-03 22:50:22', '10.10', 2, 32),
('6452e530d19d36652db8daf5', '2023-05-03 22:50:22', '14.00', 1, 32),
('6452e530d19d36652db8daf6', '2023-05-03 22:50:22', '10.40', 2, 32),
('6452e531d19d36652db8daf9', '2023-05-03 22:50:22', '14.00', 1, 32),
('6452e531d19d36652db8dafa', '2023-05-03 22:50:22', '10.70', 2, 32),
('6452e532d19d36652db8daff', '2023-05-03 22:50:22', '14.00', 1, 32),
('6452e532d19d36652db8db00', '2023-05-03 22:50:22', '11.00', 2, 32),
('6452e533d19d36652db8db05', '2023-05-03 22:50:22', '14.00', 1, 32),
('6452e533d19d36652db8db06', '2023-05-03 22:50:22', '11.30', 2, 32),
('6452e534d19d36652db8db08', '2023-05-03 22:50:22', '14.00', 1, 32),
('6452e534d19d36652db8db09', '2023-05-03 22:50:22', '11.60', 2, 32),
('6452e535d19d36652db8db0a', '2023-05-03 22:50:22', '14.00', 1, 32),
('6452e535d19d36652db8db0b', '2023-05-03 22:50:22', '11.60', 2, 32),
('6452e536d19d36652db8db11', '2023-05-03 22:50:22', '14.00', 1, 32),
('6452e536d19d36652db8db12', '2023-05-03 22:50:22', '11.60', 2, 32),
('6452e537d19d36652db8db14', '2023-05-03 22:50:22', '14.00', 1, 32),
('6452e539d19d36652db8db15', '2023-05-03 22:50:22', '11.60', 2, 32),
('6452e539d19d36652db8db17', '2023-05-03 22:50:22', '14.00', 1, 32),
('6452e539d19d36652db8db1d', '2023-05-03 22:50:33', '14.00', 1, 32),
('6452e539d19d36652db8db1e', '2023-05-03 22:50:33', '11.60', 2, 32),
('6452e53ad19d36652db8db20', '2023-05-03 22:50:33', '14.00', 1, 32),
('6452e53ad19d36652db8db21', '2023-05-03 22:50:33', '11.60', 2, 32),
('6452e53bd19d36652db8db25', '2023-05-03 22:50:33', '14.00', 1, 32),
('6452e53bd19d36652db8db26', '2023-05-03 22:50:33', '11.60', 2, 32),
('6452e53cd19d36652db8db2a', '2023-05-03 22:50:33', '14.00', 1, 32),
('6452e53cd19d36652db8db2b', '2023-05-03 22:50:33', '11.60', 2, 32),
('6452e53dd19d36652db8db2e', '2023-05-03 22:50:33', '14.00', 1, 32),
('6452e53dd19d36652db8db2f', '2023-05-03 22:50:33', '11.90', 2, 32),
('6452e53ed19d36652db8db32', '2023-05-03 22:50:33', '14.00', 1, 32),
('6452e53ed19d36652db8db33', '2023-05-03 22:50:33', '12.20', 2, 32),
('6452e53fd19d36652db8db35', '2023-05-03 22:50:33', '14.00', 1, 32),
('6452e53fd19d36652db8db36', '2023-05-03 22:50:33', '12.50', 2, 32),
('6452e540d19d36652db8db37', '2023-05-03 22:50:33', '14.00', 1, 32),
('6452e540d19d36652db8db38', '2023-05-03 22:50:33', '12.80', 2, 32),
('6452e541d19d36652db8db3f', '2023-05-03 22:50:33', '14.00', 1, 32),
('6452e541d19d36652db8db40', '2023-05-03 22:50:33', '13.10', 2, 32),
('6452e542d19d36652db8db45', '2023-05-03 22:50:33', '14.00', 1, 32),
('6452e542d19d36652db8db46', '2023-05-03 22:50:33', '13.40', 2, 32),
('6452e543d19d36652db8db49', '2023-05-03 22:50:33', '14.00', 1, 32),
('6452e543d19d36652db8db4a', '2023-05-03 22:50:33', '13.70', 2, 32),
('6452e544d19d36652db8db4b', '2023-05-03 22:50:33', '14.00', 1, 32),
('6452e544d19d36652db8db4c', '2023-05-03 22:50:33', '14.00', 2, 32),
('6452e545d19d36652db8db52', '2023-05-03 22:50:33', '14.00', 1, 32),
('6452e545d19d36652db8db53', '2023-05-03 22:50:33', '14.00', 2, 32),
('6452e546d19d36652db8db55', '2023-05-03 22:50:33', '14.00', 1, 32),
('6452e546d19d36652db8db56', '2023-05-03 22:50:33', '14.00', 2, 32),
('6452e547d19d36652db8db5a', '2023-05-03 22:50:33', '13.70', 1, 32),
('6452e547d19d36652db8db5b', '2023-05-03 22:50:33', '14.00', 2, 32),
('6452e548d19d36652db8db61', '2023-05-03 22:50:33', '13.40', 1, 32),
('6452e548d19d36652db8db62', '2023-05-03 22:50:33', '14.00', 2, 32),
('6452e549d19d36652db8db63', '2023-05-03 22:50:33', '13.10', 1, 32),
('6452e54ad19d36652db8db69', '2023-05-03 22:50:49', '12.80', 1, 32),
('6452e54bd19d36652db8db70', '2023-05-03 22:50:50', '12.50', 1, 32),
('6452e54bd19d36652db8db71', '2023-05-03 22:50:50', '14.00', 2, 32),
('6452e54cd19d36652db8db72', '2023-05-03 22:50:50', '12.20', 1, 32),
('6452e54cd19d36652db8db73', '2023-05-03 22:50:50', '14.00', 2, 32),
('6452e54dd19d36652db8db78', '2023-05-03 22:50:50', '11.90', 1, 32),
('6452e54dd19d36652db8db79', '2023-05-03 22:50:50', '14.00', 2, 32),
('6452e54ed19d36652db8db7e', '2023-05-03 22:50:50', '11.60', 1, 32),
('6452e54ed19d36652db8db7f', '2023-05-03 22:50:50', '14.00', 2, 32),
('6452e54fd19d36652db8db81', '2023-05-03 22:50:50', '11.30', 1, 32),
('6452e54fd19d36652db8db82', '2023-05-03 22:50:50', '14.00', 2, 32),
('6452e550d19d36652db8db86', '2023-05-03 22:50:50', '11.00', 1, 32),
('6452e550d19d36652db8db87', '2023-05-03 22:50:50', '14.00', 2, 32),
('6452e551d19d36652db8db8a', '2023-05-03 22:50:50', '11.00', 1, 32),
('6452e551d19d36652db8db8c', '2023-05-03 22:50:50', '14.00', 2, 32),
('6452e552d19d36652db8db8f', '2023-05-03 22:50:50', '11.00', 1, 32),
('6452e552d19d36652db8db90', '2023-05-03 22:50:50', '14.00', 2, 32),
('6452e553d19d36652db8db92', '2023-05-03 22:50:50', '11.00', 1, 32),
('6452e553d19d36652db8db93', '2023-05-03 22:50:50', '14.00', 2, 32),
('6452e554d19d36652db8db98', '2023-05-03 22:50:50', '11.00', 1, 32),
('6452e554d19d36652db8db99', '2023-05-03 22:50:50', '14.00', 2, 32),
('6452e555d19d36652db8db9b', '2023-05-03 22:50:50', '11.00', 1, 32),
('6452e556d19d36652db8dba1', '2023-05-03 22:51:01', '11.00', 1, 32),
('6452e556d19d36652db8dba2', '2023-05-03 22:51:01', '14.00', 2, 32),
('6452e557d19d36652db8dba8', '2023-05-03 22:51:01', '11.00', 1, 32),
('6452e557d19d36652db8dba9', '2023-05-03 22:51:01', '14.00', 2, 32),
('6452e558d19d36652db8dbad', '2023-05-03 22:51:01', '11.00', 1, 32),
('6452e558d19d36652db8dbae', '2023-05-03 22:51:01', '14.00', 2, 32),
('6452e559d19d36652db8dbb2', '2023-05-03 22:51:01', '11.00', 1, 32),
('6452e559d19d36652db8dbb3', '2023-05-03 22:51:01', '14.00', 2, 32),
('6452e55ad19d36652db8dbba', '2023-05-03 22:51:01', '11.00', 1, 32),
('6452e55ad19d36652db8dbbb', '2023-05-03 22:51:01', '14.00', 2, 32),
('6452e55bd19d36652db8dbbd', '2023-05-03 22:51:01', '11.30', 1, 32),
('6452e55bd19d36652db8dbbe', '2023-05-03 22:51:01', '14.00', 2, 32),
('6452e55cd19d36652db8dbc0', '2023-05-03 22:51:01', '11.60', 1, 32),
('6452e55cd19d36652db8dbc1', '2023-05-03 22:51:01', '14.00', 2, 32),
('6452e55dd19d36652db8dbc6', '2023-05-03 22:51:01', '11.90', 1, 32),
('6452e55dd19d36652db8dbc7', '2023-05-03 22:51:01', '14.00', 2, 32),
('6452e55ed19d36652db8dbca', '2023-05-03 22:51:01', '12.20', 1, 32),
('6452e55fd19d36652db8dbd0', '2023-05-03 22:51:10', '12.50', 1, 32),
('6452e55fd19d36652db8dbd1', '2023-05-03 22:51:10', '14.00', 2, 32),
('6452e560d19d36652db8dbd7', '2023-05-03 22:51:10', '12.80', 1, 32),
('6452e560d19d36652db8dbd8', '2023-05-03 22:51:10', '14.00', 2, 32),
('6452e561d19d36652db8dbdb', '2023-05-03 22:51:10', '13.10', 1, 32),
('6452e561d19d36652db8dbdc', '2023-05-03 22:51:10', '14.00', 2, 32),
('6452e562d19d36652db8dbe1', '2023-05-03 22:51:10', '13.40', 1, 32),
('6452e562d19d36652db8dbe2', '2023-05-03 22:51:10', '14.00', 2, 32),
('6452e563d19d36652db8dbe4', '2023-05-03 22:51:10', '13.70', 1, 32),
('6452e563d19d36652db8dbe5', '2023-05-03 22:51:10', '14.00', 2, 32),
('6452e564d19d36652db8dbe8', '2023-05-03 22:51:10', '14.00', 1, 32),
('6452e564d19d36652db8dbe9', '2023-05-03 22:51:10', '14.00', 2, 32),
('6452e565d19d36652db8dbee', '2023-05-03 22:51:10', '14.00', 1, 32),
('6452e566d19d36652db8dbf3', '2023-05-03 22:51:17', '14.00', 1, 32),
('6452e567d19d36652db8dbf7', '2023-05-03 22:51:18', '14.00', 1, 32),
('6452e567d19d36652db8dbf8', '2023-05-03 22:51:18', '14.00', 2, 32),
('6452e568d19d36652db8dbfb', '2023-05-03 22:51:18', '14.00', 1, 32),
('6452e568d19d36652db8dbfc', '2023-05-03 22:51:18', '14.00', 2, 32),
('6452e569d19d36652db8dc04', '2023-05-03 22:51:18', '14.00', 1, 32),
('6452e569d19d36652db8dc05', '2023-05-03 22:51:18', '14.00', 2, 32),
('6452e56ad19d36652db8dc08', '2023-05-03 22:51:18', '14.00', 1, 32),
('6452e56ad19d36652db8dc09', '2023-05-03 22:51:18', '14.00', 2, 32),
('6452e56bd19d36652db8dc0a', '2023-05-03 22:51:18', '14.00', 1, 32),
('6452e56bd19d36652db8dc0b', '2023-05-03 22:51:18', '14.00', 2, 32);

--
-- Triggers `medicoestemperatura`
--
DROP TRIGGER IF EXISTS `CreateTempAlert`;
DELIMITER $$
CREATE TRIGGER `CreateTempAlert` AFTER INSERT ON `medicoestemperatura` FOR EACH ROW BEGIN
  DECLARE ongoing_exp_id, alertExists, can_insert INT;
  DECLARE temp_ideal, periodicity, var_max_temp DECIMAL(4,2);
  DECLARE time_last_alert TIMESTAMP;
  
  SET can_insert = 0;
  SELECT parametrosadicionais.PeriodicidadeAlerta INTO periodicity
  FROM parametrosadicionais
  WHERE parametrosadicionais.IDExperiencia = GetOngoingExpId();

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
    
    -- verificar se o ultimo light_temp pode ser inserido (periodicidade)
    SELECT COUNT(*) INTO alertExists
    FROM alerta WHERE alerta.tipo = 'light_temp' and alerta.sensor = NEW.sensor;
    
    IF alertExists > 0 THEN
      SELECT MAX(hora) INTO time_last_alert
      FROM alerta WHERE alerta.tipo = 'light_temp' and alerta.sensor = NEW.sensor;
      IF (TIMESTAMPDIFF(SECOND, time_last_alert, NEW.hora)) >=  periodicity THEN
        SET can_insert = 1;
      END IF;
    ELSEIF alertExists = 0 THEN
      SET can_insert = 1;
    END IF;
    
    IF can_insert = 1 THEN
      IF ((NEW.leitura) >  temp_ideal + var_max_temp) THEN
        INSERT INTO alerta (hora, sala, sensor, leitura, tipo, mensagem, horaescrita)
        VALUES (NEW.hora, NULL, NEW.sensor, NEW.leitura, 'urgent_temp', 'Temperatura alta excedeu limite máximo', CURRENT_TIMESTAMP());
      ELSEIF ((NEW.leitura) < temp_ideal - var_max_temp) THEN
        INSERT INTO alerta (hora, sala, sensor, leitura, tipo, mensagem, horaescrita)
        VALUES (NEW.hora, NULL, NEW.sensor, NEW.leitura, 'urgent_temp', 'Temperatura baixa excedeu limite mínimo', CURRENT_TIMESTAMP());
      ELSEIF ((NEW.leitura) > temp_ideal + var_max_temp * 0.9) THEN
        INSERT INTO alerta (hora, sala, sensor, leitura, tipo, mensagem, horaescrita)
        VALUES (NEW.hora, NULL, NEW.sensor, NEW.leitura, 'light_temp', 'Temperatura perto do limite máximo', CURRENT_TIMESTAMP());
      ELSEIF ((NEW.leitura) < temp_ideal - var_max_temp * 0.9) THEN
        INSERT INTO alerta (hora, sala, sensor, leitura, tipo, mensagem, horaescrita)
        VALUES (NEW.hora, NULL, NEW.sensor, NEW.leitura, 'light_temp', 'Temperatura perto do limite mínimo', CURRENT_TIMESTAMP());
      END IF;
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
  `IDExperiencia` int(11) NOT NULL,
  `codigoodor` int(11) DEFAULT NULL,
  PRIMARY KEY (`sala`,`IDExperiencia`),
  KEY `idexperiencia` (`IDExperiencia`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `parametrosadicionais`
--

DROP TABLE IF EXISTS `parametrosadicionais`;
CREATE TABLE IF NOT EXISTS `parametrosadicionais` (
  `IDExperiencia` int(11) NOT NULL,
  `DataHoraInicio` timestamp NULL DEFAULT NULL,
  `DataHoraFim` timestamp NULL DEFAULT NULL,
  `MotivoTermino` varchar(50) DEFAULT NULL,
  `DataHoraPortasExtAbertas` timestamp NULL DEFAULT NULL,
  `PeriodicidadeAlerta` double DEFAULT 30,
  PRIMARY KEY (`IDExperiencia`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `parametrosadicionais`
--

INSERT INTO `parametrosadicionais` (`IDExperiencia`, `DataHoraInicio`, `DataHoraFim`, `MotivoTermino`, `DataHoraPortasExtAbertas`, `PeriodicidadeAlerta`) VALUES
(32, '2023-05-03 22:46:31', '2023-05-03 23:42:41', 'Acabou sem anomalias', NULL, 30);

--
-- Triggers `parametrosadicionais`
--
DROP TRIGGER IF EXISTS `CheckIfRatsDied`;
DELIMITER $$
CREATE TRIGGER `CheckIfRatsDied` AFTER UPDATE ON `parametrosadicionais` FOR EACH ROW BEGIN

DECLARE segundos INT;

SELECT configuracaolabirinto.segundosaberturaportaexterior INTO segundos
FROM configuracaolabirinto
WHERE configuracaolabirinto.IDConfiguracao = 0;

IF TIMESTAMPDIFF(SECOND, NEW.DataHoraFim, NEW.DataHoraPortasExtAbertas) > segundos THEN
	INSERT INTO alerta(alerta.hora, alerta.tipo, alerta.mensagem, alerta.horaescrita, alerta.IDExperiencia)
    VALUES (CURRENT_TIMESTAMP, 'urgent_ratsdied', 'Ratos morreram. Portas não foram abertas a tempo', CURRENT_TIMESTAMP, NEW.IDExperiencia);
END IF;

END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `substanciasexperiencia`
--

DROP TABLE IF EXISTS `substanciasexperiencia`;
CREATE TABLE IF NOT EXISTS `substanciasexperiencia` (
  `numeroratos` int(11) DEFAULT NULL,
  `codigosubstancia` varchar(5) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `IDExperiencia` int(11) NOT NULL,
  PRIMARY KEY (`codigosubstancia`,`IDExperiencia`),
  KEY `idexperiencia` (`IDExperiencia`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `utilizador`
--

DROP TABLE IF EXISTS `utilizador`;
CREATE TABLE IF NOT EXISTS `utilizador` (
  `nome` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `telefone` varchar(12) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `tipo` varchar(3) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `email` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  PRIMARY KEY (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `alerta`
--
ALTER TABLE `alerta`
  ADD CONSTRAINT `alerta_ibfk_1` FOREIGN KEY (`IDExperiencia`) REFERENCES `experiencia` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `experiencia`
--
ALTER TABLE `experiencia`
  ADD CONSTRAINT `experiencia_ibfk_1` FOREIGN KEY (`investigador`) REFERENCES `utilizador` (`email`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Constraints for table `medicoespassagens`
--
ALTER TABLE `medicoespassagens`
  ADD CONSTRAINT `medicoespassagens_ibfk_1` FOREIGN KEY (`IDExperiencia`) REFERENCES `experiencia` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `medicoessala`
--
ALTER TABLE `medicoessala`
  ADD CONSTRAINT `medicoessala_ibfk_1` FOREIGN KEY (`IDExperiencia`) REFERENCES `experiencia` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `medicoestemperatura`
--
ALTER TABLE `medicoestemperatura`
  ADD CONSTRAINT `medicoestemperatura_ibfk_1` FOREIGN KEY (`IDExperiencia`) REFERENCES `experiencia` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `odoresexperiencia`
--
ALTER TABLE `odoresexperiencia`
  ADD CONSTRAINT `odoresexperiencia_ibfk_1` FOREIGN KEY (`IDExperiencia`) REFERENCES `experiencia` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `parametrosadicionais`
--
ALTER TABLE `parametrosadicionais`
  ADD CONSTRAINT `parametrosadicionais_ibfk_1` FOREIGN KEY (`IDExperiencia`) REFERENCES `experiencia` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `substanciasexperiencia`
--
ALTER TABLE `substanciasexperiencia`
  ADD CONSTRAINT `substanciasexperiencia_ibfk_1` FOREIGN KEY (`IDExperiencia`) REFERENCES `experiencia` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
