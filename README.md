# Proyek Modul 4: Cloud Integration & Secure Workflow

**Nama:** Muhammad Ihsan Ramadhan

**NIM:** 241511083

**Kelas:** 2C - D3 Teknik Informatika

---

## Deskripsi Proyek

Aplikasi ini merupakan tahap evolusi lanjutan dari penyimpanan lokal menuju integrasi *Cloud Database*. Fokus utama pada modul ini adalah menghubungkan aplikasi ke **MongoDB Atlas** menggunakan *Direct Driver*, menerapkan protokol keamanan untuk data sensitif, mengelola *Asynchronous Programming* untuk menjaga performa UI, serta membangun arsitektur kode yang solid (SOLID principles) melalui pemisahan *Service* dan penerapan *Singleton Pattern*.

## Fitur Utama

1. **Cloud CRUD Database:** Fitur operasi data (Tambah, Baca, Edit, Hapus) yang kini terhubung secara langsung ke *database* MongoDB Atlas.
2. **SOLID & Async Architecture:** Pemisahan tanggung jawab (*Single Responsibility Principle*) yang jelas antara UI, Model, dan akses data. Manajemen koneksi *database* diisolasi di dalam `MongoService` menggunakan *Singleton pattern* agar koneksi tidak redundan.
4. **Secure Workflow & Identity:** Mengamankan *Connection String* dan kredensial sensitif lainnya ke dalam file `.env` (yang dikecualikan via `.gitignore`). Selain itu, pembuatan *unique identifier* dokumen memanfaatkan standar industri BSON `ObjectId` bawaan MongoDB.

---

## Self-Reflection

Setelah menyelesaikan Modul 4, wawasan saya terkait pengembangan aplikasi standar industri semakin terbuka, terutama pada aspek keamanan dan arsitektur *cloud*:

1. Saya menyadari betapa berbahayanya menyimpan kredensial akses *database* langsung di dalam kode (*hardcoded*). Menggunakan file `.env` adalah langkah esensial untuk keamanan. Selain itu, dengan memusatkan koneksi MongoDB di `MongoService` menggunakan *Singleton*, manajemen koneksi menjadi jauh lebih hemat *resource* dan terstruktur.
2. Implementasi *Asynchronous Programming* (`async`/`await`) sangat penting untuk *User Experience*. Dengan menambahkan *state loading* (`_isLoading`) dan `CircularProgressIndicator`, aplikasi tidak lagi mengalami *freeze* saat menunggu respons dari server *cloud*, sehingga terasa jauh lebih profesional.
3. Pemahaman terkait arsitektur NoSQL juga bertambah. Daripada menggunakan pustaka eksternal seperti `uuid` untuk ID dokumen, menggunakan `ObjectId()` bawaan dari BSON jauh lebih optimal dan sesuai dengan standar ekosistem MongoDB.
4. Menghubungkan aplikasi langsung ke *database* melalui *Direct Driver* memiliki tantangan tersendiri terkait jaringan. Saya mendapati bahwa akses sering kali terblokir saat menggunakan koneksi WiFi kampus (seperti jaringan "polban"), meskipun IP sudah di-*whitelist*. Hal ini memicu rasa penasaran saya untuk ke depannya mempelajari arsitektur *Offline-First*, di mana data bisa tersimpan secara lokal sementara, dan disinkronkan ke *cloud* saat jaringan kembali normal dan stabil.

---

## Tech Stack & Tools

* **Language:** Dart
* **Framework:** Flutter
* **Database:** MongoDB Atlas
