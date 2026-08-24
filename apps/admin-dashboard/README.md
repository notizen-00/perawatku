# Medic Admin

Dashboard admin untuk platform **Perawatku.app / Medic App** berbasis **Nuxt.js**.

Aplikasi ini digunakan oleh admin untuk mengelola operasional platform layanan kesehatan, seperti data mitra tenaga kesehatan, konsultasi pasien, order obat, kode promo, dan pengajuan layanan mitra.

## Repository

```bash
https://github.com/notizen-00/medic-admin
```

## Tech Stack

* Nuxt 4
* Vue 3
* TypeScript
* Pinia
* Nuxt UI
* Tailwind CSS
* sidebase/nuxt-auth
* Nuxt Image
* VueUse
* TanStack Table Core
* Zod
* Docker
* GitHub Actions

## Fitur Utama

### 1. Authentication Admin

Sistem autentikasi admin menggunakan local auth dari `@sidebase/nuxt-auth`.

Fitur:

* Login admin
* Logout admin
* Session check
* Bearer token authentication
* Protected route menggunakan global auth middleware
* Redirect ke halaman login jika belum login

Endpoint auth:

```bash
POST /api/auth/login
POST /api/auth/logout
GET  /api/auth/session
```

## 2. Dashboard

Halaman utama admin untuk mengakses seluruh menu manajemen.

Fitur:

* Dashboard admin
* Sidebar navigation
* Responsive layout
* Dark mode dan light mode
* Command palette / dashboard template behavior
* Navigasi ke menu utama aplikasi

## 3. Partners / Mitra

Menu untuk mengelola data mitra tenaga kesehatan.

Jenis mitra:

* Dokter
* Perawat
* Bidan

Fitur:

* List data mitra
* Search mitra
* Filter berdasarkan profesi
* Filter berdasarkan status available
* Filter berdasarkan status verifikasi
* Menampilkan profil mitra
* Menampilkan jumlah konsultasi mitra
* Menampilkan jumlah layanan mitra
* Menampilkan jumlah booking layanan mitra

Data profil mitra:

* Profession
* Specialization
* Work location
* License number
* Availability status
* Verification status
* STR photo path
* KTP photo path

Status verifikasi:

```bash
pending
verified
rejected
```

Endpoint:

```bash
GET /api/admin/partners
```

## 4. Service Applications / Partner Services

Menu untuk mengelola pengajuan layanan dari mitra.

Fitur:

* List pengajuan layanan mitra
* Search pengajuan layanan
* Filter berdasarkan partner
* Filter berdasarkan service
* Filter status aktif
* Filter status verifikasi
* Verifikasi layanan mitra
* Aktivasi / nonaktif layanan mitra
* Menambahkan catatan verifikasi

Data yang ditampilkan:

* Partner
* Email partner
* Profesi partner
* Service
* Service type
* Status active
* Status verified
* Notes
* Created at

Endpoint:

```bash
GET   /api/admin/partner-services
PATCH /api/admin/service-applications/{id}/verify
```

Payload verifikasi:

```json
{
  "is_verified": true,
  "is_active": true,
  "notes": "Layanan disetujui"
}
```

## 5. Consultations

Menu untuk mengelola konsultasi antara pasien dan mitra.

Fitur:

* List konsultasi
* Detail konsultasi
* Search konsultasi
* Filter berdasarkan status
* Filter berdasarkan partner
* Filter berdasarkan pasien
* Filter berdasarkan service type
* Pagination

Status konsultasi:

```bash
pending
confirmed
ongoing
completed
cancelled
```

Data konsultasi:

* Consultation code
* Status
* Service type
* Patient
* Partner
* Partner profession
* Created at

Endpoint:

```bash
GET /api/admin/consultations
GET /api/admin/consultations/{id}
```

## 6. Orders

Menu untuk mengelola order obat atau resep.

Fitur:

* List order
* Detail order
* Search order
* Filter berdasarkan status order
* Filter berdasarkan tipe order
* Filter berdasarkan pasien
* Filter berdasarkan apotek
* Pagination

Status order:

```bash
pending
confirmed
processed
shipped
delivered
cancelled
```

Tipe order:

```bash
resep
non_resep
```

Data order:

* Order code
* Status
* Order type
* Total amount
* Patient
* Pharmacy
* Created at

Endpoint:

```bash
GET /api/admin/orders
GET /api/admin/orders/{id}
```

## 7. Promo Codes

Menu untuk mengelola kode promo aplikasi.

Fitur:

* List promo code
* Detail promo code
* Tambah promo code
* Edit promo code
* Hapus promo code
* Toggle active / inactive
* Search promo code
* Filter berdasarkan status aktif
* Pagination

Data promo code:

* Name
* Code
* Description
* Discount type
* Discount value
* Minimum transaction
* Maximum discount
* Valid from
* Valid until
* Usage limit
* Usage count
* Active status
* Created at
* Updated at

Tipe diskon:

```bash
percentage
fixed
```

Endpoint:

```bash
GET    /api/admin/promo-codes
GET    /api/admin/promo-codes/{id}
POST   /api/admin/promo-codes
PATCH  /api/admin/promo-codes/{id}
DELETE /api/admin/promo-codes/{id}
PATCH  /api/admin/promo-codes/{id}/toggle-status
```

## 8. Patients

Menu untuk data pasien.

Fitur:

* Halaman manajemen pasien
* Dapat digunakan untuk melihat data user pasien
* Dapat dikembangkan untuk detail riwayat konsultasi dan order pasien

## 9. Inbox

Menu inbox admin.

Fitur:

* Halaman inbox
* Dapat digunakan untuk notifikasi admin
* Dapat dikembangkan untuk notifikasi konsultasi, order, verifikasi mitra, dan pengajuan layanan

## 10. Settings

Menu pengaturan aplikasi admin.

Fitur:

* Halaman settings
* Dapat dikembangkan untuk konfigurasi admin, profil, role, permission, dan konfigurasi sistem

## Struktur Folder

```bash
medic-admin
├── .github
│   └── workflows
├── app
│   ├── assets
│   │   └── css
│   ├── components
│   ├── composables
│   ├── layouts
│   ├── pages
│   │   ├── consultations
│   │   ├── orders
│   │   ├── partners
│   │   ├── patients
│   │   ├── promo-codes
│   │   ├── service-applications
│   │   ├── settings
│   │   ├── inbox.vue
│   │   ├── index.vue
│   │   ├── login.vue
│   │   └── settings.vue
│   ├── services
│   │   ├── admin
│   │   │   ├── consultations.ts
│   │   │   ├── orders.ts
│   │   │   ├── partner-services.ts
│   │   │   ├── partners.ts
│   │   │   └── promo-codes.ts
│   │   └── shared
│   ├── stores
│   │   ├── auth.ts
│   │   ├── consultations.ts
│   │   ├── orders.ts
│   │   ├── partnerServiceApplications.ts
│   │   ├── partners.ts
│   │   └── promo-codes.ts
│   ├── types
│   ├── utils
│   ├── app.config.ts
│   ├── app.vue
│   └── error.vue
├── docker
├── public
├── server
├── Dockerfile
├── docker-compose.yml
├── docker-compose.prod.yml
├── nuxt.config.ts
├── package.json
└── README.md
```

## Environment Variables

Buat file `.env` dari `.env.example`.

```bash
cp .env.example .env
```

Isi konfigurasi:

```env
NUXT_PUBLIC_SITE_URL=http://localhost:3000
NUXT_PUBLIC_API_BASE=https://backend.perawatku.tech
NUXT_PUBLIC_STORAGE_BASE=https://backend.perawatku.tech/storage
NUXT_PUBLIC_AUTH_BASE_URL=http://localhost:3000/api/auth
```

Keterangan:

| Variable                    | Fungsi                        |
| --------------------------- | ----------------------------- |
| `NUXT_PUBLIC_SITE_URL`      | URL frontend admin            |
| `NUXT_PUBLIC_API_BASE`      | Base URL backend API          |
| `NUXT_PUBLIC_STORAGE_BASE`  | Base URL file storage backend |
| `NUXT_PUBLIC_AUTH_BASE_URL` | Base URL auth untuk Nuxt auth |

## Instalasi Lokal

Clone repository:

```bash
git clone https://github.com/notizen-00/medic-admin.git
cd medic-admin
```

Install dependency:

```bash
pnpm install
```

Jalankan development server:

```bash
pnpm dev
```

Akses aplikasi:

```bash
http://localhost:3000
```

## Script

```bash
pnpm dev
```

Menjalankan development server.

```bash
pnpm build
```

Build aplikasi untuk production.

```bash
pnpm preview
```

Preview hasil build production.

```bash
pnpm lint
```

Menjalankan ESLint.

```bash
pnpm typecheck
```

Menjalankan TypeScript type check.

## Docker Development

Jalankan aplikasi dengan Docker Compose:

```bash
docker compose up --build
```

Aplikasi berjalan di:

```bash
http://localhost:3000
```

## Docker Production-like

Jalankan profile production dari compose development:

```bash
docker compose --profile prod up --build
```

## Docker Production

Gunakan file `docker-compose.prod.yml`.

```bash
docker compose -f docker-compose.prod.yml up -d
```

Pastikan environment variable `IMAGE` sudah diisi.

Contoh:

```bash
IMAGE=ghcr.io/notizen-00/medic-admin:latest docker compose -f docker-compose.prod.yml up -d
```

## Deployment

Repository ini sudah disiapkan untuk deployment menggunakan GitHub Actions dan Docker Compose.

File deployment:

```bash
DEPLOYMENT.md
docker-compose.prod.yml
.github/workflows/ci.yml
.github/workflows/cd.yml
```

Secret yang dibutuhkan:

```bash
SSH_HOST
SSH_USER
SSH_PORT
SSH_PASSWORD
DEPLOY_PATH
GHCR_USER
GHCR_TOKEN
```

Alur CD:

1. Push ke branch deployment.
2. GitHub Actions build Docker image.
3. Image dipush ke GHCR.
4. Server login ke GHCR jika diperlukan.
5. Server menjalankan Docker Compose production.
6. Aplikasi berjalan di port `3000`.

## Integrasi Backend

Frontend admin menggunakan backend API Perawatku.

Contoh live backend:

```bash
https://backend.perawatku.tech
```

Runtime config Nuxt:

```ts
runtimeConfig: {
  public: {
    siteUrl: process.env.NUXT_PUBLIC_SITE_URL,
    apiBase: process.env.NUXT_PUBLIC_API_BASE,
    storageBase: process.env.NUXT_PUBLIC_STORAGE_BASE
  }
}
```

## State Management

Project menggunakan Pinia.

Store utama:

| Store                           | Fungsi                        |
| ------------------------------- | ----------------------------- |
| `auth.ts`                       | State autentikasi admin       |
| `partners.ts`                   | State data mitra              |
| `consultations.ts`              | State konsultasi              |
| `orders.ts`                     | State order                   |
| `partnerServiceApplications.ts` | State pengajuan layanan mitra |
| `promo-codes.ts`                | State promo code              |

## API Services

Service API berada di:

```bash
app/services/admin
```

Service yang tersedia:

| File                  | Modul                             |
| --------------------- | --------------------------------- |
| `partners.ts`         | Data mitra                        |
| `partner-services.ts` | Layanan / pengajuan layanan mitra |
| `consultations.ts`    | Konsultasi                        |
| `orders.ts`           | Order                             |
| `promo-codes.ts`      | Promo code                        |

## Authentication Flow

1. Admin membuka halaman login.
2. Admin mengisi credential.
3. Frontend mengirim request ke `/api/auth/login`.
4. Backend mengembalikan token.
5. Token digunakan sebagai Bearer token.
6. Session admin dicek melalui `/api/auth/session`.
7. Jika session valid, admin bisa mengakses dashboard.
8. Jika belum login, admin diarahkan ke `/login`.

## Pagination

Beberapa modul menggunakan query pagination:

```ts
{
  page?: number
  per_page?: number
}
```

Modul yang mendukung pagination:

* Partners
* Consultations
* Orders
* Partner services
* Promo codes

## Filter Data

Filter yang tersedia pada modul admin:

### Partners

```ts
{
  profession?: 'dokter' | 'perawat' | 'bidan'
  search?: string
  is_available?: boolean
  verification_status?: 'pending' | 'verified' | 'rejected'
  page?: number
  per_page?: number
}
```

### Consultations

```ts
{
  status?: 'pending' | 'confirmed' | 'ongoing' | 'completed' | 'cancelled'
  partner_user_id?: number
  patient_user_id?: number
  service_type?: string
  search?: string
  page?: number
  per_page?: number
}
```

### Orders

```ts
{
  status?: 'pending' | 'confirmed' | 'processed' | 'shipped' | 'delivered' | 'cancelled'
  order_type?: 'resep' | 'non_resep'
  patient_user_id?: number
  pharmacy_id?: number
  search?: string
  page?: number
  per_page?: number
}
```

### Partner Services

```ts
{
  partner_user_id?: number
  service_id?: number
  is_active?: boolean
  is_verified?: boolean
  search?: string
  page?: number
  per_page?: number
}
```

### Promo Codes

```ts
{
  search?: string
  is_active?: boolean
  page?: number
  per_page?: number
}
```

## Rekomendasi Pengembangan Berikutnya

Beberapa fitur yang cocok ditambahkan:

* Dashboard analytics real-time
* Statistik total pasien, mitra, konsultasi, order, dan revenue
* Detail partner lengkap dengan preview STR dan KTP
* Approve / reject partner profile
* Edit profil mitra dari admin
* Update status available mitra dari admin
* Detail patient lengkap
* Riwayat konsultasi per pasien
* Riwayat order per pasien
* Manajemen kategori layanan
* Manajemen layanan kesehatan
* Manajemen apotek
* Manajemen withdraw mitra
* Manajemen saldo / wallet
* Notification center
* Audit log aktivitas admin
* Role dan permission admin
* Export Excel / CSV
* Realtime notification dengan WebSocket
* Integrasi map untuk tracking layanan home care

## License

MIT
