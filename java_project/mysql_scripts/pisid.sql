-- phpMyAdmin SQL Dump
-- version 5.2.0
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1:3307
-- Generation Time: Apr 25, 2023 at 10:35 PM
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
DECLARE ideal_temp DOUBLE(4,2);

CALL TerminateOngoingExp(startTime,"Acabou sem anomalias");

SELECT IDExperiencia INTO id_exp FROM parametrosadicionais 
WHERE parametrosadicionais.DataHoraInicio is NULL LIMIT 1;

SELECT configuracaolabirinto.temperaturaprogramada INTO ideal_temp
FROM configuracaolabirinto
WHERE configuracaolabirinto.IDConfiguracao = 0;

UPDATE parametrosadicionais
SET parametrosadicionais.DataHoraInicio = startTime
-- proxima exp a decorrer
WHERE IDExperiencia = id_exp;


UPDATE experiencia
SET experiencia.temperaturaideal = ideal_temp
WHERE experiencia.id = id_exp;

SELECT numerosalas INTO nrRooms FROM configuracaolabirinto
ORDER BY IDConfiguracao DESC LIMIT 1;

SELECT COUNT(*) INTO id_exists FROM medicoessala
WHERE medicoessala.IDExperiencia = id_exp;

IF id_exists = 1 THEN
    WHILE i < nrRooms DO
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
CREATE DEFINER=`root`@`localhost` PROCEDURE `WriteConfig` (IN `set_temperature` DOUBLE(4,2), IN `open_doors` INT, IN `nrRooms` INT)   BEGIN

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
) ENGINE=InnoDB AUTO_INCREMENT=432460 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

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

IF NEW.tipo <> 'urgent_temp' THEN
    IF NEW.tipo <> 'urgent_mov' THEN
        
        IF NEW.tipo = 'light_mov' THEN

            SELECT COUNT(*) INTO alertExists
            FROM alerta
            WHERE alerta.tipo = NEW.tipo and alerta.sala = NEW.sala;

            IF alertExists > 0 THEN

                SELECT MAX(alerta.hora) into time_alert
                FROM alerta
                WHERE alerta.tipo = NEW.tipo and alerta.sala = NEW.sala;

                IF (TIMESTAMPDIFF(SECOND, time_alert, NEW.hora)) <  periodicity THEN
                    SIGNAL SQLSTATE '45000'
                    SET MESSAGE_TEXT = 'Alert periodicity';
                END IF;
            END IF;
         ELSE 
            SELECT COUNT(*) INTO alertExists FROM alerta 
            WHERE alerta.tipo = NEW.tipo and alerta.sensor = NEW.sensor;
    
            IF alertExists > 0 THEN
                SELECT MAX(alerta.hora) into time_alert
                FROM alerta
                WHERE alerta.tipo = NEW.tipo and alerta.sensor = NEW.sensor;

                IF (TIMESTAMPDIFF(SECOND, time_alert, NEW.hora)) <  periodicity THEN
                    SIGNAL SQLSTATE '45000'
                    SET MESSAGE_TEXT = 'Alert periodicity';
                END IF;
        
            END IF;
    
        END IF;
    END IF;
END IF;
END
$$
DELIMITER ;
DROP TRIGGER IF EXISTS `TerminateExpUrgentAlert`;
DELIMITER $$
CREATE TRIGGER `TerminateExpUrgentAlert` AFTER INSERT ON `alerta` FOR EACH ROW BEGIN

IF NEW.tipo = 'urgent_mov' THEN
        -- alerta dos movimentos
    CALL TerminateOngoingExp(NEW.hora,NEW.mensagem);
END IF;

IF NEW.tipo = 'urgent_temp' THEN
        -- alerta da temperatura
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
  `temperaturaprogramada` double(4,2) DEFAULT NULL,
  `segundosaberturaportaexterior` int(11) DEFAULT NULL,
  `numerosalas` int(11) DEFAULT NULL,
  PRIMARY KEY (`IDConfiguracao`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `configuracaolabirinto`
--

INSERT INTO `configuracaolabirinto` (`IDConfiguracao`, `temperaturaprogramada`, `segundosaberturaportaexterior`, `numerosalas`) VALUES
(0, 18.00, 20, 10);

-- --------------------------------------------------------

--
-- Table structure for table `experiencia`
--

DROP TABLE IF EXISTS `experiencia`;
CREATE TABLE IF NOT EXISTS `experiencia` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `descricao` text DEFAULT NULL,
  `investigador` varchar(50) DEFAULT NULL,
  `DataRegisto` timestamp NULL DEFAULT current_timestamp(),
  `numeroratos` int(11) DEFAULT NULL,
  `limiteratossala` int(11) DEFAULT NULL,
  `segundossemmovimento` int(11) DEFAULT NULL,
  `temperaturaideal` decimal(4,2) DEFAULT NULL,
  `variacaotemperaturamaxima` decimal(4,2) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `investigador` (`investigador`)
) ENGINE=InnoDB AUTO_INCREMENT=28 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

--
-- Dumping data for table `experiencia`
--

INSERT INTO `experiencia` (`id`, `descricao`, `investigador`, `DataRegisto`, `numeroratos`, `limiteratossala`, `segundossemmovimento`, `temperaturaideal`, `variacaotemperaturamaxima`) VALUES
(24, NULL, NULL, '2023-04-25 22:32:12', 40, 30, 120, '18.00', '10.00'),
(25, NULL, NULL, '2023-04-25 22:32:12', 40, 30, 120, '18.00', '10.00'),
(26, NULL, NULL, '2023-04-25 22:32:39', 40, 25, 80, '18.00', '15.00'),
(27, NULL, NULL, '2023-04-25 22:32:39', 30, 19, 39, '18.00', '13.00');

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
  `IDMongo` varchar(100) NOT NULL,
  `hora` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `salaentrada` int(11) DEFAULT NULL,
  `salasaida` int(11) DEFAULT NULL,
  `IDExperiencia` int(11) DEFAULT NULL,
  PRIMARY KEY (`IDMongo`),
  KEY `IDExperiencia` (`IDExperiencia`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

--
-- Dumping data for table `medicoespassagens`
--

INSERT INTO `medicoespassagens` (`IDMongo`, `hora`, `salaentrada`, `salasaida`, `IDExperiencia`) VALUES
('072f12e5-5e0b-40a0-b4d3-e4beb7bd6ec1', '2023-04-25 22:34:09', 3, 2, 24),
('0ad9633b-2808-45b4-9424-1de930ec245b', '2023-04-25 22:34:23', 3, 2, 25),
('20e1da23-f1bd-4259-93ee-2a2c04f341e3', '2023-04-25 22:33:45', 3, 2, 24),
('247f1fe8-ed6f-4b65-adbe-76622992d1f8', '2023-04-25 22:33:58', 3, 2, 24),
('25234a4b-4ce7-44c3-ba47-7b962ad14f0e', '2023-04-25 22:34:25', 3, 2, 25),
('274a0cf6-1317-4045-8a45-143540fc83ce', '2023-04-25 22:34:13', 3, 2, 24),
('2e4d4346-5a28-411a-a4f4-0a35a17f5ace', '2023-04-25 22:34:30', 3, 2, 25),
('2f475768-e405-4205-904c-0dab537bd869', '2023-04-25 22:34:46', 0, 0, NULL),
('2f93813a-ade0-40c9-9fd8-7cc876337cd1', '2023-04-25 22:34:34', 3, 2, 25),
('36bf8901-e977-4cff-a302-a20194ab0d81', '2023-04-25 22:34:08', 3, 2, 24),
('4585e4ec-81c8-4372-9e26-d789fcad8195', '2023-04-25 22:34:44', 3, 2, 25),
('48b75518-f9de-4fb5-9d04-3c51aaeaaf4e', '2023-04-25 22:33:35', 3, 2, 24),
('4b3328b0-33dc-4d19-a14b-c1ebe7327843', '2023-04-25 22:34:56', 0, 0, NULL),
('536d74d6-1239-442c-9fde-a3a756052ee8', '2023-04-25 22:33:44', 3, 2, 24),
('5ea0072f-52f0-4e3e-8880-8bfa42345dd3', '2023-04-25 22:34:19', 3, 2, 24),
('6c2d3ff7-26bc-4197-ad9c-d4f565ed7197', '2023-04-25 22:34:20', 0, 0, NULL),
('72fabe8e-83f2-4442-99ee-c93758c88ff5', '2023-04-25 22:34:29', 3, 2, 25),
('76d577d5-1155-405c-8891-1bd9ed666df1', '2023-04-25 22:34:49', 0, 0, NULL),
('785644be-c8ac-4b2d-9d52-ef6dedc1ff8c', '2023-04-25 22:34:48', 0, 0, NULL),
('79988e7a-5716-4bfb-b0bc-dd705feccc14', '2023-04-25 22:34:07', 3, 2, 24),
('7a67c567-5bf0-4e10-b0ed-f10f565016aa', '2023-04-25 22:34:42', 3, 2, 25),
('95d357ff-87c8-46aa-ba86-e13498db3140', '2023-04-25 22:33:47', 3, 2, 24),
('b0613ca9-2c8d-46a6-89d8-1699daa189b1', '2023-04-25 22:34:35', 3, 2, 25),
('b307c091-1cbe-41b8-9b8e-e1f99003ecbb', '2023-04-25 22:33:41', 3, 2, 24),
('b5533b7e-5711-4f49-aa8a-aa40d4ba8320', '2023-04-25 22:33:42', 3, 2, 24),
('bd1a2157-d1ac-490a-b287-948687b36dca', '2023-04-25 22:33:38', 3, 2, 24),
('bdf1883c-c3bc-424b-8d50-1e8eb8b079c4', '2023-04-25 22:33:29', 3, 2, 24),
('c65fd54f-80ea-4e10-9989-942ce73a5d48', '2023-04-25 22:34:00', 3, 2, 24),
('c8d8e00d-bee7-4747-98ae-3826d9c882e1', '2023-04-25 22:34:18', 3, 2, 24),
('cc423ab2-4e2a-4498-8bf9-07edbee67a38', '2023-04-25 22:33:27', 3, 2, 24),
('cfbe8474-18c0-4027-b1d4-ce020e9015f3', '2023-04-25 22:34:17', 3, 2, 24),
('d7c9fe7f-80a6-43fd-aa42-efd62a670827', '2023-04-25 22:34:04', 3, 2, 24),
('dab49dd4-d250-468d-ac56-19ba74ab9bff', '2023-04-25 22:34:38', 3, 2, 25),
('e0620467-11b0-4050-9457-5c78fe394465', '2023-04-25 22:33:54', 3, 2, 24),
('e40e13dd-8311-472f-9bd4-99bb0e066e24', '2023-04-25 22:33:57', 3, 2, 24),
('e52ad5c2-22dc-4eba-a86a-e9ebcaa66569', '2023-04-25 22:33:48', 3, 2, 24),
('e57b8672-fdda-43b6-a7e2-1a16d4d807c4', '2023-04-25 22:34:40', 3, 2, 25),
('e5e2279a-7684-4c8d-853c-87830be97bc6', '2023-04-25 22:34:14', 3, 2, 24),
('e9d0be32-1931-4e1b-8605-0587210838ec', '2023-04-25 22:33:26', 0, 0, NULL),
('f1ea9658-0187-481c-ba38-5c17eb2d6777', '2023-04-25 22:33:50', 3, 2, 24),
('f78d9007-9b02-48a2-ba10-4a27e321eb35', '2023-04-25 22:34:01', 3, 2, 24);

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

DECLARE expID, entryRoomExists, exitRoomExists, nr_rats, max_rats, nr_rats_exitroom INT;

SET expID = GetOngoingExpId();

IF NEW.salaentrada <> NEW.salasaida THEN 

SELECT medicoessala.numeroratosfinal INTO nr_rats_exitroom
FROM medicoessala
WHERE medicoessala.sala = NEW.salasaida and medicoessala.IDExperiencia = expID;

SELECT COUNT(1) into entryRoomExists
FROM medicoessala
WHERE medicoessala.idexperiencia = expID and medicoessala.sala = NEW.salaentrada;

SELECT COUNT(1) into exitRoomExists
FROM medicoessala
WHERE medicoessala.idexperiencia = expID and medicoessala.sala = NEW.salasaida;

IF entryRoomExists = 1 THEN
    IF (nr_rats_exitroom - 1 >= 0) THEN
        UPDATE medicoessala
        SET medicoessala.numeroratosfinal = GetRatsInRoom(NEW.salaentrada) + 1
        WHERE medicoessala.idexperiencia = expID and medicoessala.sala = NEW.salaentrada;
    END IF;
END IF;

IF exitRoomExists = 1 THEN
    IF (nr_rats_exitroom - 1 >= 0) THEN
        UPDATE medicoessala
        SET medicoessala.numeroratosfinal = GetRatsInRoom(NEW.salasaida) - 1
        WHERE medicoessala.idexperiencia = expID and medicoessala.sala = NEW.salasaida;
    END IF;
END IF;

SET nr_rats = GetRatsInRoom(NEW.salaentrada);

SELECT experiencia.limiteratossala INTO max_rats
FROM experiencia
WHERE experiencia.id = GetOngoingExpId();

IF (nr_rats > max_rats) THEN
    IF new.salaentrada <> 1 THEN
        INSERT INTO alerta (hora,sala,sensor,leitura,tipo,mensagem,horaescrita)
        VALUES (NEW.hora,NEW.salaentrada,null,null,'urgent_mov','Excedeu limite de ratos por sala',CURRENT_TIMESTAMP());
    END IF;
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
  `IDExperiencia` int(11) NOT NULL,
  `numeroratosfinal` int(11) DEFAULT NULL,
  `sala` int(11) NOT NULL,
  PRIMARY KEY (`IDExperiencia`,`sala`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

--
-- Dumping data for table `medicoessala`
--

INSERT INTO `medicoessala` (`IDExperiencia`, `numeroratosfinal`, `sala`) VALUES
(24, 40, 1),
(24, 0, 2),
(24, 0, 3),
(24, 0, 4),
(24, 0, 5),
(24, 0, 6),
(24, 0, 7),
(24, 0, 8),
(24, 0, 9),
(25, 40, 1),
(25, 0, 2),
(25, 0, 3),
(25, 0, 4),
(25, 0, 5),
(25, 0, 6),
(25, 0, 7),
(25, 0, 8),
(25, 0, 9),
(26, 40, 1),
(26, 0, 2),
(26, 0, 3),
(26, 0, 4),
(26, 0, 5),
(26, 0, 6),
(26, 0, 7),
(26, 0, 8),
(26, 0, 9),
(27, 30, 1),
(27, 0, 2),
(27, 0, 3),
(27, 0, 4),
(27, 0, 5),
(27, 0, 6),
(27, 0, 7),
(27, 0, 8),
(27, 0, 9);

-- --------------------------------------------------------

--
-- Table structure for table `medicoestemperatura`
--

DROP TABLE IF EXISTS `medicoestemperatura`;
CREATE TABLE IF NOT EXISTS `medicoestemperatura` (
  `IDMongo` varchar(100) NOT NULL,
  `hora` timestamp NOT NULL DEFAULT current_timestamp(),
  `leitura` decimal(4,2) DEFAULT NULL,
  `sensor` int(11) DEFAULT NULL,
  `IDExperiencia` int(11) DEFAULT NULL,
  PRIMARY KEY (`IDMongo`),
  KEY `IDExperiencia` (`IDExperiencia`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

--
-- Dumping data for table `medicoestemperatura`
--

INSERT INTO `medicoestemperatura` (`IDMongo`, `hora`, `leitura`, `sensor`, `IDExperiencia`) VALUES
('1032fbf9-0908-4bfc-acb6-7ee2a9abf841', '2023-04-25 22:34:21', '20.01', 1, 25),
('135cf62c-8f19-418d-8bf8-aa71c04e7eee', '2023-04-25 22:33:53', '20.01', 1, 24),
('13620272-c7dc-4c39-af2c-c7563e269ec3', '2023-04-25 22:34:43', '20.01', 1, 25),
('1599d065-a1a9-4109-8351-6e357f40baaf', '2023-04-25 22:33:32', '20.01', 1, 24),
('22c72310-87d0-4b06-912b-d9fe8407e7af', '2023-04-25 22:34:16', '20.01', 1, 24),
('26c66d6b-2352-492c-a30c-00de4c4f26aa', '2023-04-25 22:33:55', '20.01', 1, 24),
('321df061-c02a-4da3-926a-e8246475c0c4', '2023-04-25 22:33:28', '20.01', 1, 24),
('3973a33b-02e5-4fcb-9873-15c1ee858ecc', '2023-04-25 22:33:52', '20.01', 1, 24),
('3d189e06-deb1-450b-a593-ee58b21b62e7', '2023-04-25 22:34:22', '20.01', 1, 25),
('4660565d-d595-44df-8326-f50698d9ac26', '2023-04-25 22:34:36', '20.01', 1, 25),
('48864496-c7a3-4cad-be61-c5a003a3c465', '2023-04-25 22:33:33', '20.01', 1, 24),
('4ee193a6-c1b6-4d11-a39e-2d93adce1bd1', '2023-04-25 22:34:03', '20.01', 1, 24),
('5035fff7-7fa3-4e11-8fe7-d094a781f37a', '2023-04-25 22:34:28', '20.01', 1, 25),
('52c16459-4a0d-41ad-a97a-dff069804ac7', '2023-04-25 22:34:24', '20.01', 1, 25),
('59530eec-a5e7-4e01-9807-6a6309c89457', '2023-04-25 22:34:47', '20.01', 1, 26),
('641a09ae-7729-4ca8-82b5-db3074defb5f', '2023-04-25 22:33:30', '20.01', 1, 24),
('6db2a9bb-18ec-4cf6-b14d-f3e3c716d649', '2023-04-25 22:34:45', '20.01', 1, 25),
('7235ad5f-d2a4-4723-8dfe-c07afa16b0bd', '2023-04-25 22:34:06', '20.01', 1, 24),
('731940b6-2a8a-41ee-a560-40a16ac85206', '2023-04-25 22:33:49', '20.01', 1, 24),
('78271e86-a177-4ef4-9b4b-d59cb28e835f', '2023-04-25 22:34:32', '20.01', 1, 25),
('849b1d6f-d3df-40c6-a525-26e69f6b6eaa', '2023-04-25 22:34:39', '20.01', 1, 25),
('87f6a0df-b032-49fa-af7d-d17daddb4af5', '2023-04-25 22:33:56', '20.01', 1, 24),
('8c153db3-54b9-4534-a25a-4f6632548d59', '2023-04-25 22:34:11', '20.01', 1, 24),
('93e695fa-9439-41df-b187-14b0cfce20e4', '2023-04-25 22:34:15', '20.01', 1, 24),
('a0363fd8-52c1-4675-9352-b3626f15ba3c', '2023-04-25 22:34:05', '20.01', 1, 24),
('a795b96e-3ce1-406c-9bdf-88edb7628e83', '2023-04-25 22:33:39', '20.01', 1, 24),
('af7119dc-e3dc-4b3e-b3eb-27b97f0e5068', '2023-04-25 22:34:10', '20.01', 1, 24),
('bd08e684-b313-48ff-bca2-409b5aad5b78', '2023-04-25 22:34:02', '20.01', 1, 24),
('be048121-afe5-4802-86d8-7809c7c9b8d5', '2023-04-25 22:33:34', '20.01', 1, 24),
('c5cb8dde-dc15-4463-97d1-8238cc7d24ff', '2023-04-25 22:33:43', '20.01', 1, 24),
('d4e5b05f-1161-4554-b7b9-1bab6d40b702', '2023-04-25 22:34:31', '20.01', 1, 25),
('e08c48ee-d1ed-4cc4-b315-798aa5e43887', '2023-04-25 22:34:33', '20.01', 1, 25),
('e1e3f3f3-c363-488f-9b9c-067fe94d7f75', '2023-04-25 22:33:31', '20.01', 1, 24),
('e2a91d6c-3f5e-4324-a0c5-fbaf64bc6faa', '2023-04-25 22:34:41', '20.01', 1, 25),
('e39212f3-3c3d-4e5a-9e6b-1fd72a1e9916', '2023-04-25 22:33:37', '20.01', 1, 24),
('f154771c-5957-404b-8352-93c015f35cc1', '2023-04-25 22:34:27', '20.01', 1, 25),
('f99e93d4-ef9b-4db4-aedb-d707ab4d018c', '2023-04-25 22:33:51', '20.01', 1, 24),
('fea02c3d-3c49-4b8d-8ffe-6d2e29ae82df', '2023-04-25 22:33:40', '20.01', 1, 24);

--
-- Triggers `medicoestemperatura`
--
DROP TRIGGER IF EXISTS `CreateAlertTemp`;
DELIMITER $$
CREATE TRIGGER `CreateAlertTemp` BEFORE INSERT ON `medicoestemperatura` FOR EACH ROW BEGIN
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
    FROM alerta WHERE alerta.tipo = 'light_temp';
    
    IF alertExists > 0 THEN
      SELECT MAX(hora) INTO time_last_alert
      FROM alerta WHERE alerta.tipo = 'light_temp';
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

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
  `PeriodicidadeAlerta` double DEFAULT 30,
  PRIMARY KEY (`IDExperiencia`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `parametrosadicionais`
--

INSERT INTO `parametrosadicionais` (`IDExperiencia`, `DataHoraInicio`, `DataHoraFim`, `MotivoTermino`, `PeriodicidadeAlerta`) VALUES
(24, '2023-04-25 22:33:26', '2023-04-25 22:34:20', 'Acabou sem anomalias', 30),
(25, '2023-04-25 22:34:20', '2023-04-25 22:34:46', 'Acabou sem anomalias', 30),
(26, '2023-04-25 22:34:46', '2023-04-25 22:34:48', 'Acabou sem anomalias', 30),
(27, '2023-04-25 22:34:48', '2023-04-25 22:34:49', 'Acabou sem anomalias', 30);

-- --------------------------------------------------------

--
-- Table structure for table `substanciasexperiencia`
--

DROP TABLE IF EXISTS `substanciasexperiencia`;
CREATE TABLE IF NOT EXISTS `substanciasexperiencia` (
  `numeroratos` int(11) DEFAULT NULL,
  `codigosubstancia` varchar(5) NOT NULL,
  `IDExperiencia` int(11) NOT NULL,
  PRIMARY KEY (`codigosubstancia`,`IDExperiencia`),
  KEY `idexperiencia` (`IDExperiencia`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `utilizador`
--

DROP TABLE IF EXISTS `utilizador`;
CREATE TABLE IF NOT EXISTS `utilizador` (
  `nome` varchar(100) DEFAULT NULL,
  `telefone` varchar(12) DEFAULT NULL,
  `tipo` varchar(3) DEFAULT NULL,
  `email` varchar(50) NOT NULL,
  PRIMARY KEY (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

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
  ADD CONSTRAINT `parametrosadicionais_ibfk_1` FOREIGN KEY (`IDExperiencia`) REFERENCES `experiencia` (`id`);

--
-- Constraints for table `substanciasexperiencia`
--
ALTER TABLE `substanciasexperiencia`
  ADD CONSTRAINT `substanciasexperiencia_ibfk_1` FOREIGN KEY (`IDExperiencia`) REFERENCES `experiencia` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
