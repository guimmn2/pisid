DELIMITER $$
CREATE DEFINER=`root`@`localhost` FUNCTION `getRatsInRoom`(`nrSala` INT) RETURNS int
BEGIN

DECLARE nrRatos INT;

SELECT numeroratosfinal into nrRatos
FROM medicoespassagem
WHERE idexperiencia = GetOngoingExpId() and sala = nrSala;

return nrRatos;

END$$
DELIMITER ;