#!/usr/bin/env bash

docker container run --rm --name pg-docker -e POSTGRES_PASSWORD=$1 --env-file=$2 \
-d -p 5433:5432 \
-v $HOME/docker/volumes/postgres:/var/lib/postgresql/data appfactory-pg:10.9
