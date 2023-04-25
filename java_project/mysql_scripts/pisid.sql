-- phpMyAdmin SQL Dump
-- version 5.2.0
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1:3307
-- Generation Time: Apr 25, 2023 at 03:23 PM
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

DECLARE i INT DEFAULT 2;
DECLARE nrSalas, id_exp, id_existe INT;
DECLARE temp_ideal DOUBLE(4,2);

CALL TerminateOngoingExp(dataInicio,"Acabou sem anomalias");

SELECT IDExperiencia INTO id_exp FROM parametrosadicionais 
WHERE parametrosadicionais.DataHoraInicio is NULL LIMIT 1;

SELECT configuracaolabirinto.temperaturaprogramada INTO temp_ideal
FROM configuracaolabirinto
WHERE configuracaolabirinto.IDConfiguracao = 0;

UPDATE parametrosadicionais
SET parametrosadicionais.DataHoraInicio = dataInicio
-- proxima exp a decorrer
WHERE IDExperiencia = id_exp;


UPDATE experiencia
SET experiencia.temperaturaideal = temp_ideal
WHERE experiencia.id = id_exp;

SELECT numerosalas INTO nrSalas FROM configuracaolabirinto
ORDER BY IDConfiguracao DESC LIMIT 1;

SELECT COUNT(*) INTO id_existe FROM medicoessala
WHERE medicoessala.IDExperiencia = id_exp;

IF id_existe = 1 THEN
    WHILE i < nrSalas DO
        INSERT INTO medicoessala (IDExperiencia, numeroratosfinal, sala)
        VALUES (id_exp, 0, i);  
    SET i = i + 1;
    END WHILE;
END IF;

END$$

DROP PROCEDURE IF EXISTS `TerminateOngoingExp`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `TerminateOngoingExp` (IN `dataFim` TIMESTAMP, IN `motivo_fim` VARCHAR(50))  NO SQL BEGIN

UPDATE parametrosadicionais
SET parametrosadicionais.DataHoraFim = dataFim, parametrosadicionais.MotivoTermino = motivo_fim
WHERE parametrosadicionais.IDExperiencia = GetOngoingExpId();
END$$

DROP PROCEDURE IF EXISTS `WriteAlert`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `WriteAlert` (IN `hora` TIMESTAMP, IN `sala` INT, IN `sensor` INT, IN `leitura` DECIMAL(4,2), IN `tipo` VARCHAR(50), IN `mensagem` VARCHAR(50), IN `horaescrita` TIMESTAMP)   BEGIN

IF OngoingExp() THEN
	INSERT INTO alerta (id, hora, sala, sensor, leitura, tipo, mensagem, horaescrita, IDExperiencia)
	VALUES (id, hora, sala, sensor, leitura, tipo, mensagem, horaescrita, GetOngoingExpId());
END IF;
END$$

DROP PROCEDURE IF EXISTS `WriteConfig`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `WriteConfig` (IN `temp_prog` DOUBLE(4,2), IN `seg_porta_ex` INT, IN `nsalas` INT)   BEGIN

DECLARE existeConfig INT;

SELECT COUNT(*) INTO existeConfig 
FROM configuracaolabirinto;

IF existeConfig > 0 THEN
	UPDATE configuracaolabirinto
    SET 
    configuracaolabirinto.temperaturaprogramada = temp_prog,
    configuracaolabirinto.segundosaberturaportaexterior = seg_porta_ex,
    configuracaolabirinto.numerosalas = nsalas
    WHERE configuracaolabirinto.IDConfiguracao = 0;
ELSE
	INSERT INTO configuracaolabirinto(IDConfiguracao, temperaturaprogramada, segundosaberturaportaexterior, numerosalas)
    VALUES(0,temp_prog, seg_porta_ex,nsalas);
END IF;
END$$

DROP PROCEDURE IF EXISTS `WriteMov`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `WriteMov` (IN `id_mongo` VARCHAR(100), IN `hora` TIMESTAMP, IN `salaentrada` INT, IN `salasaida` INT)  NO SQL BEGIN

DECLARE duplicate INT;

SELECT COUNT(*) into duplicate
FROM medicoespassagens
WHERE medicoespassagens.IDMongo = id_mongo;

IF duplicate = 0 THEN
    IF OngoingExp() THEN
        INSERT INTO medicoespassagens (IDMongo, hora, salaentrada, salasaida, IDExperiencia)
        VALUES (id_mongo, hora, salaentrada, salasaida, GetOngoingExpId());
    ELSEIF ((salaentrada + salasaida) = 0) THEN
        INSERT INTO medicoespassagens (IDMongo, hora, salaentrada, salasaida, IDExperiencia)
        VALUES (id_mongo, hora, salaentrada, salasaida, NULL);
    END IF;
END IF;
END$$

DROP PROCEDURE IF EXISTS `WriteTemp`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `WriteTemp` (IN `id_mongo` VARCHAR(100), IN `sensor` INT, IN `hora` TIMESTAMP, IN `leitura` DECIMAL(4,2))  NO SQL BEGIN

DECLARE duplicate INT;

SELECT COUNT(*) into duplicate
FROM medicoestemperatura
WHERE medicoestemperatura.IDMongo = id_mongo;

IF duplicate = 0 THEN
    IF OngoingExp() THEN
        INSERT INTO medicoestemperatura (IDMongo, sensor, hora, leitura, IDExperiencia) 
        VALUES (id_mongo, sensor, hora, leitura, GetOngoingExpId());
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
  `tipo` varchar(20) NOT NULL DEFAULT 'light',
  `mensagem` varchar(100) NOT NULL,
  `horaescrita` timestamp NOT NULL DEFAULT current_timestamp(),
  `IDExperiencia` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `IDExperiencia` (`IDExperiencia`)
) ENGINE=InnoDB AUTO_INCREMENT=432410 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

--
-- Dumping data for table `alerta`
--

INSERT INTO `alerta` (`id`, `hora`, `sala`, `sensor`, `leitura`, `tipo`, `mensagem`, `horaescrita`, `IDExperiencia`) VALUES
(432404, '2023-04-25 15:13:48', NULL, 1, '47.01', 'light_temp', 'Temperatura perto do limite máximo', '2023-04-25 15:13:48', NULL),
(432405, '2023-04-25 15:13:54', NULL, 1, '47.01', 'light_temp', 'Temperatura perto do limite máximo', '2023-04-25 15:13:54', NULL),
(432406, '2023-04-25 15:13:59', NULL, 1, '47.01', 'light_temp', 'Temperatura perto do limite máximo', '2023-04-25 15:13:59', NULL),
(432407, '2023-04-25 15:21:59', 2, NULL, NULL, 'urgent_mov', 'Excedeu numero de ratos', '2023-04-25 15:21:59', NULL),
(432408, '2023-04-25 15:22:04', 2, NULL, NULL, 'urgent_mov', 'Excedeu numero de ratos', '2023-04-25 15:22:05', NULL),
(432409, '2023-04-25 15:22:20', 2, NULL, NULL, 'urgent_mov', 'Excedeu numero de ratos', '2023-04-25 15:22:20', NULL);

--
-- Triggers `alerta`
--
DROP TRIGGER IF EXISTS `AlertPeriodicity`;
DELIMITER $$
CREATE TRIGGER `AlertPeriodicity` BEFORE INSERT ON `alerta` FOR EACH ROW BEGIN

DECLARE time_alert TIMESTAMP;
DECLARE periodicidade DOUBLE;
DECLARE alertaExiste, sensor, sala INT;

SELECT parametrosadicionais.PeriodicidadeAlerta INTO periodicidade
FROM parametrosadicionais
WHERE parametrosadicionais.IDExperiencia = GetOngoingExpId();

IF NEW.tipo <> 'urgent_temp' THEN
	IF NEW.tipo <> 'urgent_mov' THEN
    	
        IF NEW.tipo = 'light_mov' THEN

            SELECT COUNT(*) INTO alertaExiste
            FROM alerta
            WHERE alerta.tipo = NEW.tipo and alerta.sala = NEW.sala;

            IF alertaExiste > 0 THEN

                SELECT MAX(alerta.hora) into time_alert
                FROM alerta
                WHERE alerta.tipo = NEW.tipo and alerta.sala = NEW.sala;

                IF (TIMESTAMPDIFF(SECOND, time_alert, NEW.hora)) <  periodicidade THEN
                    SIGNAL SQLSTATE '45000'
                    SET MESSAGE_TEXT = 'Periodicidade alerta';
                END IF;
            END IF;
         ELSE 
         	SELECT COUNT(*) INTO alertaExiste FROM alerta 
   			WHERE alerta.tipo = NEW.tipo and alerta.sensor = NEW.sensor;
    
   		 	IF alertaExiste > 0 THEN
                SELECT MAX(alerta.hora) into time_alert
                FROM alerta
                WHERE alerta.tipo = NEW.tipo and alerta.sensor = NEW.sensor;

                IF (TIMESTAMPDIFF(SECOND, time_alert, NEW.hora)) <  periodicidade THEN
                    SIGNAL SQLSTATE '45000'
                    SET MESSAGE_TEXT = 'Periodicidade Alerta';
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
  `IDConfiguracao` int(11) NOT NULL,
  `temperaturaprogramada` double(4,2) NOT NULL,
  `segundosaberturaportaexterior` int(11) NOT NULL,
  `numerosalas` int(11) NOT NULL,
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
  `descricao` text NOT NULL,
  `investigador` varchar(50) DEFAULT NULL,
  `DataRegisto` timestamp NULL DEFAULT current_timestamp(),
  `numeroratos` int(11) NOT NULL,
  `limiteratossala` int(11) NOT NULL,
  `segundossemmovimento` int(11) NOT NULL,
  `temperaturaideal` decimal(4,2) DEFAULT NULL,
  `variacaotemperaturamaxima` decimal(4,2) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `investigador` (`investigador`)
) ENGINE=InnoDB AUTO_INCREMENT=24 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

--
-- Dumping data for table `experiencia`
--

INSERT INTO `experiencia` (`id`, `descricao`, `investigador`, `DataRegisto`, `numeroratos`, `limiteratossala`, `segundossemmovimento`, `temperaturaideal`, `variacaotemperaturamaxima`) VALUES
(21, '', NULL, '2023-04-25 15:18:46', 40, 10, 120, '18.00', '10.00'),
(22, '', NULL, '2023-04-25 15:18:46', 40, 10, 120, '18.00', '20.00'),
(23, '', NULL, '2023-04-25 15:19:21', 40, 10, 120, '18.00', '30.00');

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
  `salaentrada` int(11) NOT NULL,
  `salasaida` int(11) NOT NULL,
  `IDExperiencia` int(11) DEFAULT NULL,
  PRIMARY KEY (`IDMongo`),
  KEY `IDExperiencia` (`IDExperiencia`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

--
-- Dumping data for table `medicoespassagens`
--

INSERT INTO `medicoespassagens` (`IDMongo`, `hora`, `salaentrada`, `salasaida`, `IDExperiencia`) VALUES
('01199311-d01e-4669-bae1-01381db4973d', '2023-04-25 15:20:09', 2, 1, 21),
('04b1a2ff-c535-4776-aa51-e68470a4512b', '2023-04-25 15:22:20', 2, 1, 23),
('0702e603-cfd4-47f1-9147-38c1f6585518', '2023-04-25 15:20:11', 2, 1, 21),
('07fb710e-5497-4805-8c83-4515dddb518e', '2023-04-25 15:22:03', 2, 1, 22),
('090b979b-4200-419f-866c-f13ce04d88cb', '2023-04-25 15:22:13', 2, 1, 23),
('0bfdfc2e-56c2-4fd8-9b32-96a172c6dae8', '2023-04-25 15:20:07', 2, 1, 21),
('15b5a4d8-f9fb-4165-9b7a-b94d9f25683c', '2023-04-25 15:20:22', 2, 1, 22),
('1674ba6d-fabc-42c8-96f0-e125bbc09dbd', '2023-04-25 15:22:15', 2, 1, 23),
('1c37d746-043f-44e2-af65-e881cf206f0d', '2023-04-25 15:22:11', 0, 0, NULL),
('2248bec1-93e6-4bb6-82da-ee508ba634f3', '2023-04-25 15:21:58', 2, 1, 21),
('433e507b-6814-49f1-917d-8e1fa875b9e8', '2023-04-25 15:21:54', 0, 0, NULL),
('4df4a6bc-54b2-4d8d-a5dc-abdeafa331eb', '2023-04-25 15:22:12', 2, 1, 23),
('5482bc2c-0b4c-4213-b5c7-6e0fb82d4501', '2023-04-25 15:21:59', 2, 1, 21),
('56baf810-5542-4073-acb7-35e9a5bcadf9', '2023-04-25 15:20:19', 2, 1, 22),
('5c61c9b8-b159-4aea-a704-43afd8af2cff', '2023-04-25 15:21:57', 2, 1, 21),
('5c645872-eb73-4c4e-84b9-3d83dd42aa0a', '2023-04-25 15:22:16', 2, 1, 23),
('676cfd99-2268-46ae-8c06-bd766f6701e3', '2023-04-25 15:20:20', 2, 1, 22),
('6b1d9ed9-713c-4567-8dce-ce6caecd7054', '2023-04-25 15:20:24', 0, 0, 22),
('6b407c29-2708-4b5b-956f-e408d55bd8d9', '2023-04-25 15:20:08', 2, 1, 21),
('6c0f81a4-0af7-4a4e-af47-158514ea92b2', '2023-04-25 15:20:25', 2, 1, 23),
('6f2681fe-64ad-4c99-b0ba-12ae248136bb', '2023-04-25 15:20:29', 0, 0, 23),
('71e5f76c-6d62-4345-9b07-bf8fd74355d0', '2023-04-25 15:21:56', 2, 1, 21),
('78bb4c86-1f5b-4213-9d3d-6dd5064e70e2', '2023-04-25 15:20:16', 2, 1, 22),
('7a99d1a7-e106-42ed-ba1c-967dbeff8a66', '2023-04-25 15:20:28', 2, 1, 23),
('7d35c552-a4a6-4510-9c85-4bf511b13e3b', '2023-04-25 15:22:02', 0, 0, NULL),
('80a0ab53-08a7-4fec-bea6-6d1545085cbd', '2023-04-25 15:20:26', 2, 1, 23),
('95e83aea-35b1-4ebb-867b-473ea12f9e78', '2023-04-25 15:21:55', 2, 1, 21),
('9a18c6f6-b4b3-454c-8b3c-4311648b651f', '2023-04-25 15:22:19', 2, 1, 23),
('9b2db9cc-fd57-4de1-85d9-d1663d100794', '2023-04-25 15:22:14', 2, 1, 23),
('a6ead4d8-ca95-464e-ab2a-079f202a775d', '2023-04-25 15:20:14', 2, 1, 22),
('aa1e6596-c771-4d70-a3b0-016235bed6b7', '2023-04-25 15:22:04', 2, 1, 22),
('b6184edf-a768-4f10-9eb3-a4c1c1094abc', '2023-04-25 15:20:10', 2, 1, 21),
('b92e1f54-22a9-48ff-825a-6d24b1f731c5', '2023-04-25 15:20:17', 2, 1, 22),
('d3f9014d-a02f-40d9-9918-fdffd2553e62', '2023-04-25 15:20:23', 2, 1, 22),
('da9b556f-88df-4b4e-aad2-f63ec9ab3182', '2023-04-25 15:22:18', 2, 1, 23),
('e0c8ac84-2b97-431a-91e7-ba31e7f6fe13', '2023-04-25 15:20:13', 0, 0, 21),
('e0cf0352-962f-4d4b-a873-23ac7db2497a', '2023-04-25 15:20:06', 0, 0, NULL),
('e73b2a67-ff2d-4bbe-890a-370581c858a4', '2023-04-25 15:20:18', 2, 1, 22),
('e8da180d-ff0b-4887-82f7-399fe8ea633d', '2023-04-25 15:20:21', 2, 1, 22),
('f28fef15-ebfa-4696-8921-4fda31ce14b6', '2023-04-25 15:20:12', 2, 1, 21);

--
-- Triggers `medicoespassagens`
--
DROP TRIGGER IF EXISTS `CheckRatsMov`;
DELIMITER $$
CREATE TRIGGER `CheckRatsMov` BEFORE INSERT ON `medicoespassagens` FOR EACH ROW BEGIN

DECLARE tempo_sem_mov INT;

SELECT experiencia.segundossemmovimento INTO tempo_sem_mov FROM experiencia 
WHERE experiencia.id = GetOngoingExpId();

IF TIMESTAMPDIFF(SECOND, (SELECT MAX(hora) FROM medicoespassagens), NOW()) > tempo_sem_mov THEN
	INSERT INTO alerta(alerta.hora,alerta.tipo,alerta.mensagem,alerta.horaescrita)
    VALUES (CURRENT_TIMESTAMP, 'urgent_mov', "Ratos não se movimentaram", CURRENT_TIMESTAMP);
END IF;
END
$$
DELIMITER ;
DROP TRIGGER IF EXISTS `RatsCount`;
DELIMITER $$
CREATE TRIGGER `RatsCount` AFTER INSERT ON `medicoespassagens` FOR EACH ROW BEGIN

DECLARE expID, salaEntradaExiste, salaSaidaExiste, nr_ratos, max_ratos, nr_ratos_salasaida INT;

SET expID = GetOngoingExpId();

IF NEW.salaentrada <> NEW.salasaida THEN 

SELECT medicoessala.numeroratosfinal INTO nr_ratos_salasaida
FROM medicoessala
WHERE medicoessala.sala = NEW.salasaida and medicoessala.IDExperiencia = expID;

SELECT COUNT(1) into salaEntradaExiste
FROM medicoessala
WHERE medicoessala.idexperiencia = expID and medicoessala.sala = NEW.salaentrada;

SELECT COUNT(1) into salaSaidaExiste
FROM medicoessala
WHERE medicoessala.idexperiencia = expID and medicoessala.sala = NEW.salasaida;

IF salaEntradaExiste = 1 THEN
	IF (nr_ratos_salasaida - 1 >= 0) THEN
        UPDATE medicoessala
        SET medicoessala.numeroratosfinal = GetRatsInRoom(NEW.salaentrada) + 1
        WHERE medicoessala.idexperiencia = expID and medicoessala.sala = NEW.salaentrada;
    END IF;
END IF;

IF salaSaidaExiste = 1 THEN
	IF (nr_ratos_salasaida - 1 >= 0) THEN
        UPDATE medicoessala
        SET medicoessala.numeroratosfinal = GetRatsInRoom(NEW.salasaida) - 1
        WHERE medicoessala.idexperiencia = expID and medicoessala.sala = NEW.salasaida;
    END IF;
END IF;

SET nr_ratos = GetRatsInRoom(NEW.salaentrada);

SELECT experiencia.limiteratossala INTO max_ratos
FROM experiencia
WHERE experiencia.id = GetOngoingExpId();

IF (nr_ratos > max_ratos) THEN
	IF new.salaentrada <> 1 THEN
        INSERT INTO alerta (hora,sala,sensor,leitura,tipo,mensagem,horaescrita)
        VALUES (NEW.hora,NEW.salaentrada,null,null,'urgent_mov','Excedeu numero de ratos',CURRENT_TIMESTAMP());
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
  `numeroratosfinal` int(11) NOT NULL,
  `sala` int(11) NOT NULL,
  PRIMARY KEY (`IDExperiencia`,`sala`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

--
-- Dumping data for table `medicoessala`
--

INSERT INTO `medicoessala` (`IDExperiencia`, `numeroratosfinal`, `sala`) VALUES
(21, 29, 1),
(21, 11, 2),
(21, 0, 3),
(21, 0, 4),
(21, 0, 5),
(21, 0, 6),
(21, 0, 7),
(21, 0, 8),
(21, 0, 9),
(22, 29, 1),
(22, 11, 2),
(22, 0, 3),
(22, 0, 4),
(22, 0, 5),
(22, 0, 6),
(22, 0, 7),
(22, 0, 8),
(22, 0, 9),
(23, 29, 1),
(23, 11, 2),
(23, 0, 3),
(23, 0, 4),
(23, 0, 5),
(23, 0, 6),
(23, 0, 7),
(23, 0, 8),
(23, 0, 9);

-- --------------------------------------------------------

--
-- Table structure for table `medicoestemperatura`
--

DROP TABLE IF EXISTS `medicoestemperatura`;
CREATE TABLE IF NOT EXISTS `medicoestemperatura` (
  `IDMongo` varchar(100) NOT NULL,
  `hora` timestamp NOT NULL DEFAULT current_timestamp(),
  `leitura` decimal(4,2) NOT NULL,
  `sensor` int(11) NOT NULL,
  `IDExperiencia` int(11) DEFAULT NULL,
  PRIMARY KEY (`IDMongo`),
  KEY `IDExperiencia` (`IDExperiencia`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

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
  `IDExperiencia` int(11) NOT NULL,
  `codigoodor` int(11) NOT NULL,
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
  `PeriodicidadeAlerta` double DEFAULT NULL,
  PRIMARY KEY (`IDExperiencia`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `parametrosadicionais`
--

INSERT INTO `parametrosadicionais` (`IDExperiencia`, `DataHoraInicio`, `DataHoraFim`, `MotivoTermino`, `PeriodicidadeAlerta`) VALUES
(21, '2023-04-25 15:21:54', '2023-04-25 15:21:59', 'Excedeu numero de ratos', NULL),
(22, '2023-04-25 15:22:02', '2023-04-25 15:22:04', 'Excedeu numero de ratos', NULL),
(23, '2023-04-25 15:22:11', '2023-04-25 15:22:20', 'Excedeu numero de ratos', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `substanciasexperiencia`
--

DROP TABLE IF EXISTS `substanciasexperiencia`;
CREATE TABLE IF NOT EXISTS `substanciasexperiencia` (
  `numeroratos` int(11) NOT NULL,
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
  `nome` varchar(100) NOT NULL,
  `telefone` varchar(12) NOT NULL,
  `tipo` varchar(3) NOT NULL,
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
