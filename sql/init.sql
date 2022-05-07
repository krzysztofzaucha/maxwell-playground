CREATE USER `maxwell`@`%` IDENTIFIED BY 'password';
CREATE USER `maxwell`@`localhost` IDENTIFIED BY 'password';
GRANT ALL ON `maxwell`.* TO `maxwell`@`%`;
GRANT ALL ON `maxwell`.* TO `maxwell`@`localhost`;
GRANT SELECT, REPLICATION CLIENT, REPLICATION SLAVE ON *.* TO `maxwell`@`%`;
GRANT SELECT, REPLICATION CLIENT, REPLICATION SLAVE ON *.* TO `maxwell`@`localhost`;

CREATE DATABASE IF NOT EXISTS `example`;

USE `example`;

CREATE TABLE `primary`
(
    `id`      int(11) NOT NULL AUTO_INCREMENT,
    `value` varchar(62) DEFAULT NULL,
    PRIMARY KEY (`id`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8
  COLLATE = utf8_unicode_ci;

CREATE TABLE `secondary`
(
    `id`      int(11) NOT NULL AUTO_INCREMENT,
    `value` varchar(62) DEFAULT NULL,
    PRIMARY KEY (`id`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8
  COLLATE = utf8_unicode_ci;

CREATE TABLE `tertiary`
(
    `id`      int(11) NOT NULL AUTO_INCREMENT,
    `value` varchar(62) DEFAULT NULL,
    PRIMARY KEY (`id`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8
  COLLATE = utf8_unicode_ci;
