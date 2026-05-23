# Entity Relationship Diagram (ERD)
## Cuan Flow — Database Schema

**Versi:** 3.1 | **Tanggal:** Mei 2026

> Preview diagram: buka file ini di VSCode → klik kanan → **"Open Preview"**, atau tekan `Cmd+Shift+V` (Mac) / `Ctrl+Shift+V` (Windows).  
> Butuh ekstensi **Markdown Preview Mermaid Support** (ID: `bierner.markdown-mermaid`) jika diagram tidak tampil.

---

## Diagram Relasi

```mermaid
erDiagram
    users ||--|| profiles : "has"
    users ||--o{ spaces : "owns"

    spaces ||--o{ transactions : "scopes"
    spaces ||--o{ wallets : "scopes"
    spaces ||--o{ debts : "scopes"
    spaces ||--o{ recurring_transactions : "scopes"
    spaces ||--o{ inventory_items : "scopes"
    spaces ||--o{ quick_sale_presets : "scopes"
    spaces ||--o{ user_categories : "scopes"
    spaces ||--o{ budgets : "scopes"
    spaces ||--o{ products : "scopes"
    spaces ||--o{ raw_materials : "scopes"
    spaces ||--o{ production_batches : "scopes"
    spaces ||--o{ outlets : "scopes"

    transactions }o--o| outlets : "tagged outlet_id"
    transactions }o--o| wallets : "from wallet_id"

    outlets ||--o{ outlet_closures : "closed on dates"
    recurring_transactions }o--o| outlets : "outlet_id (skip if closed)"

    quick_sale_presets }o--o| outlets : "for outlet_id"
    quick_sale_presets }o--o| wallets : "to wallet_id"

    budgets }o--o| user_categories : "per category_id"

    production_batches }o--|| products : "produces product_id"
    production_batches ||--|{ batch_materials : "uses"
    batch_materials }o--|| raw_materials : "consumes raw_material_id"

    users {
        uuid id PK
        text email
    }

    spaces {
        uuid id PK
        uuid user_id FK
        text type
        timestamptz created_at
    }

    profiles {
        uuid id PK_FK
        text owner_name
        text business_name
        text whatsapp
        bool is_business_premium
        timestamptz business_premium_until
        bool onboarding_complete
    }

    transactions {
        uuid id PK
        uuid user_id FK
        text type
        int amount
        text category
        text note
        uuid outlet_id FK
        text wallet_id FK
        timestamptz effective_date
        timestamptz created_at
    }

    wallets {
        uuid id PK
        uuid user_id FK
        text name
        text type
        int initial_balance
        bool is_default
        timestamptz created_at
    }

    debts {
        uuid id PK
        uuid user_id FK
        text person_name
        int amount
        text type
        bool is_paid
        text notes
        timestamptz due_date
        timestamptz created_at
    }

    recurring_transactions {
        uuid id PK
        uuid user_id FK
        text name
        int amount
        text type
        text category
        text frequency
        int day_of_month
        text wallet_id FK
        uuid outlet_id FK
        bool is_active
        timestamptz next_execute
        timestamptz last_executed
        timestamptz created_at
    }

    outlet_closures {
        uuid id PK
        uuid outlet_id FK
        uuid user_id FK
        date date
        text note
        timestamptz created_at
    }

    inventory_items {
        uuid id PK
        uuid user_id FK
        text name
        text unit
        numeric current_stock
        numeric min_stock
        int cost_price
        int sell_price
        text category
        timestamptz created_at
    }

    quick_sale_presets {
        uuid id PK
        uuid user_id FK
        text name
        int sell_price
        text category
        text note
        text wallet_id FK
        uuid outlet_id FK
        int sort_order
    }

    user_categories {
        text id PK
        uuid user_id FK
        text name
        text type
        bool is_stock_purchase
    }

    budgets {
        uuid id PK
        uuid user_id FK
        text type
        text category_id FK
        int target_amount
        text month
        timestamptz created_at
    }

    products {
        uuid id PK
        uuid user_id FK
        text name
        int yield_qty
        text yield_unit
        int selling_price
        json ingredients
        json other_costs
        timestamptz created_at
    }

    raw_materials {
        text id PK
        uuid user_id FK
        text name
        text unit
        double current_stock
        double min_stock
        double cost_per_unit
        text supplier_name
        text category
        timestamptz created_at
    }

    production_batches {
        text id PK
        uuid user_id FK
        text product_id FK
        text product_name
        datetime date
        double qty_produced
        text notes
        timestamptz created_at
    }

    batch_materials {
        text raw_material_id FK
        text raw_material_name
        double quantity
        text unit
        double cost_per_unit
    }

    outlets {
        uuid id PK
        uuid user_id FK
        text name
        text address
        bool is_default
        timestamptz created_at
    }
```

---

## Penjelasan Tiap Tabel

### `users` (Supabase Auth)
Dikelola sepenuhnya oleh Supabase Auth. App hanya pakai `id` sebagai foreign key.

---

### `spaces`
Ruang data yang terpisah per tipe bisnis. Satu user bisa punya 1–3 spaces.

| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | UUID (PK) | |
| `user_id` | UUID (FK) | Referensi ke `auth.users.id` |
| `type` | TEXT | `'personal'` / `'store'` / `'production'` |
| `created_at` | TIMESTAMPTZ | |

**Constraint:** `UNIQUE(user_id, type)` — maks 1 dari setiap tipe per user.

Semua tabel domain (`transactions`, `wallets`, `budgets`, dll) punya kolom `space_id` FK ke tabel ini sehingga data terisolasi per Ruang.

> Lihat [docs/MULTI_SPACE_REFACTOR.md](MULTI_SPACE_REFACTOR.md) untuk checklist implementasi lengkap.

---

### `profiles`
Ekstensi data user. Satu user = satu profil. Menyimpan data subscription.

| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | UUID (FK) | Sama dengan `auth.users.id` |
| `owner_name` | TEXT | Nama pemilik |
| `business_name` | TEXT | Nama usaha (opsional) |
| `whatsapp` | TEXT | Nomor WA |
| `is_business_premium` | BOOL | Apakah sudah bayar Business Premium? |
| `business_premium_until` | TIMESTAMPTZ | Tanggal expiry (null = tidak pernah bayar) |
| `onboarding_complete` | BOOL | Sudah lewat layar setup Ruang? |

> **Feature flags lama** (`feature_product`, `feature_outlets`, dll) masih ada di DB selama masa transisi. Akan dihapus via Migration 004b setelah Phase 5 selesai. Jangan gunakan untuk logika baru — pakai `SpaceFeatures` helper sebagai gantinya.

---

### `transactions`
Inti dari app — semua pemasukan & pengeluaran.

| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | UUID | Auto-generate |
| `user_id` | UUID (FK) | |
| `type` | TEXT | `'income'` atau `'expense'` |
| `amount` | INTEGER | Dalam Rupiah (tanpa desimal) |
| `category` | TEXT | Nama kategori |
| `note` | TEXT | Keterangan |
| `outlet_id` | UUID (FK, null) | Hanya jika `featureOutlets` aktif |
| `wallet_id` | TEXT (null) | Referensi ke dompet |
| `effective_date` | TIMESTAMPTZ | Tanggal transaksi (bisa backdate) |
| `created_at` | TIMESTAMPTZ | Waktu input |

> `wallet_id` tersimpan lokal tetapi belum di-sync ke server (payload sync belum include).

---

### `wallets`
Dompet/rekening user. Hanya aktif untuk mode personal.

| Kolom | Tipe | Nilai |
|---|---|---|
| `type` | TEXT | `'cash'` / `'bank'` / `'ewallet'` |
| `initial_balance` | INTEGER | Saldo awal saat dompet dibuat |
| `is_default` | BOOL | Dompet yang otomatis dipilih |

**Saldo aktual** = `initial_balance + Σ income - Σ expense` untuk `wallet_id` tersebut.

---

### `debts`
Catatan utang & piutang. Aktif jika `featureDebt = true`.

| Kolom | Tipe | Nilai |
|---|---|---|
| `type` | TEXT | `'iOwe'` = saya berhutang / `'theyOwe'` = mereka berhutang |
| `is_paid` | BOOL | Lunas atau belum (data tidak dihapus) |
| `due_date` | TIMESTAMPTZ | Jatuh tempo (opsional) |

---

### `recurring_transactions`
Template transaksi yang berjalan otomatis saat app dibuka.

| Kolom | Tipe | Nilai |
|---|---|---|
| `frequency` | TEXT | `'daily'` / `'weekly'` / `'monthly'` |
| `day_of_month` | INTEGER | 1–28, hanya untuk monthly |
| `outlet_id` | UUID (FK, null) | Jika diisi, cek `outlet_closures` sebelum eksekusi |
| `is_active` | BOOL | Pause/resume global |
| `next_execute` | TIMESTAMPTZ | Kapan berikutnya akan berjalan |
| `last_executed` | TIMESTAMPTZ | Terakhir kali dieksekusi |

**Logika skip libur:** Saat app dibuka dan recurring siap dieksekusi — jika `outlet_id` diisi dan ada record di `outlet_closures` untuk outlet + tanggal hari ini → transaksi di-skip, `next_execute` tetap maju ke hari berikutnya.

Use case utama: gaji harian karyawan per outlet. Jika outlet tutup, gaji tidak dibuat otomatis.

---

### `outlet_closures`
Tanggal-tanggal outlet tutup (libur, force close, dll). Dipakai untuk skip recurring gaji otomatis.

| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | UUID (PK) | |
| `outlet_id` | UUID (FK) | Outlet yang tutup |
| `user_id` | UUID (FK) | |
| `date` | DATE | Tanggal tutup |
| `note` | TEXT | Alasan tutup (opsional: libur, banjir, dll) |
| `created_at` | TIMESTAMPTZ | |

**Constraint:** `UNIQUE(outlet_id, date)` — tidak bisa double-mark tutup di hari yang sama.

**Side effect:** Saat Multi-Space live, `outlet_closures` juga dapat `space_id` (ikut Migration 004).

---

### `inventory_items`
Stok barang toko. Aktif jika `featureStock = true`.

| Kolom | Tipe | Keterangan |
|---|---|---|
| `current_stock` | NUMERIC | Stok saat ini |
| `min_stock` | NUMERIC | Batas minimum (trigger alert) |
| `cost_price` | INTEGER | Harga beli / HPP |
| `sell_price` | INTEGER | Harga jual |

---

### `quick_sale_presets`
Template penjualan cepat. Aktif jika `featureQuickSale = true`. Urutan diatur via `sort_order`.

---

### `user_categories`
Kategori custom buatan user.

| Kolom | Tipe | Nilai |
|---|---|---|
| `type` | TEXT | `'income'` atau `'expense'` |
| `is_stock_purchase` | BOOL | Tandai sebagai pembelian stok |

> `id` bertipe TEXT (bukan UUID) — legacy dari versi lama app.

---

### `budgets`
Target pemasukan atau batas pengeluaran per bulan. Aktif jika `featureBudget = true`.

| Kolom | Tipe | Keterangan |
|---|---|---|
| `type` | TEXT | `'income'` atau `'expense'` |
| `category_id` | TEXT (null) | Null = berlaku untuk semua kategori |
| `target_amount` | INTEGER | Nominal target/batas |
| `month` | TEXT | Format `'YYYY-MM'` |

---

### `products`
Hasil kalkulasi HPP. Aktif jika `featureProduct = true`.

| Kolom | Tipe | Keterangan |
|---|---|---|
| `yield_qty` | INTEGER | Jumlah unit yang dihasilkan |
| `ingredients` | JSONB | Array bahan baku + harga (`[{name, price}]`) |
| `other_costs` | JSONB | Array biaya tambahan (`[{name, amount}]`) |
| `selling_price` | INTEGER | Harga jual per unit |

---

### `raw_materials`
Daftar bahan baku untuk mode produksi. Aktif jika `featureProduction = true`.

| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | TEXT | ID lokal (timestamp + random) |
| `name` | TEXT | Nama bahan baku |
| `unit` | TEXT | Satuan (kg, liter, pcs, dll) |
| `current_stock` | DOUBLE | Stok saat ini |
| `min_stock` | DOUBLE | Minimum stok (trigger alert) |
| `cost_per_unit` | DOUBLE | Harga per satuan |
| `supplier_name` | TEXT | Nama supplier (opsional) |
| `category` | TEXT | Kategori bahan (opsional) |

**Status stok:**
- Habis: `currentStock <= 0`
- Menipis: `!isOutOfStock && minStock > 0 && currentStock <= minStock`
- Aman: selainnya

---

### `production_batches`
Catatan setiap kali produksi dilakukan. Aktif jika `featureProduction = true`.

| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | TEXT | ID lokal |
| `product_id` | TEXT (FK) | Referensi ke `products.id` |
| `product_name` | TEXT | Snapshot nama produk |
| `date` | DATETIME | Tanggal produksi |
| `qty_produced` | DOUBLE | Jumlah unit yang diproduksi |
| `notes` | TEXT | Catatan opsional |

**`batch_materials`** (embedded sebagai JSON array di dalam batch):

| Field | Tipe | Keterangan |
|---|---|---|
| `rawMaterialId` | TEXT | Referensi ke `raw_materials.id` |
| `rawMaterialName` | TEXT | Snapshot nama bahan |
| `quantity` | DOUBLE | Jumlah yang dipakai |
| `unit` | TEXT | Satuan |
| `costPerUnit` | DOUBLE | Harga per satuan saat produksi |

**Kalkulasi:** `costPerUnit = totalMaterialCost / qtyProduced`

---

### `outlets`
Cabang / outlet bisnis. Aktif jika `featureOutlets = true`.

| Kolom | Tipe | Keterangan |
|---|---|---|
| `name` | TEXT | Nama outlet |
| `address` | TEXT | Alamat (opsional) |
| `is_default` | BOOL | Outlet default saat input transaksi |

Tiap outlet bisa punya daftar tanggal tutup di `outlet_closures`. Recurring transactions yang punya `outlet_id` akan otomatis di-skip pada tanggal tutup tersebut.

---

## Field & Data yang Belum Di-sync ke Supabase

> ⚠️ Bagian ini wajib dibaca sebelum release atau saat menambah fitur monetisasi.

### 1. `subscription_tier` + `subscription_expiry` — sudah di-sync, akan digantikan

**Status:** Kolom sudah ada di Supabase (Migration 001). `ProfileService` sudah sync kedua field ini.

**Rencana ke depan:** Kedua kolom ini akan digantikan oleh `is_business_premium` + `business_premium_until` saat Multi-Space diimplementasi (Migration 004). Kolom lama tetap ada sampai Migration 004b dijalankan.

**Action saat ini:** Tidak perlu apa-apa — sudah lengkap.

---

### 2. `products` — `ProductSyncService` ada, tapi belum disambungkan ke AppState

**Model Dart:** `ProductModel` (HPP Calculator)

**Status:** File `core/services/product_sync_service.dart` sudah dibuat mengikuti pola `RawMaterialSyncService`, tapi `AppState.addProduct()` / `updateProduct()` / `deleteProduct()` masih hanya panggil `_persist()` → local JSON. **Belum ada koneksi ke sync service.**

**Supabase `products` table:** Ada di ERD dan sync service sudah siap, tapi belum dipanggil dari AppState.

**Konsekuensi:** Data produk (HPP, bahan baku resep) tidak tersync antar device. Jika user ganti HP, data produk hilang.

**Action saat ingin sync:**
1. Inject `ProductSyncService` ke `AppState` (ikuti pola `_rawMaterialSync`).
2. Panggil `_productSync.upsert(product).ignore()` setelah `_persist()` di `addProduct()` / `updateProduct()`.
3. Panggil `_productSync.delete(id).ignore()` di `deleteProduct()`.

---

### 3. `wallet_id` di `transactions` — tidak terkirim ke Supabase

**Status:** Field `wallet_id` tersimpan di lokal tapi payload sync transaksi tidak menyertakannya.
(Sudah didokumentasikan di bagian transactions di atas.)

---

### 4. `AppSettings` — murni local, tidak akan pernah di-sync

`AppSettings` (tema, bahasa, PIN, reminder notifikasi) by design hanya di device. Tidak ada rencana sync ke Supabase.

---

## Storage Architecture

```mermaid
flowchart LR
    A[User Action] --> B[Local JSON\nSharedPreferences]
    B --> C[UI Update\nChangeNotifier]
    B --> D{Online?}
    D -- Yes --> E[Supabase\nSync]
    D -- No --> F[Queue\nRetry]
    F --> E
    E -- Pull on Login --> B
```

**Prinsip:**
- Local JSON = source of truth untuk UI
- Supabase = backup & sync antar device
- App selalu bisa dipakai offline
- ID lokal diganti UUID server setelah sync berhasil
