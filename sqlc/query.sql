-- name: CreatePrimary :execresult
INSERT INTO `primary` (`name`, `value`)
VALUES (?, ?);

-- name: CreateSecondary :execresult
INSERT INTO `secondary` (`name`, `value`)
VALUES (?, ?);

-- name: CreateTertiary :execresult
INSERT INTO `tertiary` (`name`, `value`)
VALUES (?, ?);

-- name: SaveDestination :execresult
INSERT IGNORE INTO `destination` (`source_id`, `source_name`, `value`)
VALUES (?, ?, ?);
