#!/usr/bin/env sh
set -eu

cd /var/www/html

# There is no .env file inside this container -- config comes purely from
# env vars injected via `env_file:` in docker-compose.prod.yml, so
# `artisan key:generate` has nowhere to persist a key to. Fail loudly
# instead of silently booting with no/changing key, which would corrupt
# sessions and encrypted data across restarts.
if [ -z "${APP_KEY:-}" ]; then
  echo "APP_KEY is not set. Generate one and put it in apps/backend/.env before deploying:" >&2
  echo '  docker run --rm php:8.4-cli php -r "echo base64_encode(random_bytes(32)).PHP_EOL;"' >&2
  exit 1
fi

# Wait for the database so `migrate` below doesn't fail on a cold start.
if [ -n "${DB_HOST:-}" ] && [ "${DB_CONNECTION:-}" != "sqlite" ]; then
  HOST="${DB_HOST}"
  PORT="${DB_PORT:-5432}"
  echo "Waiting for DB at ${HOST}:${PORT}..."
  i=0
  while [ "$i" -lt 60 ]; do
    H="$HOST" P="$PORT" php -r "exit(@fsockopen(getenv('H'), (int) getenv('P')) ? 0 : 1);" && break || true
    i=$((i + 1))
    sleep 1
  done
fi

# Only the php-fpm (app) container runs migrations/cache warmup. The reverb
# container shares this image/entrypoint but boots with a different CMD, so
# without this guard both containers would race to write the same cache
# files and re-run migrations on every deploy.
if [ "${1:-}" = "php-fpm" ]; then
  # public/ is a shared volume with the nginx container; re-sync the image's
  # built copy into it so new deploys (new hashed asset filenames, etc.)
  # actually show up. `storage` symlink is excluded so it's left alone.
  rsync -a --delete --exclude storage /opt/app-public-dist/ public/

  php artisan migrate --force
  php artisan storage:link || true
  php artisan config:cache
  php artisan route:cache
  php artisan view:cache
fi

exec "$@"
