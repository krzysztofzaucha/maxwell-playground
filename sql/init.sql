CREATE USER `maxwell`@`%` IDENTIFIED BY 'password';
CREATE USER `maxwell`@`localhost` IDENTIFIED BY 'password';
GRANT ALL ON `maxwell`.* TO `maxwell`@`%`;
GRANT ALL ON `maxwell`.* TO `maxwell`@`localhost`;
GRANT SELECT, REPLICATION CLIENT, REPLICATION SLAVE ON *.* TO `maxwell`@`%`;
GRANT SELECT, REPLICATION CLIENT, REPLICATION SLAVE ON *.* TO `maxwell`@`localhost`;

CREATE DATABASE IF NOT EXISTS `example`;
