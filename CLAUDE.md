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

- App gratis dengan Google AdMob
- Tidak ada subscription atau in-app purchase saat ini
- Fitur AI (free-text input) **ditunda** karena biaya API per-request tidak cocok untuk app gratis

---

## Roadmap Aktif (per 2026-04)

Prioritas saat ini (dari diskusi dengan owner):

1. **Quick Amount Shortcuts** (effort: kecil) — tombol `+5rb` `+10rb` `+50rb` di form input
2. **Recent/Frequent Items** (effort: sedang) — 5 item yang sering diinput muncul saat buka form
3. **Budget Alert Notification** (effort: sedang) — push notif saat budget hampir habis
4. **Shopping List → Draft Transaksi** (effort: besar, HOOK UTAMA) — buat daftar belanja, centang saat belanja, auto-generate transaksi

Fitur AI input (free-text → parse → Supabase) **ditunda ke v3+**.

---

## Konvensi

- Bahasa komentar: Bahasa Indonesia (lihat komentar existing di `app_state.dart`)
- Amount/saldo disimpan sebagai `int` (rupiah, bukan desimal)
- Tanggal efektif transaksi selalu di-strip time-nya via `_stripTime()`
- ID lokal (sebelum sync) punya prefix: `tx_`, `outlet_`, dll.
