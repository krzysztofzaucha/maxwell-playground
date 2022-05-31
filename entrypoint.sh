#!/bin/sh

ENDPOINT="$(jq -r '.es.protocol' < config.json)://$(jq -r '.es.host' < config.json):$(jq -r '.es.port' < config.json)"
NAME="$(jq -r '.es.name' < config.json)"

until [ "$(curl -sS "${ENDPOINT}/_cluster/health" | jq -r '.status')" == "green" ]; do
  echo "waiting for ElasticSearch to be ready..."
  sleep 5
done

if ! curl -XGET --output /dev/null --silent --head --fail "${ENDPOINT}/${NAME}/_search" -H 'content-type: application/json' -d'{"query":{"match_all":{}}}'; then
  echo "creating '${NAME}' index..."
  if ! curl -XPUT --output /dev/null --silent --head --fail "${ENDPOINT}/${NAME}"; then
    echo "unable to create '${NAME}' index"
    exit 1
  fi
fi

until ! curl -XGET --output /dev/null --silent --head --fail "${ENDPOINT}/${NAME}/_search" -H 'content-type: application/json' -d'{"query":{"match_all":{}}}'; do
    echo "waiting for index to be created..."
    sleep 5
done

#curl -sS -XGET "${ENDPOINT}/_cat/indices"

bin/app
