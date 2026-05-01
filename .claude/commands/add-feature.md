# /add-feature — Panduan Menambah Fitur Baru

Argumen: nama fitur yang ingin ditambah (contoh: `/add-feature shopping-list`)

Nama fitur: $ARGUMENTS

---

Bantu developer menambah fitur baru ke app cari_untung dengan mengikuti pola yang sudah ada.

## Langkah yang harus dilakukan:

### 1. Analisis Konteks
- Baca `CLAUDE.md` untuk memahami arsitektur
- Baca `lib/src/core/config/feature_config.dart` untuk memahami feature flags
- Cek apakah fitur ini perlu feature flag (hanya tersedia di mode tertentu) atau universal

### 2. Struktur File yang Perlu Dibuat

Jelaskan file-file yang perlu dibuat/dimodifikasi:

```
lib/src/features/<nama_feature>/
├── <nama>_screen.dart      # Main screen widget
└── widgets/                # Sub-widgets jika perlu (opsional)

lib/src/core/models/        # Model baru jika perlu
lib/src/core/services/      # Sync service baru jika perlu
```

### 3. Checklist Integrasi

Tunjukkan secara eksplisit:

- [ ] **Route**: Tambah konstanta di `lib/src/app/routes.dart` dan case di `lib/src/app/router.dart`
- [ ] **AppState**: Tambah list, getter, dan CRUD methods di `lib/src/core/state/app_state.dart` (ikuti pola existing: update list → `_persist()` → `notifyListeners()` → sync.ignore())
- [ ] **Persistence**: Tambah key ke `_persist()` map di AppState
- [ ] **Feature Flag** (jika perlu): Tambah entry di `Feature` enum dan `featureConfig` map di `feature_config.dart`
- [ ] **Navigation**: Tambah entry point di screen yang relevan (home, profile, dll)

### 4. Pola Kode

Tunjukkan contoh konkret dengan kode, mengikuti pola yang sudah ada di project:
- Widget mengakses state via `AppStateScope.of(context)`
- Feature check via `useFeature(Feature.namaFeature, appState.profile)`
- Amount selalu `int` (rupiah)
- Tanggal selalu via `_stripTime()`

### 5. Estimasi Effort
Berikan estimasi: kecil (< 1 hari) / sedang (1-3 hari) / besar (> 3 hari)

---

Gunakan bahasa Indonesia untuk penjelasan. Kode tetap dalam bahasa Inggris/Dart.
