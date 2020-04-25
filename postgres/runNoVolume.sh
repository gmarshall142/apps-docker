#!/usr/bin/env bash

docker container run --rm --name pg-docker -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=$1 --env-file=$2 \
-d -p 5433:5432 \
gemapps-pg:10.9
