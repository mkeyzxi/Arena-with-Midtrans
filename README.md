# Arena Futsal App

Aplikasi booking lapangan futsal yang terintegrasi dengan sistem pembayaran Midtrans, dirancang untuk mempermudah manajemen jadwal dan pemesanan.

---

## 🚀 Fitur Utama

-   **Autentikasi Pengguna**: Login & Registrasi dinamis untuk user, dengan satu akun admin yang telah ditentukan.
-   **Booking Lapangan**:
    -   Pengguna dapat memesan lapangan dengan memilih tanggal, jam, dan durasi.
    -   Validasi jadwal yang canggih untuk mencegah booking tumpang tindih.
-   **Booking Member**:
    -   Fitur khusus untuk admin untuk membuat jadwal booking berulang (member) setiap minggu selama 3 bulan.
    -   Terdapat diskon khusus untuk booking member.
-   **Pembayaran**:
    -   Integrasi dengan **Midtrans Sandbox** untuk simulasi pembayaran nyata.
    -   Opsi pembayaran `DP (50%)` atau `Lunas`.
-   **Dashboard Admin**:
    -   Melihat daftar semua booking dengan detail lengkap.
    -   Fitur monitoring jadwal yang menampilkan blok waktu tersedia, terbooking, dan telah lewat secara visual.
    -   Admin dapat mengubah status booking (Paid, Pending, Cancelled) dan membuat booking baru untuk user lain.

---

## ⚙️ Teknologi yang Digunakan

-   **Frontend**: Flutter & Dart
-   **Manajemen State**: `setState()`
-   **Database**: SQLite (lokal, menggunakan paket `sqflite` dan `path_provider`)
-   **Pembayaran**: Midtrans (terintegrasi langsung menggunakan `http` dan `webview_flutter`)
-   **Manajemen Tanggal**: `intl`

---

## 🛠️ Cara Memulai

Ikuti langkah-langkah di bawah ini untuk menjalankan proyek di lingkungan lokal Anda.

### 1. Kloning Repositori

```bash
git clone [https://github.com/mkeyzxi/Arena-with-Midtrans.git](https://github.com/mkeyzxi/Arena-with-Midtrans.git)
cd Arena-with-Midtrans
```

### 2. Instal Dependensi

```bash
flutter pub get
```

### 3. Konfigurasi Android
Untuk memastikan Midtrans dapat terhubung dengan benar di Android, pastikan <b>file AndroidManifest.xml</b> Anda memiliki konfigurasi berikut:
```bash
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application
        ...
        android:usesCleartextTraffic="true">
        ...
    </application>
</manifest>
```
Penting: Pengaturan android:usesCleartextTraffic="true" hanya direkomendasikan untuk pengembangan dan lingkungan sandbox. Jangan gunakan ini dalam aplikasi produksi.

### 4. Akun Awal
Untuk login, gunakan kredensial berikut:
- Admin: admin@arena.com / admin
- User: Gunakan fitur Daftar Sekarang untuk membuat akun user baru.

### 5. Jalankan Aplikasi
Jalankan perintah berikut untuk memulai aplikasi di emulator atau perangkat fisik Anda:

```bash
flutter run
```

---

🌐 Deployment
Proyek ini telah dideploy sebagai aplikasi web:

app-arena.netlify.app

---

🤝 Kontributor
Proyek ini dikembangkan oleh:

- Muhammad Makbul N (mkeyzxi)
- Rio Zulfitra
