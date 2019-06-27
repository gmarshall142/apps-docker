#!/bin/bash

set -e

psql -v ON_ERROR_STOP=1 -v appowner_pswd=$POSTGRES_OWNER_PSWD -v appuser_pswd=$POSTGRES_PSWD --username postgres <<-EOSQL
  create role appowner with login password 'V-22specialProjects';
  create role appuser with login password 'fb4k0F4';
  CREATE DATABASE appfactory;
  \c appfactory
  CREATE SCHEMA app;
  ALTER SCHEMA app OWNER TO appowner;
  CREATE SCHEMA metadata;
  ALTER SCHEMA metadata OWNER TO appowner;
EOSQL
