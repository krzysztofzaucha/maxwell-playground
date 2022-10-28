.PHONY: mariadb sqlc

export SHELL:=/bin/bash
export BASE_NAME:=$(shell basename ${PWD})
export IMAGE_BASE_NAME:=kz/$(shell basename ${PWD})
export NETWORK:=${BASE_NAME}-network
export PRODUCER_THREADS:=1 # number of threads
export CONSUMER_THREADS:=1 # number of threads
export PRODUCER_WAIT:=10 # step waiting time in milliseconds
export CONSUMER_WAIT:=10 # step waiting time in milliseconds
export TOTAL:=100 # number of events per events type

default: help

help: ## Prints help for targets with comments
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' ${MAKEFILE_LIST} | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-50s\033[0m %s\n", $$1, $$2}'
	@echo ""

#######
# Run #
#######

BASE:=\
	-f docker-compose/mariadb.yml \
	-f docker-compose/localstack.yml \
	-f docker-compose/maxwell-primary.yml \
	-f docker-compose/maxwell-secondary.yml \
	-f docker-compose/maxwell-tertiary.yml \
	-f docker-compose/elasticsearch.yml \
	-f docker-compose/kibana.yml

CONSUMERS:=\
	-f docker-compose/consumer-primary.yml \
	-f docker-compose/consumer-secondary.yml \
	-f docker-compose/consumer-tertiary.yml

PRODUCERS:=\
	-f docker-compose/producer-primary.yml \
	-f docker-compose/producer-secondary.yml \
	-f docker-compose/producer-tertiary.yml

compose:
	@docker-compose ${COMPOSE} \
		-p ${BASE_NAME} \
		up # --build # --remove-orphans # --force-recreate # --abort-on-container-exit

up-base: ## Start the example
	@COMPOSE="${BASE}" make compose

up-consumers: ## Start consumers
	@COMPOSE="${CONSUMERS}" make compose

up-producers: ## Start producers
	@COMPOSE="${PRODUCERS}" make compose

###########
# Testing #
###########

mariadb-up: ## Start MariaDB
	@COMPOSE=" -f docker-compose/mariadb.yml" make compose

localstack-up: ## Start Localstack
	@COMPOSE=" -f docker-compose/localstack.yml" make compose

maxwell-primary-up: ## Start Maxwell Primary
	@COMPOSE=" -f docker-compose/maxwell-primary.yml" make compose

producer-primary-up: ## Start Producer Primary
	@COMPOSE=" -f docker-compose/producer-primary.yml" make compose

consumers-primary-up: ## Start Consumer Primary
	@COMPOSE=" -f docker-compose/consumer-primary.yml" make compose

elasticsearch-kibana-up: ## Start ElasticSearch and Kibana
	@COMPOSE=" -f docker-compose/elasticsearch.yml -f docker-compose/kibana.yml" make compose

###########
# MariaDB #
###########

mariadb: ## Access MariaDB shell
	@docker exec -it ${BASE_NAME}-mariadb mysql -uroot -ppassword

mariadb-insert-primary: ## Insert example row to `example`.`primary` table
	@docker exec -it ${BASE_NAME}-mariadb sh -c "mysql -uroot -ppassword example < /mnt/20-insert-primary.sql"

mariadb-insert-secondary: ## Insert example row to `example`.`secondary` table
	@docker exec -it ${BASE_NAME}-mariadb sh -c "mysql -uroot -ppassword example < /mnt/20-insert-secondary.sql"

mariadb-insert-tertiary: ## Insert example row to `example`.`tertiary` table
	@docker exec -it ${BASE_NAME}-mariadb sh -c "mysql -uroot -ppassword example < /mnt/20-insert-tertiary.sql"

########
# SQLC #
########

sqlc: ## Generate database layer
	@docker run --rm \
		-w ${PWD} \
		-v ${PWD}:${PWD} \
		kjconroy/sqlc generate

######
# Go #
######

plugins: ## Builds plugins
	@go build -buildmode=plugin -o bin/producer.so internal/plugin/producer.go
	@go build -buildmode=plugin -o bin/consumer.so internal/plugin/consumer.go

build: plugins ## Compile
	@go build -o bin/app .

#######
# AWS #
#######

aws-sqs-list-queues: ## List all queues
	@docker exec -it ${BASE_NAME}-localstack awslocal sqs list-queues --region=eu-west-1

aws-sqs-get-queue-attributes-maxwell-primary: ## Get maxwell-primary queue attributes
	@docker exec -it ${BASE_NAME}-localstack awslocal sqs get-queue-attributes \
		--queue-url=http://${BASE_NAME}-localstack:4566/queue/maxwell-primary \
		--region=eu-west-1 \
		--attribute-names=ApproximateNumberOfMessages

aws-sqs-send-message-maxwell-primary: ## Send message to the maxwell-primary queue
	@docker exec -it ${BASE_NAME}-localstack awslocal sqs send-message \
		--queue-url=http://${BASE_NAME}-localstack:4566/queue/maxwell-primary \
		--region=eu-west-1 \
		--message-body="Hello world!"

aws-sqs-receive-message-maxwell-primary: ## Receive message from the maxwell-primary queue
	@docker exec -it ${BASE_NAME}-localstack awslocal sqs receive-message \
		--queue-url=http://${BASE_NAME}-localstack:4566/queue/maxwell-primary \
		--region=eu-west-1

aws-sqs-send-message-maxwell-primary-fifo: ## Send message to the maxwell-primary.fifo queue
	@docker exec -it ${BASE_NAME}-localstack awslocal sqs send-message \
		--queue-url=http://${BASE_NAME}-localstack:4566/queue/maxwell-primary.fifo \
		--region=eu-west-1 \
		--message-body="Hello world!"

aws-sqs-receive-message-maxwell-primary-fifo: ## Receive message from the maxwell-primary.fifo queue
	@docker exec -it ${BASE_NAME}-localstack awslocal sqs receive-message \
		--queue-url=http://${BASE_NAME}-localstack:4566/queue/maxwell-primary.fifo \
		--region=eu-west-1

aws-sqs-receive-message-maxwell-secondary: ## Receive message from the maxwell-secondary queue
	@docker exec -it ${BASE_NAME}-localstack awslocal sqs receive-message \
		--queue-url=http://${BASE_NAME}-localstack:4566/queue/maxwell-secondary \
		--region=eu-west-1

aws-sqs-receive-message-maxwell-secondary-fifo: ## Receive message from the maxwell-secondary.fifo queue
	@docker exec -it ${BASE_NAME}-localstack awslocal sqs receive-message \
		--queue-url=http://${BASE_NAME}-localstack:4566/queue/maxwell-secondary.fifo \
		--region=eu-west-1

aws-sqs-receive-message-maxwell-tertiary: ## Receive message from the maxwell-tertiary queue
	@docker exec -it ${BASE_NAME}-localstack awslocal sqs receive-message \
		--queue-url=http://${BASE_NAME}-localstack:4566/queue/maxwell-tertiary \
		--region=eu-west-1

aws-sqs-receive-message-maxwell-tertiary-fifo: ## Receive message from the maxwell-tertiary.fifo queue
	@docker exec -it ${BASE_NAME}-localstack awslocal sqs receive-message \
		--queue-url=http://${BASE_NAME}-localstack:4566/queue/maxwell-tertiary.fifo \
		--region=eu-west-1

###############
# Danger Zone #
###############

reset: ## Cleanup
	@docker stop $(shell docker ps -aq) || true
	@docker system prune || true
	@docker volume rm $(shell docker volume ls -q) || true
	@docker rmi -f ${IMAGE_BASE_NAME}-mariadb:latest || true
	@docker rmi -f ${IMAGE_BASE_NAME}-maxwell:latest || true
	@docker rmi -f ${IMAGE_BASE_NAME}-go:latest || true
	@docker rmi -f ${IMAGE_BASE_NAME}-localstack:latest || true
	@docker rmi -f ${IMAGE_BASE_NAME}-elasticsearch:latest || true
	@docker rmi -f ${IMAGE_BASE_NAME}-kibana:latest || true
