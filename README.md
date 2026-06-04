# SplitEase
![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![SQLite](https://img.shields.io/badge/SQLite-07405E?style=for-the-badge&logo=sqlite&logoColor=white)
![Provider](https://img.shields.io/badge/Provider-42A5F5?style=for-the-badge&logo=flutter&logoColor=white)

SplitEase adalah solusi digital untuk manajemen patungan keuangan bersama. Aplikasi ini membantu pengguna melacak siapa yang membayar apa, serta menghitung total utang-piutang secara otomatis.

## Fitur Utama

*   **Manajemen Kontak & Grup**: Mendata teman dan membuat grup patungan (misal: "Liburan Bali" atau "Makan Siang").
*   **Pencatatan Transaksi**: Mencatat pengeluaran kelompok secara detail dan menghitung pembagian secara otomatis.
*   **Settlement (Pelunasan)**: Memantau dan merekam pembayaran utang antar-anggota dengan mudah.
*   **Visualisasi Data**: Menampilkan ringkasan keuangan kelompok yang jelas.
*   **Personalisasi Pengaturan**: Mendukung pengaturan tema warna, mata uang, dan format tanggal.

## Tech Stack & Arsitektur

Aplikasi ini dibangun menggunakan **Flutter** dengan pendekatan arsitektur yang modular:

*   **Local Database**: SQLite dengan metode **DAO (Data Access Object)** untuk memisahkan logika query SQL agar kode lebih rapi.
*   **State Management**: Menggunakan `Provider` untuk manajemen *state* yang reaktif dan efisien.
*   **Persistence**: `SharedPreferences` untuk menyimpan konfigurasi (nama pengguna, mata uang, tema, format tanggal).

## Struktur Data (DAO)

SplitEase menggunakan pola DAO untuk 4 modul utama:

*   **GroupDao**: Manajemen CRUD grup.
*   **TransactionDao**: Logika pencatatan pengeluaran.
*   **ContactDao**: Manajemen daftar teman.
*   **SettlementDao**: Rekam jejak pelunasan utang.

## Konfigurasi (SharedPreferences)

Kami menggunakan `PreferencesService` (Singleton) untuk menyimpan 4 kunci utama:

*   `pref_user_name`: Nama profil pengguna (Header Beranda).
*   `pref_default_currency`: Simbol mata uang (misal: Rp).
*   `pref_color_theme`: Konfigurasi tema warna antarmuka.
*   `pref_date_format`: Preferensi format penanggalan.
