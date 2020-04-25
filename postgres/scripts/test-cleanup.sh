#!/bin/bash

psql gmarshall < /home/scripts/test/remove_apps.sql
psql gmarshall < /home/scripts/test/remove_sample_app.sql
