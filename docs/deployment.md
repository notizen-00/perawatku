# Deployment (Docker)

Panduan deploy production untuk monorepo **perawatku** memakai Docker Compose.
Yang dicakup: backend Laravel (API + WebSocket Reverb) dan admin dashboard
(Nuxt). Aplikasi mobile (`mobile-pasien`, `mobile-mitra`) **tidak** termasuk
di sini — itu di-build sebagai APK/IPA lewat Flutter dan didistribusikan via
Play Store/App Store/internal distribution, bukan lewat Docker.

## Arsitektur

```
                                   Internet
                                      |
                         (TLS: Nginx Proxy Manager / Caddy / Traefik
                          yang sudah berjalan di VPS — di luar stack ini)
                                      |
                +---------------------------------------+
                |                    |                    |
        admin.perawatku.tech   backend.perawatku.tech (HTTP + WSS)
                |                    |
                v                    v
     +----------------+   +---------------------+
     |  admin (Nuxt)  |   |  nginx (Laravel)     |
     |  :3000         |   |  :8081 -> :80        |
     +----------------+   +----------+-----------+
                                      |
                        +-------------+--------------+
                        |             |               |
                        v             v               v
                +----------+   +-----------+   +-------------+
                |   app    |   |  reverb   |   | (php-fpm:9000|
                | (php-fpm)|   | (:8080 WS)|   |  fastcgi)    |
                +----+-----+   +-----+-----+   +-------------+
                     |               |
                     +-------+-------+
                             |
                  +----------+----------+
                  |                     |
                  v                     v
             +--------+           +---------+
             |   db   |           |  redis  |
             |Postgres|           |         |
             +--------+           +---------+
```

Semua service jalan dalam satu Docker Compose project (`perawatku`) di
[deploy/docker-compose.prod.yml](../deploy/docker-compose.prod.yml), di satu
Docker network internal. Hanya `nginx` (backend) dan `admin` yang publish
port ke host — DB dan Redis sengaja **tidak** dibuka ke luar container.

TLS/HTTPS **tidak** ditangani di sini. Server diasumsikan sudah punya
reverse proxy (mis. Nginx Proxy Manager) yang forward domain publik ke port
host `nginx`/`admin` di bawah, sesuai pola yang sudah dipakai backend saat
ini (lihat [`docker/nginx/reverb-production-proxy.conf.example`](../apps/backend/docker/nginx/reverb-production-proxy.conf.example)).

## Prasyarat

Di server (VPS):

- Docker Engine + Docker Compose plugin (`docker compose version` >= v2).
- Reverse proxy dengan TLS yang sudah jalan (Nginx Proxy Manager/Caddy/Traefik)
  dan domain (`backend.perawatku.tech`, `admin.perawatku.tech` atau
  domain kamu sendiri) sudah diarahkan ke server.
- Akses SSH ke server dengan user yang bisa run Docker.

## Struktur file deploy

| File | Fungsi |
| --- | --- |
| [`deploy/docker-compose.prod.yml`](../deploy/docker-compose.prod.yml) | Orkestrasi semua service production (backend + admin + db + redis). |
| [`deploy/.env.example`](../deploy/.env.example) | Template variabel level-compose (port host, kredensial PostgreSQL/Redis). |
| [`deploy/deploy.sh`](../deploy/deploy.sh) | Script build + up + cleanup untuk redeploy. |
| [`apps/backend/Dockerfile.prod`](../apps/backend/Dockerfile.prod) | Image production Laravel (source & vendor & asset di-bake saat build, bukan runtime). |
| [`apps/backend/docker/entrypoint.prod.sh`](../apps/backend/docker/entrypoint.prod.sh) | Entrypoint production: migrate aman (bukan `migrate:fresh`), cache config/route/view. |
| [`apps/backend/.env.docker.prod.example`](../apps/backend/.env.docker.prod.example) | Template `.env` Laravel khusus jalan di dalam Compose (host `db`/`redis`/`reverb`). |
| [`apps/admin-dashboard/Dockerfile`](../apps/admin-dashboard/Dockerfile) (`target: runner`) | Image production Nuxt (sudah ada sebelumnya, dipakai ulang). |
| [`apps/admin-dashboard/.env.example`](../apps/admin-dashboard/.env.example) | Template `.env` Nuxt. |

> Catatan: `apps/backend/docker-compose.yml` dan `apps/admin-dashboard/docker-compose*.yml`
> yang sudah ada sebelumnya tetap dipakai untuk **development lokal per-app**
> (bind mount source, hot reload). File-file di atas untuk **production**.

## 1) Setup awal di server (one-time)

```bash
# clone/copy source ke server, mis. /opt/perawatku
git clone <repo-url> /opt/perawatku   # atau rsync kalau tidak pakai git remote
cd /opt/perawatku

cp deploy/.env.example deploy/.env
cp apps/backend/.env.docker.prod.example apps/backend/.env
cp apps/admin-dashboard/.env.example apps/admin-dashboard/.env
```

Isi tiga file `.env` tadi:

- **`deploy/.env`** — port host (`BACKEND_HTTP_PORT`, `ADMIN_HTTP_PORT`), kredensial
  bootstrap PostgreSQL (`POSTGRES_DB`/`POSTGRES_USER`/`POSTGRES_PASSWORD`),
  dan `REDIS_PASSWORD`. **Nilai PostgreSQL/Redis di sini harus sama persis** dengan
  yang di `apps/backend/.env` (`DB_DATABASE`/`DB_USERNAME`/`DB_PASSWORD`/`REDIS_PASSWORD`) —
  compose pakai file ini untuk bootstrap container `db`/`redis`, sedangkan Laravel
  pakai `apps/backend/.env` untuk connect ke keduanya.
- **`apps/backend/.env`** — konfigurasi Laravel lengkap: `APP_KEY` (generate baru,
  jangan pakai contoh), `APP_URL`, kredensial Midtrans, SMTP, dsb. `DB_HOST=db`,
  `REDIS_HOST=redis`, `REVERB_HOST=reverb` sudah benar untuk jalan di Compose —
  jangan diganti ke `127.0.0.1`.
- **`apps/admin-dashboard/.env`** — `NUXT_PUBLIC_API_BASE` diarahkan ke URL publik
  backend (mis. `https://backend.perawatku.tech/api`), `NUXT_PUBLIC_AUTH_BASE_URL`,
  dst.

Generate `APP_KEY` baru (jangan pakai nilai contoh di file `.env.docker.prod.example`):

```bash
docker run --rm -v "$PWD/apps/backend":/app -w /app php:8.4-cli php -r \
  "echo 'base64:'.base64_encode(random_bytes(32)).PHP_EOL;"
```

Salin hasilnya ke `APP_KEY=` di `apps/backend/.env`.

## 2) Deploy pertama kali

```bash
cd /opt/perawatku
chmod +x deploy/deploy.sh
./deploy/deploy.sh
```

Script ini akan build image backend (`Dockerfile.prod`) dan admin (`Dockerfile`
target `runner`), lalu `docker compose up -d`. Saat container `app` pertama kali
start, [`entrypoint.prod.sh`](../apps/backend/docker/entrypoint.prod.sh) otomatis:

- generate `APP_KEY` **hanya kalau kosong** (sebaiknya sudah kamu isi manual, lihat di atas),
- `php artisan migrate --force` (aman, tidak drop data — beda dengan entrypoint dev
  yang pakai `migrate:fresh --seed`),
- `storage:link`, `config:cache`, `route:cache`, `view:cache`.

Cek statusnya:

```bash
docker compose -f deploy/docker-compose.prod.yml --env-file deploy/.env ps
docker compose -f deploy/docker-compose.prod.yml --env-file deploy/.env logs -f app nginx reverb admin
```

Backend bisa diakses di `http://<server-ip>:8081`, admin dashboard di
`http://<server-ip>:3000`. Arahkan reverse proxy (Nginx Proxy Manager, dst) di
domain publik ke dua port ini untuk HTTPS.

## 3) Update / redeploy

```bash
cd /opt/perawatku
git pull            # atau rsync source terbaru ke server
./deploy/deploy.sh
```

`deploy.sh` rebuild image (composer install + npm build sudah "dibekukan" di
image, jadi startup container jadi cepat karena tidak install ulang tiap
boot), lalu `up -d` — Docker Compose otomatis recreate container yang image-nya
berubah dan biarkan yang tidak berubah (mis. `db`) tetap jalan tanpa downtime
data.

## 4) WebSocket (Reverb)

Reverb (`reverb` service, port `8080`) **tidak** dipublish ke host. Nginx
backend (`nginx` service, port `8081`) sudah proxy `/app` dan `/apps/` ke
`reverb:8080` secara internal (lihat
[`docker/nginx/default.conf`](../apps/backend/docker/nginx/default.conf)).

Di reverse proxy host (Nginx Proxy Manager dkk.), aktifkan **Websockets
Support** untuk domain backend, lalu forward tetap ke port `8081` yang sama
(bukan ke `8080`). Contoh konfigurasi tambahan ada di
[`reverb-production-proxy.conf.example`](../apps/backend/docker/nginx/reverb-production-proxy.conf.example).

Alur lengkap:

```
Browser wss://backend.perawatku.tech/app/{REVERB_APP_KEY}
  -> reverse proxy host (TLS)
  -> nginx container :8081
  -> reverb container :8080
```

## 5) Database: migrasi, backup, restore

Migrasi jalan otomatis tiap deploy (`migrate --force`, bukan `migrate:fresh`,
jadi aman dipakai berulang). Untuk jalankan artisan command manual:

```bash
docker compose -f deploy/docker-compose.prod.yml --env-file deploy/.env exec app php artisan tinker
docker compose -f deploy/docker-compose.prod.yml --env-file deploy/.env exec app php artisan migrate:status
```

Backup database (dump ke file di host):

```bash
docker compose -f deploy/docker-compose.prod.yml --env-file deploy/.env exec db \
  sh -c 'exec pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB"' > backup-$(date +%F).sql
```

Restore:

```bash
docker compose -f deploy/docker-compose.prod.yml --env-file deploy/.env exec -T db \
  sh -c 'exec psql -U "$POSTGRES_USER" -d "$POSTGRES_DB"' < backup-2026-08-15.sql
```

Data PostgreSQL & Redis persisten lewat named volume Docker (`perawatku_db_data`,
`perawatku_redis_data`) — tidak hilang saat container di-recreate lewat
`deploy.sh`. Volume baru hilang kalau eksplisit `docker compose down -v` atau
`docker volume rm`, jadi hindari dua perintah itu di production kecuali
memang mau reset total.

> Migrasi dari MySQL lama ke PostgreSQL (kalau server ini sebelumnya sudah
> punya data production di MySQL) **tidak otomatis** — dump MySQL tidak bisa
> di-restore langsung ke PostgreSQL. Pakai tool seperti [`pgloader`](https://pgloader.io/)
> untuk transfer data + konversi tipe kolom, lalu verifikasi manual (terutama
> kolom `enum` yang di PostgreSQL jadi `CHECK` constraint, dan urutan
> auto-increment/`serial`) sebelum cutover.

## 6) Akses Adminer (opsional, manual)

Adminer (DB inspector, mendukung PostgreSQL) **tidak** ikut start otomatis di
production (risiko keamanan kalau kebuka publik). Nyalakan sementara kalau
perlu, lalu matikan lagi:

```bash
docker compose -f deploy/docker-compose.prod.yml --env-file deploy/.env --profile tools up -d adminer
# akses via SSH tunnel: ssh -L 8082:127.0.0.1:8082 user@server, lalu buka http://localhost:8082
# System: PostgreSQL, Server: db
docker compose -f deploy/docker-compose.prod.yml --env-file deploy/.env --profile tools down adminer
```

Port-nya sengaja di-bind ke `127.0.0.1` saja (lihat compose file), jadi hanya
bisa diakses lewat SSH tunnel dari server, tidak lewat internet.

## 7) Rollback

Karena image di-build dari source (bukan tag registry), rollback = checkout
commit sebelumnya lalu redeploy:

```bash
git checkout <commit-atau-tag-sebelumnya>
./deploy/deploy.sh
```

Migrasi database **tidak otomatis di-rollback** — kalau deploy yang bermasalah
menambah migration baru, jalankan `php artisan migrate:rollback --force` di
container `app` secara manual sebelum/dari commit lama, sesuaikan case per
case.

## 8) Troubleshooting

| Gejala | Cek |
| --- | --- |
| `502 Bad Gateway` dari nginx | `docker compose logs app` — biasanya php-fpm belum ready atau `migrate` gagal (cek kredensial DB). |
| WebSocket gagal connect | Pastikan reverse proxy host meneruskan header `Upgrade`/`Connection` dan Websockets Support aktif; lihat §4. |
| Upload gambar/file 404 | Pastikan `storage:link` sukses (`docker compose exec app php artisan storage:link`) — symlink ini hidup di volume `backend_public`/`backend_storage` yang dishare `app` dan `nginx`. |
| Env berubah tapi app tidak baca | Container perlu di-restart supaya `env_file` ke-load ulang: `docker compose up -d app reverb admin`. Kalau ubah `APP_ENV`/config lain, cache lama masih kepakai sampai container restart (`entrypoint.prod.sh` re-run `config:cache` tiap boot). |
| Container `db`/`redis` unhealthy terus | `docker compose logs db` / `logs redis`; cek `POSTGRES_PASSWORD`/`REDIS_PASSWORD` di `deploy/.env` tidak kosong. |
| Migration gagal dengan syntax error saat `migrate --force` | Kemungkinan ada migration baru yang pakai raw SQL MySQL-only (`MODIFY`, `INNER JOIN` di `UPDATE`, dsb) tanpa guard PostgreSQL — lihat [README_TESTING_FEATURE.md](../apps/backend/readMe/README_TESTING_FEATURE.md#catatan-migration-sqlite--postgresql) di backend. |

## Keamanan

- Port DB (`5432`) dan Redis (`6379`) **tidak** dipublish ke host — hanya
  bisa diakses dari dalam Docker network. Jangan tambahkan `ports:` untuk
  `db`/`redis` di production.
- Redis diwajibkan pakai password (`--requirepass`), beda dari compose dev
  yang tanpa auth.
- Adminer off secara default, dan kalau dinyalakan cuma bind ke `127.0.0.1`.
- Jangan commit file `.env` / `deploy/.env` berisi secret asli — hanya
  `*.env.example` yang masuk repo.
- `APP_DEBUG` harus `false` di production (`apps/backend/.env`) supaya stack
  trace tidak bocor ke publik.
