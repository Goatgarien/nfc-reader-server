#!/bin/bash
set -e

# Ensure PGDATA is set
export PGDATA=${PGDATA:-/var/lib/postgresql/data}

# Create data directory if it doesn't exist
mkdir -p "$PGDATA"
chown -R postgres:postgres "$PGDATA"

# Initialize database only if empty
if [ -z "$(ls -A "$PGDATA")" ]; then
    echo "No existing database found, initializing..."
    su - postgres -c "/usr/lib/postgresql/${PG_MAJOR}/bin/initdb -D '$PGDATA'"
else
    echo "Existing database found, skipping initialization."
fi

# Start Postgres in background to run migrations / app setup
echo "Starting PostgreSQL..."
su - postgres -c "/usr/lib/postgresql/${PG_MAJOR}/bin/pg_ctl -D '$PGDATA' -w start"

# Run your app's migrations if applicable
# Example:
# su - postgres -c "psql -d mydb -f /app/migrations.sql"

# Keep Postgres running in foreground
exec su - postgres -c "/usr/lib/postgresql/${PG_MAJOR}/bin/postgres -D '$PGDATA'"
