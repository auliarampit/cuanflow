# /diskusi — Diskusi Arsitektur & Desain

Argumen: topik yang ingin didiskusikan (contoh: `/diskusi gimana cara terbaik handle offline sync di Multi-Space`)

Topik: $ARGUMENTS

---

Mode ini untuk brainstorming, validasi desain, atau eksplorasi konsep. Tidak ada coding dulu sebelum kesimpulan jelas.

## Langkah 1 — Load Konteks yang Relevan

Sebelum berdiskusi, baca dokumen yang relevan dengan topik:

- Topik arsitektur / database → `docs/ERD.md` + `docs/MULTI_SPACE_REFACTOR.md`
- Topik fitur / roadmap → `docs/BRD.md`
- Topik UX / flow → `docs/USER_FLOW.md`
- Topik monetisasi / tier → `docs/BRD.md` bagian Monetisasi + `docs/MULTI_SPACE_REFACTOR.md` bagian Subscription
- Topik teknikal umum → `docs/AI_CONTEXT.md`

Jika topik menyebut kode spesifik, baca file yang relevan dulu.

## Langkah 2 — Pahami Masalah

Sebelum kasih rekomendasi, klarifikasi:
- Apa constraint-nya? (waktu, biaya, UX, teknikal)
- Apakah ini keputusan permanen atau bisa diubah nanti?
- Siapa yang terdampak? (user gratis, premium, semua?)

Jika topik cukup jelas, langsung ke Langkah 3.

## Langkah 3 — Berikan Rekomendasi

Format diskusi yang baik:
- Sajikan **2–3 opsi konkret** jika ada trade-off
- Untuk setiap opsi: sebutkan pro, kontra, dan kapan cocok dipilih
- Kasih **rekomendasi tegas** di akhir — jangan netral tanpa pilihan
- Gunakan wireframe ASCII jika topik menyangkut UI

## Langkah 4 — Kesimpulan & Tindak Lanjut

Setelah user validasi:
- Ringkas keputusan dalam 2–3 bullet point
- Tanya: apakah langsung implementasi sekarang atau dokumentasi dulu?
- Jika implementasi: transisi ke `/add-feature` atau `/fix` sesuai kasusnya

---

**Prinsip diskusi:**
- Jangan mulai coding di mode ini — selesaikan diskusi dulu
- Jika topik berubah di tengah jalan, ikuti arahnya
- Catat keputusan penting ke docs jika cukup signifikan
- Gunakan Bahasa Indonesia
