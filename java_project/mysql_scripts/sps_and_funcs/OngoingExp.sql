DELIMITER $$
CREATE DEFINER=`root`@`localhost` FUNCTION `OngoingExp`() RETURNS tinyint(1)
    NO SQL
BEGIN-- id da exp a decorrer
    DECLARE ongoing_exp_id INT;
    SELECT id INTO ongoing_exp_id
    FROM experiencia 
    WHERE experiencia.datahorainicio IS NOT NULL 
    AND experiencia.datahorafim IS NULL;
    
    IF ongoing_exp_id IS NULL THEN
    RETURN FALSE;
    ELSE
    RETURN TRUE;
    END IF;
END$$
DELIMITER ;