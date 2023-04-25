-- phpMyAdmin SQL Dump
-- version 5.2.0
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1:3307
-- Generation Time: Apr 23, 2023 at 02:16 PM
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

CALL TerminateOngoingExp(dataInicio,"Acabou sem anomalias");

SELECT IDExperiencia INTO id_exp FROM parametrosadicionais 
WHERE parametrosadicionais.DataHoraInicio is NULL LIMIT 1;

UPDATE parametrosadicionais
SET parametrosadicionais.DataHoraInicio = dataInicio
-- proxima exp a decorrer
WHERE IDExperiencia = id_exp;

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
	INSERT INTO alerta (id, hora, sala, sensor, leitura, tipo, mensagem, horaescrita)
	VALUES (id, hora, sala, sensor, leitura, tipo, mensagem, horaescrita);
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
        INSERT INTO medicoespassagens (IDMongo, hora, salaentrada, salasaida)
        VALUES (id_mongo, hora, salaentrada, salasaida);
    ELSEIF ((salaentrada + salasaida) = 0) THEN
        INSERT INTO medicoespassagens (IDMongo, hora, salaentrada, salasaida)
        VALUES (id_mongo, hora, salaentrada, salasaida);
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
        INSERT INTO medicoestemperatura (IDMongo, sensor, hora, leitura) VALUES (id_mongo, sensor, hora, leitura);
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
  `hora` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `sala` int(11) DEFAULT NULL,
  `sensor` int(11) DEFAULT NULL,
  `leitura` decimal(4,2) DEFAULT NULL,
  `tipo` varchar(20) NOT NULL DEFAULT 'light',
  `mensagem` varchar(100) NOT NULL,
  `horaescrita` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=432376 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

--
-- Dumping data for table `alerta`
--

INSERT INTO `alerta` (`id`, `hora`, `sala`, `sensor`, `leitura`, `tipo`, `mensagem`, `horaescrita`) VALUES
(432371, '2023-04-23 13:34:27', NULL, 1, '80.01', 'urgent_temp', 'Temperatura muito alta', '2023-04-23 13:34:27'),
(432372, '2023-04-23 13:34:37', NULL, 1, '80.01', 'urgent_temp', 'Temperatura muito alta', '2023-04-23 13:34:37'),
(432373, '2023-04-23 13:46:14', 2, NULL, NULL, 'urgent_mov', 'Excedeu numero de ratos', '2023-04-23 13:46:14'),
(432374, '2023-04-23 13:53:19', 2, NULL, NULL, 'urgent_mov', 'Excedeu numero de ratos', '2023-04-23 13:53:19'),
(432375, '2023-04-23 13:58:40', 2, NULL, NULL, 'urgent_mov', 'Excedeu numero de ratos', '2023-04-23 13:58:40');

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

IF NEW.tipo = 'light_mov' THEN
	
    SELECT COUNT(*) INTO alertaExiste FROM alerta 
    WHERE alerta.tipo = NEW.tipo and alerta.sala = NEW.sala;
    
    IF alertaExiste > 0 THEN
    	SELECT MAX(alerta.hora) into time_alert
        FROM alerta
        WHERE alerta.tipo = NEW.tipo and alerta.sala = NEW.sala;
        
        IF (TIMESTAMPDIFF(SECOND, time_alert, NEW.hora)) <  periodicidade THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'You can not insert record';
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
            SET MESSAGE_TEXT = 'You can not insert record';
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
  `IDConfiguracao` int(11) NOT NULL AUTO_INCREMENT,
  `numerosalas` int(11) NOT NULL,
  PRIMARY KEY (`IDConfiguracao`)
) ENGINE=MyISAM AUTO_INCREMENT=172 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `configuracaolabirinto`
--

INSERT INTO `configuracaolabirinto` (`IDConfiguracao`, `numerosalas`) VALUES
(171, 10);

--
-- Triggers `configuracaolabirinto`
--
DROP TRIGGER IF EXISTS `CheckLastConfig`;
DELIMITER $$
CREATE TRIGGER `CheckLastConfig` BEFORE INSERT ON `configuracaolabirinto` FOR EACH ROW BEGIN

DECLARE config_sala INT;

SELECT numerosalas INTO config_sala
FROM configuracaolabirinto
ORDER BY IDConfiguracao DESC LIMIT 1;

IF NEW.numerosalas = config_sala THEN
	SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Config igual à anterior';
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
  `DataRegisto` timestamp NULL DEFAULT current_timestamp(),
  `numeroratos` int(11) NOT NULL,
  `limiteratossala` int(11) NOT NULL,
  `segundossemmovimento` int(11) NOT NULL,
  `temperaturaideal` decimal(4,2) NOT NULL,
  `variacaotemperaturamaxima` decimal(4,2) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `investigador` (`investigador`)
) ENGINE=InnoDB AUTO_INCREMENT=16 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

--
-- Dumping data for table `experiencia`
--

INSERT INTO `experiencia` (`id`, `descricao`, `investigador`, `DataRegisto`, `numeroratos`, `limiteratossala`, `segundossemmovimento`, `temperaturaideal`, `variacaotemperaturamaxima`) VALUES
(1, 'ww', NULL, '2023-04-23 13:33:41', 50, 9999, 9999999, '90.00', '20.00'),
(2, 'www', NULL, '2023-04-23 13:33:41', 50, 9999, 9999, '90.00', '30.00');

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
  PRIMARY KEY (`IDMongo`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

--
-- Dumping data for table `medicoespassagens`
--

INSERT INTO `medicoespassagens` (`IDMongo`, `hora`, `salaentrada`, `salasaida`) VALUES
('01b56359-e414-4db0-9102-e37e30d9fb18', '2023-04-23 14:05:24', 0, 0),
('2ee9b2ec-cdc9-4440-867b-fb0adc34bcb0', '2023-04-23 14:05:07', 0, 0),
('7a2cc435-0402-48f7-b00f-e47a705fbfcc', '2023-04-23 14:05:34', 0, 0),
('a9ea2843-32c4-4a30-b908-dd52e376658e', '2023-04-23 14:05:29', 0, 0);

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
(1, 13, 1),
(1, 37, 2),
(1, 0, 3),
(1, 0, 4),
(1, 0, 5),
(1, 0, 6),
(1, 0, 7),
(1, 0, 8),
(1, 0, 9),
(2, 0, 1),
(2, 50, 2),
(2, 0, 3),
(2, 0, 4),
(2, 0, 5),
(2, 0, 6),
(2, 0, 7),
(2, 0, 8),
(2, 0, 9);

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
  PRIMARY KEY (`IDMongo`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

--
-- Dumping data for table `medicoestemperatura`
--

INSERT INTO `medicoestemperatura` (`IDMongo`, `hora`, `leitura`, `sensor`) VALUES
('0e5e4fa6-8282-4789-9e9c-24a4e64f1159', '2023-04-23 14:05:28', '80.01', 1),
('0f59088c-ffa4-424b-84a9-c9b35c16a859', '2023-04-23 14:05:23', '80.01', 1),
('56759fb1-3423-41ea-8115-70692e166ad5', '2023-04-23 14:05:21', '80.01', 1),
('5cf86a3a-5bd3-452f-b545-f2d8910b2559', '2023-04-23 14:05:18', '80.01', 1),
('731fd9d1-05bc-4859-84f4-ec0451cc7442', '2023-04-23 14:05:19', '80.01', 1),
('7be26c4a-2b80-4de9-8ef3-b50ee312bd94', '2023-04-23 14:05:22', '80.01', 1),
('7ee09227-b378-4117-ad80-906755324784', '2023-04-23 14:05:26', '80.01', 1),
('8b8a13b1-16d6-40b0-857a-bec3f0979fdd', '2023-04-23 14:05:27', '80.01', 1),
('99e4c1ff-35a1-48c1-8e3b-d5ccfc7b5ef0', '2023-04-23 14:05:25', '80.01', 1),
('e2a6064c-226b-4374-b22a-30e38a3f2f38', '2023-04-23 14:05:16', '80.01', 1),
('fb82a24f-e1a4-4676-8ec0-ee1d4695cc50', '2023-04-23 14:05:20', '80.01', 1);

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
(1, '2023-04-23 14:05:07', '2023-04-23 14:05:24', 'Acabou sem anomalias', NULL),
(2, '2023-04-23 14:05:24', '2023-04-23 14:05:29', 'Acabou sem anomalias', NULL);

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
-- Constraints for table `experiencia`
--
ALTER TABLE `experiencia`
  ADD CONSTRAINT `experiencia_ibfk_1` FOREIGN KEY (`investigador`) REFERENCES `utilizador` (`email`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Constraints for table `medicoessala`
--
ALTER TABLE `medicoessala`
  ADD CONSTRAINT `medicoessala_ibfk_1` FOREIGN KEY (`IDExperiencia`) REFERENCES `experiencia` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

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
