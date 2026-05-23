# Multi-Space (Ruang) — Desain & Checklist Refactor

**Status:** Desain final, belum diimplementasi  
**Tanggal:** Mei 2026  
**Prioritas:** Phase 1 setelah go-public

---

## Konsep Inti

Satu akun dapat memiliki hingga 3 **Ruang** yang terpisah. Setiap Ruang punya data sendiri (transaksi, kategori, laporan) dan mode fitur yang berbeda. User toggle antar Ruang dari tab di atas app.

### 3 Tipe Ruang (Fixed Naming)

| Tipe | Nama di UI | Target User | Mode Sebelumnya |
|------|-----------|-------------|-----------------|
| `personal` | Pribadi | Keuangan individu | personal |
| `store` | Warung | Penjual / toko | store |
| `production` | Produksi | Produsen Tipe A* | production |

> **Produsen Tipe A** = produksi sendiri + jual di outlet sendiri (bakeri, laundry, warung makan yang masak sendiri).  
> Produsen Tipe B (grosir ke reseller) = belum di-scope, butuh fitur invoice & piutang kompleks.

### Aturan Setup
- Setiap user bisa aktifkan 1, 2, atau 3 Ruang
- Maksimal 1 dari setiap tipe (tidak bisa punya 2 Ruang Warung)
- Ruang bisa ditambah kapan saja dari Settings
- Jika hanya 1 Ruang: tidak ada tab switcher, langsung masuk home Ruang tersebut

---

## Model Subscription Baru

### Skema Locking Fitur

**Ruang: Pribadi (personal)**

| Fitur | Gratis | Premium Pribadi (future v3+) |
|-------|--------|------------------------------|
| Input transaksi & history | ✓ | ✓ |
| Kategori custom | ✓ | ✓ |
| Dompet (multiple wallets) | ✓ | ✓ |
| Budget bulanan | ✗ | ✓ |
| Recurring transaction | ✗ | ✓ |

**Ruang: Warung (store)**

| Fitur | Gratis | Business Premium |
|-------|--------|-----------------|
| Input transaksi & history | ✓ | ✓ |
| Kategori custom | ✓ | ✓ |
| Laporan harian/mingguan | ✓ | ✓ |
| Jual Cepat (Quick Sale) | ✗ | ✓ |
| Utang & Piutang | ✗ | ✓ |
| Stok Barang (Inventory) | ✗ | ✓ |
| Multi-Outlet | ✗ | ✓ |
| Analitik Produk | ✗ | ✓ |

**Ruang: Produksi (production)**

| Fitur | Gratis | Business Premium |
|-------|--------|-----------------|
| Input transaksi & history | ✓ | ✓ |
| Kategori custom | ✓ | ✓ |
| Kalkulasi HPP | ✗ | ✓ |
| Bahan Baku & Stok | ✗ | ✓ |
| Batch Produksi | ✗ | ✓ |
| Multi-Outlet | ✗ | ✓ |

### Harga

| Paket | Harga | Yang Terbuka |
|-------|-------|--------------|
| Gratis | Rp 0 | Semua Ruang dengan fitur dasar, tampil iklan |
| **Business Premium** | ~Rp 20.000/bulan | Semua fitur Warung + Produksi, tanpa iklan |
| Premium Pribadi | TBD (v3+) | Budget + Recurring di Ruang Pribadi |

> Satu pembelian Business Premium unlock **kedua** Ruang Warung & Produksi sekaligus.

---

## Perubahan Database

### Tabel Baru: `spaces`

```sql
CREATE TABLE spaces (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  type       text NOT NULL CHECK (type IN ('personal', 'store', 'production')),
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(user_id, type)
);
```

### Tabel yang Ditambah `space_id`

Semua tabel domain berikut ditambah kolom `space_id uuid REFERENCES spaces(id) ON DELETE SET NULL`:

- `transactions` ← **prioritas tertinggi**
- `wallets`
- `budgets`
- `debts`
- `recurring_transactions`
- `inventory_items`
- `quick_sale_presets`
- `user_categories`
- `outlets`
- `products`
- `raw_materials`
- `production_batches`

> Kolom `space_id` nullable dulu untuk mendukung data lama. Setelah migrasi data selesai baru dibuat NOT NULL.

### Perubahan `profiles`

Tambah kolom subscription baru, hapus feature flags lama (bertahap):

```sql
-- Tambah
ALTER TABLE profiles
  ADD COLUMN is_business_premium    boolean NOT NULL DEFAULT false,
  ADD COLUMN business_premium_until timestamptz;

-- Hapus (setelah migrasi selesai — Phase 5)
-- ALTER TABLE profiles DROP COLUMN feature_product;
-- ALTER TABLE profiles DROP COLUMN feature_outlets;
-- ... dst
```

---

## ERD Setelah Refactor

```
users ──< spaces (type: personal/store/production)
spaces ──< transactions
spaces ──< wallets
spaces ──< budgets
spaces ──< debts
spaces ──< recurring_transactions
spaces ──< inventory_items
spaces ──< quick_sale_presets
spaces ──< user_categories
spaces ──< outlets
spaces ──< products
spaces ──< raw_materials
spaces ──< production_batches

profiles: is_business_premium, business_premium_until
```

---

## Arsitektur Flutter

### Model Baru

```dart
// lib/src/core/models/space_model.dart
enum SpaceType { personal, store, production }

class SpaceModel {
  final String id;
  final SpaceType type;
  final DateTime createdAt;

  String get displayName => switch (type) {
    SpaceType.personal   => 'Pribadi',
    SpaceType.store      => 'Warung',
    SpaceType.production => 'Produksi',
  };
}
```

### Perubahan AppState

```dart
// Tambah ke AppState:
List<SpaceModel> _spaces = [];
String? _activeSpaceId;

SpaceModel? get activeSpace =>
    _spaces.where((s) => s.id == _activeSpaceId).firstOrNull;

// CRUD
Future<void> addSpace(SpaceType type) async { ... }
Future<void> switchSpace(String spaceId) async { ... }
```

### Feature Access Helper (Gantikan profile.featureX)

```dart
// lib/src/core/config/space_features.dart
class SpaceFeatures {
  static bool canUseQuickSale(SpaceModel? space, bool isPremium) =>
      space?.type == SpaceType.store && isPremium;

  static bool canUseDebt(SpaceModel? space, bool isPremium) =>
      space?.type != SpaceType.personal && isPremium;

  static bool canUseHpp(SpaceModel? space, bool isPremium) =>
      space?.type == SpaceType.production && isPremium;

  static bool canUseBudget(SpaceModel? space, bool isPremium) =>
      space?.type == SpaceType.personal && isPremium;

  // dst...
}
```

---

## Checklist Implementasi

> Kerjakan per phase. Jangan mulai phase berikutnya sebelum phase sebelumnya selesai dan di-commit.

### Phase 1 — Data & Model Layer (tidak ada UI change)
- [x] Buat `SpaceModel` + `SpaceType` enum di `core/models/space_model.dart`
- [x] Update `UserProfile`: tambah `isBusinessPremium`, `businessPremiumUntil`; hapus semua `feature*` fields
- [x] Update `UserProfile.fromJson` / `toJson` untuk field baru
- [x] Tambah `_spaces` list dan `_activeSpaceId` ke `AppState`
- [x] Tambah `addSpace()`, `removeSpace()`, `switchSpace()` ke `AppState`
- [x] Update `_persist()` untuk include `spaces` dan `activeSpaceId`
- [x] Update `LocalDatabase` keys jika ada naming conflict
- [x] Buat `SpaceSyncService` di `core/services/space_sync_service.dart` (ikuti pola yang ada)

### Phase 2 — Sync Layer
- [x] Jalankan **Migration 004** di Supabase (lihat `migrations.sql`)
- [x] Update `ProfileService.upsert()`: ganti `feature_*` payload → `is_business_premium`, `business_premium_until`
- [x] Update `ProfileService.fetchProfile()`: map field baru ke `UserProfile`
- [x] Update `TransactionSyncService`: tambah `space_id` ke payload & filter fetch
- [x] Update semua sync service lain: `WalletSyncService`, `BudgetSyncService`, `DebtSyncService`, `RecurringSyncService`, `InventorySyncService`, `QuickSaleSyncService`, `CategorySyncService`, `OutletSyncService`, `ProductSyncService`, `RawMaterialSyncService`, `ProductionBatchSyncService`
- [x] Migrasi data lama: untuk user lama, buat 1 space default berdasarkan `subscription_tier` lama

### Phase 3 — UI: Space Switcher & Onboarding
- [x] Buat `SpaceSwitcherBar` widget: tab Pribadi/Warung/Produksi sesuai `appState.spaces`
- [x] Integrasikan `SpaceSwitcherBar` ke scaffold utama (di atas bottom nav atau sebagai AppBar subtitle)
- [x] Update `HomeScreen`: semua data filter by `activeSpaceId`
- [x] Update `HistoryScreen`: filter by `activeSpaceId`
- [x] Update `ProfileScreen`: tampilkan daftar Ruang aktif + tombol tambah Ruang
- [x] Buat `SetupSpacesScreen` untuk onboarding user baru (pilih ruang mana yang ingin diaktifkan)
- [x] Update `OnboardingScreen` untuk arahkan ke `SetupSpacesScreen` bukan mode picker lama

### Phase 4 — Feature Locking UI
- [x] Buat `SpaceFeatures` helper class (lihat contoh di atas)
- [x] Buat `LockedFeatureCard` widget: tampilkan konten terkunci + CTA upgrade
- [x] Update semua screen yang pakai `profile.featureX` → pakai `SpaceFeatures.canUseX(...)`
- [x] Pastikan menu "Fitur Aktif" di ProfileScreen driven by `SpaceFeatures` bukan feature flags lama
- [x] Buat `UpgradeScreen` baru yang spesifik Business Premium (gantikan yang lama)
- [ ] Integrasikan payment gateway (in-app purchase atau link ke Midtrans/Xendit) — SKIP (ditunda, butuh keputusan vendor)

### Phase 5 — Cleanup (setelah Phase 4 stabil)
- [ ] Hapus semua `feature*` field dari `UserProfile` model
- [ ] Hapus `feature_config.dart` dan semua `useFeature()` calls
- [ ] Hapus `subscriptionTier` enum (ganti dengan `isBusinessPremium`)
- [ ] Jalankan **Migration 004b** di Supabase: DROP COLUMN feature_* dari profiles
- [ ] Update ERD.md — hapus feature flag columns dari dokumentasi

---

## Migrasi User Lama

Saat user lama (sebelum fitur Ruang) buka app versi baru:

1. App deteksi `spaces` kosong di local storage
2. Baca `subscriptionTier` lama dari profile
3. Auto-create space default:
   - `free` → buat Ruang Pribadi
   - `retail` → buat Ruang Warung (+ mark `isBusinessPremium = true` jika `subscriptionExpiry` masih valid)
   - `production` → buat Ruang Produksi (+ mark `isBusinessPremium = true`)
4. Set `activeSpaceId` ke space yang baru dibuat
5. Assign semua transaksi lama ke space ini (`UPDATE transactions SET space_id = $spaceId WHERE user_id = $userId AND space_id IS NULL`)

---

## Wireframe Space Switcher

Hanya muncul jika user punya >1 Ruang aktif:

```
┌─────────────────────────────────────────────┐
│  [● Pribadi]  [  Warung  ]  [  Produksi  ]  │  ← tab switcher
├─────────────────────────────────────────────┤
│                                             │
│  Home content — data khusus Ruang aktif     │
│                                             │
└─────────────────────────────────────────────┘
```

Jika hanya 1 Ruang: tidak ada tab, langsung masuk home.

---

## Catatan Penting

1. **Jangan hapus feature flags sebelum Phase 4 selesai** — masih dipakai di banyak screen
2. **`space_id` nullable dulu** di DB — data lama tidak punya space_id, jangan break existing users
3. **`user_categories` per Ruang** — kategori "Makanan" di Warung tidak harus sama dengan di Pribadi
4. **Quick sale presets** tetap terikat ke outlet, outlet terikat ke Ruang Warung/Produksi
5. **Notifikasi & PIN** tetap shared antar Ruang (tidak perlu dipisah)
