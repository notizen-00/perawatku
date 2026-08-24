# Backend Contract - Module Laporan Admin

Dokumen ini adalah kontrak backend untuk fitur **Laporan** pada admin Nuxt.
Tujuannya agar endpoint laporan tidak error saat dipanggil frontend di `/reports`.

Semua endpoint berada di bawah:

```http
/api/admin
```

Semua request wajib memakai middleware admin yang sama dengan endpoint admin lain:

```http
Authorization: Bearer <TOKEN_ADMIN>
Accept: application/json
```

## Response Umum

Semua endpoint harus mengembalikan HTTP 200 saat tidak ada data. Jangan return 500 hanya karena data kosong.

Format sukses yang diterima frontend:

```json
{
  "message": "OK",
  "data": {}
}
```

Atau:

```json
{
  "success": true,
  "data": {}
}
```

Untuk list/table, gunakan Laravel paginator atau array biasa.

Paginator Laravel:

```json
{
  "message": "OK",
  "data": {
    "data": [],
    "current_page": 1,
    "last_page": 1,
    "per_page": 100,
    "total": 0
  }
}
```

Array biasa:

```json
{
  "message": "OK",
  "data": []
}
```

Nilai angka sebaiknya dikembalikan sebagai number, bukan string. Jika belum ada nilai, gunakan `0` atau `null`, bukan menghilangkan object `data`.

## 1. Laporan Orders

```http
GET /api/admin/reports/orders
```

Query:

| Field | Type | Keterangan |
| --- | --- | --- |
| from | date `YYYY-MM-DD` | Opsional, tanggal awal |
| to | date `YYYY-MM-DD` | Opsional, tanggal akhir |
| status | string | Opsional |
| patient_user_id | int | Opsional |
| pharmacy_id | int | Opsional |

Minimal response:

```json
{
  "message": "OK",
  "data": {
    "total_orders": 0,
    "orders_count": 0,
    "total_amount": 0,
    "paid_amount": 0,
    "pending_amount": 0,
    "cancelled_orders": 0,
    "completed_orders": 0
  }
}
```

Field yang akan dibaca frontend untuk kartu ringkasan:

- `total_orders`
- `orders_count`
- `total_count`
- `count`

Backend boleh menambahkan field lain. Frontend akan menampilkannya sebagai kartu tambahan jika nilainya primitive (`string`, `number`, `boolean`, atau `null`).

## 2. Laporan Customers

```http
GET /api/admin/reports/customers
```

Query:

| Field | Type | Keterangan |
| --- | --- | --- |
| from | date `YYYY-MM-DD` | Opsional |
| to | date `YYYY-MM-DD` | Opsional |

Minimal response:

```json
{
  "message": "OK",
  "data": {
    "total_customers": 0,
    "new_customers": 0,
    "active_customers": 0,
    "inactive_customers": 0
  }
}
```

Field yang akan dibaca frontend untuk kartu ringkasan:

- `new_customers`
- `customers_count`
- `total_customers`
- `count`

## 3. Laporan Profit & Loss / Laba Rugi

```http
GET /api/admin/reports/profit-loss
```

Query:

| Field | Type | Keterangan |
| --- | --- | --- |
| from | date `YYYY-MM-DD` | Opsional |
| to | date `YYYY-MM-DD` | Opsional |

Minimal response yang direkomendasikan:

```json
{
  "message": "OK",
  "data": {
    "revenue": 0,
    "total_revenue": 0,
    "cogs": 0,
    "gross_profit": 0,
    "operational_cost": 0,
    "app_profit": 0,
    "platform_profit": 0,
    "net_profit": 0
  }
}
```

Field pendapatan yang dibaca frontend:

- `revenue`
- `total_revenue`
- `income`
- `gross_revenue`
- `total_income`

Field beban pokok / HPP yang dibaca frontend:

- `cogs`
- `cost_of_goods_sold`
- `cost`
- `total_cost`

Field biaya operasional yang dibaca frontend:

- `operational_cost`
- `operating_expense`
- `expense`
- `total_expense`

Field laba aplikator yang dibaca frontend:

- `app_profit`
- `applicator_profit`
- `platform_profit`
- `laba_aplikator`

Field laba bersih yang dibaca frontend:

- `net_profit`
- `profit`

Catatan perhitungan disarankan:

```text
gross_profit = revenue - cogs
net_profit = gross_profit - operational_cost
app_profit/platform_profit = pendapatan aplikasi setelah hak partner/vendor/biaya langsung
```

Jika backend belum bisa menghitung salah satu field, return `0`, bukan error.

## 4. Neraca / Saldo User

Frontend menggunakan endpoint saldo existing untuk tab Neraca:

```http
GET /api/admin/balance
```

Query:

| Field | Type | Keterangan |
| --- | --- | --- |
| status | string | Opsional |
| search | string | Opsional |
| per_page | int | Default frontend: 100 |
| page | int | Opsional |

Response list minimal:

```json
{
  "message": "OK",
  "data": {
    "data": [
      {
        "id": 1,
        "user_id": 10,
        "balance": 150000,
        "status": "active",
        "updated_at": "2026-07-13T10:00:00Z",
        "user": {
          "id": 10,
          "name": "Patient Name",
          "email": "patient@example.com"
        }
      }
    ],
    "current_page": 1,
    "last_page": 1,
    "per_page": 100,
    "total": 1
  }
}
```

Field saldo yang dibaca frontend:

- `balance`
- `amount`
- `saldo`

Field user yang dibaca frontend:

- `user.name`
- `name`
- `user.email`
- `email`

Status aktif yang dianggap aktif oleh frontend:

- `active`
- `aktif`
- `true`
- `null`

## 5. Transaksi Umum

```http
GET /api/admin/transactions
```

Query:

| Field | Type | Keterangan |
| --- | --- | --- |
| search | string | Opsional |
| per_page | int | Default frontend: 100 |
| page | int | Opsional |

Response list minimal:

```json
{
  "message": "OK",
  "data": {
    "data": [
      {
        "id": 1,
        "transaction_code": "TRX-0001",
        "reference": "ORDER-0001",
        "reference_type": "order",
        "type": "credit",
        "amount": 100000,
        "status": "success",
        "description": "Pembayaran order",
        "created_at": "2026-07-13T10:00:00Z",
        "user": {
          "id": 10,
          "name": "Patient Name"
        }
      }
    ],
    "current_page": 1,
    "last_page": 1,
    "per_page": 100,
    "total": 1
  }
}
```

Field yang dibaca frontend:

- Kode/reference: `transaction_code`, `reference`, `reference_type`, `id`
- User: `user.name`, `patient.name`, `partner.name`
- Type: `type`, `transaction_type`
- Nominal: `amount`, `total_amount`, `value`
- Status: `status`
- Tanggal: `created_at`, `transaction_date`
- Deskripsi: `description`, `notes`

## 6. Transaksi Saldo

```http
GET /api/admin/balance/transactions
```

Query:

| Field | Type | Keterangan |
| --- | --- | --- |
| type | string | Opsional |
| status | string | Opsional |
| user_id | int | Opsional |
| from_date | date `YYYY-MM-DD` | Opsional |
| to_date | date `YYYY-MM-DD` | Opsional |
| per_page | int | Default frontend: 100 |
| page | int | Opsional |

Gunakan shape response yang sama dengan transaksi umum. Pastikan `amount`, `type`, `status`, dan `created_at` tersedia.

## 7. Jurnal Keuangan

```http
GET /api/admin/journals
```

Query:

| Field | Type | Keterangan |
| --- | --- | --- |
| from | date `YYYY-MM-DD` | Opsional |
| to | date `YYYY-MM-DD` | Opsional |
| status | `draft`, `posted`, `void` | Opsional |
| per_page | int | Default frontend: 100 |
| page | int | Opsional |

Response list minimal:

```json
{
  "message": "OK",
  "data": {
    "data": [
      {
        "id": 1,
        "entry_date": "2026-07-13",
        "description": "Pendapatan order",
        "reference_type": "order",
        "reference_id": 100,
        "status": "posted",
        "is_balanced": true,
        "totals": {
          "debit": 100000,
          "credit": 100000
        },
        "created_at": "2026-07-13T10:00:00Z"
      }
    ],
    "current_page": 1,
    "last_page": 1,
    "per_page": 100,
    "total": 1
  }
}
```

Field yang dibaca frontend:

- `description`
- `reference_type`
- `reference_id`
- `entry_date`
- `created_at`
- `totals.debit`
- `totals.credit`
- `total_debit`
- `total_credit`
- `status`
- `is_balanced`

Untuk neraca ringkas, frontend menjumlahkan `totals.debit` dan `totals.credit`.

## 8. Status Warna

Frontend mengenali status berikut:

Status sukses:

- `success`
- `completed`
- `paid`
- `posted`

Status error:

- `failed`
- `cancelled`
- `void`

Status warning:

- `pending`
- `draft`

Status lain tetap ditampilkan dengan warna netral.

## 9. Checklist Backend Agar Tidak Error

- Semua endpoint di atas harus return JSON valid.
- Jangan return HTML error page.
- Jika tidak ada data, return object/array kosong dengan HTTP 200.
- Pastikan `data` selalu ada.
- Pastikan angka nominal bisa di-cast ke number.
- Date gunakan ISO string atau `YYYY-MM-DD`.
- Paginator gunakan key Laravel standar: `data`, `current_page`, `last_page`, `per_page`, `total`.
- Filter date harus menerima `from`/`to` untuk reports dan journals.
- Filter date transaksi saldo harus menerima `from_date`/`to_date`.
- Jangan wajibkan query yang frontend kirim sebagai opsional.
- Untuk laporan laba rugi, minimal return `revenue`, `app_profit` atau `platform_profit`, dan `net_profit`.

## 10. Contoh Laravel Route

```php
Route::middleware(['auth:sanctum', 'admin'])
    ->prefix('admin')
    ->group(function () {
        Route::get('/reports/orders', [ReportController::class, 'orders']);
        Route::get('/reports/customers', [ReportController::class, 'customers']);
        Route::get('/reports/profit-loss', [ReportController::class, 'profitLoss']);

        Route::get('/transactions', [TransactionController::class, 'index']);
        Route::get('/balance', [BalanceController::class, 'index']);
        Route::get('/balance/transactions', [BalanceController::class, 'transactions']);
        Route::get('/journals', [JournalController::class, 'index']);
    });
```

