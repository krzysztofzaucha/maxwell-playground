#!/bin/bash

until mysql -h "${HOST}" -u"${USERNAME}" -p"${PASSWORD}" -P"${PORT}"; do
  >&2 echo "waiting for MySQL to be ready..."
  sleep 1
done

# The following script is here just to ensure the queue has been created...
until aws sqs get-queue-attributes \
  --endpoint-url="${ENDPOINT_URL}" \
  --queue-url="${SQS_QUEUE_URI}" \
  --region=eu-west-1; do
    >&2 echo "waiting for SQS to be ready..."
    sleep 1
done

bin/maxwell \
  --replica_server_id="${REPLICA_SERVER_ID}" \
  --client_id="${SERVER_ID}" \
  --host="${HOST}" \
  --port="${PORT}" \
  --user="${USERNAME}" \
  --password="${PASSWORD}" \
  --filter="${FILTER}" \
  --producer="${PRODUCER}" \
  --sqs_service_endpoint="${ENDPOINT_URL}" \
  --sqs_signing_region="${AWS_REGION}" \
  --sqs_queue_uri="${SQS_QUEUE_URI}"

# Start and subscribe to maxwell queue
#bin/maxwell \
#  --host="maxwell-playground-mariadb" \
#  --port="3306" \
#  --user="maxwell" \
#  --password="password" \
#  --producer="sqs" \
#  --sqs_queue_uri="maxwell-playground-localstack:4566/queue/maxwell"

# Start and use stdout as an output
#bin/maxwell \
#  --host="maxwell-playground-mariadb" \
#  --port="3306" \
#  --user="root" \
#  --password="password" \
#  --producer="stdout"

# Use the following to test the localstack
#aws sqs send-message \
#  --endpoint-url="http://maxwell-playground-localstack:4566" \
#  --queue-url="http://maxwell-playground-localstack:4566/queue/maxwell" \
#  --region=eu-west-1 \
#  --message-body="Hello world!"

# Use to test message receive
#aws sqs receive-message \
#   --endpoint-url="http://maxwell-playground-localstack:4566" \
#	  --queue-url="http://${BASE_NAME}-localstack:4566/queue/maxwell" \
#	  --region=eu-west-1

# Delete queue
#aws sqs delete-queue \
#   --endpoint-url="http://maxwell-playground-localstack:4566" \
#   --queue-url="http://${BASE_NAME}-localstack:4566/queue/maxwell" \
#   --region=eu-west-1

# Use to test waiting loop
#until aws sqs receive-message \
#  --endpoint-url="http://maxwell-playground-localstack:4566" \
#  --queue-url="http://${SQS_QUEUE_URI}" \
#  --region=eu-west-1; do
#    >&2 echo "waiting for SQS to be ready..."
#    sleep 1
#done
