#!/bin/bash

psql appfactory < /home/scripts/test/remove_apps.sql
psql appfactory < /home/scripts/test/remove_sample_app.sql
