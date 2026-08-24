# Deployment (GitHub Actions + Docker Compose)

This repo includes:

- CI: `.github/workflows/ci.yml`
- CD: `.github/workflows/cd.yml`
- Server compose: `docker-compose.prod.yml`

## 1) Prepare your server (one-time)

1. Install Docker + Docker Compose plugin on the server.
2. Create a deploy folder, e.g. `/opt/medic-admin`.
3. Copy these files to that folder:
   - `docker-compose.prod.yml`
   - `.env` (server runtime env for Nuxt)

Example on server:

```bash
mkdir -p /opt/medic-admin
cd /opt/medic-admin
# put docker-compose.prod.yml + .env here
```

## 2) Configure GitHub Secrets (one-time)

Repository → Settings → Secrets and variables → Actions → New repository secret:

- `SSH_HOST` (server IP/domain)
- `SSH_USER` (e.g. `root`/`ubuntu`)
- `SSH_PORT` (optional, default `22`)
- `SSH_PASSWORD` (SSH password for the user above)
- `DEPLOY_PATH` (e.g. `/opt/medic-admin`)

Optional (only if your GHCR package is private):

- `GHCR_USER` (your GitHub username or org name)
- `GHCR_TOKEN` (PAT with `read:packages`)

## 3) First deploy

Push a commit to `main`. Workflow `CD` will:

1. Build and push image to GHCR: `ghcr.io/<owner>/<repo>:<sha>` + `:latest`
2. SSH into the server and run:
   - (optional) `docker login ghcr.io ...`
   - `IMAGE=ghcr.io/<owner>/<repo>:<sha> docker compose -f docker-compose.prod.yml up -d --pull always`

## Notes

- If you want to deploy only on tags/releases (instead of every push to `main`), tell me your preferred flow and I’ll adjust the workflow triggers.
- Make sure port `3000` is open / reverse-proxied (Nginx/Caddy/Traefik) as needed.
