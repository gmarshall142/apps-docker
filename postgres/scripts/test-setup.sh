#!/bin/bash

psql appfactory < /home/scripts/test/add_sample_app.sql
psql appfactory < /home/scripts/test/add_apps.sql
