# Panduan Implementasi & Eksekusi Huniya (Ready-to-Run di IDE)

Seluruh kode **Backend (Golang + Gin + GORM + PostgreSQL + JWT + Haversine)** dan **Frontend (Flutter + Provider + Dio + Geolocator + Google Maps)** sesuai spesifikasi PRD Huniya v1.0.0 telah dieksekusi dan dibungkus ke dalam struktur folder proyek yang siap dibuka langsung di IDE (**VS Code**, **GoLand**, atau **Android Studio**).

## 1. Struktur Proyek yang Telah Dibangun

| Direktori / File | Jumlah File | Deskripsi |
| :--- | :--- | :--- |
| `huniya-backend/` | 26 File | RESTful API Golang (Clean Architecture, GORM AutoMigrate, JWT RBAC Middleware, Query Haversine KM, Multi-Image Upload, Docker Compose, & Swagger JSON) |
| `huniya_mobile/` | 24 File | Aplikasi Flutter Cross-Platform (Provider State Management, Dio JWT Interceptor, Geolocator GPS, Google Maps Marker & Pinpoint Picker, & Deep-Link WhatsApp) |
| `seed_dummy_data.sql` | 1 File | Script opsional pengisi data awal (1 akun `owner`, 1 akun `user`, dan 3 kos sampel di Jakarta) untuk pengujian cepat |

## 2. Langkah Cepat Menjalankan Backend (`huniya-backend`) di VS Code / GoLand

### Opsi A: Menggunakan Docker Compose (Paling Cepat - 1 Perintah)
1. Buka terminal pada folder `huniya-backend/`.
2. Jalankan perintah berikut untuk menyalakan **PostgreSQL 16** sekaligus **Huniya API Server**:
   ```bash
   cd huniya-backend
   docker compose up -d --build
   ```
3. Server otomatis berjalan di `http://localhost:8080` dan menjalankan `AutoMigrate` untuk tabel `users`, `properties`, dan `wishlists` beserta *geospatial index* `(latitude, longitude)`.

### Opsi B: Menjalankan Secara Lokal di IDE (Tanpa Docker untuk Go)
1. Pastikan **Go >= 1.22** dan **PostgreSQL** sudah aktif di komputer Anda, lalu buat database bernama `huniya_db`:
   ```sql
   CREATE DATABASE huniya_db;
   ```
2. Buka folder `huniya-backend/` di VS Code atau GoLand, sesuaikan kredensial database pada file `.env` jika diperlukan.
3. Unduh semua *dependencies* dan jalankan server:
   ```bash
   cd huniya-backend
   go mod tidy
   go run ./cmd/api/main.go
   ```
4. Cek status server di browser atau Postman:
   * **Healthcheck:** `GET http://localhost:8080/health`
   * **Swagger Spec:** `GET http://localhost:8080/swagger/doc.json`

## 3. Langkah Cepat Menjalankan Frontend (`huniya_mobile`) di VS Code / Android Studio

1. **Buka Folder Proyek Flutter:**
   * Jika Anda membuka langsung dari hasil ekstrak `huniya-fullstack-ready.zip`, buka folder `huniya_mobile/` di VS Code atau Android Studio.
   * Jika platform folder bawaan (`android/gradle`, `ios/Runner.xcodeproj`) belum ter-generate penuh di mesin lokal Anda, jalankan perintah ini di dalam folder `huniya_mobile/` untuk melengkapi *scaffold* native tanpa menimpa kode `lib/`:
     ```bash
     cd huniya_mobile
     flutter create . --project-name huniya_mobile --org com.huniya
     flutter pub get
     ```
2. **Pasang Google Maps API Key:**
   * **Android (`android/app/src/main/AndroidManifest.xml`):** Ganti nilai `YOUR_GOOGLE_MAPS_API_KEY_HERE` dengan API Key Google Maps Anda.
   * **iOS (`ios/Runner/AppDelegate.swift`):** Tambahkan `GMSServices.provideAPIKey("YOUR_GOOGLE_MAPS_API_KEY_HERE")`.
3. **Konfigurasi Base URL API (`lib/core/api/api_endpoints.dart`):**
   * Secara default, `ApiEndpoints.baseHost` otomatis menggunakan `http://10.0.2.2:8080` saat dijalankan di **Android Emulator** dan `http://localhost:8080` di **iOS Simulator**.
   * Jika Anda menguji menggunakan **HP Fisik (Real Device)**, ubah nilai `baseHost` ke IP LAN komputer Anda (contoh: `http://192.168.1.10:8080`).
4. **Jalankan Aplikasi:**
   ```bash
   flutter run
   ```

## 4. Ringkasan Endpoint RESTful API & RBAC yang Sudah Aktif

| Method & Endpoint | Hak Akses (RBAC) | Fungsi Utama |
| :--- | :--- | :--- |
| `POST /api/v1/auth/register` | Public | Registrasi akun baru dengan pilihan role `user` atau `owner` & Bcrypt hash |
| `POST /api/v1/auth/login` | Public | Autentikasi email/password & pembuatan JWT Bearer Token |
| `GET /api/v1/auth/me` | `user`, `owner` | Mengambil profil pengguna aktif berdasarkan klaim JWT |
| `GET /api/v1/properties` | Public / `user` | Pencarian kos dengan filter `search`, `type`, `min_price`, `max_price`, `city`, `page`, `limit` |
| `GET /api/v1/properties/nearby` | `user` | Pencarian properti terdekat dengan rumus **Haversine SQL** (`lat`, `lng`, `radius`, `type`) |
| `GET /api/v1/properties/:id` | `user`, `owner` | Detail lengkap properti beserta informasi kontak WhatsApp pemilik |
| `GET /api/v1/wishlists` | `user` | Menampilkan daftar properti favorit (`Wishlist`) milik pencari kos |
| `POST /api/v1/wishlists/:property_id` | `user` | Toggle tambah/hapus properti dari daftar favorit (`Wishlist`) |
| `GET /api/v1/owner/properties` | `owner` | Menampilkan daftar properti milik `owner` yang sedang login |
| `POST /api/v1/owner/properties` | `owner` | Tambah properti baru (`multipart/form-data`, maks. 5 foto @ 2MB, koordinat peta) |
| `PUT /api/v1/owner/properties/:id` | `owner` | Edit properti (dilengkapi validasi kepemilikan `property.owner_id == jwt.user_id`) |
| `PATCH /api/v1/owner/properties/:id/availability` | `owner` | Toggle cepat status ketersediaan (`is_available`) & sisa kamar (`room_available`) |
| `DELETE /api/v1/owner/properties/:id` | `owner` | Hapus properti milik `owner` |

## 5. Skenario Pengujian End-to-End (Sesuai Tahap 6 PRD)

1. **Uji Alur Owner (Pemilik Kos):**
   * Daftar akun baru di layar **Register** dengan memilih kartu **"Pemilik Kos" (`owner`)**.
   * Masuk ke **Owner Dashboard**, tekan tombol **Tambah Properti**, pilih titik koordinat kos melalui layar **Map Picker**, unggah foto kos, lalu simpan.
   * Uji tombol **Set Penuh / Set Tersedia** untuk mengubah ketersediaan kamar secara instan.
2. **Uji Alur User (Pencari Kos) & Haversine GPS:**
   * Keluar (*Logout*) lalu daftar akun baru dengan memilih kartu **"Pencari Kos" (`user`)**.
   * Izinkan akses lokasi GPS; layar **User Home** akan menampilkan alamat GPS saat ini dan daftar kos di bagian **"Terdekat dari Kamu"** lengkap dengan label jarak presisi dalam satuan **KM** (`distance_km`).
   * Buka **Eksplor Peta GPS** untuk melihat titik *Marker* kos di sekitar lokasi Anda, ketuk *Marker* untuk memunculkan *Preview Card*, lalu buka halaman detail dan tekan **"Hubungi Pemilik (WhatsApp)"**.
3. **Uji Keamanan RBAC:**
   * Gunakan token milik `user` untuk memanggil `GET /api/v1/owner/properties` atau `POST /api/v1/owner/properties` di Postman — middleware akan langsung menolak akses dengan status `403 Forbidden`.
