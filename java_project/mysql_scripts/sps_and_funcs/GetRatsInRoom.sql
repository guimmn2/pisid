DELIMITER $$
CREATE DEFINER=`root`@`localhost` FUNCTION `getRatsInRoom`(`nrSala` INT) RETURNS int(11)
BEGIN

DECLARE nrRatos INT;

SELECT numeroratosfinal into nrRatos
FROM medicoessala
WHERE idexperiencia = GetOngoingExpId() and sala = nrSala;

return nrRatos;

END$$
DELIMITER ;