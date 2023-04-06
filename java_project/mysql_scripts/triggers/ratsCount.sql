CREATE TRIGGER `RatsCount` AFTER INSERT ON `medicoespassagens`
 FOR EACH ROW BEGIN

DECLARE expID, salaEntradaExiste, salaSaidaExiste, nr_ratos, max_ratos INT;
SET expID = GetOngoingExpId();

IF NEW.salaentrada <> NEW.salasaida THEN 

SELECT COUNT(1) into salaEntradaExiste
FROM medicoessala
WHERE medicoessala.idexperiencia = expID and medicoessala.sala = NEW.salaentrada;

SELECT COUNT(1) into salaSaidaExiste
FROM medicoessala
WHERE medicoessala.idexperiencia = expID and medicoessala.sala = NEW.salasaida;

IF salaEntradaExiste = 1 THEN
    UPDATE medicoessala
    SET medicoessala.numeroratosfinal = GetRatsInRoom(NEW.salaentrada) + 1
    WHERE medicoessala.idexperiencia = expID and medicoessala.sala = NEW.salaentrada;
ELSE
    INSERT INTO medicoessala (idexperiencia, numeroratosfinal, sala)
    VALUES (expID, 1, NEW.salaentrada);
END IF;

IF salaSaidaExiste = 1 THEN
    UPDATE medicoessala
    SET medicoessala.numeroratosfinal = GetRatsInRoom(NEW.salasaida) - 1
    WHERE medicoessala.idexperiencia = expID and medicoessala.sala = NEW.salasaida;
ELSE
    INSERT INTO medicoessala (idexperiencia, numeroratosfinal, sala)
    VALUES (expID, -1, NEW.salasaida);
END IF;

SET nr_ratos = GetRatsInRoom(NEW.salaentrada);

SELECT experiencia.limiteratossala INTO max_ratos
FROM experiencia
WHERE experiencia.id = GetOngoingExpId();

IF (nr_ratos > max_ratos) THEN
	INSERT INTO alerta (hora,sala,sensor,leitura,tipo,mensagem,horaescrita)
    VALUES (NEW.hora,NEW.salaentrada,null,null,'URGENT','Excedeu numero de ratos',CURRENT_TIMESTAMP());
    
END IF;

END IF;

END