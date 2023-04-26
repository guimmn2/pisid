-- phpMyAdmin SQL Dump
-- version 5.2.0
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1:3307
-- Generation Time: Apr 26, 2023 at 12:04 PM
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
) ENGINE=InnoDB AUTO_INCREMENT=432470 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

--
-- Dumping data for table `alerta`
--

INSERT INTO `alerta` (`id`, `hora`, `sala`, `sensor`, `leitura`, `tipo`, `mensagem`, `horaescrita`, `IDExperiencia`) VALUES
(432460, '2023-04-26 08:11:30', 2, NULL, NULL, 'urgent_mov', 'Excedeu limite de ratos por sala', '2023-04-26 08:11:30', NULL),
(432461, '2023-04-26 08:12:15', 1, NULL, NULL, 'light_mov', 'Número de ratos na sala perto do limite', '2023-04-26 08:12:15', NULL),
(432462, '2023-04-26 08:15:06', 2, NULL, NULL, 'light_mov', 'Número de ratos na sala perto do limite', '2023-04-26 08:15:06', NULL),
(432463, '2023-04-26 08:24:55', 2, NULL, NULL, 'light_mov', 'Número de ratos na sala perto do limite', '2023-04-26 08:24:55', NULL),
(432464, '2023-04-26 11:58:29', 2, NULL, NULL, 'light_mov', 'Número de ratos na sala perto do limite', '2023-04-26 11:58:29', NULL),
(432465, '2023-04-26 11:58:39', 2, NULL, NULL, 'urgent_mov', 'Excedeu limite de ratos por sala', '2023-04-26 11:58:39', NULL),
(432466, '2023-04-26 11:59:20', 2, NULL, NULL, 'light_mov', 'Número de ratos na sala perto do limite', '2023-04-26 11:59:20', NULL),
(432467, '2023-04-26 11:59:23', 2, NULL, NULL, 'urgent_mov', 'Excedeu limite de ratos por sala', '2023-04-26 11:59:23', NULL),
(432468, '2023-04-26 12:03:57', 2, NULL, NULL, 'light_mov', 'Número de ratos na sala perto do limite', '2023-04-26 12:03:57', NULL),
(432469, '2023-04-26 12:03:59', NULL, 1, '20.01', 'urgent_temp', 'Temperatura alta excedeu limite máximo', '2023-04-26 12:03:59', NULL);

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
(26, NULL, NULL, '2023-04-25 22:32:39', 40, 25, 80, '18.00', '0.00'),
(27, NULL, NULL, '2023-04-25 22:32:39', 30, 19, 39, '18.00', '0.00');

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
('009ab170-7286-44b3-9c5d-35a7d60d77b6', '2023-04-26 11:58:31', 2, 1, 24),
('01151798-f151-479c-9af9-cf12eba69731', '2023-04-26 08:23:05', 2, 1, 27),
('01835b02-bd64-4b01-bf62-621f4bd72736', '2023-04-26 08:23:09', 0, 0, NULL),
('0384460b-90f4-409f-8997-f0902246493b', '2023-04-26 11:59:11', 2, 1, 25),
('0504d5b6-c3dc-4e2d-a31e-0370e19d99ec', '2023-04-26 11:58:24', 2, 1, 24),
('06ccd66c-550f-4ab2-ac06-d954757c2d3e', '2023-04-26 11:57:52', 2, 1, 24),
('06d60130-68fb-43d7-bc72-9f382230e810', '2023-04-26 12:02:15', 2, 1, 27),
('0b07b2fa-5c47-4dee-bf49-6d87fadf2046', '2023-04-26 11:58:20', 2, 1, 24),
('0f5eeab9-1ba3-4edd-8415-df4ac9405914', '2023-04-26 11:58:06', 2, 1, 24),
('106558da-99ed-4a4e-827c-2f031e2091f7', '2023-04-26 11:58:56', 2, 1, 25),
('1127f4e7-24e5-45a4-b385-37184d2f8506', '2023-04-26 12:03:58', 2, 1, 27),
('12113cce-f408-47f0-b01d-22b0a1bdc3f9', '2023-04-26 12:02:17', 2, 1, 27),
('12afab62-00b9-4d95-b581-8e3136efe9b8', '2023-04-26 11:58:01', 2, 1, 24),
('162fb96d-57ea-400a-ad94-13d6b11bf134', '2023-04-26 08:23:56', 0, 0, NULL),
('18ce89e5-50eb-45eb-b241-b131a814aa30', '2023-04-26 11:58:36', 2, 1, 24),
('18fbed99-28ea-4306-a54a-9dfe19477573', '2023-04-26 11:58:33', 2, 1, 24),
('1a8e6e03-105f-4660-baca-02fc7eb9f64b', '2023-04-26 11:58:46', 2, 1, 25),
('1c7b71ba-11ef-41ae-90ac-10dcd5a60e5d', '2023-04-26 12:02:34', 2, 1, 27),
('1d18e6eb-eca5-4bae-885f-795170692daa', '2023-04-26 08:24:51', 0, 0, NULL),
('202d5aa6-40b0-4e45-b7cd-fa7910531393', '2023-04-26 12:02:24', 2, 1, 27),
('21165fa6-e4dc-4cd3-8b24-7476ebf440b3', '2023-04-26 12:02:18', 2, 1, 27),
('26777d37-7bbd-499a-bd0b-b307ffa82470', '2023-04-26 11:58:15', 2, 1, 24),
('2ad93ebb-827b-4747-8719-14e5c0e832aa', '2023-04-26 11:58:39', 2, 1, 24),
('2ae2998e-a43f-4317-ae8d-df555b80bc3f', '2023-04-26 12:03:57', 2, 1, 27),
('2bd87c40-f15f-4aed-b22a-81819c0e3182', '2023-04-26 08:23:04', 2, 1, 27),
('2fe6cd3a-722a-45fa-8a9f-475a4a1132f6', '2023-04-26 11:58:44', 2, 1, 25),
('2ff5428c-fe51-48be-8fd2-b57f0041acca', '2023-04-26 08:23:53', 2, 1, 27),
('347232cf-6842-4b45-9a4b-3d87e4950d35', '2023-04-26 11:58:00', 2, 1, 24),
('34b32e2f-eb13-46b7-9e81-2e5f0d624282', '2023-04-26 11:58:52', 2, 1, 25),
('36119f70-a092-4a25-879e-1fab1bb3b2b5', '2023-04-26 08:23:08', 2, 1, 27),
('3679509a-12b9-4206-a6a3-753bd8f2c049', '2023-04-26 11:59:10', 2, 1, 25),
('391f9822-ab3f-4349-8b04-3362211475ab', '2023-04-26 08:23:00', 0, 0, NULL),
('3b24ead3-af8b-49fd-8ffb-b607bbdc0ec2', '2023-04-26 11:58:21', 2, 1, 24),
('3d49cfc2-699d-453d-b5ff-f7101b74b9dd', '2023-04-26 08:23:06', 2, 1, 27),
('3dae02e3-1e2a-4959-96b8-8641b4397be5', '2023-04-26 11:58:02', 2, 1, 24),
('41cb3585-dbde-4e45-9e88-f40455c3415b', '2023-04-26 08:23:03', 2, 1, 27),
('4609b7fd-e0d4-45d1-8995-920659c3ec1d', '2023-04-26 11:57:42', 2, 1, 24),
('4a0ebb53-968d-4366-9995-1860e4289649', '2023-04-26 11:58:19', 2, 1, 24),
('4f88878d-e078-43d7-b61f-6e92691b38fa', '2023-04-26 12:02:31', 2, 1, 27),
('50a16c4d-93ab-489a-8ef5-07d55f43e39f', '2023-04-26 08:23:51', 2, 1, 27),
('544e3be6-ae64-4d11-8a9a-77da7d3e5a47', '2023-04-26 11:57:49', 2, 1, 24),
('571d4fa9-f0fa-421c-b56c-4460ee1ac1b1', '2023-04-26 08:23:52', 2, 1, 27),
('5762b149-18fe-4798-af8b-27c891862409', '2023-04-26 11:57:44', 2, 1, 24),
('57da9886-5bea-4e99-8b60-8edba5bab187', '2023-04-26 12:02:27', 2, 1, 27),
('5b79df17-a811-4768-bacc-6e075eba8b7f', '2023-04-26 08:24:55', 2, 1, 27),
('5d3a6860-e6d1-4253-93a3-0553a521dc33', '2023-04-26 11:58:30', 2, 1, 24),
('5f0156ec-b5d2-45b7-b529-271b48c73042', '2023-04-26 12:02:40', 2, 1, 27),
('5f159fcb-f268-4ec4-8cdc-26a1a6134c49', '2023-04-26 12:03:56', 0, 0, NULL),
('5f52c789-5ad3-4824-9543-a75803506bbe', '2023-04-26 11:59:13', 0, 0, NULL),
('62674429-2f38-4a78-b3d8-cb964dbec29c', '2023-04-26 11:58:22', 2, 1, 24),
('6559dd0c-5308-4644-a4ca-326e7426fe12', '2023-04-26 11:58:42', 2, 1, 25),
('68215555-116d-4ccb-afe1-4d0810620745', '2023-04-26 11:57:51', 2, 1, 24),
('69153944-2f3c-48bd-924c-2fa1804d6c57', '2023-04-26 11:59:08', 2, 1, 25),
('69bd9f72-9551-4767-98a2-73b4b1124016', '2023-04-26 08:24:52', 2, 1, 27),
('6c2954ce-19e1-4781-9e4b-750aeeeae29e', '2023-04-26 11:57:59', 2, 1, 24),
('74e767b0-9689-4132-8f4b-ed7e7697041a', '2023-04-26 12:02:19', 2, 1, 27),
('76fa2661-1605-462b-9c0f-097479aeca5a', '2023-04-26 08:24:56', 2, 1, 27),
('7a92ce29-d148-4834-994a-194bc9cc7ea6', '2023-04-26 11:58:45', 2, 1, 25),
('7bc543ad-3bcc-4c89-9f3d-951750c12c51', '2023-04-26 12:02:30', 2, 1, 27),
('7fb0593a-4712-4d45-87d8-56afda6e1415', '2023-04-26 08:23:02', 2, 1, 27),
('82205e2b-ba10-4e0b-bc22-ceb7822c842b', '2023-04-26 11:59:00', 2, 1, 25),
('85da3201-c07d-433c-9b5b-039f8ba19949', '2023-04-26 11:58:18', 2, 1, 24),
('862f4ea6-068f-4a28-b440-d51085c34916', '2023-04-26 08:23:50', 0, 0, NULL),
('878e7374-aa3c-4416-98ba-558d71870b5c', '2023-04-26 08:23:55', 2, 1, 27),
('92b00f34-53b9-499b-9f75-1e47f6611f92', '2023-04-26 11:59:14', 2, 1, 26),
('953a1720-b11a-4e24-9fe5-0d671c86c438', '2023-04-26 11:58:03', 2, 1, 24),
('9bf5f1b3-8abd-4552-86f6-968541dc38cc', '2023-04-26 11:59:15', 2, 1, 26),
('9c1015bf-6400-4a46-9056-a130baf98f45', '2023-04-26 11:59:17', 0, 0, NULL),
('a355da6e-7da3-4b41-bd7d-0c2ef22e9316', '2023-04-26 11:59:16', 2, 1, 26),
('a4f196fc-e056-4829-91a5-146d7194c7bb', '2023-04-26 08:23:54', 2, 1, 27),
('a870b469-e29a-457b-9066-b7a91dc39da9', '2023-04-26 12:02:36', 2, 1, 27),
('a924e45f-65fd-4539-a064-1a7be72cd4a9', '2023-04-26 12:02:33', 2, 1, 27),
('ae4eb21c-80b7-4138-88bf-37bd35a9f22c', '2023-04-26 11:59:23', 2, 1, 27),
('af1ef818-0103-4d05-b40b-aa4d5f37c799', '2023-04-26 12:02:11', 2, 1, 27),
('b1f2f2d1-eb42-4bba-9481-7b4fd2367c7d', '2023-04-26 12:02:09', 2, 1, 27),
('b354a0e1-0ee6-4641-a396-2971501e38c4', '2023-04-26 08:24:54', 2, 1, 27),
('bb48535b-48da-4bb9-9c80-b353188b38ef', '2023-04-26 11:59:04', 2, 1, 25),
('bf088955-35fb-42ac-bd31-88ab89eb7049', '2023-04-26 11:58:32', 2, 1, 24),
('c195b02e-6bc6-49da-a24f-3a811abe3e6e', '2023-04-26 11:58:58', 2, 1, 25),
('c7bc9b88-751b-42b6-a33b-78083d129e3e', '2023-04-26 08:24:57', 0, 0, NULL),
('c9583ff5-5c9c-40b5-a7b9-da6910f101de', '2023-04-26 11:59:21', 2, 1, 27),
('c9ae9880-4a73-4317-8d71-00063a011bcb', '2023-04-26 11:58:40', 0, 0, NULL),
('cab4d19e-4c58-4687-b0a2-7a27793262f2', '2023-04-26 11:57:48', 2, 1, 24),
('cb1803d4-8a64-4f3a-9f2d-c385b02bea0a', '2023-04-26 11:58:29', 2, 1, 24),
('cb71153b-da34-4af5-bdfb-3d5781290712', '2023-04-26 08:23:07', 2, 1, 27),
('cc48d540-8910-4e8f-ad75-8990dcb49e93', '2023-04-26 08:24:53', 2, 1, 27),
('ce7b45d7-a36f-4a21-b19e-0991f19efd12', '2023-04-26 11:59:12', 2, 1, 25),
('d1442a94-d2b1-4d50-8745-34b9275c0b02', '2023-04-26 11:58:47', 2, 1, 25),
('d3d936b7-1247-4fd9-82fb-f48168cf65a4', '2023-04-26 11:57:54', 2, 1, 24),
('d3fd0d3e-fa83-4253-966d-a2a36528da44', '2023-04-26 11:58:59', 2, 1, 25),
('d8c2f72b-d971-4f30-89b1-314463583f69', '2023-04-26 11:58:34', 2, 1, 24),
('d9ede975-7d84-4f4b-9163-ea40d37c71f9', '2023-04-26 11:58:04', 2, 1, 24),
('da403efb-a2a5-4824-8c5a-1cfe3eaf8608', '2023-04-26 11:57:39', 0, 0, NULL),
('dd707bbd-2675-4a4c-90d3-ecd817b11d3a', '2023-04-26 11:59:19', 2, 1, 27),
('ded5c8d5-f9e3-4576-85ef-a4f69d3c89a1', '2023-04-26 08:25:00', 0, 0, NULL),
('e42e8e1b-4573-4f47-a0c1-1107e03fa468', '2023-04-26 12:02:08', 0, 0, NULL),
('ec9a1a6a-ae34-4c8c-8eed-3b2d76107b56', '2023-04-26 11:59:07', 2, 1, 25),
('eea8d0db-fcc4-4568-b93b-3a941ddf7d09', '2023-04-26 11:58:16', 2, 1, 24),
('f0217ca8-b765-421b-af39-57b33ae646c5', '2023-04-26 11:58:09', 2, 1, 24),
('fcec9cec-5d32-42e4-aa93-699e3610a9cc', '2023-04-26 12:02:21', 2, 1, 27);

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
(24, 9, 1),
(24, 31, 2),
(24, 0, 3),
(24, 0, 4),
(24, 0, 5),
(24, 0, 6),
(24, 0, 7),
(24, 0, 8),
(24, 0, 9),
(25, 24, 1),
(25, 16, 2),
(25, 0, 3),
(25, 0, 4),
(25, 0, 5),
(25, 0, 6),
(25, 0, 7),
(25, 0, 8),
(25, 0, 9),
(26, 37, 1),
(26, 3, 2),
(26, 0, 3),
(26, 0, 4),
(26, 0, 5),
(26, 0, 6),
(26, 0, 7),
(26, 0, 8),
(26, 0, 9),
(27, 3, 1),
(27, 17, 2),
(27, 0, 3),
(27, 0, 4),
(27, 0, 5),
(27, 0, 6),
(27, 0, 7),
(27, 0, 8),
(27, 0, 9);

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
('10b1776b-e442-401a-b0e3-b0376aa97865', '2023-04-26 11:57:41', '20.01', 1, 24),
('11c1ed8c-91d6-4330-9c34-e96f31c7485f', '2023-04-26 11:58:55', '20.01', 1, 25),
('14ba608a-8500-47f6-aa4f-6cd5e81220a5', '2023-04-26 11:57:57', '20.01', 1, 24),
('1ab775f0-eed2-4ccb-8d48-a1e669955edb', '2023-04-26 11:57:46', '20.01', 1, 24),
('1dfffa4c-1f55-4a1e-85f8-cb1e7387d6c6', '2023-04-26 11:57:45', '20.01', 1, 24),
('1e4599e3-f31c-45f8-af27-388ea5e32f71', '2023-04-26 11:58:07', '20.01', 1, 24),
('241003c7-cfd6-4f03-b64e-39c61e56d3b4', '2023-04-26 12:02:13', '20.01', 1, 27),
('26fc4162-65d5-4713-818e-2ef248cc871b', '2023-04-26 12:02:39', '20.01', 1, 27),
('2c1278d3-be8d-4236-bc26-490703699a83', '2023-04-26 11:58:53', '20.01', 1, 25),
('2d45afee-93a6-45aa-acc8-29ea820f9038', '2023-04-26 12:02:16', '20.01', 1, 27),
('3e1f772c-b3f8-41cf-a209-56121d960df7', '2023-04-26 12:02:37', '20.01', 1, 27),
('4e983db1-8610-4418-a5c3-37c4d3ccdbf9', '2023-04-26 11:59:22', '20.01', 1, 27),
('529a0910-4221-421d-92bd-f9bf46688926', '2023-04-26 11:58:13', '20.01', 1, 24),
('546b7055-a1a1-4bec-85cd-f0b4fba16616', '2023-04-26 12:02:20', '20.01', 1, 27),
('54b112a6-6fe3-4fc7-978b-2fe34d283811', '2023-04-26 11:58:10', '20.01', 1, 24),
('5550f7b1-e3bc-44c9-9dfb-2c5d1349ac42', '2023-04-26 11:58:17', '20.01', 1, 24),
('55cf1315-c975-439f-9c8e-1c483db2813a', '2023-04-26 12:02:38', '20.01', 1, 27),
('59e46a6f-d193-4b78-8c2d-836cfbc246e2', '2023-04-26 11:58:43', '20.01', 1, 25),
('5b2fb02a-e825-4a9d-bc17-d2ccf62509be', '2023-04-26 11:59:03', '20.01', 1, 25),
('628b4a3c-6d58-4dfa-87c0-c14ee4d37be0', '2023-04-26 11:57:58', '20.01', 1, 24),
('64e6fddb-367f-49fe-9b81-867fbb76c4d6', '2023-04-26 11:58:38', '20.01', 1, 24),
('6cc28c66-8188-42b1-8d2f-7538db0a4d75', '2023-04-26 11:59:09', '20.01', 1, 25),
('863e69d0-1c36-41ad-901f-240b1085d213', '2023-04-26 11:57:56', '20.01', 1, 24),
('88b9660a-0c51-4473-9ded-e742e39cb19c', '2023-04-26 11:58:51', '20.01', 1, 25),
('92462d20-8a34-4ff4-b1b4-942c00a6f544', '2023-04-26 11:59:01', '20.01', 1, 25),
('9ac3b085-3d71-4721-ae75-2e790646827d', '2023-04-26 11:57:40', '20.01', 1, 24),
('a131504b-d81f-4c6e-8f87-095d7b554627', '2023-04-26 11:57:55', '20.01', 1, 24),
('b0cd72bb-990c-4e8a-a52e-383df600ffe7', '2023-04-26 12:02:32', '20.01', 1, 27),
('b2b96c6a-2142-4cce-8a70-322ad2457e31', '2023-04-26 12:02:25', '20.01', 1, 27),
('b56ead5c-22c8-4d37-b614-1e62e621d160', '2023-04-26 11:58:27', '20.01', 1, 24),
('b762d0a4-f560-45ae-a423-ac70e02344d5', '2023-04-26 11:58:23', '20.01', 1, 24),
('bc0b90a1-5db7-4176-92b6-83880724f4b6', '2023-04-26 12:02:26', '20.01', 1, 27),
('c023e30d-71d8-46e6-bc67-aaaa26415159', '2023-04-26 11:59:02', '20.01', 1, 25),
('c315e70a-49f6-4106-924c-cd600522e97f', '2023-04-26 11:58:26', '20.01', 1, 24),
('c53e4573-62fa-40b9-8140-24735b4ed5f5', '2023-04-26 11:57:47', '20.01', 1, 24),
('c5927a62-dafa-4179-be49-2d9bacb4b9b3', '2023-04-26 11:59:06', '20.01', 1, 25),
('d3c2b69b-25d7-4c3a-92ba-aad4791cc379', '2023-04-26 11:58:50', '20.01', 1, 25),
('dc93d732-cc58-43e2-a100-60026ca3c427', '2023-04-26 12:03:59', '20.01', 1, 27),
('dd466944-6967-4d5c-ab02-c547a12e7e96', '2023-04-26 11:57:43', '20.01', 1, 24),
('e3fdfb34-aaf6-42d7-801e-ff719b745ecd', '2023-04-26 12:02:12', '20.01', 1, 27),
('e499e899-7a3f-43c3-8ca4-9ec1b8e12a46', '2023-04-26 11:58:25', '20.01', 1, 24),
('e4e2c29e-3c3c-4cf9-88f6-7739fa5a6b28', '2023-04-26 11:58:35', '20.01', 1, 24),
('e6c8afea-41ba-4786-aab6-fdb96893bf3e', '2023-04-26 12:02:14', '20.01', 1, 27),
('e7e6c5c2-9334-45bd-a94d-b7a422ba3bc8', '2023-04-26 11:57:53', '20.01', 1, 24),
('ea61ecbc-f826-4dc4-9bc0-5b0f1498a9ef', '2023-04-26 12:02:23', '20.01', 1, 27),
('edefecef-a341-4da5-b0ff-c24f07a3baaa', '2023-04-26 11:58:57', '20.01', 1, 25),
('ee0a9f5a-51ee-4751-82d5-168992680bb8', '2023-04-26 11:58:12', '20.01', 1, 24),
('f0302c3f-e44a-4f98-857d-b9cf3b48bf0f', '2023-04-26 11:58:48', '20.01', 1, 25),
('f6986606-1686-416d-b1c5-54b30949f6de', '2023-04-26 11:58:37', '20.01', 1, 24),
('f7ae9085-b350-4866-bc88-d3f41253ecc3', '2023-04-26 11:58:49', '20.01', 1, 25),
('faee60b3-d34d-4ce1-a28d-fb3da423dc4c', '2023-04-26 12:02:28', '20.01', 1, 27),
('fb582908-5c3f-4da1-ad9b-c3d48683424a', '2023-04-26 12:02:29', '20.01', 1, 27),
('fc855f65-76aa-4557-adb1-a48ed669893c', '2023-04-26 11:58:11', '20.01', 1, 24),
('fe4ca1df-86e2-40e4-8d83-ec6bbc837764', '2023-04-26 11:59:18', '20.01', 1, 27),
('fff92db6-ae9a-41eb-bbab-e8bd531a8b09', '2023-04-26 11:58:08', '20.01', 1, 24);

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
(24, '2023-04-26 11:57:39', '2023-04-26 11:58:39', 'Excedeu limite de ratos por sala', 30),
(25, '2023-04-26 11:58:40', '2023-04-26 11:59:13', 'Acabou sem anomalias', 30),
(26, '2023-04-26 11:59:13', '2023-04-26 11:59:17', 'Acabou sem anomalias', 30),
(27, '2023-04-26 12:03:56', '2023-04-26 12:03:59', 'Temperatura alta excedeu limite máximo', 30);

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
