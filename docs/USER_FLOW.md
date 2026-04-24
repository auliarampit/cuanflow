# User Flow & Business Flow
## Cuan Flow — Panduan Penggunaan per Persona

---

## Alur Onboarding (Pertama Kali)

```
Buka App
    │
    ▼
Splash Screen (logo + versi)
    │
    ▼
Sudah punya akun? ──Ya──► Login (email/HP + PIN)
    │                           │
    Tidak                       ▼
    │                      Home Screen
    ▼
Register (nama + PIN 6 digit)
    │
    ▼
Pilih Mode Penggunaan
    ├── Catat Keuangan Pribadi  ──► langsung ke Home
    └── Pemilik Usaha           ──► pilih fitur yang dibutuhkan
                                     ├── [✓] Budget & Target
                                     ├── [ ] Kelola Outlet
                                     └── [ ] Kalkulator HPP
                                     ──► Home Screen
```

> **Ubah mode kapan saja:** Pengaturan → FITUR AKTIF → toggle on/off

---

## Flow A — Pengguna Personal (Sehari-hari)

### Pagi: Cek kondisi keuangan
```
Buka App
    │
    ▼
Home Screen
    ├── Lihat "Laba/Sisa Hari Ini" → angka hijau = sisa positif, merah = minus
    ├── Lihat "Saldo Total" → tap untuk detail per dompet
    └── Geser card untuk lihat perbandingan minggu ini
```

### Siang: Catat pengeluaran
```
Home → tombol "Pengeluaran" (merah)
    │
    ▼
Input nominal (kalkulator angka)
    │
    ▼
Pilih kategori (Makan, Transport, dll)
    │
    ▼
Isi keterangan (opsional)
    │
    ▼
Pilih dompet (jika ada)
    │
    ▼
SIMPAN ✓  →  langsung balik ke Home, saldo terupdate
```

### Akhir bulan: Cek laporan
```
Tab Laporan
    ├── Navigasi bulan (< >)
    ├── Lihat Total Pemasukan vs Pengeluaran
    ├── Lihat Sisa Uang bulan ini
    ├── Pantau progress Budget (jika aktif)
    └── Export PDF (share ke WhatsApp, simpan, dll)
```

---

## Flow B — Pedagang Kelontong (Sehari-hari)

### Pagi: Buka warung, cek kondisi
```
Buka App
    │
    ▼
Home Screen
    ├── ⚠ Alert kuning: "3 barang stok menipis" → tap untuk lihat
    └── Lihat laba kemarin vs hari sebelumnya
    (Saldo dompet tidak ditampilkan — bisnis tidak pakai fitur dompet)
    │
    ▼ (jika ada alert stok)
Stok Barang
    ├── Lihat daftar: merah (habis), kuning (menipis), hijau (aman)
    └── Keputusan: hubungi supplier untuk restok
```

### Saat jualan: Catat penjualan (2 ketukan)
```
Home → tombol "Jual Cepat" (biru)
    │
    ▼
Grid Preset (Indomie, Es Teh, Rokok Sampoerna, dll)
    │
    ▼ (tap salah satu, misal "Rokok Sampoerna")
Dialog konfirmasi:
    ├── Nama: Rokok Sampoerna
    ├── Harga: Rp 26.000
    ├── Jumlah: [−] 1 [+]  ← ubah jika beli lebih dari 1
    └── Total: Rp 26.000
    │
    ▼ (ketuk "Catat Penjualan")
✓ Tercatat! → muncul snackbar hijau "Rokok Sampoerna — Rp 26.000 dicatat"
```

### Saat terima kiriman supplier: Update stok
```
Profil → Stok Barang
    │
    ▼
Cari item (misal: Indomie Goreng, stok sekarang 5)
    │
    ▼
Tap [+10] → stok jadi 15
Tap [+10] → stok jadi 25
    │
    ▼
✓ Tersimpan otomatis
```

### Saat pelanggan hutang: Catat piutang
```
Profil → Utang & Piutang
    │
    ▼
Tab "Piutang Saya" → tombol +
    │
    ▼
Isi: Nama (Pak Budi), Jumlah (75.000), Jatuh Tempo (30 April)
    │
    ▼
✓ Tersimpan → muncul di list dengan countdown jatuh tempo
    │
    ▼ (saat Pak Budi bayar)
Tap "Tandai Lunas" → ✓
```

### Akhir bulan: Analisa bisnis
```
Tab Laporan
    ├── Lihat omzet bulan ini vs bulan lalu
    ├── Kategori Terlaris → "Rokok" paling banyak = jangan sampai stok habis
    ├── Hari Tersibuk → Sabtu & Minggu ⭐ = tambah stok sebelum weekend
    ├── Rincian Pengeluaran → Operasional vs Pembelian Stok
    └── Export PDF untuk arsip
```

---

## Flow C — Multi-outlet

### Setup outlet baru
```
Profil → Kelola Outlet → [+]
    │
    ▼
Isi nama outlet (misal: "Cabang Barat")
    │
    ▼
✓ Tersimpan → muncul di dropdown filter
```

### Catat transaksi per outlet
```
Home → Pemasukan
    │
    ▼
Input nominal + kategori
    │
    ▼
Pilih Outlet: [Cabang Pusat ▼]
    │
    ▼
✓ Tersimpan dengan tag outlet
```

### Bandingkan kinerja antar cabang
```
Tab Laporan → (semua outlet dipilih)
    ├── Chart "Kontribusi Outlet" → pie chart porsi pendapatan
    └── Chart "Tren per Outlet" → line chart perbandingan bulanan
```

---

## Flow D — Produsen (HPP Calculator)

### Hitung HPP produk baru
```
Profil → Kelola Produk & HPP → [+]
    │
    ▼
Nama Produk: "Kue Brownies"
Hasil Produksi: 20 potong
    │
    ▼
Tambah Bahan Baku:
    ├── Tepung Terigu 500gr → Rp 8.000
    ├── Telur 3 butir → Rp 7.500
    ├── Coklat Batang → Rp 15.000
    └── [+ Tambah Item]
    │
    ▼
Tambah Biaya Lain:
    ├── Gas LPG (alokasi) → Rp 5.000
    └── Kemasan → Rp 6.000
    │
    ▼
Hasil:
    ├── Total Biaya: Rp 41.500
    ├── HPP per potong: Rp 2.075
    ├── Input Harga Jual: Rp 5.000
    ├── Profit per potong: Rp 2.925
    └── Margin: 141%
    │
    ▼
Simpan Produk ✓
```

---

## Flow: Transaksi Berulang (Semua User)

### Setup (sekali saja)
```
Profil → Transaksi Berulang → [+]
    │
    ▼
Nama: "Bayar Netflix"
Jumlah: Rp 54.000
Tipe: Pengeluaran
Kategori: Hiburan
Frekuensi: Bulanan
Tanggal: 15
    │
    ▼
✓ Tersimpan → next_execute = tanggal 15 bulan depan
```

### Eksekusi otomatis
```
Buka App (tanggal 15)
    │
    ▼ (di background, saat init)
App cek: next_execute <= hari ini?
    ├── Ya → buat transaksi "Bayar Netflix Rp 54.000"
    │         update next_execute ke bulan depan
    └── Tidak → skip
    │
    ▼
User buka Riwayat → transaksi sudah ada ✓
```

---

## Navigasi App (Bottom Navigation)

```
┌─────────────────────────────────────────────┐
│                  HOME SCREEN                │
│  - Ringkasan hari ini & minggu ini          │
│  - Total saldo semua dompet                 │
│  - Alert stok (bisnis)                      │
│  - Tombol: Pemasukan | Pengeluaran          │
│  - Tombol: Jual Cepat (bisnis)              │
├──────────┬──────────┬──────────┬────────────┤
│  Beranda │ Riwayat  │ Laporan  │   Profil   │
│    🏠    │    📋    │    📊    │    👤      │
└──────────┴──────────┴──────────┴────────────┘
```

### Tab Riwayat
- Filter: Hari Ini / Kemarin / Minggu Ini / Bulan Ini / Custom
- Filter outlet (jika featureOutlets)
- Edit & hapus transaksi
- Export PDF

### Tab Laporan
- Navigasi per bulan
- Kartu: Total Pemasukan, Pengeluaran, Laba/Sisa
- Rincian Pengeluaran (Operasional vs Stok)
- Budget progress (jika aktif)
- Bar chart harian/mingguan
- **Kategori Terlaris** (bisnis)
- **Hari Tersibuk** (bisnis)
- Chart outlet (jika featureOutlets + ≥2 outlet)

### Tab Profil
- Pengaturan Akun (nama, bisnis, WA)
- Dompet & Rekening
- Utang & Piutang
- Transaksi Berulang
- Budget & Target
- Stok Barang (bisnis)
- Jual Cepat (bisnis)
- Kelola Outlet (featureOutlets)
- Kelola Produk & HPP (featureProduct)
- Kelola Kategori
- Notifikasi & Pengingat
- Ganti PIN
- Bahasa
- Tentang Aplikasi
- Keluar

---

## Alur Sinkronisasi Data

```
Aksi User (tambah/edit/hapus)
    │
    ▼
Simpan ke Local Storage (JSON) ← Langsung, offline-safe
    │
    ▼
Notifikasi UI update (ChangeNotifier)
    │
    ▼ (background, fire & forget)
Push ke Supabase
    ├── Sukses → ID lokal diganti UUID server
    └── Gagal  → tetap di lokal, retry saat online

Login / Buka App:
    └── Pull dari Supabase → merge dengan data lokal
```

> **Prinsip:** App selalu bisa dipakai offline. Data lokal adalah source of truth untuk UI. Supabase adalah backup & sync antar device.
