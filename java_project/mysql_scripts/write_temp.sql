DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `WriteTemp`(IN `sensor` INT, IN `hora` TIMESTAMP, IN `leitura` DECIMAL(4,2))
    NO SQL
BEGIN
    IF OngoingExp() THEN
        INSERT INTO medicoestemperatura (sensor, hora, leitura) VALUES (sensor, hora, leitura);
    END IF;
END$$
DELIMITER ;
