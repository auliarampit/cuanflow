-- ============================================================
-- CuanFlow — Supabase Migration Scripts
-- Jalankan di Supabase Dashboard → SQL Editor
-- ============================================================


-- ============================================================
-- MIGRATION 001 — Tambah kolom yang belum ada di profiles
-- Jalankan sekarang agar ProfileService bisa sync semua field.
-- ============================================================

ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS feature_stock             boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS feature_product_analytics boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS feature_debt              boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS subscription_tier         text    NOT NULL DEFAULT 'free',
  ADD COLUMN IF NOT EXISTS subscription_expiry       timestamptz;

-- Validasi nilai tier yang diizinkan
ALTER TABLE profiles
  DROP CONSTRAINT IF EXISTS profiles_subscription_tier_check;

ALTER TABLE profiles
  ADD CONSTRAINT profiles_subscription_tier_check
  CHECK (subscription_tier IN ('free', 'retail', 'production'));

-- RLS: user hanya bisa baca/tulis profil sendiri (pastikan sudah aktif)
-- ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
-- CREATE POLICY "profiles: own row only" ON profiles
--   USING (auth.uid() = id)
--   WITH CHECK (auth.uid() = id);


-- ============================================================
-- MIGRATION 002 — Sambungkan ProductSyncService ke AppState
-- Tidak ada perubahan DB — hanya reminder untuk kode Dart.
--
-- Yang perlu dilakukan di app_state.dart:
--   1. Inject ProductSyncService (ikuti pola _rawMaterialSync)
--   2. addProduct()    → tambah: _productSync.upsert(product).ignore()
--   3. updateProduct() → tambah: _productSync.upsert(product).ignore()
--   4. deleteProduct() → tambah: _productSync.delete(id).ignore()
--   5. init()          → tambah: pull products dari Supabase saat login
-- ============================================================


-- ============================================================
-- MIGRATION 003 — wallet_id di transaksi (jika ingin sync)
-- Kolom wallet_id SUDAH ADA di tabel transactions.
-- Yang perlu dilakukan hanya di kode Dart (TransactionSyncService):
--   Tambah 'wallet_id': item.walletId ke payload _toRemote().
-- Tidak ada ALTER TABLE yang dibutuhkan.
-- ============================================================


-- ============================================================
-- CATATAN: Tabel yang sudah lengkap (tidak perlu migration)
-- ============================================================
-- products          — sudah ada, ProductSyncService sudah siap
-- raw_materials     — sudah sync via RawMaterialSyncService
-- production_batches— sudah sync
-- transactions      — sudah sync (kecuali wallet_id di atas)
-- wallets           — sudah sync
-- debts             — sudah sync
-- recurring_transactions — sudah sync
-- inventory_items   — sudah sync
-- quick_sale_presets     — sudah sync
-- user_categories   — sudah sync
-- budgets           — sudah sync
-- outlets           — sudah sync


-- ============================================================
-- MIGRATION 004 — Multi-Space (Ruang)
-- Jalankan saat Phase 2 implementasi Multi-Space dimulai.
-- Lihat docs/MULTI_SPACE_REFACTOR.md untuk checklist lengkap.
-- ============================================================

-- 1. Tabel spaces: satu per tipe per user, maks 3
CREATE TABLE IF NOT EXISTS spaces (
  id         uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    uuid        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  type       text        NOT NULL CHECK (type IN ('personal', 'store', 'production')),
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, type)
);

ALTER TABLE spaces ENABLE ROW LEVEL SECURITY;

CREATE POLICY "spaces: own rows only" ON spaces
  USING  (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- 2. Tambah space_id ke tabel domain (nullable dulu untuk data lama)
ALTER TABLE transactions          ADD COLUMN IF NOT EXISTS space_id uuid REFERENCES spaces(id) ON DELETE SET NULL;
ALTER TABLE wallets               ADD COLUMN IF NOT EXISTS space_id uuid REFERENCES spaces(id) ON DELETE SET NULL;
ALTER TABLE budgets               ADD COLUMN IF NOT EXISTS space_id uuid REFERENCES spaces(id) ON DELETE SET NULL;
ALTER TABLE debts                 ADD COLUMN IF NOT EXISTS space_id uuid REFERENCES spaces(id) ON DELETE SET NULL;
ALTER TABLE recurring_transactions ADD COLUMN IF NOT EXISTS space_id uuid REFERENCES spaces(id) ON DELETE SET NULL;
ALTER TABLE inventory_items       ADD COLUMN IF NOT EXISTS space_id uuid REFERENCES spaces(id) ON DELETE SET NULL;
ALTER TABLE quick_sale_presets    ADD COLUMN IF NOT EXISTS space_id uuid REFERENCES spaces(id) ON DELETE SET NULL;
ALTER TABLE user_categories       ADD COLUMN IF NOT EXISTS space_id uuid REFERENCES spaces(id) ON DELETE SET NULL;
ALTER TABLE outlets               ADD COLUMN IF NOT EXISTS space_id uuid REFERENCES spaces(id) ON DELETE SET NULL;
ALTER TABLE products              ADD COLUMN IF NOT EXISTS space_id uuid REFERENCES spaces(id) ON DELETE SET NULL;
ALTER TABLE raw_materials         ADD COLUMN IF NOT EXISTS space_id uuid REFERENCES spaces(id) ON DELETE SET NULL;
ALTER TABLE production_batches    ADD COLUMN IF NOT EXISTS space_id uuid REFERENCES spaces(id) ON DELETE SET NULL;

-- 3. Tambah kolom subscription baru ke profiles
ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS is_business_premium    boolean     NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS business_premium_until timestamptz;

-- ============================================================
-- MIGRATION 004b — Cleanup (jalankan setelah Phase 5 selesai)
-- Hapus feature flags lama setelah semua screen sudah migrasi
-- ke SpaceFeatures helper.
-- ============================================================

-- ALTER TABLE profiles
--   DROP COLUMN IF EXISTS feature_product,
--   DROP COLUMN IF EXISTS feature_outlets,
--   DROP COLUMN IF EXISTS feature_budget,
--   DROP COLUMN IF EXISTS feature_production,
--   DROP COLUMN IF EXISTS feature_quick_sale,
--   DROP COLUMN IF EXISTS feature_top_categories,
--   DROP COLUMN IF EXISTS feature_busiest_day,
--   DROP COLUMN IF EXISTS feature_stock,
--   DROP COLUMN IF EXISTS feature_product_analytics,
--   DROP COLUMN IF EXISTS feature_debt,
--   DROP COLUMN IF EXISTS subscription_tier,
--   DROP COLUMN IF EXISTS subscription_expiry;

-- ============================================================
-- MIGRASI DATA LAMA — Jalankan setelah Migration 004
-- Auto-create 1 space per user berdasarkan subscription_tier
-- ============================================================

-- Untuk user tier 'free' → buat Ruang Pribadi
INSERT INTO spaces (user_id, type)
SELECT id, 'personal'
FROM profiles
WHERE subscription_tier = 'free'
  AND NOT EXISTS (SELECT 1 FROM spaces WHERE spaces.user_id = profiles.id)
ON CONFLICT DO NOTHING;

-- Untuk user tier 'retail' → buat Ruang Warung
INSERT INTO spaces (user_id, type)
SELECT id, 'store'
FROM profiles
WHERE subscription_tier = 'retail'
  AND NOT EXISTS (SELECT 1 FROM spaces WHERE spaces.user_id = profiles.id)
ON CONFLICT DO NOTHING;

-- Untuk user tier 'production' → buat Ruang Produksi + Warung
INSERT INTO spaces (user_id, type)
SELECT id, 'production'
FROM profiles
WHERE subscription_tier = 'production'
  AND NOT EXISTS (SELECT 1 FROM spaces WHERE spaces.user_id = profiles.id AND type = 'production')
ON CONFLICT DO NOTHING;

INSERT INTO spaces (user_id, type)
SELECT id, 'store'
FROM profiles
WHERE subscription_tier = 'production'
  AND NOT EXISTS (SELECT 1 FROM spaces WHERE spaces.user_id = profiles.id AND type = 'store')
ON CONFLICT DO NOTHING;

-- Mark user lama yang sudah bayar sebagai business premium
UPDATE profiles
SET is_business_premium    = true,
    business_premium_until = subscription_expiry
WHERE subscription_tier IN ('retail', 'production')
  AND (subscription_expiry IS NULL OR subscription_expiry > now());

-- Assign transaksi lama ke space yang baru dibuat (berdasarkan tipe space utama)
UPDATE transactions t
SET space_id = s.id
FROM spaces s
WHERE s.user_id = t.user_id
  AND t.space_id IS NULL
  AND s.type = CASE
    WHEN (SELECT subscription_tier FROM profiles WHERE id = t.user_id) = 'production' THEN 'production'
    WHEN (SELECT subscription_tier FROM profiles WHERE id = t.user_id) = 'retail'     THEN 'store'
    ELSE 'personal'
  END;
