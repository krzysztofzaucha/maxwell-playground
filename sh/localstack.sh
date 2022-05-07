#!/bin/bash

#######
# SQS #
#######

# create sqs queues
SQS_QUEUE_NAMES=${SQS_QUEUE_NAMES//,/ }

echo "initialising AWS localstack..."

for target in ${SQS_QUEUE_NAMES}; do
  echo "creating ${target} queue..."
  awslocal sqs create-queue --queue-name "${target}" --region "${AWS_REGION}"
  awslocal sqs create-queue --queue-name "${target}.fifo" --region "${AWS_REGION}" --attributes FifoQueue=true
done
