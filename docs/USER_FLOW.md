# User Flow & Business Flow
## Cuan Flow — Panduan Penggunaan per Persona

**Versi:** 2.1 | **Tanggal:** April 2026

> Preview diagram: buka file ini di VSCode → klik kanan → **"Open Preview"**, atau tekan `Cmd+Shift+V` (Mac) / `Ctrl+Shift+V` (Windows).  
> Butuh ekstensi **Markdown Preview Mermaid Support** (ID: `bierner.markdown-mermaid`) jika diagram tidak tampil.

---

## 1. Alur Onboarding (Pertama Kali)

```mermaid
flowchart TD
    A([Buka App]) --> B[Splash Screen]
    B --> C{Sudah punya akun?}
    C -- Ya --> D[Login\nemail + PIN]
    C -- Tidak --> E[Register\nnama + email + PIN 6 digit]
    D --> H([Home Screen])
    E --> F[Pilih Mode Penggunaan]

    F --> G1[Personal\nCatat Keuangan Pribadi]
    F --> G2[Bisnis / Store\nPemilik Toko / Warung]
    F --> G3[Produksi\nHome Industry]

    G1 --> H

    G2 --> G2a{Fitur tambahan?}
    G2a --> G2b["[✓] Budget & Target\n[ ] Multi Outlet\n[ ] HPP & Produk"]
    G2b --> H

    G3 --> G3a{Fitur tambahan?}
    G3a --> G3b["HPP, Bahan Baku, Batch = ON otomatis\n[✓] Budget & Target (opsional)\n[ ] Multi Outlet (opsional)"]
    G3b --> H
```

> **Ubah kapan saja:** Profil → Atur Fitur → toggle on/off

---

## 2. Flow Personal — Sehari-hari

### 2a. Cek Kondisi Keuangan (Pagi)

```mermaid
flowchart TD
    A([Buka App]) --> B[Home Screen]
    B --> C["Laba/Sisa Hari Ini\n🟢 positif / 🔴 minus"]
    B --> D["Saldo Total\n→ tap untuk detail per dompet"]
    B --> E["Geser card → perbandingan\npemasukan vs pengeluaran minggu ini"]
```

### 2b. Catat Pengeluaran

```mermaid
flowchart TD
    A([Home]) --> B["Tap tombol Pengeluaran 🔴"]
    B --> C[Input nominal\nvia kalkulator angka]
    C --> D[Pilih kategori\nMakan, Transport, dll]
    D --> E[Isi keterangan\nopsional]
    E --> F{Punya dompet?}
    F -- Ya --> G[Pilih dompet]
    F -- Tidak --> H
    G --> H[SIMPAN ✓]
    H --> I([Balik ke Home\nsaldo terupdate])
```

### 2c. Cek Laporan Akhir Bulan

```mermaid
flowchart TD
    A([Tab Laporan]) --> B["Navigasi bulan ← →"]
    B --> C[Total Pemasukan\nvs Pengeluaran]
    C --> D[Pantau Budget\njika featureBudget aktif]
    D --> E{Export?}
    E -- Ya --> F["Export PDF\nShare WhatsApp / simpan"]
    E -- Tidak --> G([Selesai])
    F --> G
```

---

## 3. Flow Store (Bisnis/Kelontong) — Sehari-hari

### 3a. Buka Warung, Cek Kondisi

```mermaid
flowchart TD
    A([Buka App]) --> B[Home Screen]
    B --> C{"Alert stok?"}
    C -- Ya --> D["⚠ N barang menipis/habis"]
    D --> E[Stok Barang\nlihat daftar merah/kuning/hijau]
    E --> F[Keputusan: hubungi supplier]
    C -- Tidak --> G[Lihat laba kemarin\nvs hari sebelumnya]
```

### 3b. Catat Penjualan (Jual Cepat — 2 Ketukan)

```mermaid
flowchart TD
    A([Home]) --> B["Tap Jual Cepat 🔵"]
    B --> C[Grid Preset\nIndomie, Es Teh, Rokok, dll]
    C --> D[Tap salah satu preset]
    D --> E["Dialog Konfirmasi\nNama · Harga · Qty · Total"]
    E --> F{Qty benar?}
    F -- Ubah --> G["[−] qty [+]"]
    G --> E
    F -- Benar --> H["Tap Catat Penjualan"]
    H --> I(["✓ Snackbar hijau\nNama — Rp xxx dicatat"])
```

### 3c. Update Stok Saat Terima Supplier

```mermaid
flowchart TD
    A([Profil → Stok Barang]) --> B[Cari item]
    B --> C["Stok sekarang: 5"]
    C --> D["Tap [+10] → stok: 15"]
    D --> E["Tap [+10] → stok: 25"]
    E --> F(["✓ Tersimpan otomatis"])
```

### 3d. Analisa Bisnis Akhir Bulan

```mermaid
flowchart TD
    A([Tab Laporan]) --> B[Omzet bulan ini\nvs bulan lalu]
    B --> C[Kategori Terlaris\n→ Rokok paling banyak]
    C --> D[Hari Tersibuk\n→ Sabtu & Minggu ⭐]
    D --> E[Rincian Pengeluaran\nOperasional vs Pembelian Stok]
    E --> F["Export PDF untuk arsip"]
```

---

## 4. Flow Multi-outlet (Store + featureOutlets)

```mermaid
flowchart TD
    A([Profil → Kelola Outlet]) --> B["Tap + Tambah Outlet"]
    B --> C["Isi nama: Cabang Barat"]
    C --> D(["✓ Tersimpan → muncul di dropdown"])

    E([Home → Pemasukan]) --> F[Input nominal + kategori]
    F --> G["Pilih Outlet: Cabang Pusat ▼"]
    G --> H(["✓ Tersimpan dengan tag outlet"])

    I([Tab Laporan]) --> J["Chart Kontribusi Outlet\npie chart porsi pendapatan"]
    J --> K["Chart Tren per Outlet\nline chart perbandingan bulanan"]
```

---

## 5. Flow Produksi (Mode Production)

### 5a. Kelola Bahan Baku

```mermaid
flowchart TD
    A([Profil → Bahan Baku]) --> B["Daftar bahan baku\n🔴 habis / 🟡 menipis / 🟢 aman"]
    B --> C{Aksi}
    C -- Tambah --> D["Isi: nama, satuan, harga/unit\nstok awal, min stok, supplier"]
    D --> E(["✓ Bahan baku ditambahkan"])
    C -- Edit Stok --> F["Update current_stock"]
    F --> E
    C -- Cari --> G["Filter by nama"]
    G --> B
```

### 5b. Hitung HPP & Simpan Produk

```mermaid
flowchart TD
    A([Profil → Kelola Produk & HPP]) --> B["Tap + Produk Baru"]
    B --> C["Nama: Kue Brownies\nHasil Produksi: 20 potong"]
    C --> D[Tambah Bahan Baku]
    D --> D1["Tepung 500gr → Rp 8.000"]
    D --> D2["Telur 3 butir → Rp 7.500"]
    D --> D3["Coklat Batang → Rp 15.000"]
    D1 & D2 & D3 --> E[Tambah Biaya Lain]
    E --> E1["Gas LPG → Rp 5.000"]
    E --> E2["Kemasan → Rp 6.000"]
    E1 & E2 --> F["Kalkulasi Otomatis"]
    F --> G["Total Biaya: Rp 41.500\nHPP/unit: Rp 2.075"]
    G --> H["Input Harga Jual: Rp 5.000"]
    H --> I["Profit/unit: Rp 2.925\nMargin: 141%"]
    I --> J(["Simpan Produk ✓"])
```

### 5c. Catat Batch Produksi

```mermaid
flowchart TD
    A([Profil → Batch Produksi]) --> B["Tap + Batch Baru"]
    B --> C["Pilih Produk: Kue Brownies"]
    C --> D["Tanggal produksi: hari ini"]
    D --> E["Qty diproduksi: 30 potong"]
    E --> F["Pilih bahan baku yang dipakai\n(dari daftar raw_materials)"]
    F --> G["Input qty masing-masing bahan"]
    G --> H["HPP/unit batch: dihitung otomatis\ntotalMaterialCost / qtyProduced"]
    H --> I(["Simpan Batch ✓"])
```

### 5d. Analitik Produk

```mermaid
flowchart TD
    A([Profil → Analitik Produk]) --> B[Pilih produk]
    B --> C["Statistik penjualan produk"]
    C --> D["Margin per periode"]
    D --> E["Trend qty terjual"]
    E --> F["Breakeven analysis"]
```

---

## 6. Flow Utang & Piutang

```mermaid
flowchart TD
    A([Profil → Utang & Piutang]) --> B{Tab}
    B -- Hutang Saya --> C["iOwe: saya berhutang"]
    B -- Piutang Saya --> D["theyOwe: mereka berhutang"]

    C --> E["Tap +\nNama · Jumlah · Jatuh Tempo"]
    D --> E

    E --> F(["✓ Muncul di list\ndengan countdown jatuh tempo"])

    F --> G{"Lunas?"}
    G -- Ya --> H["Tap Tandai Lunas"]
    H --> I(["is_paid = true\nData tetap tersimpan"])
```

---

## 7. Flow Transaksi Berulang

```mermaid
flowchart TD
    A([Profil → Transaksi Berulang]) --> B["Tap + Tambah"]
    B --> C["Nama: Bayar Netflix\nJumlah: Rp 54.000\nTipe: Pengeluaran\nKategori: Hiburan\nFrekuensi: Bulanan\nTanggal: 15"]
    C --> D(["✓ next_execute = tgl 15 bulan depan"])

    E([Buka App tgl 15]) --> F{next_execute <= hari ini?}
    F -- Ya --> G["Buat transaksi otomatis\nBayar Netflix Rp 54.000"]
    G --> H["Update next_execute → bulan depan"]
    H --> I(["Muncul di Riwayat ✓"])
    F -- Tidak --> J([Skip])
```

---

## 8. Flow Atur Fitur (Manage Features)

```mermaid
flowchart TD
    A([Profil → Atur Fitur]) --> B[Halaman Atur Fitur]
    B --> C["LAPORAN & INSIGHT\n▶ Kategori Terlaris\n▶ Hari Tersibuk"]
    B --> D["FITUR TRANSAKSI\n▶ Jual Cepat"]
    B --> E["FITUR BISNIS\n▶ Budget & Target\n▶ Multi Outlet"]
    B --> F["FITUR PRODUKSI\n▶ HPP & Produk\n▶ Bahan Baku & Batch"]

    C & D & E & F --> G[Toggle ON/OFF]
    G --> H["Profile diupdate via updateProfile()"]
    H --> I(["UI refresh otomatis\nMenu muncul/hilang sesuai flag"])
```

---

## 9. Navigasi App (Bottom Navigation)

```mermaid
flowchart LR
    Home["🏠 Beranda\n─────────────\nRingkasan hari ini\nSaldo total\nAlert stok\nTombol: Pemasukan\nTombol: Pengeluaran\nTombol: Jual Cepat\n(jika featureQuickSale)"]
    History["📋 Riwayat\n─────────────\nFilter waktu\nFilter outlet\nEdit & hapus\nExport PDF"]
    Report["📊 Laporan\n─────────────\nNavigasi bulan\nTotal in/out/laba\nBudget progress\nBar chart harian\nKategori Terlaris\nHari Tersibuk\nChart outlet"]
    Profile["👤 Profil\n─────────────\nPengaturan Akun\nDompet & Rekening\nUtang & Piutang\nTransaksi Berulang\nBudget & Target\nStok Barang\nJual Cepat\nKelola Outlet\nProduk & HPP\nBahan Baku\nBatch Produksi\nAnalitik Produk\nKelola Kategori\nAtur Fitur\nNotifikasi\nGanti PIN\nBahasa\nTentang App\nKeluar"]

    Home --- History
    History --- Report
    Report --- Profile
```

---

## 10. Alur Sinkronisasi Data

```mermaid
sequenceDiagram
    actor User
    participant App as Flutter App\n(Local JSON)
    participant UI as UI Layer\n(ChangeNotifier)
    participant Supabase

    User->>App: Tambah/Edit/Hapus data
    App->>App: Simpan ke Local JSON
    App->>UI: Notifikasi update
    UI->>User: Tampilan terupdate (instant)

    App-->>Supabase: Push (background, fire & forget)
    alt Sukses
        Supabase-->>App: ID lokal → UUID server
    else Gagal / Offline
        App->>App: Queue untuk retry
    end

    Note over App,Supabase: Saat Login / Buka App
    Supabase-->>App: Pull data terbaru
    App->>App: Merge dengan data lokal
```

> **Prinsip:** App selalu bisa dipakai offline. Local = source of truth untuk UI. Supabase = backup & sync antar device.
