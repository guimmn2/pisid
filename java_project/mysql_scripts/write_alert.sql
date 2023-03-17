BEGIN
IF OngoingExp() THEN
INSERT INTO alerta (hora, sala, sensor, leitura, tipo, mensagem)
VALUES (hora, sala, sensor, leitura, tipo, mensagem);
END IF;
END
