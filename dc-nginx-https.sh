#!/bin/bash

docker-compose -f dc-web.yml -f dc-app.yml -f dc-nginx-https.yml $1
