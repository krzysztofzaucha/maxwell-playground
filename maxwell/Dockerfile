FROM zendesk/maxwell:latest

USER root

ENV HOST=localhost
ENV PORT=3306
ENV USERNAME=root
ENV PASSWORD=password
ENV PRODUCER=stdout

RUN apt-get update \
    && apt-get -y dist-upgrade \
    && apt-get -y install default-mysql-client \
    && apt-get -y install python python3-pip \
    && pip install awscli \
    && rm -R -f /app/lib/aws-java-sdk-core-*.jar\
    && rm -R -f /app/lib/aws-java-sdk-sqs-*.jar \
    && rm -R -f /app/lib/maxwell-*.jar

CMD bin/maxwell --user=${USERNAME} --password=${PASSWORD} --host=${MYSQL_HOST} --producer=${PRODUCER}

ADD config.properties /app/config.properties
ADD entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

USER 1000

ADD .aws /app/.aws

ENTRYPOINT /entrypoint.sh
