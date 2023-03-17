GRANT USAGE ON *.* TO `admin_app`@`localhost` IDENTIFIED BY PASSWORD '*E2A6174CBD239120E90C993D7039A9FA9C08199A';

GRANT SELECT, INSERT, UPDATE, DELETE ON `pisid`.* TO `admin_app`@`localhost`;

GRANT SELECT, INSERT, UPDATE, DELETE ON `pisid`.`experiencia` TO `admin_app`@`localhost`;

GRANT SELECT, INSERT, UPDATE, DELETE ON `pisid`.`utilizador` TO `admin_app`@`localhost`;