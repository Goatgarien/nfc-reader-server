# Build frontend
FROM node:20-alpine AS client_build
WORKDIR /app/client
COPY client/package.json client/package-lock.json ./
RUN npm ci
COPY client/ .
RUN npm run build

# Final image with Node + Postgres
FROM alpine:3.20

# Install Node.js + Postgres
RUN apk add --no-cache nodejs npm postgresql postgresql-contrib su-exec bash

# Set workdir
WORKDIR /app

# Copy backend code
COPY package.json package-lock.json ./
RUN npm ci --omit=dev
COPY server.js ./
COPY init.sql /docker-entrypoint-initdb.d/init.sql

# Copy built frontend
COPY --from=client_build /app/client/dist ./client_dist

# Environment
ENV PGDATA=/var/lib/postgresql/data
ENV DB_NAME=appdb
ENV DB_USER=app
# DB_PASSWORD and USERNAME/PASSWORD come from env at runtime

# Startup script
COPY --chmod=755 <<'EOF' /start.sh
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
EOF

EXPOSE 3000
CMD ["/start.sh"]
