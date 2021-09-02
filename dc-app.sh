#!/bin/bash

docker-compose -f dc-appservices.yml -f dc-app.yml $1
