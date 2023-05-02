-- phpMyAdmin SQL Dump
-- version 5.2.0
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1:3307
-- Generation Time: May 02, 2023 at 11:40 AM
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
) ENGINE=InnoDB AUTO_INCREMENT=432611 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `alerta`
--

INSERT INTO `alerta` (`id`, `hora`, `sala`, `sensor`, `leitura`, `tipo`, `mensagem`, `horaescrita`, `IDExperiencia`) VALUES
(432610, '2023-05-02 11:37:41', NULL, NULL, NULL, 'urgent_ratsdied', 'Ratos morreram. Portas não foram abertas a tempo', '2023-05-02 11:37:41', 29);

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

ELSEIF NEW.tipo = 'light_temp' OR NEW.tipo = 'avaria' THEN  
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
       
ELSEIF NEW.tipo = 'MongoDB_status' THEN
    SELECT COUNT(*) INTO alertExists FROM alerta 
    WHERE alerta.tipo = NEW.tipo; 

    IF alertExists > 0 THEN
        SELECT MAX(alerta.hora) into time_alert
        FROM alerta
        WHERE alerta.tipo = NEW.tipo; 

        IF (TIMESTAMPDIFF(SECOND, time_alert, NEW.hora)) <  periodicity THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Alert periodicity';
        END IF;

    END IF;
ELSEIF NEW.tipo = 'descartada' THEN 
    SELECT COUNT(*) INTO alertExists FROM alerta 
    WHERE alerta.tipo = NEW.tipo;

    IF alertExists > 0 THEN
        SELECT MAX(alerta.hora) into time_alert
        FROM alerta
        WHERE alerta.tipo = NEW.tipo;

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
) ENGINE=InnoDB AUTO_INCREMENT=31 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `experiencia`
--

INSERT INTO `experiencia` (`id`, `descricao`, `investigador`, `DataRegisto`, `numeroratos`, `limiteratossala`, `segundossemmovimento`, `temperaturaideal`, `variacaotemperaturamaxima`) VALUES
(28, 'Teste', NULL, '2023-04-29 16:36:06', 30, 20, 999999, '18.00', '15.00'),
(29, 'fgfgsf', NULL, '2023-04-29 16:45:30', 40, 30, 99999, '18.00', '10.00'),
(30, NULL, NULL, '2023-05-02 11:36:56', 40, 30, 200000, '19.00', '2.00');

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
('', '2023-05-02 11:35:54', 0, 0, NULL),
('jojonl', '2023-05-02 11:36:17', 0, 0, NULL),
('kmlknjkbh', '2023-05-02 11:39:06', 0, 0, NULL),
('lkmlk nkhvjg', '2023-05-02 11:38:05', 0, 0, NULL),
('llknln', '2023-05-02 11:37:30', 0, 0, NULL);

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
(28, 30, 1),
(28, 0, 2),
(28, 0, 3),
(28, 0, 4),
(28, 0, 5),
(28, 0, 6),
(28, 0, 7),
(28, 0, 8),
(28, 0, 9),
(29, 40, 1),
(29, 0, 2),
(29, 0, 3),
(29, 0, 4),
(29, 0, 5),
(29, 0, 6),
(29, 0, 7),
(29, 0, 8),
(29, 0, 9),
(30, 40, 1),
(30, 0, 2),
(30, 0, 3),
(30, 0, 4),
(30, 0, 5),
(30, 0, 6),
(30, 0, 7),
(30, 0, 8),
(30, 0, 9);

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
(28, '2023-04-29 16:28:00', '2023-04-29 16:28:00', 'Acabou sem anomalias', '2023-04-10 11:10:19', 30),
(29, '2023-04-29 16:28:00', '2023-05-02 11:35:54', 'Acabou sem anomalias', '2023-05-02 11:37:36', 30),
(30, '2023-05-02 11:38:05', '2023-05-02 11:39:06', 'Acabou sem anomalias', NULL, 30);

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
