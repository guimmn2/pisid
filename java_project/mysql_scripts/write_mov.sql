BEGIN
IF OngoingExp() THEN
	INSERT INTO medicoespassagens (datahora, salaentrada, salasaida)
    VALUES (dataHora, salaEntrada, salaSaida);
END IF;
END
