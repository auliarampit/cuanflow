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

## 9. VIBE CODING WORKFLOW

### Flow Setiap Sesi Coding

```
DISCOVERY → PLANNING → IMPLEMENTATION → VERIFY
```

**Jangan langsung coding.** Selalu tanya dulu:
1. Ini fix bug atau tambah fitur?
2. Fitur ini untuk mode mana? (cek feature flag)
3. Ada dampak ke AppState, model, atau route?

### Ritual Awal Sesi
Gunakan `/start` untuk load konteks lengkap sebelum mulai coding.

### Jenis Task & Skill yang Tepat

| Task | Skill | Dokumen yang dibaca |
|---|---|---|
| Tambah fitur baru | `/add-feature` | BRD + AI_CONTEXT + feature_config |
| Fix bug | `/fix` | AI_CONTEXT + file terdampak |
| Cek roadmap & status | `/roadmap` | CLAUDE.md + git log |
| Mulai sesi baru | `/start` | BRD + AI_CONTEXT + git log |
| Cek/ubah feature flag | `/feature-flags` | feature_config.dart |

### Prioritas Implementasi (Dari Diskusi Owner, 2026-05)

```
PHASE 0 — Fondasi (sebelum publik)
├── P0.1  Onboarding wizard redesign (guided, bukan mode picker)
├── P0.2  Shopping list bulk expense UX  ← KILLER FEATURE
├── P0.3  Personal mode (budget + trend harian)
└── P0.4  Freemium/paywall scaffold

PHASE 1 — Retail Polish (bulan 1 setelah launch)
├── P1.1  Quick sale improvement
├── P1.2  Health dashboard per outlet
└── P1.3  Push notif budget alert (sudah ada, polish)

PHASE 2 — Produsen Complete (kuartal 1)
├── P2.1  HPP calculator yang intuitif
├── P2.2  Raw material → produksi → margin flow
└── P2.3  Laporan profit per batch
```

---

## 10. HOW AI SHOULD WORK

Setiap task:

1. Baca `docs/AI_CONTEXT.md` + `docs/BRD.md` untuk konteks bisnis
2. Kerjakan per task kecil, jangan modify scope tanpa instruksi
3. Ikuti pola CRUD AppState yang sudah ada
4. Jangan over-engineer — solusi paling sederhana yang benar

---

## 11. OUTPUT EXPECTATION

AI harus:

- Konsisten dengan docs (BRD > USER_FLOW > ERD)
- Tidak over-engineer
- Tidak menambah fitur di luar scope yang disepakati
- Menghasilkan code modular mengikuti pola existing
- Komentar dalam Bahasa Indonesia