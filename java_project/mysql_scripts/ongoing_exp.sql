BEGIN-- id da exp a decorrer
    DECLARE ongoing_exp_id INT;
    SELECT id INTO ongoing_exp_id
    FROM experiencia 
    WHERE experiencia.datahora IS NOT NULL 
    AND experiencia.dataHoraFim IS NULL;
    
    IF ongoing_exp_id IS NULL THEN
    RETURN FALSE;
    ELSE
    RETURN TRUE;
    END IF;
END
