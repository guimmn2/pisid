BEGIN
    IF OngoingExp() THEN
        INSERT INTO medicoestemperatura (sensor, hora, leitura) VALUES (idSensor, dataHora, temperatura);
    END IF;
END
