#!/bin/sh
set -eu

cd /app

# Per request: install pnpm via npm, then install deps, build, and run via pm2
npm i -g pnpm pm2

pnpm i
pnpm run build

exec pm2-runtime start node --name medic-admin -- .output/server/index.mjs
