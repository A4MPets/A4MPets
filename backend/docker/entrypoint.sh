#!/bin/sh
set -eu

cd /var/www/html

if [ -z "${APP_KEY:-}" ]; then
  echo "APP_KEY no esta definida. Configura APP_KEY en docker-compose.yml" >&2
  exit 1
fi

if [ "${DB_CONNECTION:-sqlite}" = "sqlite" ]; then
  db_file="${DB_DATABASE:-/data/database.sqlite}"
  mkdir -p "$(dirname "$db_file")"
  touch "$db_file"
  echo "SQLite listo en $db_file"
fi

if ! php artisan migrate --force >/tmp/migrate.log 2>&1; then
  echo "No fue posible correr migraciones" >&2
  cat /tmp/migrate.log >&2 || true
  exit 1
fi

echo "Migraciones aplicadas correctamente"

php artisan serve --host=0.0.0.0 --port=8000
