# AI CONTEXT — CUAN FLOW
Versi: 2.1

---

## 1. SOURCE OF TRUTH (WAJIB DIIKUTI)

AI HARUS selalu refer ke:

- BRD.md → business rules & feature scope
- USER_FLOW.md → UX flow & user behavior
- ERD.md → database schema & relasi

Jika ada konflik:
USER_FLOW > BRD > ERD

---

## 2. CORE CONCEPT

Cuan Flow adalah aplikasi pencatatan keuangan untuk:

- Personal (`mode = personal`)
- Toko / Warung (`mode = store`)
- Produksi / Home industry (`mode = production`)

Pendekatan:
- ⚡ cepat (≤ 10 detik input)
- 📱 offline-first
- 🧩 modular (feature flag driven)

---

## 3. MODE & FEATURE FLAG SYSTEM

Mode hanya preset awal.

Semua fitur dikontrol oleh feature flag di `profiles`.

### Feature Flags:

- feature_product
- feature_outlets
- feature_budget
- feature_production
- feature_quick_sale
- feature_top_categories
- feature_busiest_day
- feature_stock
- feature_product_analytics
- feature_debt

---

### Default Mode Mapping:

| Mode | Flags ON |
|-----|--------|
| personal | semua OFF |
| store | quick_sale, top_categories, busiest_day, stock, product_analytics |
| production | product, outlets, budget, production, stock, product_analytics, debt |

---

## 4. CORE SYSTEM RULES (KRITIS)

### 4.1 Transaction = Source of Truth
- Semua saldo dihitung dari `transactions`
- Tidak ada stored balance
- Formula:
  saldo = initial_balance + income - expense

---

### 4.2 Offline-first Architecture
- Local JSON = source of truth (UI)
- Supabase = sync layer
- Semua write → local dulu → sync background

---

### 4.3 Wallet Rules
- Hanya aktif di mode personal
- Mode store & production → wallet disembunyikan

---

### 4.4 Stock Rules
- Manual update only
- Tidak terhubung ke quick sale
- Status:
  - hijau: aman
  - kuning: menipis
  - merah: habis

---

### 4.5 Quick Sale Rules
- Hanya create transaction (income)
- Tidak mengurangi stok
- Tidak menggunakan wallet

---

### 4.6 Debt Rules
- iOwe = saya berhutang
- theyOwe = orang lain berhutang
- Tandai lunas → hanya update `is_paid = true`

---

### 4.7 Production Rules
- Batch produksi mencatat:
  - produk
  - qty
  - bahan baku
- Tidak mengurangi stok bahan otomatis
- Formula:
  costPerUnit = totalMaterialCost / qtyProduced

---

## 5. DATA MODEL RULES (ERD)

AI HARUS mengikuti:

- Semua FK sesuai ERD
- Tidak boleh tambah field tanpa update ERD
- Gunakan:
  - UUID untuk server entity
  - TEXT untuk local ID tertentu (legacy)

---

## 6. IMPLEMENTATION RULES

Saat implement fitur:

1. Cek USER_FLOW terlebih dahulu
2. Validasi dengan BRD (business rules)
3. Cocokkan dengan ERD (schema)
4. Baru implement code

---

## 7. ARCHITECTURE EXPECTATION

- UI ≠ business logic
- Tidak boleh ada logic di widget
- Gunakan:
  - service / controller / provider
- State harus predictable

---

## 8. ANTI-PATTERN (DILARANG)

❌ Menambah logic tanpa refer USER_FLOW  
❌ Mengubah schema tanpa ERD  
❌ Menghubungkan fitur yang dipisah (quick sale ↔ stock)  
❌ Hardcode mode tanpa cek feature flag  
❌ Menghitung saldo secara manual di UI  

---

## 9. HOW AI SHOULD WORK

Setiap task:

1. Gunakan AI_CONTEXT.md
2. Gunakan PRD (jika ada)
3. Kerjakan per task kecil
4. Jangan modify scope tanpa instruksi

---

## 10. OUTPUT EXPECTATION

AI harus:

- Konsisten dengan docs
- Tidak over-engineer
- Tidak menambah fitur di luar scope
- Menghasilkan code modular & scalable