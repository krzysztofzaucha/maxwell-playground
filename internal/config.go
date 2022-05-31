package internal

type MariaDB struct {
	Host     string `json:"host"`
	Port     int    `json:"port"`
	Username string `json:"username"`
	Password string `json:"password"`
	Name     string `json:"name"`
}

type SQS struct {
	Region          string   `json:"region"`
	EndpointURL     string   `json:"endpointURL"`
	AccessKey       string   `json:"accessKey"`
	SecretAccessKey string   `json:"secretAccessKey"`
	Token           string   `json:"token"`
	QueueURL        QueueURL `json:"queueURL"`
}

type ES struct {
	Protocol string `json:"protocol"`
	Host     string `json:"host"`
	Port     int    `json:"port"`
	Name     Name   `json:"name"`
}

type QueueURL string

type Name string

type Config struct {
	MariaDB MariaDB `json:"mariaDB"`
	SQS     SQS     `json:"sqs"`
	ES      ES      `json:"es"`
}
