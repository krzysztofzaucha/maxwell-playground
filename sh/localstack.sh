#!/bin/bash

#######
# SQS #
#######

SQS_QUEUE_NAMES=${SQS_QUEUE_NAMES//,/ }

echo "initialising AWS localstack..."

for target in ${SQS_QUEUE_NAMES}; do
  echo "creating ${target} queue..."
  awslocal sqs create-queue --queue-name "${target}" --region "${AWS_REGION}"
  awslocal sqs create-queue --queue-name "${target}.fifo" --region "${AWS_REGION}" --attributes FifoQueue=true
done

#################
# ElasticSearch #
#################

# ERROR: The client noticed that the server is not Elasticsearch and we do not support this unknown product!
# Elasticsearch package does not support localstack.

##awslocal es create-elasticsearch-domain --domain-name "${ES_DOMAIN}"
#awslocal es create-elasticsearch-domain --domain-name "${ES_DOMAIN}" \
#    --domain-endpoint-options \
#    "{\"CustomEndpoint\":\"http://${HOSTNAME_EXTERNAL}:4566/${ES_DOMAIN}\",\"CustomEndpointEnabled\":true}"
#
#until [[ "$(awslocal es describe-elasticsearch-domain --domain-name "${ES_DOMAIN}" | jq -r '.DomainStatus.Processing')" == "false" ]]; do
#    echo "waiting for ElasticSearch to be ready..."
#    sleep 5
#done
#
##curl -sS -X GET "${ES_DOMAIN}.eu-west-1.es.localhost.localstack.cloud:4566/_cluster/health" | jq
#curl -sS -X GET "${HOSTNAME_EXTERNAL}:4566/${ES_DOMAIN}/_cluster/health" | jq
##curl -sS -X PUT "${ES_DOMAIN}.eu-west-1.es.localhost.localstack.cloud:4566/destination" | jq
#curl -sS -X PUT "${HOSTNAME_EXTERNAL}:4566/${ES_DOMAIN}/destination" | jq
##curl -sS -X GET "${ES_DOMAIN}.eu-west-1.es.localhost.localstack.cloud:4566/_cat/indices"
#curl -sS -X GET "${HOSTNAME_EXTERNAL}:4566/${ES_DOMAIN}/_cat/indices"
