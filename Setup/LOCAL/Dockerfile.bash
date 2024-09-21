#Use PostgreSQL 16.4 as base image
ARG POSTGRES_VERSION=16.4
FROM postgres:${POSTGRES_VERSION}

#Add metadata
LABEL \
	maintainer="luke.nguyen@starixsoft.com" \
	version="1.0" \
	description="PostgreSQL image with additional extensions: pg_partman, pg_cron, pgBadger."

#Install and update necessary packages
RUN apt-get update \
    && apt-get install -y \
    build-essential \
    postgresql-server-dev-all \
    git \
    wget \
    ca-certificates \
    perl \
    libjson-perl \
    libtext-csv-perl \
    libyaml-perl \
    && rm -rf /var/lib/apt/lists/*
	
#Install pg_partman
RUN git clone https://github.com/pgpartman/pg_partman.git /pg_partman \
    && cd /pg_partman \
    && make \
    && make install \
    && rm -rf /pg_partman

# Install pg_cron
RUN git clone https://github.com/citusdata/pg_cron.git /pg_cron \
    && cd /pg_cron \
    && make \
    && make install \
    && rm -rf /pg_cron

# Install pgBadger
RUN wget https://github.com/darold/pgbadger/archive/v11.4.tar.gz \
    && tar xzvf v11.4.tar.gz \
    && cd pgbadger-11.4 \
    && perl Makefile.PL \
    && make \
    && make install \
    && rm -rf /pgbadger-11.4 v11.4.tar.gz
	
#Set environment variables
ENV POSTGRES_USER=postgres
ENV POSTGRES_PASSWORD=postgres

#Expose default postgres port
EXPOSE 5432
