#!/bin/bash

set -e

echo ===== GEMAPPS_POSTGRES_PSWD: =====
echo "'$GEMAPPS_POSTGRES_PSWD'"

psql -v ON_ERROR_STOP=1 -v gmarshall_pswd="'$GEMAPPS_POSTGRES_PSWD'" <<-EOSQL
  create role gmarshall with login password :gmarshall_pswd;
  CREATE DATABASE gmarshall;
  \c gmarshall
EOSQL

echo 'load initial setup'
psql gmarshall < /home/migrations/V1.1__initial_setup.sql
