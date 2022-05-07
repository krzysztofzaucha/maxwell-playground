# Maxwell Sandbox

This repository contains basic **MariaDB**, **Maxwell** and **AWS** **SQS** [localstack](https://localstack.cloud/) configuration.

To run this example **Docker** installation is required.

More detailed documentation of the **Maxwell** daemon can be found [here](https://maxwells-daemon.io/).

## Diagram

![](diagram/flow.svg)

## Makefile

Use `Makefile` to run all the examples. To list all available options run `make`.

## Instructions

- Run `make up` to start everything up.
- Run `make mariadb` to access database shell, run the below example SQL queries to create records.
- Run `make mariadb-insert-primary`, `make mariadb-insert-secondary` or `make mariadb-insert-tertiary` to insert database records.
- Run e.g. `make aws-sqs-receive-message-maxwell-primary` to consume primary queue (run `make` to see more options).
