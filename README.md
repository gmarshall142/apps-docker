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
### REST Server
The REST service handles requests from the front-end and runs as a Node application.  This is built in the __server__
directory and is defined under the __server__ service.
Key attributes in this service are:
* build - the build definition
  * context - specifies using the 'postgres' subdirectory
  * dockerfile - the docker file to build from, currently 'Dockerfile'.  This can be updated as other Node versions are 
  used.  
* image - the image name [appfactory-server]
* container_name - the container instance name that will appear in the 'docker container ls' listing [appserver]
* environment - environment variables that will be set in the running container.  These make use of environment
variables that must be set on the host machine:
  * POSTGRES_PASSWORD
  * POSTGRES_PSWD
  * POSTGRES_OWNER_PSWD
      POSTGRES_HOST:          postgres
      POSTGRES_PORT:          5432
      POSTGRES_NAME:          ${POSTGRES_NAME}
      POSTGRES_USER:          ${POSTGRES_USER}
      POSTGRES_PASSWORD:      ${POSTGRES_PSWD}
      POSTGRES_PSWD:          ${POSTGRES_PSWD}
      POSTGRES_OWNER_PSWD:    ${POSTGRES_OWNER_PSWD}
      APPFACTORY_VOLUME_PATH: /usr/volumes
      VUE_APP_EMAIL:          ${VUE_APP_EMAIL}
      VUE_APP_PSWD:           ${VUE_APP_PSWD}
      VUE_APP_MODE:           ${VUE_APP_MODE}
      VUE_APP_LEVEL:          ${VUE_APP_LEVEL}
* networks - static network setting using the sub-net defined by the YAML file
* ports - port forwarding from the host to the container
  * 3000:3000
* volumes - the source code for the REST application
  * $APPFACTORY_SOURCE_PATH/services:/usr/src/app - this is the mapping from the host machine directory to the 
  container directory.  The environment variable _APPFACTORY_SOURCE_PATH_ must be set on the host machine and
  will contain the subdirectory _/services_.
  * $APPFACTORY_VOLUME_PATH/postgres/data:/var/lib/postgresql/data - this is the mapping from the host machine directory
  to the container directory.  The environment variable _APPFACTORY_VOLUME_PATH_ must be set on the host machine and
  will contain the subdirectories /logs, /files, and /help.
 
### Web Server
The Web service provides the front-end web application.  This is built in the __web__ directory and is defined under 
the __web__ service.
Key attributes in this service are:
* build - the build definition
  * context - specifies using the 'web' subdirectory
  * dockerfile - the docker file to build from, currently 'Dockerfile'.
* image - the image name [appfactory-web]
* container_name - the container instance name that will appear in the 'docker container ls' listing [web]
* environment - environment variables that will be set in the running container.  These make use of environment
variables that must be set on the host machine:
  * POSTGRES_PASSWORD
  * POSTGRES_PSWD
  * POSTGRES_OWNER_PSWD
      VUE_APP_EMAIL:          ${VUE_APP_EMAIL}
      VUE_APP_PSWD:           ${VUE_APP_PSWD}
      VUE_APP_MODE:           ${VUE_APP_MODE}
      VUE_APP_LEVEL:          ${VUE_APP_LEVEL}
      SERVERPORT:             3000
* networks - static network setting using the sub-net defined by the YAML file
* ports - port forwarding from the host to the container
  * 8080:8080
* volumes - the source code for the Web application using Vue
  * $APPFACTORY_SOURCE_PATH/appfactory:/usr/src/web - this is the mapping from the host machine directory to the 
  container directory.  The environment variable _APPFACTORY_SOURCE_PATH_ must be set on the host machine and
  will contain the subdirectory _/appfactory_.
 
### Nginx Service
The Nginx Service provides a reverse proxy for making calls to a single server and rerouting the requests to the 
appropriate application server.  This also allows SSL/HTTPS requests from the browser while using HTTP when 
communicating to the application servers.  Currently it has not been determined whether it makes sense to use the nginx
service in a deployment or whether this is a proof-of-concept, but regardless working with the nginx service identifies
issues in the configuration of the services and the URLs used in the application.

There are two sets of YAML and Dockerfiles; one for HTTP and one for HTTPS.  There are also two nginx configuration
files; _nginx-http.conf_ and _nginx-https.conf.  
 
# Launching Containers
Multiple docker-compose files are available for launching the containers for different purposes.  This work is on-going
and attempts to reuse configurations, but it requires using the _'-f'_ commandline parameter to launch multiple files.
Prior versions provided a _'extends'_ key word that allows configurations to be pulled from other files, but this 
functionality is not available in version 3.X.
 
### Web Development
Developing locally for the web server can be done by using the dc-web.yml compose file running the postgresql and 
REST server as Docker containers. 
 ``` javascript
docker-compose -f dc-web.yml up
docker-compose -f dc-web.yml down
```
The application can be run in the browser using: http://www.appfactory.com:8080      

### All Three Services in Containers
All three of the application services in containers can be started and stopped using the following command line:
``` javascript
docker-compose -f dc-web.yml -f dc-app.yml up
docker-compose -f dc-web.yml -f dc-app.yml down
``` 
OR
``` javascript
./dc-app.sh up
./dc-app.sh down
``` 

The application can be run in the browser using: http://www.appfactory.com:8080      

### Nginx 
The application can be run using an Nginx endpoint container and redirecting requests to the other application 
containers.  This makes use of the previous docker compose files and adds one for the nginx service:
``` javascript
docker-compose -f dc-web.yml -f dc-app.yml -f dc-nginx.yml up
docker-compose -f dc-web.yml -f dc-app.yml -f dc-nginx.yml down
``` 
OR
``` javascript
./dc-nginx.sh up
./dc-nginx.sh down
``` 
The application can be run in the browser using: http://www.appfactory.com.    

Launching the HTTPS version is done by using the _dc-nginx-https.yml_:
``` javascript
docker-compose -f dc-web.yml -f dc-app.yml -f dc-nginx-https.yml up
docker-compose -f dc-web.yml -f dc-app.yml -f dc-nginx-https.yml down
``` 
OR
``` javascript
./dc-nginx-https.sh up
./dc-nginx-https.sh down
``` 
The application can be run in the browser using: https://www.appfactory.com     

## Running HTTP & HTTPS in browsers using project certificates
Currently the project uses self-signed certificates which can be replaced later with signed certs.  This does cause
issues when running in the browser.
### Chrome
Chrome prevents running HTTPS using the self-signed certificates and will flag them as invalid.  Ignoring invalid the
certificate warning requires launching Chrome with the _ignore-certificate-errors_ flag.
On a Mac running the following in a terminal:
``` javascript
/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --ignore-certificate-errors &> /dev/null &
```
### Firefox
Firefox allows the user to ignore the warnings by selecting the 'Advanced' button in the Warning Screen and then 
selecting the 'Accept the Risk and Continue' button and the second dialog.
### Safari
Safari also cautions regarding invalid certificates but allows the user to ignore the warnings and proceed to the site.

# NOTES
There were several issues encountered while working with the docker configurations.  
### URL
Currently the application is launched by using the 'www.appfactory.com' Domain name.  When working locally it is
necessary to add this to the machines hosts file:
``` javascript   

```

### Changes to Images
When making changes to the containers subsequent docker compose launches are not sensitive to the changes and will 
continue to use a previously built docker image.  It is necessary to remove the old image version causing it to be 
rebuilt.  This can be done by reviewing the images and removing the changed container:
``` javascript
docker images # displays all images
docker image rm appfactory-web  # removes the appfactory-web image
```
A script has been included that cleans all container images causing them to be rebuilt when running docker compose up.
Various lines can be commented out if there are no changes to those images.  The postgres container in particular may
take longer to rebuild.
``` javascript
./clean-images.sh
```


