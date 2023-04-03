CREATE TRIGGER `TerminateExperience` AFTER INSERT ON `alerta`
 FOR EACH ROW BEGIN

IF NEW.tipo = 'urgent' THEN
	CALL TerminateOngoingExp(CURRENT_TIMESTAMP);
END IF;

END