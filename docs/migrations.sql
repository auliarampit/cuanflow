-- ============================================================
-- CuanFlow — Supabase Migration Scripts
-- Jalankan di Supabase Dashboard → SQL Editor
-- ============================================================


-- ============================================================
-- MIGRATION 001 — Subscription tier di profiles
-- Jalankan saat billing/paywall siap diluncurkan.
-- ============================================================

ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS subscription_tier text NOT NULL DEFAULT 'free',
  ADD COLUMN IF NOT EXISTS subscription_expiry timestamptz;

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
