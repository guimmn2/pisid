DELIMITER $$
CREATE DEFINER=`root`@`localhost` FUNCTION `GetRatsInRoom`(`nrSala` INT) RETURNS int(11)
    NO SQL
BEGIN

DECLARE nr_ratos INT;

SELECT numeroratosfinal INTO nr_ratos 
FROM medicoessala
WHERE medicoessala.sala = nrSala AND medicoessala.idexperiencia = GetOngoingExpId();

RETURN nr_ratos;

END$$
DELIMITER ;