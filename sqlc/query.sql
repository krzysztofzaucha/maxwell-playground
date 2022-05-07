-- name: CreatePrimary :execresult
INSERT INTO `primary` (`value`)
VALUES (?);

-- name: CreateSecondary :execresult
INSERT INTO `secondary` (`value`)
VALUES (?);

-- name: CreateTertiary :execresult
INSERT INTO `tertiary` (`value`)
VALUES (?);
