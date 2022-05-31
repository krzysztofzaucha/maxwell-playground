FROM alpine:latest as builder

RUN apk update \
    && apk add go

WORKDIR /opt/app

ADD . /opt/app

RUN go build -buildmode=plugin -o bin/producer.so internal/plugin/producer.go
RUN go build -buildmode=plugin -o bin/consumer.so internal/plugin/consumer.go
RUN go build -o bin/app .

FROM alpine:latest as final

RUN apk update \
    && apk add curl jq

WORKDIR /opt/app

COPY --from=builder /opt/app/bin /opt/app/bin

ADD entrypoint.sh /entrypoint.sh

ENTRYPOINT ["bin/app"]

CMD ["--help"]
