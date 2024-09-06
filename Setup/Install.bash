###Setup PostgreSQL 16 on Ubuntu

# Create the file repository configuration
sudo sh -c 'echo "deb https://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'

# Import the repository signing key
sudo wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -

# Update the package lists
sudo apt update

# Install PostgreSQL 16
sudo apt install postgresql-16 postgresql-contrib-16

# Set password for postgres user
sudo -u postgres psql
ALTER USER postgres WITH PASSWORD '1234aa';

# Change setting on /etc/postgresql/16/main/postgresql.conf file to listen all ip addresses instead of local:
sudo nano /etc/postgresql/16/main/postgresql.conf
#listen_addresses = '*'

# Add this line on /etc/postgresql/16/main/pg_hba.conf file to allow connection from Nexcel network:
sudo nano /etc/postgresql/16/main/pg_hba.conf
#TYPE  DATABASE        USER            ADDRESS                 METHOD
#host  all             all             10.19.10.1/24           scram-sha-256

# Restart postgres service:
sudo systemctl restart postgresql@16-main

### After this step, we can connect to new server from Nexcel network