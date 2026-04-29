#!/bin/bash
set -e

# Creates separate databases and users for Authentik and Joplin
# Runs once on first Postgres container start

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname postgres <<-EOSQL
    CREATE USER $AUTHENTIK_DB_USER WITH PASSWORD '$AUTHENTIK_DB_PASSWORD';
    CREATE DATABASE $AUTHENTIK_DB_NAME OWNER $AUTHENTIK_DB_USER;

    CREATE USER $JOPLIN_DB_USER WITH PASSWORD '$JOPLIN_DB_PASSWORD';
    CREATE DATABASE $JOPLIN_DB_NAME OWNER $JOPLIN_DB_USER;
EOSQL
