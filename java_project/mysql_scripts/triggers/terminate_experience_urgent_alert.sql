CREATE TRIGGER `TerminateExpUrgentAlert` AFTER INSERT ON `alerta`
 FOR EACH ROW BEGIN

IF NEW.tipo = 'urgent' THEN
	CALL TerminateOngoingExp(NEW.hora);
END IF;

END