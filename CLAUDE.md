# CLAUDE.md — cari_untung (CuanFlow)

Flutter financial tracking app untuk UMKM Indonesia. Offline-first dengan sync Supabase.

---

## Stack

| Layer | Tech |
|---|---|
| Framework | Flutter SDK ^3.10, Dart |
| Backend | Supabase (PostgreSQL + Auth) |
| State | ChangeNotifier (`AppState`) — satu objek global, tidak ada Riverpod/Bloc |
| Storage lokal | JSON file via `LocalDatabase` (`core/storage/`) |
| Routing | Named routes via `AppRouter.onGenerateRoute` — tidak pakai go_router |
| Charts | fl_chart ^0.69 |
| Localization | intl ^0.20, flutter_localizations (ID + EN) |
| PDF | pdf + printing |
| Ads | google_mobile_ads |
| Notifications | flutter_local_notifications |

---

## Commands

```bash
flutter pub get
flutter run
flutter analyze
flutter test
```

---

## Struktur Folder

```
lib/src/
├── app/           # AppRouter (named routes), AppRoutes constants
├── core/
│   ├── config/    # feature_config.dart — SINGLE SOURCE OF TRUTH feature flags
│   ├── constants/ # Supabase credentials
│   ├── formatters/# CurrencyInputFormatter, IDRFormatter
│   ├── localization/
│   ├── models/    # 16 model: MoneyTransaction, UserProfile, BudgetModel, dll
│   ├── services/  # 14 sync service (satu per domain)
│   ├── state/     # AppState (ChangeNotifier) + AppStateScope
│   ├── storage/   # LocalDatabase — JSON file ke disk
│   ├── theme/     # AppTheme, AppColors, AppDynamicColors
│   ├── ui/        # Shared widgets: AppGradientScaffold, ResponsiveUtils
│   └── utils/     # PDF exporter, helpers
└── features/      # 18 feature module (satu folder = satu screen atau kelompok screen)
```

### 18 Feature Modules

`auth` · `budget` · `categories` · `debt` · `history` · `home` · `inventory` · `notifications` · `onboarding` · `outlets` · `product` · `profile` · `quick_sale` · `recurring` · `settings` · `splash` · `transactions` · `wallet`

---

## Feature Flags & Business Modes

File: `lib/src/core/config/feature_config.dart`

Tiga mode bisnis:

| Mode | Target | Fitur utama |
|---|---|---|
| `personal` | Individu | Transaksi & history saja |
| `store` | Warung/toko | quickSale, topCategories, busiestDay, stock, productAnalytics, debt |
| `production` | Produsen/UMKM manufaktur | product (HPP), outlets, budget, production (batch + raw materials) |

**Cara cek fitur:**
```dart
// Di widget
if (useFeature(Feature.quickSale, appState.profile)) { ... }

// Atau via extension
if (appState.profile.hasFeature(Feature.debt)) { ... }
```

**Cara tambah feature flag baru:**
1. Tambah entry di enum `Feature` di `feature_config.dart`
2. Tambah ke `featureConfig` map untuk ketiga mode
3. Wrap UI-nya dengan `useFeature(Feature.namaFeature, profile)`

---

## AppState — Pola State Management

`AppState` adalah satu-satunya state global. Semua data ada di sini.

**Cara akses di widget:**
```dart
final appState = AppStateScope.of(context);
final transactions = appState.transactions;
```

**Pola CRUD yang konsisten** (lihat contoh di `app_state.dart`):
1. Update list in-memory
2. `await _persist()` — tulis ke JSON lokal
3. `notifyListeners()` — update UI
4. Panggil sync service secara non-blocking (`.ignore()` untuk fire-and-forget)

**Pending transaction:** ID dimulai dengan `tx_` = belum di-sync ke Supabase. Setelah sync berhasil, ID diganti UUID dari server.

---

## Pola Sync Service

Setiap domain punya sync service sendiri di `core/services/`. Pola umum:
- `fetchAll()` / `fetchBudgets()` — pull dari Supabase
- `upsert(item)` — insert atau update ke Supabase
- `delete(id)` — hapus dari Supabase

Sync dipanggil dari `AppState.init()` saat login, dan triggered lagi setelah setiap mutasi lokal.

---

## Routing

Routing menggunakan named routes. Semua route string ada di `AppRoutes` (`app/routes.dart`). Untuk navigate:
```dart
Navigator.pushNamed(context, AppRoutes.namaRoute);
// Atau dengan argumen:
Navigator.pushNamed(context, AppRoutes.namaRoute, arguments: data);
```

Untuk menambah route baru:
1. Tambah konstanta di `AppRoutes`
2. Tambah `case` di `AppRouter.onGenerateRoute`
3. Buat screen di `features/nama_feature/`

---

## Monetisasi & Biaya

- Freemium: tier gratis (AdMob) + subscription berbayar
- Retail: Rp 19.000/bulan · Produsen: Rp 49.000/bulan
- Fitur AI (free-text input) **ditunda ke v3+** — biaya API per-request tidak cocok untuk app gratis

---

## Vibe Coding Workflow

### Flow Setiap Sesi
```
/start → diskusi task → implement → /verify
```

### Skill yang Tersedia

| Skill | Kapan dipakai |
|---|---|
| `/start` | **Selalu di awal sesi** — load konteks, tampilkan roadmap, tanya mau ngerjain apa |
| `/add-feature` | Tambah fitur baru — scaffold + checklist integrasi |
| `/fix` | Fix bug — isolate → root cause → fix → verify |
| `/roadmap` | Lihat status fitur dan prioritas |
| `/feature-flags` | Cek atau ubah feature flag per mode |

### Dokumen Referensi (Dibaca Sebelum Implement)
- `docs/BRD.md` — visi produk, 3 segmen, monetisasi, go-public checklist
- `docs/AI_CONTEXT.md` — rules, anti-pattern, pola implementasi
- `docs/USER_FLOW.md` — UX flow per fitur
- `docs/ERD.md` — database schema

### Jangan Langsung Coding
Sebelum implement, selalu tanya:
1. Ini fix bug atau tambah fitur?
2. Fitur ini untuk mode mana? (cek feature flag)
3. Ada dampak ke AppState, model, atau route?

---

## Roadmap Aktif (per 2026-05, hasil diskusi owner)

### Phase 0 — Fondasi Go-Public (prioritas sekarang)
1. **Onboarding Wizard** — redesign dari mode picker ke guided situational wizard
2. **Shopping List Bulk Expense** — input banyak item sekaligus, satu save (KILLER FEATURE)
3. **Personal Mode Lengkap** — budget + spending trend harian
4. **Freemium/Paywall Scaffold** — gating fitur per tier

### Phase 1 — Retail Polish (bulan 1 setelah launch)
- Quick sale improvement, health dashboard per outlet, push notif polish

### Phase 2 — Produsen Complete (kuartal 1)
- HPP intuitif, raw material → produksi → margin flow, laporan profit per batch

Fitur AI input (free-text → parse → Supabase) **ditunda ke v3+**.

---

## Konvensi

- Bahasa komentar: Bahasa Indonesia (lihat komentar existing di `app_state.dart`)
- Amount/saldo disimpan sebagai `int` (rupiah, bukan desimal)
- Tanggal efektif transaksi selalu di-strip time-nya via `_stripTime()`
- ID lokal (sebelum sync) punya prefix: `tx_`, `outlet_`, dll.
