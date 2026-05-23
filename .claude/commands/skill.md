# /skill — CuanFlow Dev Assistant

Argumen: $ARGUMENTS

Parse argumen: **kata pertama = PERINTAH**, sisanya = DETAIL.

Jika tidak ada argumen → tampilkan daftar perintah di bawah dan tunggu pilihan user.

---

## Daftar Perintah

| Perintah | Contoh | Fungsi |
|----------|--------|--------|
| `start` | `/skill start` | Mulai sesi baru, load konteks penuh |
| `lanjut` | `/skill lanjut` | Sambung dari pekerjaan sebelumnya |
| `fix` | `/skill fix tombol simpan tidak merespons` | Perbaiki bug |
| `add` | `/skill add shopping list bulk input` | Tambah fitur baru |
| `diskusi` | `/skill diskusi gimana handle outlet schedule` | Diskusi arsitektur/desain |
| `roadmap` | `/skill roadmap` | Lihat status fitur & prioritas |
| `flags` | `/skill flags` | Cek atau ubah feature flags |

---

## Routing — ikuti HANYA blok yang sesuai PERINTAH

---

### `start` — Mulai Sesi Baru

**Load (semua, tapi selektif per section):**
- `docs/BRD.md` — baca hanya section **Roadmap & Phase aktif**
- `docs/MULTI_SPACE_REFACTOR.md` — baca hanya section **Checklist Implementasi**
- `lib/src/core/config/feature_config.dart` — baca penuh (file kecil)
- Jalankan: `git log --oneline -7`
- Jalankan: `git status`

**Tampilkan:**
```
### Status CuanFlow — [tanggal hari ini]
Phase aktif: [dari BRD]
Roadmap berikutnya:
  🔴 [item belum selesai #1]
  🔴 [item belum selesai #2]
  🟡 [item sedang berjalan]
Commit terakhir: [dari git log]
Uncommitted: [ada/tidak — sebutkan file jika ada]
```
Tutup dengan satu pertanyaan: **Hari ini mau ngerjain apa?**

---

### `lanjut` — Sambung Sesi Sebelumnya

**Load minimal dulu:**
- Jalankan: `git log --oneline -5`
- Jalankan: `git status`
- Jalankan: `git diff --stat` (jika ada uncommitted)

Dari hasil di atas, tentukan konteks pekerjaan terakhir.
Baru baca file/docs yang relevan dengan konteks tersebut — jangan load semua.

**Tampilkan:**
```
### Lanjut dari — [tanggal]
Terakhir dikerjakan: [nama fitur/bug dari git log]
Status: [selesai / masih berjalan / ada yang pending]
Uncommitted: [file apa saja, atau "tidak ada"]
Selanjutnya: [saran konkret satu langkah berikutnya]
```
Tutup: **Lanjut dari sini, atau ada yang ingin diubah arahnya?**

---

### `fix` — Perbaiki Bug

**DETAIL:** deskripsi bug dari argumen.

**Jangan load docs.** Langsung investigasi kode:
1. Grep/cari file yang relevan dengan DETAIL
2. Baca file yang ditemukan
3. Identifikasi root cause sebelum coding

**Wajib ikuti pola ini:**
1. **Isolasi** — file mana? data flow mana? (screen → AppState → service)
2. **Root cause** — kenapa terjadi? (state stale, null safety, async race, side effect?)
3. **Fix minimal** — tidak refactor, tidak tambah fitur lain
4. **Verify** — cara cek benar, edge case apa yang perlu dicek?

**Konvensi wajib:**
- Amount selalu `int` (rupiah, bukan desimal)
- Tanggal via `_stripTime()`
- CRUD: mutate → `_persist()` → `notifyListeners()` → `sync.ignore()`
- Komentar dalam Bahasa Indonesia

---

### `add` — Tambah Fitur Baru

**DETAIL:** nama/deskripsi fitur dari argumen.

**Load secukupnya:**
- `docs/BRD.md` — cek apakah fitur ini ada di roadmap, section mana
- `lib/src/core/config/feature_config.dart` — apakah butuh feature flag?
- Baca file yang relevan dengan area fitur (screen, model, AppState)

**Checklist integrasi wajib sebelum coding:**
- [ ] Route: tambah konstanta di `routes.dart` + case di `router.dart`
- [ ] AppState: list, getter, CRUD (mutate → `_persist()` → `notifyListeners()` → sync)
- [ ] Model baru jika perlu (di `core/models/`)
- [ ] Feature flag jika perlu: tambah ke `Feature` enum + `featureConfig` map
- [ ] Entry point di screen yang relevan (home, profile, dll)

Tunjukkan checklist ini ke user, konfirmasi sebelum mulai coding.

---

### `diskusi` — Diskusi Arsitektur & Desain

**DETAIL:** topik dari argumen.

**Load hanya yang relevan dengan topik DETAIL:**
- Topik DB/arsitektur → `docs/ERD.md` + `docs/MULTI_SPACE_REFACTOR.md`
- Topik roadmap/prioritas → `docs/BRD.md`
- Topik monetisasi/subscription → section Subscription di `docs/MULTI_SPACE_REFACTOR.md`
- Topik UX/flow → baca screen yang relevan dari `lib/src/features/`
- Topik teknikal spesifik → baca file kode yang relevan saja

**Format diskusi:**
- Sajikan **2–3 opsi konkret** dengan trade-off jika ada pilihan
- Kasih **rekomendasi tegas** di akhir — jangan netral
- Gunakan wireframe ASCII jika topik menyangkut UI
- **Jangan mulai coding** sampai diskusi selesai dan user validasi

Setelah user validasi → tanya: implementasi sekarang atau dokumentasi dulu?

---

### `roadmap` — Status Fitur & Prioritas

**Load:**
- `docs/BRD.md` — section Phase & Roadmap saja
- Jalankan: `git log --oneline -10`

**Tampilkan:**
- ✅ Selesai (ada buktinya di git log)
- 🔄 Sedang dikerjakan
- 🔴 Belum dimulai

Ringkas: total fitur, berapa sudah done, berapa yang blockers.

---

### `flags` — Feature Flags

**Load:**
- `lib/src/core/config/feature_config.dart` — baca penuh

**Tampilkan tabel:**

| Feature | personal | store | production |
|---------|----------|-------|------------|
| (dari featureConfig map) | ✅/❌ | ✅/❌ | ✅/❌ |

Jika DETAIL berisi **nama fitur** → jelaskan aktif di mode mana + cara pakai di widget.
Jika DETAIL berisi **"tambah"** → tampilkan perubahan yang perlu dilakukan, konfirmasi dulu.
Jika DETAIL berisi **"aktifkan"** → tampilkan perubahan spesifik, konfirmasi dulu.

---

Gunakan Bahasa Indonesia untuk semua komunikasi. Kode tetap Dart/English.
