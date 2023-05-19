DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `CreateInvestigator`(IN `name` VARCHAR(100), IN `phone` VARCHAR(12), IN `email` VARCHAR(50), IN `password` VARCHAR(255))
    NO SQL
BEGIN
-- Check if user already exists
  IF NOT EXISTS (SELECT 1 FROM mysql.user WHERE user = email) THEN
   -- Create user
  SET @create_user_query = CONCAT("CREATE USER '", email, "'@'localhost' IDENTIFIED BY '", password, "'");
  PREPARE stmt FROM @create_user_query;
  EXECUTE stmt;
  DEALLOCATE PREPARE stmt;

  -- Grant privileges on experiencia
  SET @grant_query = CONCAT("GRANT SELECT, INSERT, UPDATE ON pisid.experiencia to '", email, "'@'localhost'");
  PREPARE stmt FROM @grant_query;
  EXECUTE stmt;
    -- Grant privileges on alerta
  SET @grant_query = CONCAT("GRANT SELECT ON pisid.alerta to '", email, "'@'localhost'");
  PREPARE stmt FROM @grant_query;
  EXECUTE stmt;
    -- Grant privileges on parametrosadicionais
  SET @grant_query = CONCAT("GRANT SELECT, INSERT, UPDATE ON pisid.parametrosadicionais to '", email, "'@'localhost'");
  PREPARE stmt FROM @grant_query;
  EXECUTE stmt;
  -- Grant privileges on medicoessala
  SET @grant_query = CONCAT("GRANT SELECT, INSERT, UPDATE ON pisid.medicoessala to '", email, "'@'localhost'");
  PREPARE stmt FROM @grant_query;
  EXECUTE stmt;
    -- Grant privileges on substanciasexperiencia
  SET @grant_query = CONCAT("GRANT SELECT, INSERT, UPDATE ON pisid.substanciasexperiencia to '", email, "'@'localhost'");
  PREPARE stmt FROM @grant_query;
  EXECUTE stmt;
      -- Grant privileges on odoresexperiencia
  SET @grant_query = CONCAT("GRANT SELECT, INSERT, UPDATE ON pisid.odoresexperiencia to '", email, "'@'localhost'");
  PREPARE stmt FROM @grant_query;
  EXECUTE stmt;
  -- grant select on utilizador
    SET @grant_query = CONCAT("GRANT SELECT ON pisid.utilizador to '", email, "'@'localhost'");
  PREPARE stmt FROM @grant_query;
  EXECUTE stmt;
  DEALLOCATE PREPARE stmt;
  FLUSH PRIVILEGES;
  INSERT INTO utilizador (nome, telefone, tipo, email) VALUES (name, phone, 'inv', email);
  END IF;
END$$
DELIMITER ;