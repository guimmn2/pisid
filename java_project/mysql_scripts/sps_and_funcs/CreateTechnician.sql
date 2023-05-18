DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `CreateTechnician`(IN `name` VARCHAR(100), IN `phone` VARCHAR(12), IN `email` VARCHAR(50), IN `password` VARCHAR(255))
    NO SQL
BEGIN
-- Check if user already exists
  IF EXISTS (SELECT 1 FROM mysql.user WHERE user = email) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'User already exists';
  END IF;

  -- Create user
  SET @create_user_query = CONCAT("CREATE USER '", email, "'@'localhost' IDENTIFIED BY '", password, "'");
  PREPARE stmt FROM @create_user_query;
  EXECUTE stmt;
  DEALLOCATE PREPARE stmt;

  -- Grant privileges on temperaturas
  SET @grant_query = CONCAT("GRANT SELECT ON pisid.medicoestemperatura to '", email, "'@'localhost'");
  PREPARE stmt FROM @grant_query;
  EXECUTE stmt;
    -- Grant privileges on parametrosadicionais
  SET @grant_query = CONCAT("GRANT SELECT ON pisid.medicoespassagens to '", email, "'@'localhost'");
  PREPARE stmt FROM @grant_query;
  EXECUTE stmt;
    SET @grant_query = CONCAT("GRANT SELECT ON pisid.alerta to '", email, "'@'localhost'");
  PREPARE stmt FROM @grant_query;
  EXECUTE stmt;
    -- grant select on utilizador
    SET @grant_query = CONCAT("GRANT SELECT ON pisid.utilizador to '", email, "'@'localhost'");
  PREPARE stmt FROM @grant_query;
  EXECUTE stmt;
  DEALLOCATE PREPARE stmt;
  FLUSH PRIVILEGES;
  INSERT INTO utilizador (nome, telefone, tipo, email) VALUES (name, phone, 'tec', email);
END$$
DELIMITER ;
