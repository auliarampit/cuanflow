# CuanFlow

**CuanFlow** (sebelumnya *CatatUntung*) adalah aplikasi manajemen keuangan pribadi berbasis Flutter yang dirancang untuk membantu pengguna mencatat pemasukan dan pengeluaran dengan mudah, serta memantau kesehatan finansial melalui laporan bulanan yang informatif.

## 📱 Fitur Utama

*   **Pencatatan Transaksi**: Catat pemasukan dan pengeluaran harian dengan cepat.
*   **Kategori Transaksi**: Kelompokkan transaksi berdasarkan kategori untuk analisis yang lebih baik.
*   **Riwayat Transaksi**: Lihat riwayat transaksi lengkap dengan filter per bulan.
*   **Laporan Keuangan**: Ringkasan total pemasukan, pengeluaran, dan keuntungan bersih.
*   **Ekspor PDF**: Unduh laporan keuangan bulanan dalam format PDF siap cetak.
*   **Keamanan**: Fitur PIN untuk melindungi data keuangan Anda.
*   **Multi-bahasa**: Mendukung Bahasa Indonesia (ID) dan Bahasa Inggris (EN).
*   **Tema Gelap**: Tampilan antarmuka yang nyaman di mata (Dark Mode).

## 🛠 Teknologi yang Digunakan

*   **Framework**: [Flutter](https://flutter.dev/) (SDK ^3.10.3)
*   **Bahasa**: Dart
*   **State Management**: `ChangeNotifier` / `Provider` (Custom AppState)
*   **Penyimpanan Lokal**: `shared_preferences` / JSON file-based storage (via `LocalDatabase`)
*   **PDF Generation**: `pdf` & `printing` packages
*   **Localization**: `flutter_localizations`, `intl`

## 📂 Struktur Proyek

Proyek ini menggunakan arsitektur berbasis fitur (*Feature-First Architecture*) untuk skalabilitas dan kemudahan pemeliharaan.

```
lib/src/
├── app/                 # Konfigurasi level aplikasi (App Widget, Router)
├── core/                # Komponen inti yang digunakan di seluruh aplikasi
│   ├── formatters/      # Formatter mata uang dan input
│   ├── localization/    # Konfigurasi bahasa dan terjemahan
│   ├── models/          # Model data (MoneyTransaction, UserProfile, dll)
│   ├── services/        # Layanan eksternal (PDF Service, dll)
│   ├── state/           # State management global (AppState)
│   ├── storage/         # Implementasi penyimpanan data lokal
│   ├── theme/           # Konfigurasi tema dan warna aplikasi
│   └── ui/              # Widget UI yang dapat digunakan kembali
└── features/            # Fitur-fitur utama aplikasi
    ├── auth/            # Login dan PIN Input
    ├── history/         # Layar Riwayat Transaksi
    ├── home/            # Dashboard dan Shell Navigasi
    ├── profile/         # Profil Pengguna
    ├── settings/        # Pengaturan Aplikasi
    ├── splash/          # Layar Pembuka (Splash Screen)
    └── transactions/    # Fitur Tambah Pemasukan/Pengeluaran
```

## 🚀 Cara Menjalankan Aplikasi

Ikuti langkah-langkah berikut untuk menjalankan proyek ini di lingkungan lokal Anda.

### Prasyarat

*   Flutter SDK terinstal (versi 3.10.3 atau lebih baru).
*   Android Studio / VS Code dengan ekstensi Flutter/Dart.
*   Emulator Android/iOS atau perangkat fisik.

### Langkah Instalasi

1.  **Clone Repository** (jika ada) atau buka folder proyek.

2.  **Install Dependencies**:
    Jalankan perintah berikut di terminal root proyek:
    ```bash
    flutter pub get
    ```

3.  **Jalankan Aplikasi**:
    ```bash
    flutter run
    ```

### Generate Laporan PDF (Khusus iOS/macOS)

Untuk fitur ekspor PDF di macOS/iOS, pastikan konfigurasi di `Info.plist` sudah sesuai untuk izin akses file jika diperlukan (biasanya ditangani oleh `path_provider` dan `printing` package).

### Build APK Release (Lebih Ringan)

Untuk menghasilkan file APK yang lebih kecil (sekitar 15-20 MB) dan siap install:

```bash
flutter build apk --release --split-per-abi
```

File APK hasil build akan berada di:
`build/app/outputs/flutter-apk/`

*   Gunakan `app-arm64-v8a-release.apk` untuk sebagian besar HP Android modern.
*   Gunakan `app-armeabi-v7a-release.apk` untuk HP Android model lama.

## 🌍 Lokalisasi

Aplikasi ini menggunakan file JSON untuk menyimpan string terjemahan.
File lokasi berada di: `assets/i18n/`

*   `id.json`: Bahasa Indonesia
*   `en.json`: Bahasa Inggris

Untuk menambahkan bahasa baru, tambahkan file JSON baru dan daftarkan di `AppLocalizations`.

## 🤝 Kontribusi

Jika Anda ingin berkontribusi pada proyek ini, silakan buat *Pull Request* dengan deskripsi perubahan yang jelas. Pastikan kode Anda mengikuti prinsip *Clean Code* yang diterapkan dalam proyek ini.

## 📝 Lisensi

Proyek ini dibuat untuk tujuan pembelajaran dan penggunaan pribadi.
