# Dokumen Planning Perbaikan — Aplikasi Tugasku

> **Untuk siapa dokumen ini:** programmer junior / model AI pelaksana.
> **Sifat dokumen:** planning tingkat tinggi (high-level). Berisi *apa* yang harus dicapai dan *arah* solusinya, **bukan** kode jadi. Silakan pahami dulu keseluruhan sebelum menyentuh kode, dan konfirmasi jika ada bagian yang ambigu.
> **Aturan main:** setiap perubahan harus tetap kompatibel dengan data lama pengguna (jangan sampai tugas yang sudah tersimpan hilang atau error saat dibuka). Aplikasi menyimpan data di `SharedPreferences` lewat `TaskProvider`.

---

## Peta Kode Singkat (biar tidak tersesat)

| Bagian | File |
|---|---|
| Model data tugas | `lib/models/task_model.dart` |
| Layar tambah/edit tugas | `lib/screens/add_edit_task_screen.dart` |
| Otak state & penyimpanan | `lib/services/task_provider.dart` |
| Kartu tugas di daftar | `lib/widgets/task_card_widget.dart` |
| Daftar/tabel tugas | `lib/screens/task_list_screen.dart` |
| Dashboard / ringkasan | `lib/screens/dashboard_screen.dart` |

Istilah penting:
- **Lingkup Tugas** (`lingkupTugas`) = kategori besar konteks, contoh: *Perkuliahan*, *Tugas Rumah*, *Pekerjaan*. Disimpan sebagai `customScopes`.
- **Kategori** (`category`) = jenis tugas, contoh: *Tugas*, *Ujian*, *Proyek*. Disimpan sebagai `customCategories`.

---

# BAGIAN A — Perbaikan Utama (permintaan awal)

## Issue #1 — Setelah simpan, kembali ke tabel data tugas

**Masalah:** Setelah menekan "Tambah Tugas" atau "Simpan Perubahan", pengguna tidak diarahkan ke halaman daftar/tabel tugas. Alurnya terasa menggantung / kembali ke tempat yang tidak diharapkan.

**Tujuan:** Sesudah tugas berhasil disimpan (baik tambah maupun edit), pengguna langsung melihat **tabel data tugas** dengan tugas terbaru sudah tampil di sana.

**Arah solusi (high-level):**
- Lihat method penyimpanan di `add_edit_task_screen.dart` (`_save()`). Saat ini ia hanya "menutup" halaman dan kembali ke layar sebelumnya. Perlu dipastikan tujuan akhirnya adalah layar daftar tugas (`task_list_screen.dart`), bukan sekadar kembali ke pemanggil.
- Putuskan pola navigasinya: entah mengarahkan langsung ke layar daftar tugas, atau memastikan layar daftar tugas yang membuka form ini akan menampilkan data terbaru saat kembali.
- Pastikan daftar benar-benar ter-refresh (data dari `TaskProvider` sudah otomatis memberi tahu UI, jadi fokus utama di sini adalah **navigasinya**, bukan pengambilan data).

**Selesai bila:** menambah tugas baru maupun mengedit tugas selalu berakhir di tabel data tugas, dan tugas yang barusan disimpan terlihat di sana.

---

## Issue #2 — Kolom "Mata Kuliah" khusus lingkup Perkuliahan

**Masalah:** Kalau lingkup tugasnya *Perkuliahan*, tidak ada tempat mencatat nama mata kuliah, sehingga nanti tidak bisa dibuat ringkasan (summarize) per mata kuliah.

**Tujuan:** Ketika lingkup tugas yang dipilih adalah *Perkuliahan*, muncul **kolom tambahan "Mata Kuliah"**. Data ini nantinya bisa dipakai untuk mengelompokkan/meringkas tugas per mata kuliah.

**Arah solusi (high-level):**
- Tambahkan satu atribut baru pada model tugas (`task_model.dart`) untuk menyimpan nama mata kuliah. Buat **opsional/boleh kosong** supaya data tugas lama tetap valid, dan tangani di proses baca-tulis JSON (`toJson`/`fromJson`) dengan aman (data lama yang belum punya field ini tidak boleh error).
- Di form tambah/edit (`add_edit_task_screen.dart`), tampilkan kolom "Mata Kuliah" **hanya jika** lingkup terpilih = *Perkuliahan*. Jika lingkup lain, kolom disembunyikan dan nilainya dikosongkan.
- Teruskan nilai mata kuliah ke `TaskProvider` (`tambahTugas` / `editTugas`) agar ikut tersimpan.
- Sediakan tampilan ringkasan (summarize) per mata kuliah — minimal pengelompokan sederhana di layar yang relevan (dashboard/daftar). Cukup versi dasar dulu; boleh dirapikan belakangan.

**Keputusan desain (sudah diputuskan):**
- Patokan kemunculan kolom: **nama lingkup persis "Perkuliahan"** (pencocokan literal). Ini paling sederhana untuk tahap awal. ⚠️ Kelemahan yang disadari: lingkup itu custom — kalau user mengganti nama lingkupnya (mis. "Kuliah S2"), kolom tidak muncul. Peningkatan ke penanda "lingkup akademik" per lingkup bisa dilakukan belakangan; tulis komentar di kode agar mudah ditemukan.
- Input mata kuliah: **ketik bebas** dulu, bukan dropdown. Daftar mata kuliah yang bisa dipilih ulang boleh menyusul.
- Ringkasan per mata kuliah nantinya diperkaya oleh data waktu fokus dari Pomodoro (lihat Issue #5) — cukup jumlah tugas dulu, jam fokus menyusul.

**Selesai bila:** memilih lingkup *Perkuliahan* memunculkan kolom Mata Kuliah, nilainya tersimpan, dan tugas bisa dilihat terkelompok per mata kuliah.

---

## Issue #3 — Error merah + tulisan kuning saat menambah kategori

**Masalah:** Saat menambahkan kategori (dan kemungkinan juga saat menambah lingkup), muncul tampilan error khas Flutter (latar merah / garis kuning-hitam "overflow" atau layar error kuning). Ini menandakan ada masalah rendering atau state saat dialog "Tambah Kategori" dijalankan.

**Tujuan:** Proses menambah kategori berjalan mulus tanpa error visual apa pun.

**Arah solusi (high-level):**
- Reproduksi dulu: buka form tugas → tekan tombol tambah kategori → amati kapan persis error muncul (saat dialog dibuka, saat mengetik, atau setelah menekan "Tambah").
- Periksa dialog tambah kategori dan tambah lingkup di `add_edit_task_screen.dart` (`_showAddCategoryDialog` dan `_showAddScopeDialog`). Perhatikan hal-hal yang umum jadi biang error di sini:
  - pemanggilan `setState` yang menyentuh widget yang sudah tidak aktif,
  - `TextEditingController` yang siklus hidupnya bertabrakan dengan dialog,
  - layout di dalam dialog yang bisa *overflow* (mis. teks/indikator loading yang tidak muat).
- Perbaiki akar masalahnya, bukan sekadar menyembunyikan pesan error.

**Selesai bila:** menambah kategori baru berkali-kali (termasuk nama panjang, dan menekan cepat berulang) tidak pernah memunculkan layar/garis error, dan kategori baru langsung bisa dipakai.

---

## Issue #4 — Kategori dipisah per lingkup tugas (tidak dibagi-pakai)

**Masalah:** Saat ini daftar kategori bersifat **global** — dipakai bersama oleh semua lingkup tugas. Seharusnya tiap lingkup tugas punya daftar kategorinya **sendiri**, berdiri sendiri, dan tidak bercampur dengan lingkup lain. Nama boleh kebetulan sama antar lingkup, tapi tetap dihitung sebagai milik masing-masing lingkup.

**Tujuan:** Kategori "milik" satu lingkup tugas tertentu. Saat pengguna memilih lingkup, dropdown kategori hanya menampilkan kategori milik lingkup tersebut. Menambah kategori berarti menambah ke lingkup yang sedang aktif saja.

**Arah solusi (high-level):**
- Ubah cara `TaskProvider` menyimpan kategori: dari **satu daftar global** menjadi **daftar per lingkup** (bayangkan: tiap nama lingkup memetakan ke daftar kategorinya sendiri). Sesuaikan juga cara menyimpan/memuat dari `SharedPreferences`.
- Sesuaikan fungsi tambah/hapus kategori agar selalu tahu "kategori ini untuk lingkup mana".
- Di form tugas, dropdown kategori harus mengikuti lingkup yang sedang dipilih. Kalau lingkup diganti, daftar kategori ikut berganti, dan pilihan kategori direset ke nilai yang valid untuk lingkup baru.
- **Nasib kategori & tugas saat lingkup dihapus (penting):** karena kategori sekarang milik lingkup, menghapus sebuah lingkup harus ikut membereskan kategori-kategorinya. Selain itu, tugas menyimpan lingkup sebagai teks — tugas yang lingkupnya dihapus jadi "yatim" (menunjuk lingkup yang tidak ada lagi). Sebelum menghapus lingkup yang masih dipakai tugas, aplikasi harus memberi tahu user dan menawarkan pilihan (mis. pindahkan tugas ke lingkup lain, atau batalkan penghapusan). Jangan biarkan penghapusan diam-diam merusak data.
- **Migrasi data lama (penting):** pengguna lama punya kategori global dan tugas yang sudah menunjuk kategori tertentu. Rancang langkah migrasi sekali-jalan supaya kategori lama tetap muncul di lingkup yang sesuai dan tidak ada tugas yang kehilangan kategorinya. Cara paling aman: salin daftar kategori global lama ke **setiap** lingkup yang ada, lalu user merapikan sendiri.

**Selesai bila:** dua lingkup berbeda bisa punya kategori dengan susunan berbeda (atau kebetulan sama namanya) tanpa saling memengaruhi; menghapus lingkup tidak meninggalkan kategori/tugas yatim tanpa sepengetahuan user; dan data pengguna lama tetap utuh setelah update.

---

## Issue #5 — Tombol "Mulai Tugas" memunculkan timer Pomodoro

**Masalah:** Saat menekan "Mulai" pada sebuah tugas, aplikasi hanya mengubah status tugas menjadi *Sedang Dikerjakan*. Belum ada alat bantu fokus.

**Tujuan:** Menekan "Mulai" memunculkan **timer**, dan modelnya menerapkan **teknik Pomodoro** (siklus fokus lalu istirahat).

**Arah solusi (high-level):**
- Saat "Mulai" ditekan (lihat aksi pada `task_card_widget.dart` yang saat ini mengganti status ke *Sedang Dikerjakan*), selain mengubah status, buka layar/panel **Timer Pomodoro** untuk tugas tersebut.
- Timer Pomodoro dasar yang perlu ada:
  - satu sesi **fokus** (durasi default umum: 25 menit),
  - **istirahat pendek** setelah sesi fokus (default umum: 5 menit),
  - **istirahat panjang** setelah beberapa sesi (default umum: setelah 4 sesi, ± 15 menit),
  - kontrol dasar: mulai, jeda, lanjut, reset/berhenti,
  - penanda visual sedang di fase fokus atau istirahat, dan hitung mundur yang jelas.
- Buat durasi sebagai nilai default yang mudah diubah di kode (dan idealnya nanti bisa diatur pengguna — boleh menyusul).
- Pikirkan perilaku saat timer berjalan lalu pengguna berpindah layar: minimal timer tidak langsung hilang begitu saja tanpa peringatan. Notifikasi/suara saat sesi berakhir bersifat **opsional** (nice-to-have), boleh menyusul.

**Keputusan desain (sudah diputuskan):**
- **Timer TIDAK otomatis menandai tugas selesai.** Selesainya siklus Pomodoro hanya menghentikan timer; user tetap menandai "Selesai" secara manual. Timer adalah alat bantu fokus, bukan penentu status.
- **Catat waktu fokus aktual per tugas.** Setiap sesi fokus yang selesai dicatat (akumulasi menit fokus per tugas, disimpan di model tugas sebagai field baru yang opsional). Manfaatnya dua: (a) bisa dibandingkan dengan `estimasiWaktu` sebagai statistik "estimasi vs realita", (b) memperkaya ringkasan per mata kuliah (Issue #2) dengan total jam fokus. Cukup akumulasi sederhana — tidak perlu histori per-sesi yang detail.

**Selesai bila:** menekan "Mulai" membuka timer yang berjalan dengan siklus fokus–istirahat ala Pomodoro, kontrol dasarnya berfungsi, waktu fokus terakumulasi ke tugas, dan status "Selesai" tetap dikendalikan manual oleh user.

---

# BAGIAN B — Keamanan Data (prioritas tinggi)

## Issue #6 — Ekspor & impor data (backup manual)

**Masalah:** Seluruh data (tugas, lingkup, kategori, jadwal, pengaturan) hidup di `SharedPreferences`. Kalau user ganti HP, clear data aplikasi, atau uninstall — semuanya hilang permanen. Backup internal yang ada di `_saveTasks()` tidak menolong untuk kasus ini karena ikut terhapus.

**Tujuan:** User bisa menyimpan seluruh datanya ke sebuah file, dan memuatnya kembali di perangkat/instalasi lain.

**Arah solusi (high-level):**
- Tambahkan di layar pengaturan (`settings_screen.dart`) dua aksi: **Ekspor Data** dan **Impor Data**.
- Ekspor: kumpulkan semua data penting (daftar tugas, lingkup, kategori, konfigurasi jadwal, pengaturan notifikasi) menjadi satu file JSON, lalu biarkan user menyimpan/membagikannya lewat mekanisme berbagi standar perangkat.
- Impor: user memilih file JSON hasil ekspor; validasi dulu isinya (jangan menimpa data sehat dengan file rusak), tampilkan konfirmasi yang jelas bahwa impor akan **menggantikan** data saat ini, baru terapkan.
- Sertakan penanda versi format di dalam file ekspor, supaya impor di versi aplikasi yang lebih baru tetap bisa dikenali dan dimigrasi.

**Selesai bila:** ekspor menghasilkan file yang bisa dibagikan; impor file tersebut di instalasi bersih mengembalikan semua tugas, lingkup, dan kategori persis seperti semula; impor file rusak ditolak dengan pesan jelas tanpa merusak data yang ada.

---

## Issue #7 — Gagal simpan jangan diam-diam

**Masalah:** Di `task_provider.dart`, method `_saveTasks()` menangkap error penyimpanan dan hanya mencetaknya ke log debug. Artinya kalau penyimpanan gagal, user mengira tugasnya tersimpan padahal tidak — dan baru sadar setelah data hilang.

**Tujuan:** Setiap kegagalan menyimpan diketahui oleh user saat itu juga.

**Arah solusi (high-level):**
- Ubah alur simpan agar kegagalan **tidak ditelan**: teruskan status gagal dari `_saveTasks()` ke pemanggilnya (tambah/edit/hapus tugas), lalu ke UI.
- Di UI, tampilkan pemberitahuan yang jelas (mis. snackbar merah "Gagal menyimpan — coba lagi") dan jangan tampilkan pesan sukses palsu.
- Terapkan pola yang sama untuk penyimpanan lain yang sekarang juga menelan error (mis. `_saveSchedule()`).

**Selesai bila:** ketika penyimpanan gagal (bisa disimulasikan saat pengujian), user melihat pesan gagal — bukan pesan sukses — dan tahu datanya belum aman.

---

# BAGIAN C — Perbaikan UX

## Issue #8 — Undo setelah hapus tugas

**Masalah:** Menghapus tugas bersifat permanen seketika. Dialog konfirmasi membantu, tapi salah tekan tetap fatal.

**Tujuan:** Setelah menghapus, user punya kesempatan beberapa detik untuk mengurungkan.

**Arah solusi (high-level):**
- Setelah hapus, tampilkan snackbar "Tugas dihapus — **Urungkan**" yang tampil beberapa detik.
- Selama masa itu, simpan dulu salinan tugas yang dihapus di memori; kalau user menekan Urungkan, kembalikan tugas (beserta jadwal/notifikasinya) seperti semula.
- Perhatikan interaksi dengan notifikasi: notifikasi tugas dibatalkan saat hapus — kalau di-undo, jadwalkan ulang.
- Dengan adanya undo, dialog konfirmasi "Yakin ingin menghapus?" boleh dipertimbangkan untuk dihilangkan agar alur lebih cepat (keputusan bebas, dua-duanya boleh ada).

**Selesai bila:** menghapus tugas lalu menekan Urungkan mengembalikan tugas sepenuhnya (termasuk muncul lagi di daftar dan jadwal); membiarkan snackbar lewat membuat penghapusan final.

---

## Issue #9 — Edit/rename lingkup & kategori (dengan efek berantai)

**Masalah:** Lingkup dan kategori hanya bisa ditambah dan dihapus — tidak bisa diganti namanya. Kalau typo, user harus hapus dan buat ulang, dan tugas-tugas lama tetap menunjuk nama yang salah.

**Tujuan:** User bisa mengganti nama lingkup dan kategori, dan semua tugas yang memakainya ikut berpindah ke nama baru secara otomatis.

**Arah solusi (high-level):**
- Tambahkan aksi "ubah nama" pada pengelolaan lingkup dan kategori (di manapun ia dikelola — form tugas dan/atau layar pengaturan).
- Karena tugas menyimpan lingkup/kategori sebagai **teks**, rename harus **berantai (cascade)**: semua tugas yang memakai nama lama diperbarui ke nama baru dalam satu operasi, lalu disimpan.
- Tolak rename ke nama yang sudah dipakai di tempat yang sama (hindari dua lingkup bernama sama, atau dua kategori bernama sama dalam satu lingkup — selaras dengan Issue #4).
- Ingat kaitannya dengan Issue #2: kalau lingkup "Perkuliahan" di-rename, kolom mata kuliah ikut terpengaruh (karena patokannya nama literal). Minimal beri peringatan saat user me-rename lingkup "Perkuliahan".

**Selesai bila:** mengganti nama lingkup/kategori membuat semua tugas lama ikut menunjuk nama baru, tanpa ada tugas yang tertinggal menunjuk nama lama.

---

## Issue #10 — Urgensi & prioritas di-refresh berkala

**Masalah:** Tingkat urgensi dihitung dari deadline hanya saat data dimuat/diubah. Kalau aplikasi dibiarkan terbuka berjam-jam, label "Masih Aman" bisa sudah basi padahal deadline tinggal 2 jam — dan ranking prioritas (SAW) ikut basi.

**Tujuan:** Urgensi dan ranking selalu mencerminkan kondisi sekarang selama aplikasi terbuka.

**Arah solusi (high-level):**
- Hitung ulang urgensi + SAW pada momen-momen kunci: saat aplikasi kembali ke depan (foreground) dan/atau secara berkala dengan interval wajar (mis. tiap beberapa menit) selama app terbuka.
- Jangan berlebihan: tidak perlu hitung ulang tiap detik; pilih pemicu yang murah dan cukup.
- Pastikan UI (badge urgensi, ranking di kartu tugas, urutan daftar prioritas) ikut ter-update saat hitung ulang terjadi.

**Selesai bila:** membiarkan aplikasi terbuka melewati ambang urgensi (mis. deadline berubah dari >24 jam menjadi <24 jam) membuat label dan ranking berubah tanpa perlu restart aplikasi.

---

# BAGIAN D — Backlog Fitur (dikerjakan setelah Bagian A–C beres)

## Backlog #1 — Tugas berulang (recurring)

Untuk konteks perkuliahan sangat relevan: laporan praktikum mingguan, kuis rutin. Ide dasarnya: saat membuat tugas, user bisa memilih pola pengulangan (mis. tiap minggu); ketika satu kemunculan selesai/lewat, aplikasi otomatis membuat kemunculan berikutnya. Perlu keputusan desain lebih lanjut (kapan tugas berikutnya dibuat, bagaimana mengedit "satu kemunculan" vs "semua") — **jangan dikerjakan sebelum didiskusikan**.

## Backlog #2 — Sub-tugas / checklist

Tugas besar (skripsi, proyek) bisa dipecah menjadi langkah-langkah kecil dengan checklist di dalamnya, plus indikator progres. Menyentuh model data cukup dalam, jadi sengaja ditaruh paling belakang. Perlu diskusi desain sebelum dikerjakan.

---

# Catatan Pengerjaan Umum

1. **Urutan pengerjaan yang disarankan:**
   1. **#3** (bug kategori) — paling terisolasi, langsung terasa.
   2. **#7** (gagal simpan) — kecil tapi menutup risiko kehilangan data diam-diam.
   3. **#1** (navigasi setelah simpan).
   4. **#2** (kolom mata kuliah).
   5. **#4 + #9** (kategori per lingkup + rename berantai) — satu area kode, kerjakan berdekatan; paling berdampak ke struktur data, hati-hati migrasi.
   6. **#8** (undo hapus).
   7. **#10** (refresh urgensi).
   8. **#6** (ekspor/impor) — kerjakan **setelah** struktur data stabil (yaitu setelah #2 dan #4), supaya format ekspor tidak bolak-balik berubah.
   9. **#5** (timer Pomodoro) — fitur baru paling besar, paling akhir di Bagian A–C.
   10. Backlog (D) menyusul setelah semuanya, dan wajib diskusi desain dulu.
2. **Jaga kompatibilitas data lama** di setiap perubahan model/penyimpanan. Uji dengan skenario "buka aplikasi yang sudah punya data".
3. Setelah tiap issue selesai, lakukan uji manual singkat mengikuti bagian **"Selesai bila"** masing-masing.
4. Kerjakan **satu issue per perubahan/commit** — jangan mencampur beberapa issue dalam satu perubahan besar, supaya mudah direview dan mudah dibatalkan kalau salah.
5. Kalau ada keputusan desain yang belum jelas, tanyakan dulu sebelum menulis kode — jangan menebak. Keputusan yang sudah final ditandai *"Keputusan desain (sudah diputuskan)"* di masing-masing issue.
