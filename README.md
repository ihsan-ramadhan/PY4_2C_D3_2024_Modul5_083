# Proyek Modul 5: Offline-First & Collaborative Intelligence

**Nama:** Muhammad Ihsan Ramadhan

**NIM:** 241511083

**Kelas:** 2C - D3 Teknik Informatika

---

## Deskripsi Proyek

Pada Modul 5 ini, aplikasi dikembangkan dengan pendekatan  *Offline-First* . Data sekarang disimpan secara lokal menggunakan *database* Hive agar aplikasi tetap bisa digunakan meski tidak ada internet. Saat koneksi kembali stabil, data akan otomatis disinkronkan ke MongoDB Atlas. Selain itu, modul ini juga menambahkan fitur pembatasan hak akses dan editor  *Markdown* .

## Fitur Utama

1. **Offline-First & Sync:** Penyimpanan instan di memori lokal (Hive) dengan sinkronisasi ke MongoDB di latar belakang.
2. **Keamanan & Hak Akses:** Validasi aksi CRUD berdasarkan *role* pengguna dan isolasi data per kelompok menggunakan Team ID.
3. **Markdown Editor:** Form input yang tadinya pakai pop-up diubah jadi halaman penuh (`LogEditorPage`) dengan fitur *preview text* Markdown.
4. **Deteksi Jaringan:** Aplikasi bisa mendeteksi status internet dan menampilkan ikon status data (belum tersinkron/sudah di- *upload* ).

---

## Self-Reflection

Dari pengerjaan Modul 5 ini, ada beberapa catatan penting:

1. Saya jadi lebih paham alur kerja  *Offline-First* . Aplikasi terasa jauh lebih cepat karena menyimpan data di Hive tidak perlu nunggu respons server, dan urusan *upload* ke *cloud* tinggal diurus di belakang layar.
2. Senang bisa memigrasikan input *DialogBox* yang sempit menjadi halaman form utuh yang mendukung *formatting* laporan (tebal,  *header* , dll) secara  *real-time* .
3. **Tantangan Utama:** Bagian yang paling bikin pusing adalah memodifikasi file `log_view`. Baris kodenya jadi sangat panjang dan  *widget* -nya terlalu bertumpuk ( *nested* ). Salah taruh atau kurang satu kurung tutup saja bikin *error* se-halaman dan butuh waktu lama buat  *debugging* .
4. **Target Berikutnya:** Gara-gara kesulitan di `log_view` yang kepanjangan, target saya ke depan adalah belajar *Refactoring* di Flutter. Saya ingin coba misahin *widget-widget* yang gede jadi file komponen yang lebih kecil, supaya kodingan lebih rapi dan gampang dibaca.

---

## Tech Stack & Packages

* **Language:** Dart
* **Framework:** Flutter
* **Database:** MongoDB Atlas
* **Local Database:** Hive
