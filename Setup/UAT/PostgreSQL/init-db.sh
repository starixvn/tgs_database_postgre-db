#!/bin/bash
cp /var/lib/postgresql/data/pg_hba.conf /var/lib/postgresql/data/pg_hba.conf.backup
cp /etc/postgresql/pg_hba.conf /var/lib/postgresql/data/pg_hba.conf
exec postgres