CREATE USER 'admin_app@email.com'@'localhost' IDENTIFIED BY 'password';

GRANT CREATE USER ON *.* TO `admin_app@email.com`@`localhost` IDENTIFIED BY PASSWORD '*2470C0C06DEE42FD1618BB99005ADCA2EC9D1E19' WITH GRANT OPTION;

GRANT ALL PRIVILEGES ON `pisid`.* TO `admin_app@email.com`@`localhost`;
