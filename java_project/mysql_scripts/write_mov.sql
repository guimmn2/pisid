DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `WriteMov`(IN `hora` TIMESTAMP, IN `salaentrada` INT, IN `salasaida` INT)
    NO SQL
BEGIN
IF OngoingExp() THEN
	INSERT INTO medicoespassagens (datahora, salaentrada, salasaida)
    VALUES (dataHora, salaentrada, salasaida);
END IF;
END$$
DELIMITER ;
