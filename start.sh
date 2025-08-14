#!/bin/bash
set -e

# Require PASSWORD
if [ -z "$PASSWORD" ]; then
  echo "ERROR: PASSWORD env not set"
  exit 1
fi

# Setup DB dir
mkdir -p "$PGDATA"
chown -R postgres:postgres "$PGDATA"

# Init DB if not already
if [ ! -s "$PGDATA/PG_VERSION" ]; then
  su-exec postgres initdb
  su-exec postgres pg_ctl -D "$PGDATA" start
  su-exec postgres createdb "$DB_NAME"
  su-exec postgres psql -c "CREATE USER $DB_USER WITH PASSWORD '$PASSWORD';"
  su-exec postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;"
  su-exec postgres psql -d "$DB_NAME" -f /docker-entrypoint-initdb.d/init.sql
  su-exec postgres pg_ctl -D "$PGDATA" stop
fi

# Start Postgres in background
su-exec postgres pg_ctl -D "$PGDATA" -o "-c listen_addresses='*'" -w start

# Start Node backend
exec node server.js
