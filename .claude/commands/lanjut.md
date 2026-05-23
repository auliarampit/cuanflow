# /lanjut — Lanjut Kerja Sesi Sebelumnya

Dipakai saat sesi sudah berjalan atau ingin sambung dari pekerjaan terakhir tanpa baca ulang semua dokumen dari awal.

---

Lakukan langkah berikut:

## 1. Cek Status Git

Jalankan secara paralel:
- `git log --oneline -5` — 5 commit terakhir (apa yang sudah selesai?)
- `git status` — ada file yang belum di-commit?
- `git diff --stat` — perubahan apa yang sedang dalam proses?

## 2. Identifikasi Konteks Pekerjaan Terakhir

Dari git log dan status, tentukan:
- Fitur / bug apa yang terakhir dikerjakan?
- Apakah ada pekerjaan yang tergantung (uncommitted, atau di-commit tapi belum selesai secara fitur)?

Jika ada uncommitted changes, baca file-file yang berubah untuk pahami konteks.

## 3. Load Dokumen yang Relevan Saja

Hanya baca dokumen yang relevan dengan pekerjaan terakhir:
- Sedang kerjakan Multi-Space? → Baca `docs/MULTI_SPACE_REFACTOR.md`
- Sedang kerjakan fitur baru? → Baca `docs/BRD.md` bagian roadmap
- Sedang ada isu DB/sync? → Baca `docs/ERD.md` dan `docs/migrations.sql`
- Ragu? → Baca `docs/AI_CONTEXT.md` saja

Jangan baca semua dokumen jika tidak relevan — boros konteks.

## 4. Tampilkan Ringkasan Singkat

Format:

---

### Lanjut dari mana — [tanggal]

**Terakhir dikerjakan:** [nama fitur/bug dari git log]

**Status:** [selesai / masih berjalan / ada yang pending]

**Uncommitted changes:** [ada/tidak — sebutkan file jika ada]

**Selanjutnya:** [saran konkret langkah berikutnya]

---

## 5. Tanya

Satu pertanyaan saja:

> **Lanjut dari sini, atau ada yang ingin diubah arahnya?**

---

Gunakan Bahasa Indonesia. Tetap ringkas.
