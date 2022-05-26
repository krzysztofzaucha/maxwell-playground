USE `example`;

CREATE TABLE `primary`
(
    `id`    int(11)     NOT NULL AUTO_INCREMENT,
    `name`  varchar(62) NOT NULL,
    `value` varchar(62) NOT NULL,
    PRIMARY KEY (`id`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8
  COLLATE = utf8_unicode_ci;

CREATE TABLE `secondary`
(
    `id`    int(11)     NOT NULL AUTO_INCREMENT,
    `name`  varchar(62) NOT NULL,
    `value` varchar(62) NOT NULL,
    PRIMARY KEY (`id`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8
  COLLATE = utf8_unicode_ci;

CREATE TABLE `tertiary`
(
    `id`    int(11)     NOT NULL AUTO_INCREMENT,
    `name`  varchar(62) NOT NULL,
    `value` varchar(62) NOT NULL,
    PRIMARY KEY (`id`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8
  COLLATE = utf8_unicode_ci;

CREATE TABLE `destination`
(
    `id`          int(11)     NOT NULL AUTO_INCREMENT,
    `source_id`   int(11)     NOT NULL,
    `source_name` varchar(62) NOT NULL,
    `value`       varchar(62) NOT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY (`source_id`, `source_name`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8
  COLLATE = utf8_unicode_ci;
