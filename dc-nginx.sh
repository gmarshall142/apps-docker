#!/bin/bash

docker-compose -f dc-web.yml -f dc-app.yml -f dc-nginx.yml $1
