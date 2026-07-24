#!/bin/sh
set -e

echo "--- Running database migrations..."
/app/bin/message_app eval "MessageApp.Release.migrate()"

echo "--- Seeding database..."
/app/bin/message_app eval "MessageApp.Release.seed()"

echo "--- Starting Phoenix server..."
exec /app/bin/message_app start
