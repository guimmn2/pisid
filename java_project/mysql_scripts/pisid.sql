-- phpMyAdmin SQL Dump
-- version 5.2.0
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Mar 31, 2023 at 12:45 PM
-- Server version: 10.4.27-MariaDB
-- PHP Version: 8.2.0

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
  `variacaotemperaturamaxima` decimal(4,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Dumping data for table `experiencia`
--

INSERT INTO `experiencia` (`id`, `descricao`, `investigador`, `DataHoraInicio`, `DataHoraFim`, `numeroratos`, `limiteratossala`, `segundossemmovimento`, `temperaturaideal`, `variacaotemperaturamaxima`) VALUES
(1, 'ww', NULL, '2023-03-17 21:34:58', '2023-03-17 21:35:04', 3, 3, 3, '22.00', '10.00'),
(2, 'ww', NULL, '2023-03-17 21:40:25', NULL, 3, 3, 3, '22.22', '10.22'),
(3, 'ww', NULL, NULL, NULL, 3, 3, 3, '22.22', '10.10');

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
  `hora` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `leitura` decimal(4,2) NOT NULL,
  `sensor` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

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
  ADD KEY `investigador` (`investigador`);

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
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

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
