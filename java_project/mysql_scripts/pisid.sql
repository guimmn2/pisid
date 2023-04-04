-- phpMyAdmin SQL Dump
-- version 4.9.5deb2
-- https://www.phpmyadmin.net/
--
-- Host: localhost:3306
-- Generation Time: Apr 04, 2023 at 02:33 PM
-- Server version: 10.3.38-MariaDB-0ubuntu0.20.04.1
-- PHP Version: 7.4.3-4ubuntu2.18

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET AUTOCOMMIT = 0;
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
CREATE DEFINER=`root`@`localhost` PROCEDURE `StartNextExp` (IN `dataInicio` TIMESTAMP)  NO SQL
BEGIN

UPDATE experiencia
SET DataHoraInicio = dataInicio
-- proxima exp a decorrer
WHERE id = (SELECT id FROM experiencia WHERE DataHoraInicio is NULL LIMIT 1);

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `TerminateOngoingExp` (IN `dataFim` TIMESTAMP)  NO SQL
BEGIN

UPDATE experiencia
SET DataHoraFim = dataFim
WHERE experiencia.id = GetOngoingExpId();

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `WriteMov` (IN `hora` TIMESTAMP, IN `salaentrada` INT, IN `salasaida` INT)  NO SQL
BEGIN
IF OngoingExp() THEN
	INSERT INTO medicoespassagens (hora, salaentrada, salasaida)
    VALUES (hora, salaentrada, salasaida);
END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `WriteTemp` (IN `sensor` INT, IN `hora` TIMESTAMP, IN `leitura` DECIMAL(4,2))  NO SQL
BEGIN
    IF OngoingExp() THEN
        INSERT INTO medicoestemperatura (sensor, hora, leitura) VALUES (sensor, hora, leitura);
    END IF;
END$$

--
-- Functions
--
CREATE DEFINER=`root`@`localhost` FUNCTION `GetOngoingExpId` () RETURNS INT(11) NO SQL
BEGIN
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

CREATE DEFINER=`root`@`localhost` FUNCTION `GetRatsInRoom` (`nrSala` INT) RETURNS INT(11) NO SQL
BEGIN

DECLARE nr_ratos INT;

SELECT numeroratosfinal INTO nr_ratos 
FROM medicoessala
WHERE medicoessala.sala = nrSala AND medicoessala.idexperiencia = GetOngoingExpId();

RETURN nr_ratos;

END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `OngoingExp` () RETURNS TINYINT(1) NO SQL
BEGIN-- id da exp a decorrer
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

CREATE TABLE `alerta` (
  `id` int(11) NOT NULL,
  `hora` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `sala` int(11) DEFAULT NULL,
  `sensor` int(11) DEFAULT NULL,
  `leitura` decimal(4,2) NOT NULL,
  `tipo` varchar(20) NOT NULL DEFAULT 'light',
  `mensagem` varchar(100) NOT NULL,
  `horaescrita` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Dumping data for table `alerta`
--

INSERT INTO `alerta` (`id`, `hora`, `sala`, `sensor`, `leitura`, `tipo`, `mensagem`, `horaescrita`) VALUES
(1, '2023-04-04 12:27:59', NULL, 1, '7.59', 'URGENTE', 'PLS STOP', '2023-04-04 12:27:59'),
(2, '2023-04-04 12:27:59', NULL, 1, '5.46', 'URGENTE', 'PLS STOP', '2023-04-04 12:27:59'),
(3, '2023-04-04 12:27:59', NULL, 1, '1.13', 'URGENTE', 'PLS STOP', '2023-04-04 12:27:59'),
(4, '2023-04-04 12:27:59', NULL, 1, '11.28', 'URGENTE', 'PLS STOP', '2023-04-04 12:27:59'),
(5, '2023-04-04 12:27:59', NULL, 1, '11.61', 'URGENTE', 'PLS STOP', '2023-04-04 12:27:59'),
(6, '2023-04-04 12:28:00', NULL, 1, '8.66', 'URGENTE', 'PLS STOP', '2023-04-04 12:28:00'),
(7, '2023-04-04 12:28:00', NULL, 1, '9.37', 'URGENTE', 'PLS STOP', '2023-04-04 12:28:00'),
(8, '2023-04-04 12:28:00', NULL, 1, '12.66', 'LIGHT', 'epah yah', '2023-04-04 12:28:00'),
(9, '2023-04-04 12:28:00', NULL, 1, '7.55', 'URGENTE', 'PLS STOP', '2023-04-04 12:28:01'),
(10, '2023-04-04 12:28:01', NULL, 1, '0.45', 'URGENTE', 'PLS STOP', '2023-04-04 12:28:01'),
(11, '2023-04-04 12:28:01', NULL, 1, '2.41', 'URGENTE', 'PLS STOP', '2023-04-04 12:28:01'),
(12, '2023-04-04 12:28:01', NULL, 1, '2.10', 'URGENTE', 'PLS STOP', '2023-04-04 12:28:01'),
(13, '2023-04-04 12:28:01', NULL, 1, '6.39', 'URGENTE', 'PLS STOP', '2023-04-04 12:28:01'),
(14, '2023-04-04 12:29:21', NULL, 1, '4.15', 'URGENTE', 'PLS STOP', '2023-04-04 12:29:21'),
(15, '2023-04-04 12:29:21', NULL, 1, '11.44', 'URGENTE', 'PLS STOP', '2023-04-04 12:29:22'),
(16, '2023-04-04 12:29:22', NULL, 1, '3.91', 'URGENTE', 'PLS STOP', '2023-04-04 12:29:22'),
(17, '2023-04-04 12:29:22', NULL, 1, '8.74', 'URGENTE', 'PLS STOP', '2023-04-04 12:29:22'),
(18, '2023-04-04 12:29:22', NULL, 1, '2.32', 'URGENTE', 'PLS STOP', '2023-04-04 12:29:23'),
(19, '2023-04-04 12:29:23', NULL, 1, '0.22', 'URGENTE', 'PLS STOP', '2023-04-04 12:29:23'),
(20, '2023-04-04 12:29:23', NULL, 1, '13.06', 'LIGHT', 'epah yah', '2023-04-04 12:29:23'),
(21, '2023-04-04 12:29:23', NULL, 1, '12.86', 'LIGHT', 'epah yah', '2023-04-04 12:29:23'),
(22, '2023-04-04 12:29:23', NULL, 1, '8.00', 'URGENTE', 'PLS STOP', '2023-04-04 12:29:23'),
(23, '2023-04-04 12:29:24', NULL, 1, '12.46', 'LIGHT', 'epah yah', '2023-04-04 12:29:24'),
(24, '2023-04-04 12:29:24', NULL, 1, '7.67', 'URGENTE', 'PLS STOP', '2023-04-04 12:29:24'),
(25, '2023-04-04 12:29:24', NULL, 1, '10.04', 'URGENTE', 'PLS STOP', '2023-04-04 12:29:24'),
(26, '2023-04-04 12:29:24', NULL, 1, '4.51', 'URGENTE', 'PLS STOP', '2023-04-04 12:29:24'),
(27, '2023-04-04 12:29:24', NULL, 1, '8.47', 'URGENTE', 'PLS STOP', '2023-04-04 12:29:25'),
(28, '2023-04-04 12:29:25', NULL, 1, '6.56', 'URGENTE', 'PLS STOP', '2023-04-04 12:29:25');

-- --------------------------------------------------------

--
-- Table structure for table `experiencia`
--

CREATE TABLE `experiencia` (
  `id` int(11) NOT NULL,
  `descricao` text NOT NULL,
  `investigador` varchar(50) DEFAULT NULL,
  `DataHoraInicio` timestamp NULL DEFAULT NULL ON UPDATE current_timestamp(),
  `DataHoraFim` timestamp NULL DEFAULT NULL,
  `numeroratos` int(11) NOT NULL,
  `limiteratossala` int(11) NOT NULL,
  `segundossemmovimento` int(11) NOT NULL,
  `temperaturaideal` decimal(4,2) NOT NULL,
  `variacaotemperaturamaxima` decimal(4,2) NOT NULL,
  `idrazaofim` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Dumping data for table `experiencia`
--

INSERT INTO `experiencia` (`id`, `descricao`, `investigador`, `DataHoraInicio`, `DataHoraFim`, `numeroratos`, `limiteratossala`, `segundossemmovimento`, `temperaturaideal`, `variacaotemperaturamaxima`, `idrazaofim`) VALUES
(1, 'ww', NULL, '2023-03-17 21:34:58', '2023-03-17 21:35:04', 3, 3, 3, '22.00', '10.00', NULL),
(2, 'ww', NULL, '2023-04-03 15:33:09', '2023-04-03 15:33:00', 3, 3, 3, '22.22', '10.22', NULL),
(3, 'ww', NULL, '2023-04-03 16:05:22', NULL, 3, 3, 3, '22.22', '10.10', NULL),
(4, '', NULL, NULL, NULL, 2, 4, 2, '12.00', '23.00', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `medicoespassagens`
--

CREATE TABLE `medicoespassagens` (
  `id` int(11) NOT NULL,
  `hora` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `salaentrada` int(11) NOT NULL,
  `salasaida` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Dumping data for table `medicoespassagens`
--

INSERT INTO `medicoespassagens` (`id`, `hora`, `salaentrada`, `salasaida`) VALUES
(1, '2023-04-03 16:05:22', 0, 0),
(13, '2023-04-04 12:29:21', 1, 3),
(14, '2023-04-04 12:29:21', 1, 3),
(15, '2023-04-04 12:29:22', 1, 3),
(16, '2023-04-04 12:29:22', 1, 3),
(17, '2023-04-04 12:29:22', 1, 3),
(18, '2023-04-04 12:29:22', 1, 3),
(19, '2023-04-04 12:29:23', 1, 3),
(20, '2023-04-04 12:29:23', 1, 3),
(21, '2023-04-04 12:29:23', 1, 3),
(22, '2023-04-04 12:29:24', 1, 3),
(23, '2023-04-04 12:29:25', 1, 3),
(24, '2023-04-04 12:29:25', 1, 3),
(25, '2023-04-04 12:29:25', 1, 3);

--
-- Triggers `medicoespassagens`
--
DELIMITER $$
CREATE TRIGGER `RatsCount` AFTER INSERT ON `medicoespassagens` FOR EACH ROW BEGIN

DECLARE expID, salaEntradaExiste, salaSaidaExiste INT;
SET expID = GetOngoingExpId();

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

END
$$
DELIMITER ;
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

CREATE TABLE `medicoessala` (
  `idexperiencia` int(11) NOT NULL,
  `numeroratosfinal` int(11) NOT NULL,
  `sala` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `medicoestemperatura`
--

CREATE TABLE `medicoestemperatura` (
  `id` int(11) NOT NULL,
  `hora` timestamp NOT NULL DEFAULT current_timestamp(),
  `leitura` decimal(4,2) NOT NULL,
  `sensor` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Triggers `medicoestemperatura`
--
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
      VALUES (NEW.hora, NULL, NEW.sensor, NEW.leitura, 'URGENTE', 'PLS STOP', CURRENT_TIMESTAMP());
    ELSEIF ((NEW.leitura) < temp_ideal - var_max_temp) THEN
      INSERT INTO alerta (hora, sala, sensor, leitura, tipo, mensagem, horaescrita)
      VALUES (NEW.hora, NULL, NEW.sensor, NEW.leitura, 'URGENTE', 'PLS STOP', CURRENT_TIMESTAMP());
    ELSEIF ((NEW.leitura) > temp_ideal + var_max_temp * 0.9) THEN
      INSERT INTO alerta (hora, sala, sensor, leitura, tipo, mensagem, horaescrita)
      VALUES (NEW.hora, NULL, NEW.sensor, NEW.leitura, 'LIGHT', 'epah yah', CURRENT_TIMESTAMP());
    ELSEIF ((NEW.leitura) < temp_ideal - var_max_temp * 0.9) THEN
      INSERT INTO alerta (hora, sala, sensor, leitura, tipo, mensagem, horaescrita)
      VALUES (NEW.hora, NULL, NEW.sensor, NEW.leitura, 'LIGHT', 'epah yah', CURRENT_TIMESTAMP());
    END IF;
  END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `odoresexperiencia`
--

CREATE TABLE `odoresexperiencia` (
  `sala` int(11) NOT NULL,
  `idexperiencia` int(11) NOT NULL,
  `codigoodor` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `razaofim`
--

CREATE TABLE `razaofim` (
  `id` int(11) NOT NULL,
  `descricao` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `substanciasexperiencia`
--

CREATE TABLE `substanciasexperiencia` (
  `numeroratos` int(11) NOT NULL,
  `codigosubstancia` varchar(5) NOT NULL,
  `idexperiencia` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `utilizador`
--

CREATE TABLE `utilizador` (
  `nome` varchar(100) NOT NULL,
  `telefone` varchar(12) NOT NULL,
  `tipo` varchar(3) NOT NULL,
  `email` varchar(50) NOT NULL,
  `password` text NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Dumping data for table `utilizador`
--

INSERT INTO `utilizador` (`nome`, `telefone`, `tipo`, `email`, `password`) VALUES
('ww', 'ww', 'ww', 'ww', 'ww');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `alerta`
--
ALTER TABLE `alerta`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `experiencia`
--
ALTER TABLE `experiencia`
  ADD PRIMARY KEY (`id`),
  ADD KEY `investigador` (`investigador`),
  ADD KEY `idrazaofim` (`idrazaofim`);

--
-- Indexes for table `medicoespassagens`
--
ALTER TABLE `medicoespassagens`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `medicoessala`
--
ALTER TABLE `medicoessala`
  ADD PRIMARY KEY (`idexperiencia`,`sala`);

--
-- Indexes for table `medicoestemperatura`
--
ALTER TABLE `medicoestemperatura`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `odoresexperiencia`
--
ALTER TABLE `odoresexperiencia`
  ADD PRIMARY KEY (`sala`,`idexperiencia`),
  ADD KEY `idexperiencia` (`idexperiencia`);

--
-- Indexes for table `razaofim`
--
ALTER TABLE `razaofim`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `substanciasexperiencia`
--
ALTER TABLE `substanciasexperiencia`
  ADD PRIMARY KEY (`codigosubstancia`,`idexperiencia`),
  ADD KEY `idexperiencia` (`idexperiencia`);

--
-- Indexes for table `utilizador`
--
ALTER TABLE `utilizador`
  ADD PRIMARY KEY (`email`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `alerta`
--
ALTER TABLE `alerta`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=29;

--
-- AUTO_INCREMENT for table `experiencia`
--
ALTER TABLE `experiencia`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `medicoespassagens`
--
ALTER TABLE `medicoespassagens`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=26;

--
-- AUTO_INCREMENT for table `medicoestemperatura`
--
ALTER TABLE `medicoestemperatura`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=68;

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
