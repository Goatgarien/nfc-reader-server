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

# Copy startup script
COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 3000
CMD ["/start.sh"]
