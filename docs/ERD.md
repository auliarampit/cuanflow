# Entity Relationship Diagram (ERD)
## Cuan Flow — Database Schema

---

## Diagram Relasi

```
┌─────────────┐        ┌──────────────────────┐        ┌─────────────────┐
│    users    │        │     transactions     │        │     wallets     │
│─────────────│        │──────────────────────│        │─────────────────│
│ id (PK/UUID)│──┐     │ id (UUID)            │        │ id (UUID)       │
│ email       │  │     │ user_id (FK → users) │        │ user_id (FK)    │
│ ...         │  ├────►│ type                 │        │ name            │
└─────────────┘  │     │ amount               │        │ type            │
                 │     │ category             │        │ initial_balance │
                 │     │ note                 │        │ is_default      │
                 │     │ outlet_id (FK opt.)  │        │ created_at      │
                 │     │ wallet_id (FK opt.)  │        └─────────────────┘
                 │     │ effective_date        │
                 │     │ created_at           │        ┌─────────────────┐
                 │     └──────────────────────┘        │     debts       │
                 │                                     │─────────────────│
                 │     ┌──────────────────────┐        │ id (UUID)       │
                 │     │       budgets        │        │ user_id (FK)    │
                 │     │──────────────────────│        │ person_name     │
                 ├────►│ id (UUID)            │        │ amount          │
                 │     │ user_id (FK)         │        │ type            │
                 │     │ type                 │        │ is_paid         │
                 │     │ category_id (FK opt.)│        │ notes           │
                 │     │ target_amount        │        │ due_date        │
                 │     │ month                │        │ created_at      │
                 │     │ created_at           │        └─────────────────┘
                 │     └──────────────────────┘
                 │                                     ┌──────────────────────────┐
                 │     ┌──────────────────────┐        │  recurring_transactions  │
                 │     │       outlets        │        │──────────────────────────│
                 ├────►│──────────────────────│        │ id (UUID)                │
                 │     │ id (UUID)            │        │ user_id (FK)             │
                 │     │ user_id (FK)         │        │ name                     │
                 │     │ name                 │        │ amount                   │
                 │     │ address              │        │ type                     │
                 │     │ is_default           │        │ category                 │
                 │     │ created_at           │        │ frequency                │
                 │     └──────────────────────┘        │ day_of_month             │
                 │                                     │ wallet_id (FK opt.)      │
                 │     ┌──────────────────────┐        │ is_active                │
                 │     │   user_categories    │        │ next_execute             │
                 ├────►│──────────────────────│        │ last_executed            │
                 │     │ id (TEXT)            │        │ created_at               │
                 │     │ user_id (FK)         │        └──────────────────────────┘
                 │     │ name                 │
                 │     │ type                 │        ┌─────────────────────┐
                 │     │ is_stock_purchase    │        │   inventory_items   │
                 │     └──────────────────────┘        │─────────────────────│
                 │                                     │ id (UUID)           │
                 │     ┌──────────────────────┐        │ user_id (FK)        │
                 │     │       profiles       │        │ name                │
                 ├────►│──────────────────────│        │ unit                │
                 │     │ id (FK → users)      │        │ current_stock       │
                 │     │ owner_name           │        │ min_stock           │
                 │     │ business_name        │        │ cost_price          │
                 │     │ feature_product      │        │ sell_price          │
                 │     │ feature_outlets      │        │ category            │
                 │     │ feature_budget       │        │ created_at          │
                 │     │ onboarding_complete  │        └─────────────────────┘
                 │     └──────────────────────┘
                 │                                     ┌─────────────────────┐
                 │     ┌──────────────────────┐        │  quick_sale_presets │
                 │     │       products       │        │─────────────────────│
                 └────►│──────────────────────│        │ id (UUID)           │
                       │ id (UUID)            │        │ user_id (FK)        │
                       │ user_id (FK)         │        │ name                │
                       │ name                 │        │ sell_price          │
                       │ yield_qty            │        │ category            │
                       │ yield_unit           │        │ note                │
                       │ selling_price        │        │ wallet_id (FK opt.) │
                       │ ingredients (JSON)   │        │ outlet_id (FK opt.) │
                       │ other_costs (JSON)   │        │ sort_order          │
                       │ created_at           │        └─────────────────────┘
                       └──────────────────────┘
```

---

## Penjelasan Tiap Tabel

### `users` (Supabase Auth)
Dikelola sepenuhnya oleh Supabase Auth. App hanya pakai `id` sebagai foreign key ke semua tabel lain.

---

### `profiles`
Ekstensi data user. Satu user = satu profil.

| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | UUID (FK) | Sama dengan `auth.users.id` |
| `owner_name` | TEXT | Nama pemilik |
| `business_name` | TEXT | Nama usaha (opsional) |
| `feature_product` | BOOL | Aktifkan HPP Calculator |
| `feature_outlets` | BOOL | Aktifkan multi-outlet |
| `feature_budget` | BOOL | Aktifkan budget |
| `onboarding_complete` | BOOL | Sudah lewat layar pilih mode? |

---

### `transactions`
Inti dari app — semua pemasukan & pengeluaran.

| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | UUID | Auto-generate oleh Supabase |
| `user_id` | UUID (FK) | |
| `type` | TEXT | `'income'` atau `'expense'` |
| `amount` | INTEGER | Dalam Rupiah (tanpa desimal) |
| `category` | TEXT | Nama kategori bebas |
| `note` | TEXT | Keterangan transaksi |
| `outlet_id` | UUID (FK, null) | Hanya diisi jika `featureOutlets` aktif |
| `wallet_id` | TEXT (null) | Referensi ke dompet |
| `effective_date` | TIMESTAMPTZ | Tanggal transaksi (bisa backdate) |
| `created_at` | TIMESTAMPTZ | Waktu input |

> **Catatan:** `wallet_id` saat ini tersimpan lokal tapi belum di-sync ke server (kolom sudah ada, payload sync belum include).

---

### `wallets`
Dompet/rekening user. Tersedia untuk semua user (personal & bisnis).

| Kolom | Tipe | Nilai |
|---|---|---|
| `type` | TEXT | `'cash'` / `'bank'` / `'ewallet'` |
| `initial_balance` | INTEGER | Saldo awal saat dompet dibuat |
| `is_default` | BOOL | Dompet yang otomatis dipilih |

**Saldo aktual** = `initial_balance + Σ income - Σ expense` untuk `wallet_id` tersebut.

---

### `debts`
Catatan utang & piutang.

| Kolom | Tipe | Nilai |
|---|---|---|
| `type` | TEXT | `'iOwe'` = saya berhutang / `'theyOwe'` = mereka berhutang |
| `is_paid` | BOOL | Lunas atau belum |
| `due_date` | TIMESTAMPTZ | Jatuh tempo (opsional) |

---

### `recurring_transactions`
Template transaksi yang berjalan otomatis.

| Kolom | Tipe | Nilai |
|---|---|---|
| `frequency` | TEXT | `'daily'` / `'weekly'` / `'monthly'` |
| `day_of_month` | INTEGER | 1–28, hanya untuk monthly |
| `is_active` | BOOL | Pause/resume |
| `next_execute` | TIMESTAMPTZ | Kapan berikutnya akan berjalan |
| `last_executed` | TIMESTAMPTZ | Terakhir kali dieksekusi |

**Mekanisme:** Saat app dibuka → cek `next_execute <= now()` → buat transaksi baru → update `next_execute`.

---

### `inventory_items`
Stok barang toko. Hanya muncul jika `isBusinessMode = true`.

| Kolom | Tipe | Keterangan |
|---|---|---|
| `current_stock` | NUMERIC | Stok saat ini |
| `min_stock` | NUMERIC | Batas minimum (trigger alert) |
| `cost_price` | INTEGER | Harga beli / HPP |
| `sell_price` | INTEGER | Harga jual |

---

### `quick_sale_presets`
Template penjualan cepat. Urutan bisa diatur via `sort_order`.

---

### `user_categories`
Kategori custom buatan user (selain kategori default sistem).

| Kolom | Tipe | Nilai |
|---|---|---|
| `type` | TEXT | `'income'` atau `'expense'` |
| `is_stock_purchase` | BOOL | Tandai sebagai pembelian stok (pisah di laporan) |

> **Catatan:** `id` bertipe TEXT (bukan UUID) — legacy dari versi lama app.

---

### `budgets`
Target pemasukan atau batas pengeluaran per bulan.

| Kolom | Tipe | Keterangan |
|---|---|---|
| `type` | TEXT | `'income'` atau `'expense'` |
| `category_id` | TEXT (null) | Null = berlaku untuk semua kategori |
| `target_amount` | INTEGER | Nominal target/batas |
| `month` | TEXT | Format `'YYYY-MM'` |

---

### `products`
Hasil kalkulasi HPP. Hanya untuk `featureProduct = true`.

| Kolom | Tipe | Keterangan |
|---|---|---|
| `yield_qty` | INTEGER | Jumlah unit yang dihasilkan |
| `ingredients` | JSONB | Array bahan baku + harga |
| `other_costs` | JSONB | Array biaya tambahan |
| `selling_price` | INTEGER | Harga jual per unit |
