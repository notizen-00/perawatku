FROM node:20-alpine AS base
WORKDIR /app
RUN corepack enable

# Install dependencies (including dev deps for build/dev)
FROM base AS deps
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml* ./
RUN pnpm install --frozen-lockfile

# Development image (used by docker compose)
FROM deps AS dev
ENV NODE_ENV=development
COPY . .
EXPOSE 3000
CMD ["pnpm","dev","--host","0.0.0.0","--port","3000"]

# Build production output
FROM deps AS builder
COPY . .
RUN pnpm build

# Minimal runtime image
FROM node:20-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production
COPY --from=builder --chown=node:node /app/.output /app/.output
USER node
EXPOSE 3000
CMD ["node",".output/server/index.mjs"]

# Runtime installer (for docker compose up: install -> build -> run via pm2)
FROM node:20-alpine AS compose-runner
WORKDIR /app
ENV NODE_ENV=production
COPY . .
COPY docker/entrypoint-prod.sh /entrypoint-prod.sh
RUN chmod +x /entrypoint-prod.sh
EXPOSE 3000
CMD ["/entrypoint-prod.sh"]
