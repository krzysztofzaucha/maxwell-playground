package internal

type MariaDB struct {
	Host     string `json:"host"`
	Port     int    `json:"port"`
	Username string `json:"username"`
	Password string `json:"password"`
	Name     string `json:"name"`
}

type QueueURL string

type Config struct {
	MariaDB MariaDB `json:"mariaDB"`
	SQS     struct {
		QueueURL QueueURL `json:"queueURL"`
	} `json:"sqs"`
}
