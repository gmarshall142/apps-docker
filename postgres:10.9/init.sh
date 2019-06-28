#!/bin/bash

set -e

echo "'$POSTGRES_OWNER_PSWD'"
echo "'$POSTGRES_PSWD'"

psql -v ON_ERROR_STOP=1 -v appowner_pswd="'$POSTGRES_OWNER_PSWD'" -v appuser_pswd="'$POSTGRES_PSWD'" <<-EOSQL
  create role appowner with login password :appowner_pswd;
  create role appuser with login password :appuser_pswd;
  CREATE DATABASE appfactory;
  \c appfactory
  CREATE SCHEMA app;
  ALTER SCHEMA app OWNER TO appowner;
  CREATE SCHEMA metadata;
  ALTER SCHEMA metadata OWNER TO appowner;
EOSQL

echo 'load initial setup'
psql appfactory < /home/migrations/V1.1__initial_setup.sql
