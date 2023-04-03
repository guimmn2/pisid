-- phpMyAdmin SQL Dump
-- version 4.9.5deb2
-- https://www.phpmyadmin.net/
--
-- Host: localhost:3306
-- Generation Time: Apr 03, 2023 at 05:16 PM
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
CREATE DEFINER=`root`@`localhost` PROCEDURE `WriteMov` (IN `hora` TIMESTAMP, IN `salaentrada` INT, IN `salasaida` INT)  NO SQL
BEGIN
IF OngoingExp() THEN
	INSERT INTO medicoespassagens (datahora, salaentrada, salasaida)
    VALUES (dataHora, salaentrada, salasaida);
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
  `sala` int(11) NOT NULL,
  `sensor` int(11) NOT NULL,
  `leitura` decimal(4,2) NOT NULL,
  `tipo` varchar(20) NOT NULL DEFAULT 'light',
  `mensagem` varchar(100) NOT NULL,
  `horaescrita` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

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
(2, 'ww', NULL, '2023-04-03 15:06:13', '2023-04-03 15:06:05', 3, 3, 3, '22.22', '10.22', NULL),
(3, 'ww', NULL, NULL, NULL, 3, 3, 3, '22.22', '10.10', NULL);

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
-- Dumping data for table `medicoestemperatura`
--

INSERT INTO `medicoestemperatura` (`id`, `hora`, `leitura`, `sensor`) VALUES
(1, '2023-03-31 17:57:23', '3.82', 1),
(2, '2023-03-31 17:57:23', '8.69', 1),
(3, '2023-03-31 17:57:24', '5.17', 1),
(4, '2023-03-31 17:57:24', '0.19', 1),
(5, '2023-03-31 17:57:25', '3.05', 1),
(6, '2023-03-31 17:57:25', '14.40', 1),
(7, '2023-03-31 17:57:25', '11.88', 1),
(8, '2023-03-31 17:57:25', '13.54', 1),
(9, '2023-03-31 17:57:25', '7.92', 1),
(10, '2023-03-31 17:57:25', '0.98', 1),
(11, '2023-03-31 17:57:26', '8.58', 1),
(12, '2023-03-31 17:57:26', '3.80', 1),
(13, '2023-03-31 17:57:26', '9.50', 1),
(14, '2023-03-31 17:57:26', '8.54', 1),
(15, '2023-03-31 17:57:26', '7.86', 1),
(16, '2023-03-31 17:57:27', '0.36', 1),
(17, '2023-03-31 17:57:27', '2.58', 1),
(18, '2023-03-31 17:57:27', '6.67', 1),
(19, '2023-03-31 17:57:27', '13.28', 1),
(20, '2023-03-31 17:57:27', '6.57', 1),
(21, '2023-03-31 17:57:27', '8.22', 1),
(22, '2023-03-31 17:57:27', '13.67', 1),
(23, '2023-03-31 17:57:28', '0.89', 1),
(24, '2023-03-31 17:57:28', '9.51', 1),
(25, '2023-03-31 17:57:28', '11.10', 1),
(26, '2023-03-31 17:57:28', '14.70', 1),
(27, '2023-03-31 17:57:29', '8.92', 1),
(28, '2023-03-31 17:57:29', '3.82', 1),
(29, '2023-03-31 17:57:29', '5.78', 1);

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
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `experiencia`
--
ALTER TABLE `experiencia`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `medicoespassagens`
--
ALTER TABLE `medicoespassagens`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `medicoestemperatura`
--
ALTER TABLE `medicoestemperatura`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=30;

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
