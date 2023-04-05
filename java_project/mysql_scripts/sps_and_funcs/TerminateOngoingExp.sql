DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `TerminateOngoingExp`(IN `dataFim` TIMESTAMP)
    NO SQL
BEGIN

UPDATE experiencia
SET DataHoraFim = dataFim
WHERE experiencia.id = GetOngoingExpId();

END$$
DELIMITER ;
