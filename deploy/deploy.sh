#!/usr/bin/env bash
# Rebuilds and (re)starts the production stack on the server.
#
# Run from anywhere; it resolves the repo root from its own location. Assumes
# the code on the server is already up to date (git pull / rsync done before
# calling this) and that deploy/.env, apps/backend/.env and
# apps/admin-dashboard/.env are already filled in. See docs/deployment.md.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
COMPOSE=(docker compose -f "$SCRIPT_DIR/docker-compose.prod.yml" --env-file "$SCRIPT_DIR/.env")

cd "$REPO_ROOT"

for f in "$SCRIPT_DIR/.env" apps/backend/.env apps/admin-dashboard/.env; do
  if [ ! -f "$f" ]; then
    echo "Missing $f -- copy it from its .example and fill in the values first." >&2
    exit 1
  fi
done

echo "==> Building images"
"${COMPOSE[@]}" build

echo "==> Starting stack"
"${COMPOSE[@]}" up -d

echo "==> Waiting for the app container to report healthy DB/Redis dependencies"
"${COMPOSE[@]}" ps

echo "==> Pruning dangling images from the rebuild"
docker image prune -f

echo "==> Recent app logs"
"${COMPOSE[@]}" logs --tail=50 app
