DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `StartNextExp`(IN `dataInicio` TIMESTAMP)
    NO SQL
BEGIN

DECLARE IDExp INT;

CALL TerminateOngoingExp(dataInicio,1);

UPDATE experiencia
SET DataHoraInicio = dataInicio
-- proxima exp a decorrer
WHERE id = (SELECT id FROM experiencia WHERE DataHoraInicio is NULL LIMIT 1);

END$$
DELIMITER ;