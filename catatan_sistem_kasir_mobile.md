# Catatan Sistem — Aplikasi Kasir Toko (kasir_mobile)

**Repository:** [syawil66/kasir_mobile](https://github.com/syawil66/kasir_mobile)  
**Branch yang ditinjau:** `syawil`  
**Commit yang ditinjau:** `298d1b60464c6bd4b81a887fa3533777f2401aae` — *add: menambahkan user di firestore dan menyesuaikan user model dan auth controller agar bisa mengambil user id dari firestore*  
**Tanggal commit:** 18 November 2026  
**Bahasa/framework:** Dart dan Flutter  
**Backend yang terpakai:** Firebase Authentication dan Cloud Firestore

> **Catatan penting tentang branch:** branch `syawil` digunakan sebagai dasar catatan karena merupakan branch dengan perubahan paling baru pada saat repository diperiksa. Branch `main` masih berisi aplikasi contoh Flutter bawaan (counter demo), bukan implementasi kasir. Jadi, ketika membuka repository di GitHub, pastikan memilih branch `syawil` untuk melihat kode sistem yang dibahas di dokumen ini.

---

## 1. Gambaran umum sistem

Aplikasi Kasir Toko adalah aplikasi kasir berbasis Flutter yang ditujukan untuk membantu operasional toko melalui satu aplikasi. Struktur dan antarmukanya dibagi menjadi tiga area utama: **Dashboard**, **Kasir (Point of Sale/POS)**, dan **Inventaris/Stok**. Aplikasi juga menyediakan halaman login untuk pengguna.

Dari kode yang tersedia, sistem saat ini sudah memiliki autentikasi pengguna yang memakai Firebase. Sementara itu, modul inventaris dan transaksi POS sudah memiliki rancangan tampilan dan sebagian logika dasar, tetapi belum terhubung ke penyimpanan data permanen. Banyak angka dan daftar pada dashboard maupun POS masih berupa data contoh (*hard-coded/dummy data*).

Dengan demikian, kondisi yang paling akurat untuk menggambarkan proyek ini adalah **prototipe aplikasi kasir dengan autentikasi Firebase dan antarmuka awal untuk pengelolaan produk serta transaksi**, bukan sistem kasir penuh yang seluruh datanya sudah tersimpan dan tersinkronisasi.

## 2. Tujuan sistem

Berdasarkan modul dan antarmuka yang dibuat, tujuan sistem adalah:

1. Menyediakan akses aplikasi melalui login pengguna.
2. Menampilkan ringkasan kondisi toko melalui dashboard.
3. Menyediakan halaman untuk melihat dan mengelola data produk serta stok.
4. Menyediakan alur kasir untuk memilih produk, mengelola keranjang, dan melakukan pembayaran.
5. Menyiapkan pemisahan peran pengguna, setidaknya antara `admin` dan `kasir`.

Poin-poin tersebut menggambarkan tujuan dan rancangan fitur. Implementasi aktual masing-masing fitur dijelaskan pada bagian 5.

## 3. Pengguna dan peran

Model pengguna (`UserModel`) memiliki empat atribut:

| Atribut | Keterangan |
|---|---|
| `id` | UID pengguna dari Firebase Authentication |
| `username` | Nama akun/username dari dokumen Firestore |
| `name` | Nama tampilan pengguna |
| `role` | Peran pengguna, misalnya `admin` atau `kasir` |

`AuthController` menyediakan pemeriksaan `isAdmin` berdasarkan nilai `currentUser.role == 'admin'`. Namun, pada kode antarmuka yang ditinjau belum terlihat pembatasan menu atau tindakan berdasarkan peran. Jadi, **pemisahan role sudah disiapkan pada model/controller, tetapi otorisasi fitur berdasarkan role belum tampak diterapkan**.

## 4. Teknologi dan struktur aplikasi

### Teknologi

- **Flutter** sebagai framework antarmuka aplikasi.
- **Dart** sebagai bahasa pemrograman.
- **Material 3** untuk komponen antarmuka.
- **Firebase Core** untuk inisialisasi Firebase.
- **Firebase Authentication** untuk login email dan password.
- **Cloud Firestore** untuk mengambil dokumen profil pengguna.

Dependensi aplikasi tercatat pada `pubspec.yaml`. Konfigurasi Firebase untuk platform Android, iOS, macOS, Windows, dan Web tersedia di `lib/firebase_options.dart`. Konfigurasi Linux secara eksplisit belum disediakan.

### Struktur folder utama

```text
lib/
├── app/
│   ├── constants/       # Konstanta warna dan gaya teks
│   └── routes/          # Rute/navigasi aplikasi
├── features/
│   ├── auth/            # Login, model user, autentikasi
│   ├── dashboard/       # Dashboard dan navigasi utama
│   ├── inventory/       # Model, controller, daftar dan form produk
│   └── pos/             # Kasir, keranjang, pembayaran, model transaksi
├── shared/
│   ├── utils/           # Format mata uang dan utilitas bersama
│   └── widgets/         # Komponen UI yang dapat digunakan ulang
├── firebase_options.dart
└── main.dart
```

Pola pemisahan berdasarkan fitur membuat bagian autentikasi, dashboard, inventaris, dan POS lebih mudah dikembangkan secara terpisah.

## 5. Modul dan alur kerja

### 5.1 Login dan autentikasi

**Alur yang diterapkan di kode:**

1. Pengguna memasukkan email dan password pada `LoginScreen`.
2. Aplikasi memvalidasi agar kedua kolom tidak kosong.
3. `AuthController.login()` memanggil Firebase Authentication melalui `signInWithEmailAndPassword()`.
4. Setelah berhasil, aplikasi mengambil UID pengguna.
5. Aplikasi mencari dokumen `users/{uid}` pada Cloud Firestore.
6. Jika dokumen ditemukan, data `username`, `name`, dan `role` dibaca menjadi `UserModel` dan disimpan dalam variabel statis `currentUser`.
7. Login berhasil mengarahkan pengguna ke halaman dashboard.

Jika dokumen pengguna tidak ditemukan, aplikasi melakukan sign-out dan mengembalikan pesan bahwa data role pengguna tidak ditemukan. Login juga menangani beberapa jenis kesalahan autentikasi seperti kredensial salah, email tidak valid, dan terlalu banyak percobaan.

**Catatan implementasi:** controller memiliki fungsi `logout()` yang memanggil Firebase sign-out dan mengosongkan `currentUser`. Akan tetapi, tombol keluar pada `HomeScreen` saat ini hanya menampilkan dialog konfirmasi lalu berpindah ke halaman login. Tombol tersebut belum memanggil `AuthController.logout()`. Ini perlu diselaraskan agar sesi Firebase benar-benar diakhiri.

### 5.2 Dashboard

Dashboard menampilkan ringkasan operasional toko, berupa:

- Nilai penjualan hari ini.
- Jumlah transaksi/nota.
- Jumlah barang yang stoknya menipis.
- Aktivitas atau transaksi terakhir.

Pada kode saat ini, angka seperti penjualan Rp1.500.000, 24 nota, stok menipis 3 barang, dan transaksi `TRX-001` adalah **data statis untuk contoh tampilan**. Belum terlihat pengambilan angka-angka tersebut dari koleksi transaksi atau produk di Firestore.

### 5.3 Navigasi utama

`MainNavigationScreen` menyediakan tiga menu melalui navigasi bawah:

1. **Dashboard** — ringkasan toko.
2. **Kasir** — halaman POS untuk proses penjualan.
3. **Stok** — halaman inventaris produk.

Perpindahan tab dilakukan dengan mengubah indeks halaman aktif.

### 5.4 Inventaris produk

Model produk (`ProductModel`) memiliki atribut:

| Atribut | Keterangan |
|---|---|
| `id` | Identitas produk |
| `name` | Nama produk |
| `price` | Harga produk |
| `stock` | Jumlah stok |
| `category` | Kategori produk |

Halaman inventaris yang sudah dibuat menyediakan:

- Ringkasan jumlah jenis produk.
- Perhitungan total stok seluruh produk.
- Indikator jumlah produk dengan stok menipis.
- Pencarian berdasarkan nama, ID, atau kategori.
- Daftar produk yang menampilkan nama, ID, kategori, harga, dan stok.
- Halaman detail produk.
- Form tambah produk dengan validasi nama, harga, stok, dan kategori.

Produk ditandai memiliki stok menipis ketika jumlah stok **kurang dari atau sama dengan 5 unit**.

**Batas implementasi saat ini:** `InventoryController` mengisi tiga produk contoh secara langsung di dalam list lokal. Produk baru dari form ditambahkan ke list tersebut di memori aplikasi. Belum terlihat operasi baca/tulis produk ke Firestore, dan belum tersedia alur edit maupun hapus produk pada antarmuka yang ditinjau. Perubahan data lokal juga tidak dirancang untuk bertahan setelah aplikasi dimulai ulang.

### 5.5 Kasir / Point of Sale (POS)

Halaman POS dirancang untuk mendukung aktivitas penjualan. Komponen antarmukanya meliputi:

- Header toko dan nama/peran kasir.
- Ringkasan jumlah transaksi dalam satu shift.
- Kolom pencarian barang serta ikon pemindaian.
- Filter kategori seperti Semua, Sembako, Minuman, Snack, dan Lainnya.
- Daftar produk dalam bentuk kartu.
- Tombol keranjang yang membuka `CartBottomSheet`.
- Dialog metode pembayaran (`PaymentDialog`).

Alur UI yang digambarkan adalah memilih barang, membuka keranjang, meninjau item dan total, kemudian menuju pembayaran. Dialog pembayaran menampilkan pilihan Tunai dan QRIS serta kolom uang diterima.

**Batas implementasi saat ini:** daftar produk POS dan nilainya dibuat sebagai data contoh yang terpisah dari data inventaris. Kolom pencarian, filter kategori, kartu produk, dan ikon tambah belum dihubungkan menjadi alur transaksi aktif. Isi keranjang juga ditulis langsung sebagai contoh; tombol tambah/kurang kuantitas belum melakukan perubahan. Nilai total Rp39.500 masih statis. Pilihan Tunai/QRIS belum mengubah metode pembayaran secara fungsional, input uang diterima belum menghitung kembalian, dan tombol selesaikan transaksi hanya menutup dialog.

### 5.6 Model keranjang dan transaksi

Terdapat model dasar pada `transaction_models.dart`:

- `CartItemModel` menyimpan produk dan kuantitas.
- `totalPrice` menghitung harga produk dikali kuantitas.
- `TransactionModel` menyimpan ID transaksi, daftar item, total transaksi, dan tanggal.

`PosController` juga menyediakan fungsi dasar untuk menambah produk ke keranjang, menaikkan kuantitas jika produk yang sama telah ada, menghitung grand total, dan mengosongkan keranjang.

Namun, controller dan model tersebut belum terhubung dengan halaman POS yang saat ini menggunakan daftar produk dan isi keranjang statis. Model transaksi juga belum digunakan untuk menyimpan transaksi ke Firestore. File `receipt_screen.dart` masih kosong.

## 6. Penyimpanan data: kondisi yang terlihat di repository

| Data | Kondisi implementasi |
|---|---|
| Akun dan kredensial login | Dikelola oleh Firebase Authentication |
| Profil pengguna dan role | Dibaca dari dokumen `users/{uid}` di Cloud Firestore |
| Data produk inventaris | Data contoh pada list lokal `InventoryController` |
| Produk pada halaman POS | Data contoh statis di `PosScreen`, terpisah dari inventaris |
| Isi keranjang | Contoh statis pada `CartBottomSheet`; terdapat controller dasar yang belum diintegrasikan |
| Data transaksi | Model sudah didefinisikan, tetapi belum terlihat proses penyimpanan transaksi |
| Ringkasan dashboard | Angka dan aktivitas statis untuk tampilan |

**Kesimpulan penyimpanan:** dari kode yang ditinjau, Firestore baru digunakan secara nyata untuk membaca profil pengguna saat login. Belum ditemukan implementasi penyimpanan koleksi produk, stok, keranjang, atau transaksi ke Firestore.

## 7. Tampilan antarmuka

Sebagian besar layar menggunakan tema pastel pink, lavender, dan putih. Komponen yang digunakan mencakup kartu ringkasan, daftar produk, form input, dialog, bottom sheet, serta navigasi bawah. Gaya ini diterapkan pada halaman login, dashboard, dan inventaris. POS masih memakai beberapa komponen dengan gaya yang lebih gelap pada bagian keranjang dan pembayaran.

## 8. Status fitur saat ini

| Fitur | Status berdasarkan kode branch `syawil` |
|---|---|
| Login email/password dengan Firebase Auth | Sudah diimplementasikan |
| Membaca profil/role dari Firestore | Sudah diimplementasikan |
| Model role admin/kasir | Sudah tersedia; pembatasan akses belum tampak |
| Navigasi Dashboard, Kasir, Stok | Sudah diimplementasikan |
| Tampilan dashboard | Sudah dibuat, data masih statis |
| Pencarian produk inventaris | Sudah berfungsi pada data lokal |
| Detail produk | Sudah dibuat |
| Tambah produk | Berfungsi pada data lokal sementara |
| Edit dan hapus produk | Belum tersedia pada layar yang ditinjau |
| Penyimpanan inventaris ke Firestore | Belum terlihat |
| Katalog produk POS | Tampilan ada, sumber data statis |
| Tambah produk ke keranjang dari katalog | Belum terhubung pada UI saat ini |
| Ubah kuantitas item keranjang | Belum berfungsi pada bottom sheet |
| Hitung total transaksi | Ada logika dasar pada `PosController`, tetapi belum terintegrasi ke UI POS |
| Tunai dan QRIS | Baru berupa tampilan pilihan |
| Hitung uang kembalian | Belum diimplementasikan |
| Simpan transaksi | Belum terlihat |
| Cetak/tampilkan nota transaksi | Belum diimplementasikan; `receipt_screen.dart` kosong |
| Logout Firebase dari tombol dashboard | Perlu diperbaiki; saat ini hanya navigasi ke login |

## 9. Hal yang perlu diperhatikan / pekerjaan lanjutan

Prioritas pengembangan yang disarankan agar prototipe menjadi sistem kasir yang utuh:

1. **Satukan sumber data produk.** POS sebaiknya membaca produk yang sama dengan inventaris, bukan memakai daftar contoh terpisah.
2. **Hubungkan inventaris dengan Firestore.** Buat proses tambah, baca, ubah, dan hapus produk. Perubahan stok perlu tersimpan dan dapat dibaca ulang setelah aplikasi dibuka kembali.
3. **Integrasikan POS dengan `PosController`.** Kartu produk perlu dapat menambah item ke keranjang, kuantitas dapat diubah, dan total dihitung dari item aktual.
4. **Lengkapi proses pembayaran.** Simpan metode pembayaran, validasi uang diterima untuk pembayaran tunai, hitung kembalian, dan tentukan alur konfirmasi pembayaran QRIS.
5. **Buat penyimpanan transaksi.** Simpan ID, waktu, item, kuantitas, harga saat transaksi, total, metode pembayaran, serta pengguna/kasir yang memproses.
6. **Bangun nota transaksi.** Gunakan data transaksi yang tersimpan untuk menampilkan detail nota.
7. **Hubungkan dashboard ke data nyata.** Ringkasan penjualan, jumlah transaksi, aktivitas terakhir, dan stok menipis harus dihitung dari data produk dan transaksi.
8. **Perbaiki pengelolaan sesi dan role.** Panggil fungsi logout Firebase dari tombol Keluar, periksa sesi saat aplikasi dibuka, dan terapkan pembatasan tindakan/menu sesuai role.
9. **Tambahkan aturan keamanan Firestore.** Pastikan pengguna hanya dapat membaca atau mengubah data yang sesuai dengan kewenangannya; jangan mengandalkan pemeriksaan role di sisi tampilan saja.
10. **Perbarui pengujian.** `test/widget_test.dart` masih berupa tes counter bawaan Flutter. Buat tes untuk login, validasi form produk, perhitungan keranjang, pembayaran, dan penyimpanan transaksi.

## 10. Kesimpulan

Proyek `kasir_mobile` sudah memiliki fondasi aplikasi Flutter yang cukup jelas: pemisahan modul, navigasi utama, UI login, dashboard, inventaris, serta POS. Integrasi Firebase Authentication dan pembacaan profil pengguna dari Firestore merupakan bagian backend yang sudah diterapkan.

Akan tetapi, fitur inti operasional kasir—terutama persistensi inventaris, sinkronisasi produk dengan POS, pengelolaan keranjang, pembayaran, penyimpanan transaksi, dan nota—masih perlu dilanjutkan. Catatan ini karena itu membedakan antara **fitur yang sudah ada sebagai UI/logika lokal** dan **fitur yang sudah benar-benar terhubung ke backend**.

---

## 11. File sumber utama

Tautan berikut mengarah ke file pada branch `syawil`:

- [Inisialisasi aplikasi — `lib/main.dart`](https://github.com/syawil66/kasir_mobile/blob/syawil/lib/main.dart)
- [Konfigurasi dependency — `pubspec.yaml`](https://github.com/syawil66/kasir_mobile/blob/syawil/pubspec.yaml)
- [Autentikasi — `auth_controller.dart`](https://github.com/syawil66/kasir_mobile/blob/syawil/lib/features/auth/controllers/auth_controller.dart)
- [Model pengguna — `user_model.dart`](https://github.com/syawil66/kasir_mobile/blob/syawil/lib/features/auth/models/user_model.dart)
- [Halaman login — `login_screen.dart`](https://github.com/syawil66/kasir_mobile/blob/syawil/lib/features/auth/views/login_screen.dart)
- [Dashboard — `home_screen.dart`](https://github.com/syawil66/kasir_mobile/blob/syawil/lib/features/dashboard/views/home_screen.dart)
- [Navigasi utama — `main_navigation_screen.dart`](https://github.com/syawil66/kasir_mobile/blob/syawil/lib/features/dashboard/views/main_navigation_screen.dart)
- [Inventaris — `inventory_screen.dart`](https://github.com/syawil66/kasir_mobile/blob/syawil/lib/features/inventory/views/inventory_screen.dart)
- [Controller inventaris — `inventory_controller.dart`](https://github.com/syawil66/kasir_mobile/blob/syawil/lib/features/inventory/controllers/inventory_controller.dart)
- [Form produk — `product_form_screen.dart`](https://github.com/syawil66/kasir_mobile/blob/syawil/lib/features/inventory/views/product_form_screen.dart)
- [Halaman POS — `pos_screen.dart`](https://github.com/syawil66/kasir_mobile/blob/syawil/lib/features/pos/views/pos_screen.dart)
- [Controller POS — `pos_controller.dart`](https://github.com/syawil66/kasir_mobile/blob/syawil/lib/features/pos/controllers/pos_controller.dart)
- [Model transaksi — `transaction_models.dart`](https://github.com/syawil66/kasir_mobile/blob/syawil/lib/features/pos/models/transaction_models.dart)
- [Bottom sheet keranjang — `cart_bottom_sheet.dart`](https://github.com/syawil66/kasir_mobile/blob/syawil/lib/features/pos/views/widgets/cart_bottom_sheet.dart)
- [Dialog pembayaran — `payment_dialog.dart`](https://github.com/syawil66/kasir_mobile/blob/syawil/lib/features/pos/views/widgets/payment_dialog.dart)
