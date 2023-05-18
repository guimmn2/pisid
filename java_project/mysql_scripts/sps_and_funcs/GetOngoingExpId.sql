DELIMITER $$
CREATE DEFINER=`root`@`localhost` FUNCTION `GetOngoingExpId`() RETURNS int(11)
    NO SQL
BEGIN
    -- id da exp a decorrer
    DECLARE ongoing_exp_id INT;
    
    SELECT id INTO ongoing_exp_id
    FROM experiencia 
    WHERE experiencia.DataHoraInicio IS NOT NULL 
    AND experiencia.DataHoraFim IS NULL;
    
    IF ongoing_exp_id IS NULL THEN
    RETURN -1;
    ELSE
    RETURN ongoing_exp_id;
    END IF;
END$$
DELIMITER ;