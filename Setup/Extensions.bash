###Install extensions

##pg_partman
# Change directory to /postgres/contrib:
cd /usr/share/postgresql/16/contrib

# Clone pg_partman repo:
sudo git clone https://github.com/pgpartman/pg_partman.git

# Change directory to /pg_partman just created:
cd /pg_partman

# Start install:
sudo make install
# If above step give error "'postgres.h' file not found" , install this package to resolve:
sudo apt install postgresql-server-dev-16
# Do step start install again

# Change setting on /etc/postgresql/16/main/postgresql.conf file:
# shared_preload_libraries = 'pg_partman_bgw'

# Restart PostgreSQL service:
sudo systemctl restart postgresql@16-main

# Login to postgreSQL (standing on tgs_staging):
sudo -i -u postgres
psql -d tgs_staging
# Create schema:
CREATE SCHEMA partman;

# Create extension:
CREATE EXTENSION pg_partman SCHEMA partman
##

##pg_cron
# Download pg-cron extension:
sudo apt-get -y install postgresql-16-cron

# Modify postgresql.conf file:
sudo nano /etc/postgresql/16/main/postgresql.conf
# shared_preload_libraries = 'pg_cron'

# Modify pg_hba.conf file to allow connection from pg_cron job:
sudo nano /etc/postgresql/16/main/pg_hba.conf
# TYPE  DATABASE        USER            ADDRESS                 METHOD
# host  all             all             127.0.0.1/32            trust

# Restart PostgreSQL service
sudo systemctl restart postgresql@16-main

# Create extension
sudo -i -u postgres
psql
CREATE EXTENSION pg_cron;
##

##pgBadger
# Download pgBadger installation package:
sudo wget https://github.com/darold/pgbadger/archive/v11.4.tar.gz

# Extract archive from tarball:
sudo tar xzvf v11.4.tar.gz

# Change directory:
cd pgbadger-11.4

# Compile make file:
sudo perl Makefile.PL

# Install pgBadger:
sudo make && sudo make install

# Check pgBadger version:
pgbadger --version

# Change postgresql.conf file:
sudo nano /etc/postgresql/16/main/postgresql.conf
# log_line_prefix = '%t [%p]: user=%u,db=%d,app=%a,client=%h '
# log_min_duration_statement = 0
# log_checkpoints = on
# log_connections = on
# log_disconnections = on
# log_lock_waits = on
# log_temp_files = 0
# log_autovacuum_min_duration = 0
# log_error_verbosity = default

# Restart PostgreSQL:
sudo systemctl restart postgresql@16-main

# Use pgBadger to view log with graphics:
sudo pgbadger -I -O ./report.html /var/lib/postgresql/16/main/log/postgresql-Thu.log

# Then open html in browser for reading more detail info
ls /home/luke.nguyen@spvn.local
##
