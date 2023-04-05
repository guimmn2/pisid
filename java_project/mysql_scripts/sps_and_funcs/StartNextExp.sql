DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `StartNextExp`(IN `dataInicio` TIMESTAMP)
    NO SQL
BEGIN

DECLARE IDExp INT;

SELECT COUNT(1) INTO IDExp 
FROM experiencia
WHERE experiencia.id = GetOngoingExpId();

IF IDExp = 1 THEN
CALL TerminateOngoingExp(CURRENT_TIMESTAMP);
END IF;