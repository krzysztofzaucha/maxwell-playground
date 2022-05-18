package main

import (
	"fmt"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/sqs"
	"github.com/krzysztofzaucha/maxwell-sandbox/internal"
	"time"
)

// Consumer is a consumer plugin symbol name.
var Consumer consumer

type consumer struct {
	sqs      *sqs.SQS
	threads  int
	wait     int
	queueURL string
}

func (c *consumer) WithSQS(sqs *sqs.SQS) {
	c.sqs = sqs
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

// Execute method executes plugin logic.
func (c *consumer) Execute() error {
	for {
		_, err := c.sqs.GetQueueAttributes(&sqs.GetQueueAttributesInput{
			QueueUrl:       aws.String(c.queueURL),
			AttributeNames: aws.StringSlice([]string{"All"}),
		})

		if err != nil {
			fmt.Printf("unable to connect to %s sqs queue: %v: retrying...\n", c.queueURL, err)
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
					QueueUrl:              aws.String(c.queueURL),
					MaxNumberOfMessages:   aws.Int64(1),
					WaitTimeSeconds:       aws.Int64(20),
					VisibilityTimeout:     aws.Int64(20),
					MessageAttributeNames: aws.StringSlice([]string{"All"}),
				})
				if err != nil {
					fmt.Printf("%v", err)

					<-sem

					return
				}

				// skip processing, no messages have been received
				if len(messages.Messages) < 1 {
					<-sem

					return
				}

				c.process(messages.Messages[0])

				time.Sleep(delay)

				<-sem
			}(sem)
		}
	}
}

func (c *consumer) process(message *sqs.Message) {
	fmt.Println(*message.Body)

	params := &sqs.DeleteMessageInput{
		QueueUrl:      aws.String(c.queueURL),
		ReceiptHandle: aws.String(*message.ReceiptHandle),
	}

	_, err := c.sqs.DeleteMessage(params)
	if err != nil {
		fmt.Printf("unable to proccess sqs message: %v\n", err)
	}
}
