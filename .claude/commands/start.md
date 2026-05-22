# /start — Mulai Sesi Coding CuanFlow

Ritual awal setiap sesi. Load konteks penuh, tampilkan status, tanya mau ngerjain apa hari ini.

---

Lakukan langkah berikut secara berurutan:

## 1. Load Konteks Bisnis
Baca file-file ini:
- `docs/BRD.md` — visi produk, 3 segmen, prioritas phase
- `docs/AI_CONTEXT.md` — rules, anti-pattern, vibe coding workflow

## 2. Load Konteks Teknikal
- Baca `lib/src/core/config/feature_config.dart` — feature flags saat ini
- Jalankan: `!git log --oneline -7` — lihat 7 commit terakhir
- Jalankan: `!git status` — ada uncommitted changes?

## 3. Tampilkan Ringkasan Sesi

Tampilkan dalam format ini:

---

### Status CuanFlow — [tanggal hari ini]

**Phase aktif:** [Phase 0 / 1 / 2 dari BRD]

**Roadmap berikutnya:**
- 🔴 P0.1 Onboarding wizard redesign
- 🔴 P0.2 Shopping list bulk expense UX
- 🟡 P0.3 Personal mode (budget + trend)
- ⚪ P0.4 Freemium/paywall scaffold

*(update status berdasarkan git log dan kondisi kode aktual)*

**Commit terakhir:** [dari git log]

**Uncommitted changes:** [ada/tidak ada, sebutkan file jika ada]

---

## 4. Tanya

Tutup dengan satu pertanyaan:

> **Hari ini mau ngerjain apa?**
> Pilih task dari roadmap di atas, atau sebutkan bug/fitur spesifik yang ingin dikerjakan.

Setelah user jawab, mulai dengan pendekatan yang tepat:
- Bug? → Gunakan pola `/fix` (isolate → reproduce → root cause → fix → verify)
- Fitur baru? → Gunakan pola `/add-feature` (analisis → checklist integrasi → implement)
- Refactor? → Tanya scope dulu sebelum mulai

---

Gunakan Bahasa Indonesia untuk semua komunikasi. Tetap ringkas — tidak perlu panjang.
