#!/usr/bin/env bash

docker container run --rm --name pg-docker -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=$1 --env-file=$2 \
-d -p 5433:5432 \
-v $HOME/docker-apps/volumes/postgres:/var/lib/postgresql/data gemapps-pg:10.9
