CREATE TRIGGER `CreateAlertFullRoom` AFTER INSERT ON `medicoespassagens`
 FOR EACH ROW BEGIN

DECLARE nr_ratos, max_ratos INT;
SET nr_ratos = GetRatsInRoom(NEW.salaentrada);

SELECT experiencia.limiteratossala INTO max_ratos
FROM experiencia
WHERE experiencia.id = GetOngoingExpId();

IF (nr_ratos > max_ratos) THEN
	INSERT INTO alerta (hora,sala,sensor,leitura,tipo,mensagem,horaescrita)
    VALUES (NEW.hora,NEW.salaentrada,null,null,'URGENT','Excedeu numero de ratos',CURRENT_TIMESTAMP());
END IF;

END