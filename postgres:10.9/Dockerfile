# postgres:10.9
FROM postgres:10.9
COPY ./init.sh /docker-entrypoint-initdb.d/
RUN chmod +x /docker-entrypoint-initdb.d/init.sh
RUN mkdir ~/migrations
COPY ./migrations/V1.1__initial_setup.sql /home/migrations/
