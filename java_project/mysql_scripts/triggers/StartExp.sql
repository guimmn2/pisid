CREATE TRIGGER `StartExp` AFTER INSERT ON `medicoespassagens`
 FOR EACH ROW BEGIN

IF ((NEW.salaentrada + NEW.salasaida) = 0) THEN
	CALL StartNextExp(NEW.hora);
END IF;

END