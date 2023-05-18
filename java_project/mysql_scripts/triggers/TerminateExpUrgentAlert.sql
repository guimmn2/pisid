CREATE TRIGGER `TerminateExpUrgentAlert` AFTER INSERT ON `alerta`
 FOR EACH ROW BEGIN

IF NEW.tipo = 'urgent_mov' THEN
        -- alerta dos movimentos
    CALL TerminateOngoingExp(NEW.hora,3);
END IF;

IF NEW.tipo = 'urgent_temp' THEN
        -- alerta da temperatura
    CALL TerminateOngoingExp(NEW.hora,2);
END IF;

END