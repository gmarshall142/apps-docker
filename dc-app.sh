#!/bin/bash

docker-compose -f dc-web.yml -f dc-app.yml $1
