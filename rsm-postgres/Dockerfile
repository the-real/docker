# FROM ubuntu?
FROM vnijs/r-bionic:latest

MAINTAINER Vincent Nijs "radiant@rady.ucsd.edu"

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update \
  && apt-get -y upgrade \
  && apt-get -y install --no-install-recommends \

ENV POSTGRES_VERSION=10

RUN apt-get update && apt-get install -y \
  postgresql-${POSTGRES_VERSION} \
  postgresql-client-${POSTGRES_VERSION} \
  postgresql-contrib-${POSTGRES_VERSION}

## Run the rest of the commands as the postgres user
USER postgres

## create a postgres role for ${NB_USER} with "postgres" as the password
## create a database "rsm-docker" owned by the ${NB_USER} role.
RUN /etc/init.d/postgresql start \
    && psql --command "CREATE USER ${NB_USER} WITH SUPERUSER PASSWORD 'postgres';" \
    && createdb -O ${NB_USER} rsm-docker

COPY postgresql.conf /etc/postgresql/${POSTGRES_VERSION}/main/postgresql.conf
COPY pg_hba.conf /etc/postgresql/${POSTGRES_VERSION}/main/pg_hba.conf

USER root

## updating the supervisord.conf file for Jupyter
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

EXPOSE 8765

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
