#!/usr/bin/env bash
# Waits for the database to accept connections before exec'ing the container command.
set -euo pipefail

DB_HOST="${DB_HOST:-db}"
DB_PORT="${DB_PORT:-5432}"

echo "Waiting for database at ${DB_HOST}:${DB_PORT}..."
until (echo > "/dev/tcp/${DB_HOST}/${DB_PORT}") >/dev/null 2>&1; do
    sleep 1
done
echo "Database is up."

exec "$@"
