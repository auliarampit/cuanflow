# Business Requirements Document (BRD)
## Cuan Flow — Aplikasi Pencatatan Keuangan UMKM

**Versi:** 2.0  
**Tanggal:** April 2026  
**Status:** In Development

---

## 1. Latar Belakang

Mayoritas pelaku UMKM dan individu di Indonesia masih mencatat keuangan secara manual (buku, notes HP) atau tidak mencatat sama sekali. Akibatnya:

- Tidak tahu apakah usaha untung atau rugi
- Uang "hilang" tanpa jejak
- Sulit membuat keputusan bisnis (restok barang, buka cabang, naikkan harga)
- Tidak bisa deteksi kebocoran pengeluaran

**Cuan Flow** hadir sebagai solusi pencatatan yang ringan, cepat, dan relevan untuk dua segmen utama: **pengguna personal** dan **pedagang kecil (UMKM)**.

---

## 2. Tujuan Bisnis

| Tujuan | Indikator Berhasil |
|---|---|
| User bisa catat transaksi < 10 detik | Quick Sale: 2 ketukan |
| User tahu kondisi keuangan hari ini | Home screen: laba/rugi hari ini |
| User tidak lupa utang/piutang | Modul Utang dengan notifikasi jatuh tempo |
| Pedagang tahu stok mana yang mau habis | Alert merah/kuning di Stok Barang |
| User bisa lihat laporan bulanan tanpa akuntansi | Laporan otomatis + export PDF |

---

## 3. Target Pengguna (Personas)

### 👤 Persona A — Pengguna Personal
**Siapa:** Karyawan, mahasiswa, ibu rumah tangga  
**Masalah:** Gaji habis sebelum akhir bulan, tidak tahu uang kemana  
**Tujuan:** Catat pemasukan & pengeluaran harian, pantau sisa uang

**Fitur yang dipakai:**
- Tambah pemasukan & pengeluaran
- Dompet & Rekening (pisah tabungan vs uang jajan)
- Utang & Piutang (pinjam ke teman, dll)
- Transaksi Berulang (cicilan, langganan)
- Budget bulanan
- Laporan bulanan

---

### 🏪 Persona B — Pedagang Kelontong / Warung
**Siapa:** Pemilik warung kelontong, toko sembako, warung makan kecil  
**Masalah:** Tidak tahu omzet harian, stok sering habis tiba-tiba, uang tunai campur dengan uang pribadi  
**Tujuan:** Catat penjualan cepat, pantau stok, tahu untung/rugi per hari

**Fitur yang dipakai (semua fitur Personal +):**
- **Jual Cepat** — tap preset → langsung tercatat (killer feature)
- **Stok Barang** — pantau stok, alert kalau menipis
- **Laporan Terlaris** — kategori penjualan terbanyak
- **Hari Tersibuk** — visualisasi omzet per hari dalam seminggu

---

### 🏢 Persona C — Usaha Menengah (Multi-outlet)
**Siapa:** Pemilik beberapa cabang toko/warung, owner franchise kecil  
**Masalah:** Sulit pantau kinerja tiap cabang, tidak tahu cabang mana yang paling profitable  
**Tujuan:** Pisahkan transaksi per outlet, bandingkan kinerja antar cabang

**Fitur yang dipakai (semua fitur B +):**
- **Kelola Outlet** — daftarkan tiap cabang
- **Filter riwayat per outlet**
- **Chart kontribusi outlet** — porsi pendapatan per cabang
- **Tren pendapatan per outlet** — grafik perbandingan bulanan

---

### 🍳 Persona D — Produsen Kecil (Home Industry)
**Siapa:** Pemilik usaha produksi rumahan (kue, makanan, kerajinan)  
**Masalah:** Tidak tahu harga pokok produksi (HPP), sering jual rugi tanpa sadar  
**Tujuan:** Hitung HPP akurat, tentukan harga jual yang menguntungkan

**Fitur yang dipakai (semua fitur B +):**
- **Kalkulator HPP** — input bahan baku + biaya → dapat HPP per unit
- **Daftar Produk** — simpan hasil kalkulasi HPP per produk

---

## 4. Feature Map (Fitur vs Persona)

| Fitur | Personal | Kelontong | Multi-outlet | Produsen |
|---|:---:|:---:|:---:|:---:|
| Catat Pemasukan & Pengeluaran | ✅ | ✅ | ✅ | ✅ |
| Riwayat Transaksi | ✅ | ✅ | ✅ | ✅ |
| Laporan Bulanan + PDF | ✅ | ✅ | ✅ | ✅ |
| **Dompet & Rekening** | ✅ | ❌ | ❌ | ❌ |
| Utang & Piutang | ✅ | ✅ | ✅ | ✅ |
| Transaksi Berulang | ✅ | ✅ | ✅ | ✅ |
| Budget Bulanan | ✅ | ✅ | ✅ | ✅ |
| **Stok Barang** | ❌ | ✅ | ✅ | ✅ |
| **Jual Cepat** | ❌ | ✅ | ✅ | ✅ |
| **Laporan Terlaris + Hari Tersibuk** | ❌ | ✅ | ✅ | ✅ |
| **Kelola Outlet** | ❌ | ❌ | ✅ | ❌ |
| **Chart Perbandingan Outlet** | ❌ | ❌ | ✅ | ❌ |
| **Kalkulator HPP** | ❌ | ❌ | ❌ | ✅ |

> **Cara aktifkan:** Pengaturan → FITUR AKTIF → toggle on/off kapan saja

---

## 5. Business Rules

### 5.1 Mode & Feature Flag
- Tidak ada "mode" yang kaku — sistem berbasis **feature flag per fitur**
- `isBusinessMode = featureOutlets OR featureBudget OR featureProduct`
- Ketika `isBusinessMode = true`, fitur Stok & Jual Cepat otomatis muncul
- User bisa ubah kapan saja di **Pengaturan → Fitur Aktif**

### 5.2 Kalkulasi Saldo
- Saldo dompet = `saldo_awal + Σ(pemasukan) - Σ(pengeluaran)` untuk dompet tersebut
- Tidak ada field "saldo tersimpan" — dihitung real-time dari transaksi
- Total saldo = jumlah semua dompet yang terdaftar

### 5.3 Transaksi Berulang
- Dieksekusi otomatis saat app dibuka
- Cek: `next_execute <= hari_ini` → buat transaksi baru → update `next_execute`
- Frekuensi: Harian / Mingguan / Bulanan (dengan pilih tanggal 1–28)

### 5.4 Stok Barang
- **Hijau (Aman):** `currentStock > minStock`
- **Kuning (Menipis):** `currentStock <= minStock AND minStock > 0`
- **Merah (Habis):** `currentStock <= 0`
- Update stok: manual (+1 / -1 / +10 dari UI), **tidak** terhubung otomatis ke Jual Cepat

### 5.4b Dompet & Rekening
- Hanya tersedia untuk **pengguna personal** (`isBusinessMode = false`)
- Untuk bisnis: pencatatan kas tidak dipisah per dompet — terlalu kompleks tanpa integrasi payment gateway
- Akan dipertimbangkan kembali saat adopsi POS + payment gateway

### 5.5 Jual Cepat
- Tap preset → isi qty → konfirmasi → income tercatat
- Tidak mengurangi stok secara otomatis (scope POS belum tercapai)
- Pemilihan dompet di-disable sementara (`_kEnableWalletSelector = false`)

### 5.6 Utang & Piutang
- `iOwe` = saya berhutang ke orang lain
- `theyOwe` = orang lain berhutang ke saya
- Tandai lunas → data tetap tersimpan (tidak dihapus), hanya flag `is_paid = true`

---

## 6. Non-Functional Requirements

| Aspek | Ketentuan |
|---|---|
| **Offline-first** | Semua data tersimpan lokal (JSON), sync ke Supabase saat online |
| **Keamanan** | PIN 6 digit untuk masuk app |
| **Bahasa** | Indonesia & English (toggle di Pengaturan) |
| **Platform** | Android (utama), iOS (secondary) |
| **Iklan** | Native Ad (Google Mobile Ads) di beberapa layar |

---

## 7. Out of Scope (Sengaja Tidak Dibangun)

| Yang Tidak Dibangun | Alasan |
|---|---|
| Barcode scanner untuk stok | Butuh hardware/kamera integration — scope POS |
| Payment gateway / QRIS integration | Butuh lisensi & backend payment — scope POS |
| Laporan pajak / PPh | Terlalu kompleks, bukan kebutuhan UMKM kecil |
| Multi-user / karyawan login | Manajemen permission kompleks |
| Stok otomatis berkurang saat jual | Perlu integrasi barcode — next phase |
| Dompet & Rekening untuk mode bisnis | Tidak relevan tanpa integrasi payment gateway / POS |
| Wallet selector di Jual Cepat | Overkill untuk pencatatan sederhana — ditunda |
