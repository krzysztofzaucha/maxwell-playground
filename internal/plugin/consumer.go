package main

import (
	"bytes"
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/sqs"
	"github.com/elastic/go-elasticsearch/v8/esapi"
	_ "github.com/go-sql-driver/mysql"
	"github.com/krzysztofzaucha/maxwell-playground/internal"
	"github.com/krzysztofzaucha/maxwell-playground/internal/repository"
	"github.com/pkg/errors"
	"log"
	"time"
)

// Consumer is a consumer plugin symbol name.
var Consumer consumer

var errConsumerPlugin = errors.New("consumer")

type consumer struct {
	db       *sql.DB
	q        *repository.Queries
	sqs      *sqs.SQS
	es       *elasticsearch.Client
	threads  int
	wait     int
	queueURL string
	name     string
}

func (c *consumer) WithSQLDB(db *sql.DB) error {
	c.db = db

	c.q = repository.New(db)

	return nil
}

func (c *consumer) WithSQS(sqs *sqs.SQS) {
	c.sqs = sqs
}

func (c *consumer) WithES(es *elasticsearch.Client) {
	c.es = es
}

func (c *consumer) WithThreads(threads int) {
	c.threads = threads
}

func (c *consumer) WithWait(wait int) {
	c.wait = wait
}

func (c *consumer) WithSQSQueueURL(queueURL internal.QueueURL) {
	c.queueURL = string(queueURL)
}

func (c *consumer) WithESName(name internal.Name) {
	c.name = string(name)
}

// Execute method executes plugin logic.
func (c *consumer) Execute() error {
	for {
		_, err := c.sqs.GetQueueAttributes(&sqs.GetQueueAttributesInput{
			QueueUrl:       aws.String(c.queueURL),
			AttributeNames: aws.StringSlice([]string{"All"}),
		})

		if err != nil {
			log.Printf("unable to connect to %s sqs queue: %v: retrying...\n", c.queueURL, err)
			time.Sleep(time.Duration(3) * time.Second)

			continue
		}

		break
	}

	sem := make(chan bool, c.threads)
	defer close(sem)

	c.run(time.Duration(c.wait)*time.Millisecond, sem)

	return nil
}

func (c *consumer) run(delay time.Duration, sem chan bool) {
	for {
		select {
		case sem <- true:
			go func(sem chan bool) {
				messages, err := c.sqs.ReceiveMessage(&sqs.ReceiveMessageInput{
					QueueUrl:            aws.String(c.queueURL),
					MaxNumberOfMessages: aws.Int64(1),
					//WaitTimeSeconds:       aws.Int64(1),
					//VisibilityTimeout:     aws.Int64(10),
					MessageAttributeNames: aws.StringSlice([]string{"All"}),
				})
				if err != nil {
					log.Printf("%v", err)

					<-sem

					return
				}

				// skip processing, no messages have been received
				if len(messages.Messages) < 1 {
					<-sem

					return
				}

				err = c.process(messages.Messages[0])
				if err != nil {
					log.Printf("%v", err)

					<-sem

					return
				}

				time.Sleep(delay)

				<-sem
			}(sem)
		}
	}
}

func (c *consumer) process(message *sqs.Message) error {
	var msg map[string]interface{}

	err := json.Unmarshal([]byte(*message.Body), &msg)
	if err != nil {
		return errors.Wrapf(errConsumerPlugin, "%s", err)
	}

	doc := map[string]interface{}{
		"doc":           &msg,
		"doc_as_upsert": true,
	}

	d, err := json.Marshal(doc)
	if err != nil {
		return errors.Wrapf(errConsumerPlugin, "%s", err)
	}

	data := msg["data"].(map[string]interface{})

	log.Printf("data.id: %v\n", data["id"])

	docID := fmt.Sprintf("%v-%v", data["id"], data["name"])

	req := esapi.UpdateRequest{
		Index:           c.name,
		DocumentID:      docID,
		Body:            bytes.NewReader(d),
		Refresh:         "true",
		RetryOnConflict: func(v int) *int { return &v }(5),
	}

	res, err := req.Do(context.Background(), c.es)
	if err != nil {
		return errors.Wrapf(errConsumerPlugin, "%s", err)
	}

	defer func() {
		if err := res.Body.Close(); err != nil {
			panic(err.(any))
		}
	}()

	if res.IsError() {
		return errors.Wrapf(errConsumerPlugin,
			"[%s] error indexing document id=%s %s", res.Status(), docID, res.String(),
		)
	}

	//result, err := c.q.SaveDestination(ctx, repository.SaveDestinationParams{
	//	SourceID:   int32(data["id"].(float64)),
	//	SourceName: data["name"].(string),
	//	Value:      data["value"].(string),
	//})
	//if err != nil {
	//	return errors.Wrapf(errConsumerPlugin, "%s", err)
	//}
	//
	//id, err := result.LastInsertId()
	//if err != nil {
	//	return errors.Wrapf(errConsumerPlugin, "%s", err)
	//}
	//
	//log.Printf(
	//	"message has been successfully processed: %s, stored in the destination with id %d\n",
	//	*message.Body, id,
	//)

	params := &sqs.DeleteMessageInput{
		QueueUrl:      aws.String(c.queueURL),
		ReceiptHandle: aws.String(*message.ReceiptHandle),
	}

	_, err = c.sqs.DeleteMessage(params)
	if err != nil {
		log.Printf("unable to delete sqs message: data.id: %d: %v\n", data["id"], err)
	}

	return nil
}
