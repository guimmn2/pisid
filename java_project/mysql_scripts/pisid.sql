-- phpMyAdmin SQL Dump
-- version 5.2.0
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Mar 15, 2023 at 01:48 PM
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
  `IDAlerta` int(11) NOT NULL,
  `Hora` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `Sala` int(11) NOT NULL,
  `Sensor` int(11) NOT NULL,
  `Leitura` decimal(4,2) NOT NULL,
  `TipoAlerta` varchar(20) NOT NULL,
  `Mensagem` varchar(100) NOT NULL,
  `HoraEscrita` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `experiência`
--

CREATE TABLE `experiência` (
  `IDExperiência` int(11) NOT NULL,
  `Descrição` text NOT NULL,
  `Investigador` varchar(50) NOT NULL,
  `DataHora` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `NúmeroRatos` int(11) NOT NULL,
  `LimiteRatosSala` int(11) NOT NULL,
  `SegundosSemMovimento` int(11) NOT NULL,
  `TemperaturaIdeal` decimal(4,2) NOT NULL,
  `VariaçãoTemperaturaMáxima` decimal(4,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `mediçõespassagens`
--

CREATE TABLE `mediçõespassagens` (
  `IDMedição` int(11) NOT NULL,
  `Hora` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `SalaEntrada` int(11) NOT NULL,
  `SalaSaída` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `mediçõessala`
--

CREATE TABLE `mediçõessala` (
  `Sala` int(11) NOT NULL,
  `IDExperiência` int(11) NOT NULL,
  `NúmeroRatosFinal` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `mediçõestemperatura`
--

CREATE TABLE `mediçõestemperatura` (
  `IDMedição` int(11) NOT NULL,
  `Hora` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `Leitura` decimal(4,2) NOT NULL,
  `Sensor` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `odoresexperiência`
--

CREATE TABLE `odoresexperiência` (
  `Sala` int(11) NOT NULL,
  `IDExperiência` int(11) NOT NULL,
  `CódigoOdor` varchar(5) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `substânciasexperiência`
--

CREATE TABLE `substânciasexperiência` (
  `NúmeroRatos` int(11) NOT NULL,
  `CódigoSubstância` varchar(5) NOT NULL,
  `IDExperiência` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `utilizador`
--

CREATE TABLE `utilizador` (
  `NomeUtilizador` varchar(100) NOT NULL,
  `TelefoneUtilizador` varchar(12) NOT NULL,
  `TipoUtilizador` varchar(3) NOT NULL,
  `EmailUtilizador` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `alerta`
--
ALTER TABLE `alerta`
  ADD PRIMARY KEY (`IDAlerta`);

--
-- Indexes for table `experiência`
--
ALTER TABLE `experiência`
  ADD PRIMARY KEY (`IDExperiência`);

--
-- Indexes for table `mediçõespassagens`
--
ALTER TABLE `mediçõespassagens`
  ADD PRIMARY KEY (`IDMedição`);

--
-- Indexes for table `mediçõessala`
--
ALTER TABLE `mediçõessala`
  ADD PRIMARY KEY (`Sala`,`IDExperiência`),
  ADD KEY `IDExperiência` (`IDExperiência`);

--
-- Indexes for table `mediçõestemperatura`
--
ALTER TABLE `mediçõestemperatura`
  ADD PRIMARY KEY (`IDMedição`);

--
-- Indexes for table `odoresexperiência`
--
ALTER TABLE `odoresexperiência`
  ADD PRIMARY KEY (`Sala`,`IDExperiência`),
  ADD KEY `IDExperiência` (`IDExperiência`);

--
-- Indexes for table `substânciasexperiência`
--
ALTER TABLE `substânciasexperiência`
  ADD PRIMARY KEY (`CódigoSubstância`),
  ADD KEY `IDExperiência` (`IDExperiência`);

--
-- Indexes for table `utilizador`
--
ALTER TABLE `utilizador`
  ADD PRIMARY KEY (`EmailUtilizador`);

--
-- Constraints for dumped tables
--

--
-- Constraints for table `mediçõessala`
--
ALTER TABLE `mediçõessala`
  ADD CONSTRAINT `mediçõessala_ibfk_1` FOREIGN KEY (`IDExperiência`) REFERENCES `experiência` (`IDExperiência`),
  ADD CONSTRAINT `mediçõessala_ibfk_2` FOREIGN KEY (`Sala`) REFERENCES `odoresexperiência` (`Sala`);

--
-- Constraints for table `odoresexperiência`
--
ALTER TABLE `odoresexperiência`
  ADD CONSTRAINT `odoresexperiência_ibfk_1` FOREIGN KEY (`IDExperiência`) REFERENCES `experiência` (`IDExperiência`);

--
-- Constraints for table `substânciasexperiência`
--
ALTER TABLE `substânciasexperiência`
  ADD CONSTRAINT `substânciasexperiência_ibfk_1` FOREIGN KEY (`IDExperiência`) REFERENCES `experiência` (`IDExperiência`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
