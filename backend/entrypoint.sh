#!/bin/sh
set -e

if [ -z "$SECRET_KEY_BASE" ]; then
  echo "--- Generating SECRET_KEY_BASE..."
  export SECRET_KEY_BASE=$(mix phx.gen.secret 2>/dev/null || /app/bin/message_app eval "IO.puts(:crypto.strong_rand_bytes(64) |> Base.encode64())" | tail -1)
  echo "SECRET_KEY_BASE=$SECRET_KEY_BASE"
fi

echo "--- Waiting for PostgreSQL to become available..."
while ! pg_isready -q -h "$PGHOST" -p "$PGPORT" -U "$PGUSER"; do
  sleep 1
done

echo "--- Running database migrations..."
/app/bin/message_app eval "MessageApp.Release.migrate()"

echo "--- Starting Phoenix server..."
exec /app/bin/message_app start
