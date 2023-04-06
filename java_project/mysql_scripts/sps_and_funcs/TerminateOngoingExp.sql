DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `TerminateOngoingExp`(IN `dataFim` TIMESTAMP, IN `id_razaofim` INT)
    NO SQL
BEGIN

UPDATE experiencia
SET DataHoraFim = dataFim, experiencia.IDRazaoFim = id_razaofim
WHERE experiencia.id = GetOngoingExpId();
END$$
DELIMITER ;