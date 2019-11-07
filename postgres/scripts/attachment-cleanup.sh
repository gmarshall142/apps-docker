#!/bin/bash

psql appfactory < /home/scripts/test/remove_temp_attachments.sql
/home/scripts/remove_user_attachments.sh
