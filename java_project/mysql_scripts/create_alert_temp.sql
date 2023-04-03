BEGIN
  DECLARE ongoing_exp_id INT;
  DECLARE temp_ideal DECIMAL(4,2);
  DECLARE var_max_temp DECIMAL(4,2);

  IF OngoingExp() THEN
    SET ongoing_exp_id = GetOngoingExpId();

    -- obter temp ideal
    SELECT temperaturaideal INTO temp_ideal 
    FROM experiencia 
    WHERE id = ongoing_exp_id;

    -- obter variação máxima da temperatura
    SELECT variacaotemperaturamaxima INTO var_max_temp
    FROM experiencia
    WHERE id = ongoing_exp_id;

    IF ((NEW.leitura) >  temp_ideal + var_max_temp) THEN
      INSERT INTO alerta (hora, sala, sensor, leitura, tipo, mensagem, horaescrita)
      VALUES (NEW.hora, NULL, NEW.sensor, NEW.leitura, 'URGENTE', 'PLS STOP', CURRENT_TIMESTAMP());
    ELSEIF ((NEW.leitura) < temp_ideal - var_max_temp) THEN
      INSERT INTO alerta (hora, sala, sensor, leitura, tipo, mensagem, horaescrita)
      VALUES (NEW.hora, NULL, NEW.sensor, NEW.leitura, 'URGENTE', 'PLS STOP', CURRENT_TIMESTAMP());
    ELSEIF ((NEW.leitura) > temp_ideal + var_max_temp * 0.9) THEN
      INSERT INTO alerta (hora, sala, sensor, leitura, tipo, mensagem, horaescrita)
      VALUES (NEW.hora, NULL, NEW.sensor, NEW.leitura, 'LIGHT', 'epah yah', CURRENT_TIMESTAMP());
    ELSEIF ((NEW.leitura) < temp_ideal - var_max_temp * 0.9) THEN
      INSERT INTO alerta (hora, sala, sensor, leitura, tipo, mensagem, horaescrita)
      VALUES (NEW.hora, NULL, NEW.sensor, NEW.leitura, 'LIGHT', 'epah yah', CURRENT_TIMESTAMP());
    END IF;
  END IF;
END
