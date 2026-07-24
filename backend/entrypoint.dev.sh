#!/bin/sh
set -e

echo "--- Waiting for PostgreSQL to become available..."
while ! pg_isready -q -h "$PGHOST" -p "$PGPORT" -U "$PGUSER"; do
  sleep 1
done

echo "--- PostgreSQL is available!"

echo "--- Running database setup..."
mix ecto.create
mix ecto.migrate

echo "--- Starting Phoenix dev server..."
exec mix phx.server
