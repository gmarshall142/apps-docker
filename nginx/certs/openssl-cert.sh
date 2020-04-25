#!/bin/bash

sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout gemapps.key -out gemapps.crt -config gemapps.conf
sudo openssl dhparam -out dhparam.pem 2048
