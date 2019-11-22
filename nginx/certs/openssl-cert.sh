#!/bin/bash

sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout appfactory.key -out appfactory.crt -config appfactory.conf
sudo openssl dhparam -out dhparam.pem 2048
