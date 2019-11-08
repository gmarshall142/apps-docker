# appfactory-docker
This repository contains a YAML file for launching the test environment in Docker.  There are subdirectories for each
of the containers used in the development environment.  The docker-composition configuration relies heavily on 
environment variables which will be described in the following text.

## docker-compose YAML File
The docker-compose.yml file is located in the project root directory.  To start the containers:
* Start a terminal
* CD into the repo root directory
* Start the containers: 'docker-compose up' on the command line

The docker-compose file defines Services and Network configurations.

## Services
There is a container for each service.  The service containers are launched by the docker-compose file and are built
using the docker file and configuration files in their directory.  Each service uses environment variables in both the
build process and to set environment variables used in the container.

### Postgresql Service
The postgresql service is built from the files in the __postgres__ directory and is defined under the __db__ service.
Key attributes in this service are:
* build - the build definition
  * context - specifies using the 'postgres' subdirectory
  * dockerfile - the docker file to build from, currently 'Dockerfile-10.9'.  This can be updated as other Postgresql
  versions are used.  
* image - the image name [appfactory-pg:10.9]
* container_name - the container instance name that will appear in the 'docker container ls' listing [postgres]
* environment - environment variables that will be set in the running container.  These make use of environment
variables that must be set on the host machine:
  * POSTGRES_PASSWORD
  * POSTGRES_PSWD
  * POSTGRES_OWNER_PSWD
* networks - static network setting using the sub-net defined by the YAML file
* ports - port forwarding from the host to the container
  * 5433:5432 - the Postgresql port which is 5433 on the host and 5432 in the postgres container.  Any service or 
  application running on the host will connect using port 5433 (examples: Datagrip or the REST service running on the
  host)
* volumes - the database volume where the Postgresql data files will be stored which will be mapped in the container
to '/var/lib/postgresql/data'
  * $APPFACTORY_VOLUME_PATH/postgres/data:/var/lib/postgresql/data - this is the mapping from the host machine directory
  to the container directory.  The environment variable _APPFACTORY_VOLUME_PATH_ must be set on the host machine and
  will contain the subdirectories /postgresql/data.

#### Database Persistence
When the database container is started it will attempt to run the startup script defined in the 'postgres/init.sh' 
script file.  The script attempts to create database user roles, create the 'appfactory' database, and create the
'app' and 'metadata' schemas in the database.  If the $APPFACTORY_VOLUME_PATH/postgres/data directory does not exist
it will create the 'data' directory and the Postgresql files.  The database initialization script 
'migrations/V1.1__initial_setup.sql' will be run to initialize the database tables.  Once the directory and files are
created subsequent container startup will fail when running the 'init.sh' script leaving the database files and their 
contents intact.  In this way the state of the database can be maintained and reused through repeated docker sessions.
When the database needs to be initialized the container can be stopped, the 'data' directory deleted, and the container
restarted which will once again run the 'init.sql' script and reload the initial database tables.

#### Database Scripts
There are currently four SQL scripts that can be used to load/unload data in the database.  The scripts are pulled from
the postgres/scripts directory and are loaded into the /home/scripts directory in the container.
* /home/scripts/demo-setup.sh - loads data used in the initial demonstration [Battle Damage application]
* /home/scripts/demo-cleanup.sh - unloads demo data
* /home/scripts/test-setup.sh - loads data used in the on-going sample application [Test Application]
* /home/scripts/test-cleanup.sh - unloads on-going sample application   
__NOTE:__ The scripts do not setup or cleanup any attachment files.

Once the database has been loaded the scripts can be run by attaching a bash shell to the running container.  The 
following steps show the commans that would be used in a second terminal to attach the bash shell and run a script in 
the container bash shell as the 'postgres' user:
``` javascript
docker exec -it postgres /bin/bash
su postgres /home/scripts/test-setup.sh
```
 
