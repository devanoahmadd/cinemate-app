# Dokumentasi Spesifikasi Aplikasi — Cinemate

---

## Daftar Isi

1. [Deskripsi Aplikasi](#1-deskripsi-aplikasi)
2. [Teknologi yang Digunakan](#2-teknologi-yang-digunakan)
3. [Arsitektur Aplikasi](#3-arsitektur-aplikasi)
4. [Fitur Aplikasi](#4-fitur-aplikasi)
5. [API yang Digunakan](#5-api-yang-digunakan)
6. [Alur Navigasi](#6-alur-navigasi)
7. [Struktur Folder](#7-struktur-folder)
8. [Cara Menjalankan Aplikasi](#8-cara-menjalankan-aplikasi)

---

## 1. Deskripsi Aplikasi

**Cinemate** adalah aplikasi mobile berbasis Flutter untuk mengeksplorasi film dan serial TV. Pengguna dapat menemukan film-film terbaru, terpopuler, terbaik, akan datang, serta serial TV yang sedang tren secara real-time melalui integrasi dengan The Movie Database (TMDB) API. Aplikasi dilengkapi sistem autentikasi Firebase, watchlist pribadi yang tersimpan di Cloud Firestore, dan profil pengguna yang dapat diedit termasuk foto.

| | |
|---|---|
| **Nama Aplikasi** | Cinemate |
| **Platform** | Android (Flutter) |
| **Versi** | 1.0.0 |
| **Bahasa Pemrograman** | Dart |
| **Framework** | Flutter SDK ^3.11.1 |

---

## 2. Teknologi yang Digunakan

### Framework & Language
| Teknologi | Versi | Fungsi |
|-----------|-------|--------|
| Flutter | ^3.11.1 | Framework utama pengembangan aplikasi |
| Dart | (bundled) | Bahasa pemrograman |

### State Management
| Package | Versi | Fungsi |
|---------|-------|--------|
| `flutter_bloc` | ^9.1.1 | Implementasi pola BLoC untuk manajemen state |
| `equatable` | ^2.0.5 | Perbandingan objek berdasarkan nilai properti |

### Networking
| Package | Versi | Fungsi |
|---------|-------|--------|
| `dio` | ^5.3.3 | HTTP client untuk request ke TMDB API |

### Authentication & Backend
| Package | Versi | Fungsi |
|---------|-------|--------|
| `firebase_core` | ^4.6.0 | Inisialisasi Firebase SDK |
| `firebase_auth` | ^6.3.0 | Autentikasi pengguna (login, register, logout, ganti password) |
| `cloud_firestore` | ^6.3.0 | Penyimpanan watchlist dan data profil pengguna |
| `firebase_storage` | ^13.3.0 | Upload dan simpan foto profil pengguna |

### Navigasi
| Package | Versi | Fungsi |
|---------|-------|--------|
| `go_router` | ^17.2.0 | Deklaratif routing dengan proteksi halaman otomatis |

### UI / Tampilan
| Package | Versi | Fungsi |
|---------|-------|--------|
| `cached_network_image` | ^3.3.0 | Menampilkan dan menyimpan cache gambar dari URL |
| `shimmer` | ^3.0.0 | Animasi skeleton loading saat data dimuat |
| `google_fonts` | ^8.0.2 | Tipografi kustom di seluruh aplikasi |

### Utilities
| Package | Versi | Fungsi |
|---------|-------|--------|
| `flutter_dotenv` | ^6.0.0 | Membaca variabel rahasia dari file `.env` |
| `image_picker` | ^1.1.2 | Memilih foto profil dari galeri atau kamera |
| `url_launcher` | ^6.3.0 | Membuka link trailer dan halaman penyedia layanan di browser |
| `share_plus` | ^13.0.0 | Berbagi detail film/serial lewat sistem share sheet |

---

## 3. Arsitektur Aplikasi

Cinemate menggunakan pola arsitektur **BLoC (Business Logic Component)** yang dikombinasikan dengan **Simple Layered Architecture**.

### Diagram Arsitektur

```
┌─────────────────────────────────────────────┐
│            PRESENTATION LAYER               │
│       screens/ + bloc/ + widgets/           │
│  Widget hanya tampilkan data & kirim Event  │
├─────────────────────────────────────────────┤
│              DATA LAYER                     │
│         data/services/ + data/models/       │
│  Komunikasi dengan API, parsing JSON        │
├─────────────────────────────────────────────┤
│              CORE LAYER                     │
│   core/constants/ + core/routes/            │
│   core/theme/                               │
│  Konfigurasi bersama: routing, tema, konstan│
└─────────────────────────────────────────────┘
```

### Pola BLoC

BLoC memisahkan logika bisnis dari tampilan (UI) melalui tiga komponen:

- **Event** → Aksi yang dikirim dari Widget ke BLoC (misal: `AuthLoginRequested`)
- **BLoC** → Memproses Event, menjalankan logika, memanggil Service
- **State** → Kondisi aplikasi yang dikirim balik ke Widget (misal: `AuthAuthenticated`)

```
Widget → (add Event) → BLoC → (emit State) → Widget rebuild
```

### BLoC yang Digunakan

#### AuthBloc — Autentikasi
| Event | State yang Dihasilkan |
|-------|----------------------|
| `AuthCheckRequested` | `AuthAuthenticated` / `AuthUnauthenticated` |
| `AuthLoginRequested` | `AuthLoading` → `AuthAuthenticated` / `AuthFailure` |
| `AuthRegisterRequested` | `AuthLoading` → `AuthAuthenticated` / `AuthFailure` |
| `AuthLogoutRequested` | `AuthUnauthenticated` |

#### MovieBloc — Data Film
| Event | State yang Dihasilkan |
|-------|----------------------|
| `MovieFetchHome` | `MovieLoading` → `MovieHomeLoaded` |
| `MovieFetchListPage(category, page)` | `MovieLoading` → `MovieListPageLoaded` |
| `MovieSearch(query)` | `MovieLoading` → `MovieSearchLoaded` |
| `MovieClearSearch` | `MovieInitial` |

#### TvBloc — Data Serial TV
| Event | State yang Dihasilkan |
|-------|----------------------|
| `TvFetchHome` | `TvLoading` → `TvHomeLoaded` |
| `TvFetchListPage(category, page)` | `TvLoading` → `TvListPageLoaded` |
| `TvSearch(query)` | `TvLoading` → `TvSearchLoaded` |
| `TvClearSearch` | `TvInitial` |

#### WatchlistBloc — Watchlist Pribadi
| Event | State yang Dihasilkan |
|-------|----------------------|
| `WatchlistLoad` | `WatchlistLoading` → `WatchlistLoaded` |
| `WatchlistAdd(item)` | `WatchlistLoaded` (diperbarui) |
| `WatchlistRemove(docId)` | `WatchlistLoaded` (diperbarui) |
| `WatchlistCheckItem(docId)` | `WatchlistItemChecked` |

---

## 4. Fitur Aplikasi

### 4.1 Autentikasi Pengguna

**Registrasi Akun**
- Pengguna dapat membuat akun baru menggunakan email dan password
- Validasi format email dan kekuatan password dilakukan oleh Firebase
- Setelah berhasil daftar, pengguna langsung diarahkan ke halaman utama

**Login**
- Pengguna masuk menggunakan email dan password yang sudah terdaftar
- Tombol login dinonaktifkan selama proses berlangsung (mencegah double request)
- Menampilkan pesan error yang informatif untuk setiap jenis kegagalan

**Proteksi Halaman**
- Halaman utama hanya bisa diakses oleh pengguna yang sudah login
- Pengguna yang belum login otomatis diarahkan ke halaman login
- Pengguna yang sudah login dan mencoba buka halaman login/register otomatis diarahkan ke Home

---

### 4.2 Halaman Utama (Home Tab)

**Hero Banner**
- Menampilkan satu film unggulan dari daftar Now Playing sebagai banner utama
- Film dipilih secara acak dari 8 film teratas setiap sesi
- Menampilkan: judul, rating bintang, tahun rilis — dapat diklik untuk melihat detail
- Mendukung pull-to-refresh untuk memuat ulang dan mengacak film hero

**Grid Kategori Film**
- 4 kategori film dalam grid 2 kolom: Popular, Now Playing, Top Rated, Upcoming
- 2 kategori serial TV: Popular TV, Top Rated TV
- Setiap kartu dapat diklik untuk membuka daftar lengkap dengan pagination

**Trending Hari Ini**
- 5 film terpopuler dengan peringkat (#1–#5)
- Warna lencana ranking: Emas, Perak, Perunggu, Abu-abu
- Setiap item menampilkan: poster, judul, rating, tahun rilis

**Optimasi Performa**
- Data film home di-cache di widget; tidak perlu fetch ulang saat berpindah tab
- Loading skeleton hanya ditampilkan saat pertama kali data dimuat

---

### 4.3 Pencarian Film / Serial TV (Search Tab)

- Pencarian real-time saat pengguna mengetik (tanpa perlu tekan tombol)
- **Fallback Pencarian Aktor**: jika query tidak menemukan judul, otomatis mencari berdasarkan nama aktor dan menampilkan filmografi/serial yang dibintanginya
- Menampilkan jumlah hasil yang ditemukan
- Setiap hasil menampilkan: poster, judul, rating, tahun rilis, cuplikan sinopsis
- Tombol hapus (X) untuk mereset state pencarian
- Keyboard otomatis muncul saat tab dibuka
- Menangani kondisi: hasil kosong, loading, dan error

---

### 4.4 Daftar Film / Serial TV (List Screen)

- Menampilkan konten dalam grid 2 kolom dengan infinite scroll (load lebih otomatis)
- **Pagination**: halaman berikutnya dimuat otomatis saat pengguna scroll mendekati bawah
- **Filter Chip Genre**: filter horizontal yang bisa di-scroll; filter dilakukan secara lokal (tanpa request API tambahan)
- **Opsi Urutan**: urutkan berdasarkan Popularitas, Rating, Tanggal Rilis via dropdown
- Setiap item menampilkan: poster, judul, rating bintang

---

### 4.5 Detail Film (Movie Detail Screen)

Menampilkan informasi lengkap sebuah film yang di-fetch secara paralel:

- Backdrop image dengan efek gradient overlay
- Judul, rating bintang, nilai (skala 10), jumlah vote, tanggal rilis
- Genre, durasi, anggaran, pendapatan, status, tagline
- Sinopsis lengkap dengan expand/collapse
- **Toggle Watchlist** — simpan atau hapus dengan satu ketukan; state tersimpan di Firestore
- **Tombol Share** — bagikan judul dan rating lewat sistem share sheet
- **Watch Providers** — pilihan streaming/rental/beli untuk region pengguna
- **Trailer** — dapat diklik untuk membuka trailer resmi di browser
- **Cast** — daftar scroll horizontal dengan "See All" menuju halaman cast lengkap
- **Ulasan** — 2 ulasan pertama ditampilkan dengan "See All" menuju halaman ulasan paginasi
- **Similar & Recommended** — daftar scroll horizontal dengan "See All" untuk tampilan penuh
- **Koleksi** — jika film termasuk franchise/koleksi, kartu tappable membuka Collection Screen

---

### 4.6 Detail Serial TV (TV Detail Screen)

Mirip dengan Movie Detail, dengan field khusus TV:

- Judul, rating, tanggal tayang perdana, jumlah musim/episode
- Kreator, genre, jaringan siaran
- Cast, Ulasan, Serial Serupa, Rekomendasi, Watch Providers, Trailer
- Toggle Watchlist dan tombol Share
- Daftar musim dengan tanggal tayang

---

### 4.7 Halaman Koleksi (Collection Screen)

- Menampilkan semua film dalam satu franchise/koleksi (misal: "The Avengers Collection")
- Teks overview koleksi
- Poster film yang dapat diklik menuju Movie Detail masing-masing

---

### 4.8 Halaman Cast Lengkap (Cast Screen)

- Daftar penuh pemeran film atau serial TV dalam grid yang bisa di-scroll
- Setiap item menampilkan: foto profil, nama aktor, nama karakter

---

### 4.9 Halaman Ulasan (Reviews Screen)

- Daftar ulasan pengguna dari TMDB dengan paginasi
- Menampilkan: avatar reviewer, username, rating, tanggal ulasan, isi ulasan
- Setiap kartu ulasan mendukung expand/collapse untuk teks panjang

---

### 4.10 Watchlist Screen

- Menampilkan semua item (film dan serial TV) yang disimpan pengguna
- Didukung Cloud Firestore, tersimpan antar sesi dan perangkat
- Setiap item menampilkan: poster, judul, badge tipe (Movie / TV), rating
- Dapat dihapus dari watchlist

---

### 4.11 Tab Profil & Manajemen Profil

**Tab Profil**
- Menampilkan avatar, nama tampilan, dan email pengguna
- Preview horizontal watchlist (maksimal 6 item) dengan "See All"
- Kartu akses cepat: Edit Profil, Ganti Password, Watchlist, Logout

**Halaman Edit Profil**
- Ubah nama tampilan (disimpan ke Cloud Firestore)
- Upload foto profil baru dari galeri atau kamera (disimpan di Firebase Storage)

**Halaman Ganti Password**
- Memerlukan re-autentikasi dengan password lama sebelum mengatur password baru
- Menggunakan `reauthenticateWithCredential` + `updatePassword` dari Firebase

---

### 4.12 Navigasi Tab

- 3 tab utama: Home, Search, Profile
- `IndexedStack` menjaga posisi scroll dan state setiap tab
- Animasi aktif/tidak aktif pada ikon dan label tab

---

## 5. API yang Digunakan

### 5.1 The Movie Database (TMDB) API

**Base URL:** `https://api.themoviedb.org/3`

**Autentikasi:** Bearer Token (disimpan di `.env`, tidak di-hardcode)

```
Authorization: Bearer {TMDB_ACCESS_TOKEN}
```

#### Endpoint Film

| No | Endpoint | Method | Fungsi |
|----|----------|--------|--------|
| 1 | `/movie/now_playing?page={p}` | GET | Film yang sedang tayang (paginasi) |
| 2 | `/movie/popular?page={p}` | GET | Film paling populer (paginasi) |
| 3 | `/movie/top_rated?page={p}` | GET | Film rating tertinggi (paginasi) |
| 4 | `/movie/upcoming?page={p}` | GET | Film yang akan datang (paginasi) |
| 5 | `/trending/movie/week` | GET | Film trending mingguan |
| 6 | `/genre/movie/list` | GET | Daftar semua genre film |
| 7 | `/search/movie?query={q}` | GET | Cari film berdasarkan judul |
| 8 | `/search/person?query={q}` | GET | Cari orang (fallback pencarian aktor) |
| 9 | `/person/{id}/movie_credits` | GET | Filmografi seorang aktor |
| 10 | `/discover/movie?sort_by={s}&with_genres={g}&page={p}` | GET | Discover dengan sort + filter genre |
| 11 | `/movie/{id}` | GET | Detail film (durasi, anggaran, dll.) |
| 12 | `/movie/{id}/credits` | GET | Cast dan kru |
| 13 | `/movie/{id}/reviews?page={p}` | GET | Ulasan pengguna (paginasi) |
| 14 | `/movie/{id}/similar?page={p}` | GET | Film serupa |
| 15 | `/movie/{id}/recommendations?page={p}` | GET | Film yang direkomendasikan |
| 16 | `/movie/{id}/watch/providers` | GET | Penyedia streaming/rental/beli |
| 17 | `/movie/{id}/videos` | GET | Trailer dan klip |
| 18 | `/collection/{id}` | GET | Detail koleksi/franchise film |

#### Endpoint Serial TV

| No | Endpoint | Method | Fungsi |
|----|----------|--------|--------|
| 1 | `/tv/airing_today?page={p}` | GET | Serial yang tayang episode baru hari ini |
| 2 | `/tv/on_the_air?page={p}` | GET | Serial yang tayang dalam 7 hari ke depan |
| 3 | `/tv/popular?page={p}` | GET | Serial TV paling populer |
| 4 | `/tv/top_rated?page={p}` | GET | Serial TV rating tertinggi |
| 5 | `/trending/tv/week` | GET | Serial TV trending mingguan |
| 6 | `/genre/tv/list` | GET | Daftar semua genre TV |
| 7 | `/search/tv?query={q}` | GET | Cari serial berdasarkan judul |
| 8 | `/person/{id}/tv_credits` | GET | Serial yang dibintangi seorang aktor |
| 9 | `/discover/tv?sort_by={s}&with_genres={g}&page={p}` | GET | Discover TV dengan sort + filter genre |
| 10 | `/tv/{id}` | GET | Detail serial TV |
| 11 | `/tv/{id}/credits` | GET | Cast dan kru |
| 12 | `/tv/{id}/reviews` | GET | Ulasan pengguna |
| 13 | `/tv/{id}/similar` | GET | Serial serupa |
| 14 | `/tv/{id}/recommendations` | GET | Serial yang direkomendasikan |
| 15 | `/tv/{id}/watch/providers` | GET | Penyedia streaming |
| 16 | `/tv/{id}/videos` | GET | Trailer dan klip |
| 17 | `/tv/{id}/season/{n}` | GET | Detail musim (episode, tanggal tayang) |

**URL Gambar:**
```
Poster  : https://image.tmdb.org/t/p/w500{poster_path}
Backdrop: https://image.tmdb.org/t/p/w780{backdrop_path}
Profil  : https://image.tmdb.org/t/p/w185{profile_path}
```

**Teknik Fetch Paralel (Halaman Detail):**
```dart
final results = await Future.wait([
  _service.getMovieDetail(id),
  _service.getCredits(id),
  _service.getReviews(id),
  _service.getSimilar(id),
  _service.getRecommendations(id),
  _service.getWatchProviders(id),
  _service.getVideos(id),
]);
```

---

### 5.2 Firebase Services

#### Firebase Authentication

**Provider:** Google Firebase — Email & Password

| Operasi | Firebase Method | Keterangan |
|---------|----------------|------------|
| Cek status login | `FirebaseAuth.currentUser` | Dipanggil saat app pertama dibuka |
| Login | `signInWithEmailAndPassword()` | Autentikasi pengguna |
| Registrasi | `createUserWithEmailAndPassword()` | Membuat akun baru |
| Logout | `signOut()` | Mengakhiri sesi pengguna |
| Ganti password | `reauthenticateWithCredential()` + `updatePassword()` | Perubahan password yang aman |

**Pemetaan Kode Error Firebase:**

| Kode Error | Pesan untuk Pengguna |
|------------|----------------------|
| `user-not-found` | Email tidak ditemukan |
| `wrong-password` | Password salah |
| `email-already-in-use` | Email sudah digunakan |
| `weak-password` | Password terlalu lemah |
| `invalid-email` | Format email tidak valid |
| Lainnya | Terjadi kesalahan, coba lagi |

#### Cloud Firestore

**Koleksi yang digunakan:**

| Koleksi | Fungsi |
|---------|--------|
| `users/{uid}/profile` | Nama tampilan dan URL foto profil |
| `users/{uid}/watchlist` | Film dan serial TV yang disimpan |

**Struktur dokumen watchlist:**
```json
{
  "docId":      "movie_12345",
  "mediaType":  "movie",
  "title":      "Interstellar",
  "posterPath": "/path.jpg",
  "voteAverage": 8.4,
  "addedAt":    Timestamp
}
```

#### Firebase Storage

- Foto profil diunggah ke `profile_photos/{uid}.jpg`
- URL unduhan disimpan ke Firestore dan ditampilkan di tab Profil

---

## 6. Alur Navigasi

```
App Launch
    │
    ▼
Splash Screen (animasi logo)
    │
    ├── Sudah login? ──────────────────────────► /home (MainScreen)
    │                                                 │
    └── Belum login? ──► /login (LoginScreen)         ├── Tab: Home
                              │                       ├── Tab: Search
                              ├── Login sukses ──────►│   └── Tab: Profile
                              │
                              └── /register ──► Register sukses ──► /home

Dari Home Tab:
    ├── Klik kategori film ──────────────────► /movies (MovieListScreen)
    ├── Klik kategori TV ────────────────────► /tv (TvListScreen)
    ├── Klik hero / trending film ───────────► /movies/:id (MovieDetailScreen)
    └── Klik trending TV ────────────────────► /tv/:id (TvDetailScreen)

Dari MovieListScreen / TvListScreen:
    └── Klik item ───────────────────────────► /movies/:id atau /tv/:id

Dari MovieDetailScreen / TvDetailScreen:
    ├── Klik "See All Cast" ─────────────────► /cast (CastScreen)
    ├── Klik "See All Reviews" ──────────────► /reviews (ReviewsScreen)
    ├── Klik "See All Similar/Recommended" ──► /related (MediaRelatedScreen)
    └── Klik "Collection" ───────────────────► /collection (CollectionScreen)

Dari Profile Tab:
    ├── Klik "Edit Profile" ─────────────────► /edit-profile (EditProfileScreen)
    ├── Klik "Change Password" ──────────────► /change-password (ChangePasswordScreen)
    └── Klik "See All Watchlist" ────────────► /watchlist (WatchlistScreen)

Dari Search Tab:
    └── Klik hasil pencarian ────────────────► /movies/:id atau /tv/:id
```

**Mekanisme Proteksi Route (GoRouter Redirect):**
```
Setiap navigasi → cek auth state
    ├── Belum login + akses halaman terproteksi → paksa ke /login
    └── Sudah login + akses /login atau /register → paksa ke /home
```

---

## 7. Struktur Folder

```
lib/
├── main.dart                                # Entry point, inisialisasi app & BLoC
│
├── bloc/                                    # State Management (BLoC Pattern)
│   ├── auth_bloc/
│   │   ├── auth_bloc.dart
│   │   ├── auth_event.dart
│   │   └── auth_state.dart
│   ├── movie_bloc/
│   │   ├── movie_bloc.dart
│   │   ├── movie_event.dart
│   │   └── movie_state.dart
│   ├── tv_bloc/
│   │   ├── tv_bloc.dart
│   │   ├── tv_event.dart
│   │   └── tv_state.dart
│   └── watchlist_bloc/
│       ├── watchlist_bloc.dart
│       ├── watchlist_event.dart
│       └── watchlist_state.dart
│
├── data/                                    # Data Layer
│   ├── models/
│   │   ├── movie_model.dart
│   │   ├── movie_detail_model.dart
│   │   ├── genre_model.dart
│   │   ├── cast_model.dart
│   │   ├── review_model.dart
│   │   ├── video_model.dart
│   │   ├── watch_provider_model.dart
│   │   ├── collection_detail_model.dart
│   │   ├── movie_filter.dart
│   │   ├── tv_model.dart
│   │   ├── tv_detail_model.dart
│   │   └── watchlist_model.dart
│   └── services/
│       ├── movie_service.dart               # Panggilan API TMDB untuk film
│       ├── tv_service.dart                  # Panggilan API TMDB untuk serial TV
│       ├── watchlist_service.dart           # CRUD watchlist ke Firestore
│       └── user_service.dart               # Baca/tulis profil pengguna ke Firestore
│
├── screens/                                 # Presentation Layer (UI)
│   ├── splash/
│   │   ├── splash_screen.dart
│   │   └── cinemate_logo_animation.dart
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── register_screen.dart
│   ├── main/
│   │   ├── main_screen.dart                 # Container 3 tab dengan bottom nav
│   │   └── tabs/
│   │       ├── home_tab.dart
│   │       ├── search_tab.dart
│   │       └── profile_tab.dart
│   ├── movie/
│   │   ├── movie_list_screen.dart           # Daftar film paginasi + filter genre/urutan
│   │   ├── movie_detail_screen.dart         # Detail lengkap film
│   │   ├── collection_screen.dart           # Franchise/koleksi film
│   │   ├── cast_screen.dart                 # Grid cast lengkap
│   │   ├── reviews_screen.dart              # Ulasan dengan paginasi
│   │   └── media_related_screen.dart        # Similar / Recommendations
│   ├── tv/
│   │   ├── tv_list_screen.dart              # Daftar serial TV paginasi + filter
│   │   └── tv_detail_screen.dart            # Detail lengkap serial TV
│   └── profile/
│       ├── watchlist_screen.dart            # Watchlist lengkap
│       ├── edit_profile_screen.dart         # Edit nama + foto profil
│       └── change_password_screen.dart      # Ganti password dengan aman
│
├── widgets/
│   └── review_card.dart                     # Widget kartu ulasan yang dapat digunakan ulang
│
└── core/                                    # Shared / Core Layer
    ├── constants/
    │   └── api_constants.dart               # Semua endpoint TMDB
    ├── routes/
    │   └── app_router.dart                  # Konfigurasi GoRouter & proteksi route
    └── theme/
        ├── theme.dart                       # Barrel export
        ├── app_theme.dart                   # Konfigurasi ThemeData
        ├── app_colors.dart                  # Konstanta palet warna
        ├── app_typography.dart              # Definisi TextStyle (Google Fonts)
        ├── app_shadows.dart                 # Preset BoxShadow
        └── app_spacing.dart                 # Konstanta spacing/padding
```

---

## 8. Cara Menjalankan Aplikasi

### Prasyarat
- Flutter SDK versi 3.11.1 atau lebih baru
- Android Studio / VS Code
- Akun TMDB untuk mendapatkan API token
- Project Firebase dengan Authentication, Firestore, dan Storage yang sudah diaktifkan

### Langkah Setup

**1. Clone repository**
```bash
git clone https://github.com/username/cinemate.git
cd cinemate
```

**2. Setup environment variable**
```bash
cp .env.example .env
# Edit .env dan isi token TMDB kamu:
# TMDB_ACCESS_TOKEN=your_tmdb_bearer_token_here
```

**3. Setup Firebase**
- Buat project baru di [Firebase Console](https://console.firebase.google.com)
- Aktifkan **Authentication** (Email/Password)
- Aktifkan **Cloud Firestore** (mode production atau test)
- Aktifkan **Firebase Storage**
- Download `google-services.json` → letakkan di `android/app/`
- Jalankan `flutterfire configure` untuk regenerate `firebase_options.dart`

**4. Install dependencies**
```bash
flutter pub get
```

**5. Jalankan aplikasi**
```bash
flutter run
```

**6. (Opsional) Build release APK**
```bash
flutter build apk --release
```

---

*Dokumentasi ini dibuat untuk keperluan pengumpulan Final Project Bootcamp Flutter — Cinemate v2.0.*
