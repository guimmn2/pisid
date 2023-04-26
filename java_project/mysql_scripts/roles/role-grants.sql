## Grants for Roles ##
GRANT USAGE ON *.* TO `admin`;
GRANT ALL PRIVILEGES ON `pisid`.* TO `admin`;
GRANT USAGE ON *.* TO `investigador`;
GRANT SELECT, INSERT, UPDATE ON `pisid`.`experiencia` TO `investigador`;
GRANT USAGE ON *.* TO `admin_app`;
GRANT SELECT, INSERT, UPDATE, DELETE ON `pisid`.`experiencia` TO `admin_app`;
GRANT SELECT, INSERT, UPDATE, DELETE ON `pisid`.`utilizador` TO `admin_app`;
GRANT USAGE ON *.* TO `tecnico_manutencao`;
GRANT SELECT ON `pisid`.`medicoestemperatura` TO `tecnico_manutencao`;
GRANT SELECT ON `pisid`.`medicoespassagens` TO `tecnico_manutencao`;
GRANT SELECT ON `pisid`.`alerta` TO `tecnico_manutencao`;
