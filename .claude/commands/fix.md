# /fix — Template Bug Fix CuanFlow

Argumen: deskripsi bug yang ingin diperbaiki (contoh: `/fix tombol simpan tidak merespons di add expense`)

Bug yang dilaporkan: $ARGUMENTS

---

Gunakan pendekatan sistematis ini. Jangan langsung coding sebelum tahu root cause-nya.

## Langkah 1 — Isolasi

Identifikasi dengan membaca kode:
- File mana yang terlibat? (screen, widget, AppState, service?)
- Data flow mana yang bermasalah? (input → state → persist → UI update)
- Apakah bug ini spesifik ke mode tertentu (personal/store/production)?

Jalankan jika perlu:
- `!grep -r "kata_kunci" lib/src/ --include="*.dart" -l` untuk cari file relevan

## Langkah 2 — Reproduce

Jelaskan:
- Kapan bug ini terjadi? (kondisi apa yang memicunya)
- Apakah konsisten atau intermittent?
- Apakah ada error di console? (minta user paste jika ada)

## Langkah 3 — Root Cause

Analisis kenapa ini terjadi:
- Apakah state tidak di-update dengan benar?
- Apakah ada race condition di async?
- Apakah ada null safety issue?
- Apakah ada side effect dari perubahan sebelumnya?

Jangan fix sebelum root cause jelas. Jika masih tidak yakin, tanya user.

## Langkah 4 — Fix

Prinsip fix yang baik:
- ✅ Perubahan **minimal** — jangan refactor sekalian
- ✅ Ikuti pola existing (CRUD: mutate → `_persist()` → `notifyListeners()` → sync)
- ✅ Tidak menambah fitur baru saat fixing bug
- ❌ Jangan ubah business logic yang tidak terkait

## Langkah 5 — Verify

Setelah fix:
- Sebutkan cara memverifikasi fix ini benar
- Apakah ada edge case yang perlu dicek?
- Apakah fix ini bisa breaking change untuk fitur lain?

---

**Catatan penting:**
- Amount selalu `int` (rupiah, bukan desimal)
- Tanggal selalu via `_stripTime()`
- ID lokal punya prefix: `tx_`, `outlet_`, dll
- Semua komentar dalam Bahasa Indonesia
