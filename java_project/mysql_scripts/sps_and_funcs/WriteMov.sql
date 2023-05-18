DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `WriteMov`(IN `hora` TIMESTAMP, IN `salaentrada` INT, IN `salasaida` INT)
    NO SQL
BEGIN
IF OngoingExp() THEN
	INSERT INTO medicoespassagens (hora, salaentrada, salasaida)
    VALUES (hora, salaentrada, salasaida);
END IF;
END$$
DELIMITER ;
