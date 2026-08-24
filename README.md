# Perawatku (Medic App)

Monorepo platform layanan kesehatan **Perawatku.app**: konsultasi pasien dengan
dokter/perawat, homecare, apotek/order obat, pembayaran (Midtrans), hingga
manajemen mitra tenaga kesehatan.

## Struktur project

```
apps/
├── backend/           Laravel API + WebSocket (Reverb) — inti sistem
├── admin-dashboard/    Nuxt 4 — dashboard operasional admin
├── mobile-pasien/      Flutter — aplikasi pasien
└── mobile-mitra/       Flutter — aplikasi mitra tenaga kesehatan

deploy/                 Docker Compose production + script deploy
docs/                   Dokumentasi lintas-app (deployment, dst.)
```

| App | Stack | Peran |
| --- | --- | --- |
| [`apps/backend`](apps/backend) | Laravel 13, PostgreSQL, Redis, Reverb (WebSocket) | REST API, auth, matchmaking mitra, pembayaran, broadcasting |
| [`apps/admin-dashboard`](apps/admin-dashboard) | Nuxt 4, Vue 3, TypeScript, Nuxt UI | Panel admin: kelola mitra, konsultasi, order, promo |
| [`apps/mobile-pasien`](apps/mobile-pasien) | Flutter (GetX) | Aplikasi pasien: konsultasi, chat, pembayaran |
| [`apps/mobile-mitra`](apps/mobile-mitra) | Flutter (Bloc) | Aplikasi mitra: terima order, navigasi, pelayanan |

Dokumentasi lebih detail ada di README masing-masing folder app, termasuk
kumpulan dokumen tambahan di [`apps/backend/readMe/`](apps/backend/readMe).

## Menjalankan secara lokal

Tiap app dijalankan terpisah (bukan lewat satu perintah monorepo). Backend
harus jalan lebih dulu karena tiga app lain memanggil API-nya.

### 1. Backend (Laravel)

```bash
cd apps/backend
cp .env.example .env       # atau .env.development, sesuaikan DB_* & REDIS_*
composer install
php artisan key:generate
php artisan migrate --seed
composer run dev           # jalankan server + queue listener + vite bareng
```

Backend default di `http://127.0.0.1:8000`. Lihat
[`apps/backend/readMe/README_ENV.md`](apps/backend/readMe/README_ENV.md) untuk
detail environment, dan
[`apps/backend/readMe/README_DOCKER.md`](apps/backend/readMe/README_DOCKER.md)
untuk alternatif jalan lewat `docker-compose.yml` (dev, bukan production).

### 2. Admin dashboard (Nuxt)

```bash
cd apps/admin-dashboard
cp .env.example .env       # isi NUXT_PUBLIC_API_BASE ke URL backend lokal
pnpm install
pnpm dev
```

### 3. Mobile (Flutter — pasien / mitra)

```bash
cd apps/mobile-pasien   # atau apps/mobile-mitra
flutter pub get
flutter run
```

Arahkan base URL API di `lib/core/config/app_config.dart` (pasien) atau
konfigurasi setara di mobile-mitra ke alamat backend lokal/staging.

## Deploy ke production

Panduan deploy lengkap (Docker Compose di VPS, arsitektur, backup/restore
database, WebSocket di balik reverse proxy, rollback, troubleshooting) ada di
**[docs/deployment.md](docs/deployment.md)**.

Ringkas:

```bash
# di server
git clone <repo-url> /opt/perawatku && cd /opt/perawatku

cp deploy/.env.example deploy/.env
cp apps/backend/.env.docker.prod.example apps/backend/.env
cp apps/admin-dashboard/.env.example apps/admin-dashboard/.env
# isi ketiga .env di atas (lihat docs/deployment.md §1)

chmod +x deploy/deploy.sh
./deploy/deploy.sh
```

Yang di-cover stack Docker ini: backend Laravel (API + Reverb), admin
dashboard (Nuxt), PostgreSQL, dan Redis — semuanya lewat
[`deploy/docker-compose.prod.yml`](deploy/docker-compose.prod.yml). Aplikasi
mobile **tidak** termasuk; itu di-build sebagai APK/IPA lewat Flutter dan
didistribusikan lewat Play Store/App Store/internal distribution.

Update/redeploy setelah perubahan kode cukup jalankan ulang
`./deploy/deploy.sh` dari server setelah `git pull`.
