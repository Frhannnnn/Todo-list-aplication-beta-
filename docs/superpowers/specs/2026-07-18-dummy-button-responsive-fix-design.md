# Perbaikan Tombol Dummy & Responsivitas Layar

## Latar belakang

Survei kode menemukan 2 tombol tanpa fungsi (`onTap`/`onPressed` tidak ada sama sekali) dan 4 titik layout dengan ukuran fixed-pixel yang berisiko overflow di layar kecil atau saat text-scale besar. Tidak ditemukan fitur stub/placeholder lain — sisa aplikasi sudah fungsional.

## Lingkup

### 1. Tombol dummy

- `lib/screens/calendar_screen.dart:109-119` — tombol ikon `Icons.today_rounded` di header, saat ini `Container` tanpa `GestureDetector`/`InkWell`. Disambungkan agar men-jump kalender ke tanggal hari ini, mengikuti pola `_goToDate(DateTime.now())` yang sudah ada di `lib/screens/schedule_screen.dart:179-199`.
- `lib/screens/dashboard_screen.dart:62-71` — tombol ikon `Icons.more_horiz` di header, dihapus dari `_buildHeader()` karena tidak ada fitur yang dimaksud di baliknya.

### 2. Perbaikan responsif

- `lib/screens/pomodoro_timer_screen.dart:257-259` — ring countdown `SizedBox(width: 260, height: 260)` di dalam `Column` non-scroll. Dibungkus agar konten bisa scroll (pola `SingleChildScrollView` + `ConstrainedBox(minHeight)` seperti di `calendar_screen.dart:283-328`), supaya tidak overflow di layar pendek (mis. layar < 600px tinggi).
- `lib/main.dart:132-184` — bottom nav bar: `Row` polos dengan 6 item diubah agar tiap item dibungkus `Expanded`, supaya aman di layar sempit (~320px) atau saat font system diperbesar.
- `lib/screens/priority_screen.dart:43-61` dan `_QuadrantCard` (baris 309-367) — konten kartu (icon row, action tag, daftar tugas) dalam `SliverGrid` dengan `childAspectRatio` fixed dibuat lebih toleran terhadap teks besar (mis. dengan `Flexible`/scroll pada isi kartu), tanpa mengubah struktur grid 2×2 itu sendiri.
- `lib/screens/dashboard_screen.dart:200-216` — progress ring `SizedBox(width: 120, height: 120)` di dalam `Expanded(flex: 4)` disesuaikan agar ukurannya proporsional terhadap ruang yang tersedia (mis. `LayoutBuilder`/batas maksimum), bukan angka pixel tetap.

## Di luar lingkup

- Tidak ada fitur yang dihapus atau diganti perilakunya, selain penghapusan tombol dummy Dashboard yang disepakati.
- Tidak mengubah desain visual (warna, tipografi, ikon) — hanya perilaku tombol dan perilaku layout terhadap ukuran layar.

## Testing

Build & jalankan di perangkat fisik yang sudah terhubung via ADB (Infinix X6873, serial `143352554V103518`) menggunakan `flutter run -d <device_id>`. Verifikasi visual pada layar Kalender, Dashboard, Pomodoro Timer, Prioritas, dan navigasi bawah.
