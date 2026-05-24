# ⚡ Lijsttedoen ⚡

[![Flutter Version](https://img.shields.io/badge/Flutter-^3.11.4-blue.svg?logo=flutter&logoColor=white)](https://flutter.dev)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Linux%20%7C%20macOS%20%7C%20Windows-lightgrey.svg)](#)
[![Theme](https://img.shields.io/badge/Style-Neo--Brutalism-FFD700.svg?style=flat-square)](#)

**Lijsttedoen** (diambil dari bahasa Belanda yang berarti *"Daftar Tugas"*) adalah aplikasi manajemen tugas (To-Do List) modern dengan pendekatan estetika desain **Neo-Brutalism** yang berani, berkarakter, dan dinamis. Aplikasi ini dirancang untuk memaksimalkan produktivitas harian Anda dengan fitur-fitur canggih, performa luar biasa, serta antarmuka yang sangat atraktif.

---

## 🎨 Karakter Estetika: Neo-Brutalism
Aplikasi ini tidak sekadar berfungsi sebagai alat pencatat tugas biasa, melainkan menghadirkan pengalaman visual premium berkat penerapan gaya **Neo-Brutalism**:
* **High Contrast & Sharp Edges**: Menggunakan batas solid tebal (`4px`) hitam pekat di setiap sisi kartu dan tombol.
* **Hard Shadows**: Efek bayangan tegas tanpa *blur* (`Offset(6, 6)`) untuk memberikan sensasi kedalaman retro-modern.
* **Vibrant HSL Palette**: Kombinasi warna berani seperti *Vibrant Yellow* (Primary Container), *Electric Cyan* (Secondary Container), *Lively Green* (Success Container), dan *Soft Pink* (Error Container).
* **Premium Typography**: Menggunakan Google Fonts **Bricolage Grotesque** untuk judul yang berani dan ekspresif, serta **Hanken Grotesk** untuk pembacaan teks yang nyaman dan profesional.

---

## 🚀 Fitur Utama

### 1. Sistem Manajemen Tugas (CRUD Lengkap)
* Tambahkan tugas baru lengkap dengan deskripsi, kategori (Work, Study, Personal), tanggal pelaksanaan, dan waktu pelaksanaan (*due time*).
* Edit tugas atau hapus tugas dengan transisi animasi mikro yang halus.
* Atur batas deadline khusus dengan pengingat waktu tersendiri.

### 2. Pengingat & Notifikasi Cerdas (Notification Service)
* **Zoned Timezone Scheduling**: Integrasi `timezone` lokal secara tepat waktu menggunakan `flutter_timezone`.
* **Daily Digest**: Mengirimkan pengingat ringkasan agenda harian secara otomatis setiap jam **08:00 Pagi**.
* **Exact Time Alerts**: Notifikasi instan berkecepatan tinggi tepat pada waktu tugas yang dijadwalkan.
* **Pre-Reminders**: Dapatkan alarm peringatan `15 menit` atau `1 jam` sebelum batas waktu tugas mendekat.

### 3. Portabilitas Data Mandiri (Backup & Restore Service)
* **Offline JSON Export**: Ekspor seluruh basis data tugas, profil pengguna, dan pengaturan sistem ke dalam satu file berkas JSON terstruktur, lalu bagikan secara instan ke platform mana pun melalui *System Share Sheet* bawaan perangkat.
* **Offline JSON Import**: Impor kembali file backup JSON yang valid menggunakan pemilih file bawaan (*file picker*). Sistem akan secara otomatis menguji keaslian berkas dan menjadwalkan ulang seluruh alarm pengingat di sistem lokal tanpa hambatan.

### 4. Analisis Produktivitas & Statistik Dinamis
* Saring data produktivitas Anda berdasarkan periode waktu: **Mingguan, Bulanan, dan Tahunan**.
* **Rasio Sukses**: Dihitung secara cerdas berdasarkan rasio penyelesaian tugas tepat waktu sebelum melewati tenggat waktu.
* **Dynamic Badge Style Banner**: Banner motivasi premium yang berganti gaya visual, warna, ikon, judul, serta deskripsi secara langsung berdasarkan persentase penyelesaian tugas Anda.
* Kategori distribusi visual untuk mengetahui fokus pengerjaan harian Anda.

### 5. Dasbor Kalender Interaktif
* Lihat penanggalan interaktif untuk mengetahui tugas mana saja yang dijadwalkan pada hari tertentu secara cepat.

### 6. Pengaturan Profil & Sistem
* Kustomisasi nama pengguna dan pilihan global avatar menarik (*initial, face, pets, bunny*).
* Opsi reset data secara aman yang otomatis membatalkan seluruh jadwal alarm pengingat di sistem Android/iOS.

---

## 🛠️ Tech Stack & Dependencies

Aplikasi ini dibangun menggunakan teknologi terkini di ekosistem Flutter:
* **Framework**: Flutter SDK (Dart)
* **Penyimpanan Lokal**: `shared_preferences`
* **Notifikasi Lokal**: `flutter_local_notifications`
* **Manajemen Waktu**: `timezone` & `flutter_timezone`
* **Berbagi Berkas**: `share_plus`
* **Pemilih File**: `file_picker` & `path_provider`
* **Tipografi**: `google_fonts`
* **Launcher Icon**: `flutter_launcher_icons`

---

## 📂 Struktur Direktori Proyek

```text
lib/
├── main.dart                      # Shell Utama & Manajemen Navigasi Aplikasi
├── models/
│   └── todo_model.dart            # Representasi Objek Tugas & Konversi Data JSON
├── pages/
│   ├── add_edit_dialog.dart       # Dialog Menambah & Memodifikasi Tugas
│   ├── calendar_page.dart         # Panel Agenda Berbasis Penanggalan (Kalender)
│   ├── settings_page.dart         # Konfigurasi Profil, Notifikasi, & Backup/Restore
│   ├── stats_page.dart            # Dasbor Analisis Produktivitas & Rasio Sukses
│   └── tasks_page.dart            # Panel Utama Manajemen Tugas Terjadwal
├── services/
│   ├── backup_service.dart        # Logika Bisnis Ekspor-Impor Data Offline
│   └── notification_service.dart  # Sistem Manajemen Alur Alarm Pengingat
├── theme/
│   └── neo_brutalism_theme.dart   # Definisi Palette Warna, Radius, & Tipografi
└── widgets/
    └── neo_brutalism_widgets.dart # Kumpulan Komponen Kustom Khas Neo-Brutalism
```

---

## 🏁 Memulai & Cara Menjalankan

Ikuti panduan berikut untuk menjalankan proyek ini di mesin lokal Anda:

### Prasyarat
1. Pastikan Flutter SDK sudah terpasang di komputer Anda (`flutter --version` >= 3.11.0).
2. Jalankan `flutter doctor` untuk memastikan perangkat emulator/fisik siap digunakan.

### Langkah-langkah
1. **Dapatkan source code**:
   ```bash
   git clone git@github.com:Chanifg/Lijsttedoen.git
   cd Lijsttedoen
   ```

2. **Unduh seluruh package**:
   ```bash
   flutter pub get
   ```

3. **Jalankan aplikasi**:
   * Untuk menjalankan di emulator/perangkat yang terhubung:
     ```bash
     flutter run
     ```
   * Untuk melakukan build APK (Android):
     ```bash
     flutter build apk --release
     ```

---

## 📄 Lisensi

Proyek ini dilindungi di bawah lisensi pihak pengembang. Segala kontribusi dan modifikasi diperbolehkan untuk meningkatkan produktivitas bersama.

⚡ *Awal-awal pancen kepekso, soyo suwi dadi kulino, tembe mburine dadi wong MULYO!* ⚡
