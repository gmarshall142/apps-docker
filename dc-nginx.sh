#!/bin/bash

docker-compose -f dc-appservices.yml -f dc-app.yml -f dc-nginx.yml $1
