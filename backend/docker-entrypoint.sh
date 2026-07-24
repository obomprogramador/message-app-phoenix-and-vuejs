#!/bin/sh
set -e

cd /app

echo "==> Running migrations..."
mix ecto.migrate

echo "==> Running seeds..."
mix run priv/repo/seeds.exs

echo "==> Starting Phoenix server..."
mix phx.server
