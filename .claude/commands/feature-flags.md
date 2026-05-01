# /feature-flags — Analisis & Manajemen Feature Flags

Tampilkan status lengkap feature flags project cari_untung dan bantu manage perubahan.

## Yang harus dilakukan:

### 1. Baca file feature config
Baca `lib/src/core/config/feature_config.dart` secara lengkap.

### 2. Tampilkan tabel status

Tampilkan tabel ini:

| Feature | personal | store | production | Keterangan |
|---|---|---|---|---|
| (isi dari featureConfig map) | ✅/❌ | ✅/❌ | ✅/❌ | description dari enum |

### 3. Jika ada argumen ($ARGUMENTS), jalankan sesuai intent:

**Jika argumen berupa nama fitur** (contoh: `quickSale`, `debt`):
- Jelaskan fitur tersebut aktif di mode mana saja
- Tunjukkan cara menggunakannya di widget (`useFeature(Feature.X, profile)`)
- Tunjukkan di mana fitur ini dipakai di codebase (cari dengan grep)

**Jika argumen berisi kata "tambah" atau "add"** (contoh: `tambah shoppingList`):
- Tampilkan kode perubahan yang perlu dilakukan di `feature_config.dart`:
  1. Entry baru di enum `Feature`
  2. Entry di `featureConfig` untuk ketiga mode
  3. Entry di `featureMapping` jika relevan
- Tanyakan konfirmasi sebelum menulis ke file

**Jika argumen berisi kata "aktifkan" atau "enable"** (contoh: `aktifkan budget di store`):
- Tunjukkan perubahan spesifik di `featureConfig` map
- Tanyakan konfirmasi sebelum menulis

### 4. Jika tidak ada argumen
Tampilkan tabel di atas saja, plus ringkasan:
- Berapa total fitur
- Fitur mana yang paling restricted (hanya 1 mode)
- Fitur mana yang belum dipakai/masih TODO

Gunakan bahasa Indonesia. Jawab ringkas.
