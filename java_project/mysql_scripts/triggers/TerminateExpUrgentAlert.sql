CREATE TRIGGER `TerminateExpUrgentAlert` AFTER INSERT ON `alerta`
 FOR EACH ROW BEGIN

IF NEW.tipo = 'URGENT' THEN
	IF NEW.sala IS NOT NULL THEN
    	-- alerta dos movimentos
		CALL TerminateOngoingExp(NEW.hora,3);
    ELSE 
    	-- alerta da temperatura
    	CALL TerminateOngoingExp(NEW.hora,2);
    END IF;
END IF;

END