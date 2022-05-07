.PHONY: mariadb sqlc

export SHELL:=/bin/bash
export BASE_NAME:=$(shell basename ${PWD})
export IMAGE_BASE_NAME:=kz/$(shell basename ${PWD})
export NETWORK:=${BASE_NAME}-network
export THREADS:=1 # number of threads
export DELAY:=1000 # step waiting time
export TOTAL:=100 # number of inserts

default: help

help: ## Prints help for targets with comments
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' ${MAKEFILE_LIST} | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-50s\033[0m %s\n", $$1, $$2}'
	@echo ""

#######
# Run #
#######

compose:
	@docker-compose ${COMPOSE} \
		-p ${BASE_NAME} \
		up --build --force-recreate --remove-orphans # --abort-on-container-exit

up: ## Start the example
	@COMPOSE=" -f docker-compose.yml" make compose

###########
# MariaDB #
###########

mariadb: ## Access MariaDB shell
	@docker exec -it ${BASE_NAME}-mariadb mysql -uroot -ppassword

mariadb-insert-primary: ## Insert example row to `example`.`primary` table
	@docker exec -it ${BASE_NAME}-mariadb sh -c "mysql -uroot -ppassword example < /mnt/insert-primary.sql"

mariadb-insert-secondary: ## Insert example row to `example`.`secondary` table
	@docker exec -it ${BASE_NAME}-mariadb sh -c "mysql -uroot -ppassword example < /mnt/insert-secondary.sql"

mariadb-insert-tertiary: ## Insert example row to `example`.`tertiary` table
	@docker exec -it ${BASE_NAME}-mariadb sh -c "mysql -uroot -ppassword example < /mnt/insert-tertiary.sql"

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

build: ## Compile
	@go build -o bin/app .

#######
# AWS #
#######

aws-sqs-list-queues: ## List all queues
	@docker exec -it ${BASE_NAME}-localstack awslocal sqs list-queues --region=eu-west-1

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
	@podman rmi -f ${IMAGE_BASE_NAME}-maxwell:latest || true
