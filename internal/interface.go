// Package internal contains the core application components.
package internal

import (
	"database/sql"
	"github.com/aws/aws-sdk-go/service/sqs"
)

// Executor is the main plugin method to execute plugins logic.
type Executor interface {
	Execute() error
}

// SQLDBConfigurator is an interface for WithSQLDB.
type SQLDBConfigurator interface {
	WithSQLDB(db *sql.DB) error
}

// SQSConfigurator is an interface for WithSQS.
type SQSConfigurator interface {
	WithSQS(sqs *sqs.SQS)
}

// ThreadsConfigurator is an interface for WithThreads.
type ThreadsConfigurator interface {
	WithThreads(name int)
}

// DelayConfigurator is an interface for WithDelay.
type DelayConfigurator interface {
	WithDelay(name int)
}

// NameConfigurator is an interface for WithName.
type NameConfigurator interface {
	WithName(name string)
}

// AmountConfigurator is an interface for WithAmount.
type AmountConfigurator interface {
	WithAmount(name int)
}

// SQSQueueURLConfigurator is an interface for WithSQSQueueURL.
type SQSQueueURLConfigurator interface {
	WithSQSQueueURL(queue string)
}
