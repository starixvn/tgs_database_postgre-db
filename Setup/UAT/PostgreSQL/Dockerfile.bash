#Use PostgreSQL 16.4 as base image
ARG POSTGRES_VERSION=16.4
FROM postgres:${POSTGRES_VERSION}

#Variable environments
ARG NEW_UID=379
ARG NEW_GID=379

#Add metadata
LABEL \
        maintainer="luke.nguyen@starixsoft.com" \
        version="1.0" \
        description="PostgreSQL image with additional extensions: pg_partman, pg_cron, pgBadger."

#Install and update necessary packages
RUN apt-get update \
    && apt-get install -y \
    build-essential \
    postgresql-server-dev-16 \
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
    && git checkout v5.1.0 \
    && make \
    && make install \
    && rm -rf /pg_partman

# Install pg_cron
RUN git clone https://github.com/citusdata/pg_cron.git /pg_cron \
    && cd /pg_cron \
    && git checkout v1.6.4 \
    && make \
    && make install \
    && rm -rf /pg_cron

# Install pgBadger
RUN wget https://github.com/darold/pgbadger/archive/v12.4.tar.gz && \
    tar xzvf v12.4.tar.gz && \
    cd pgbadger-12.4 && \
    perl Makefile.PL && \
    make && \
    make install && \
    rm -rf pgbadger-12.4 v12.4.tar.gz

# Create the directory and set permissions
RUN usermod -u ${NEW_UID} postgres && \
    groupmod -g ${NEW_GID} postgres && \
    chown -R postgres:postgres /var/run/postgresql && \
    chown -R postgres:postgres /var/lib/postgresql/data

#Set environment variables
ENV POSTGRES_USER=postgres

#Expose default postgres port
EXPOSE 5432	