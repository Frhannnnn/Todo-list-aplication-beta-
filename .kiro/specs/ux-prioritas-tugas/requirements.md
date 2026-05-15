# Requirements Document

## Introduction

Fitur ini bertujuan memperbaiki pengalaman pengguna (UX) pada alur penentuan prioritas tugas di aplikasi Tugasku. Perbaikan mencakup tiga area utama: (1) form input parameter SAW pada `AddEditTaskScreen` — slider kepentingan dan urgensi diperkaya dengan label deskriptif dan tooltip agar pengguna memahami perbedaan konsep "penting" vs "mendesak"; (2) tampilan Eisenhower Matrix pada `PriorityScreen` — diubah menjadi grid 2×2 kompak dengan ringkasan jumlah tugas per kuadran yang mudah dipindai; (3) daftar tugas — setiap `TaskCardWidget` menampilkan badge label prioritas teks (Tinggi/Sedang/Rendah) dan layar daftar tugas dilengkapi kontrol filter serta sort berdasarkan prioritas.

## Glossary

- **Tugasku**: Aplikasi Flutter manajemen tugas yang menjadi subjek perbaikan.
- **AddEditTaskScreen**: Layar form untuk menambah atau mengedit tugas, berisi slider parameter SAW.
- **PriorityScreen**: Layar yang menampilkan Eisenhower Matrix pembagian tugas ke empat kuadran.
- **TaskCardWidget**: Widget kartu tugas yang ditampilkan di daftar tugas.
- **SAW (Simple Additive Weighting)**: Algoritma perhitungan skor prioritas tugas berdasarkan kepentingan, urgensi, deadline, dan estimasi waktu.
- **Eisenhower Matrix**: Kerangka 2×2 yang mengelompokkan tugas berdasarkan tingkat kepentingan dan urgensi.
- **Label Prioritas**: Teks kategori prioritas hasil perhitungan SAW — "Tinggi", "Sedang", atau "Rendah" — beserta warna yang sesuai dari `AppTheme.getPrioritasLabel()` dan `AppTheme.getPrioritasColor()`.
- **Kuadran**: Salah satu dari empat sel Eisenhower Matrix: Kerjakan, Jadwalkan, Delegasikan, Eliminasi.
- **Badge Prioritas**: Elemen UI berupa chip/label berwarna yang menampilkan teks Label Prioritas pada TaskCardWidget.
- **Slider Kepentingan**: Komponen slider pada AddEditTaskScreen untuk nilai `tingkatKepentingan` (1–5).
- **Slider Urgensi**: Komponen slider pada AddEditTaskScreen untuk nilai `tingkatUrgensi` (1–5).
- **TaskProvider**: Provider state management yang menyimpan dan mengelola daftar tugas.
- **Filter Prioritas**: Kontrol UI untuk menyaring daftar tugas berdasarkan Label Prioritas.
- **Sort Prioritas**: Kontrol UI untuk mengurutkan daftar tugas berdasarkan nilai SAW score atau ranking.

---

## Requirements

### Requirement 1 — Label Deskriptif pada Slider Kepentingan

**User Story:** Sebagai pengguna, saya ingin slider Tingkat Kepentingan disertai penjelasan yang jelas tentang makna tiap nilai, sehingga saya dapat mengisi nilai yang tepat tanpa kebingungan.

#### Acceptance Criteria

1. THE AddEditTaskScreen SHALL menampilkan teks deskripsi singkat di bawah judul "Tingkat Kepentingan" yang menjelaskan bahwa kepentingan mengacu pada dampak jangka panjang tugas terhadap tujuan akademik, bukan seberapa cepat tugas harus diselesaikan.
2. WHEN pengguna menggeser Slider Kepentingan ke nilai tertentu, THE AddEditTaskScreen SHALL memperbarui label nilai yang ditampilkan secara real-time menggunakan teks deskriptif: nilai 1 = "Sangat Rendah", nilai 2 = "Rendah", nilai 3 = "Sedang", nilai 4 = "Tinggi", nilai 5 = "Sangat Tinggi".
3. THE AddEditTaskScreen SHALL menampilkan baris contoh singkat di bawah Slider Kepentingan yang menjelaskan perbedaan antara "penting" (berdampak besar pada nilai/tujuan) dan "mendesak" (harus segera dikerjakan karena deadline dekat).
4. IF pengguna menekan ikon bantuan (info icon) di samping judul "Tingkat Kepentingan", THEN THE AddEditTaskScreen SHALL menampilkan tooltip atau dialog yang menjelaskan: "Kepentingan = seberapa besar dampak tugas ini terhadap nilai atau tujuan akademikmu. Contoh: tugas UAS lebih penting dari tugas mingguan biasa."

---

### Requirement 2 — Label Deskriptif pada Slider Urgensi

**User Story:** Sebagai pengguna, saya ingin slider Tingkat Urgensi disertai penjelasan yang membedakannya dari kepentingan, sehingga saya tidak salah mengisi kedua nilai tersebut.

#### Acceptance Criteria

1. THE AddEditTaskScreen SHALL menampilkan teks deskripsi singkat di bawah judul "Tingkat Urgensi" yang menjelaskan bahwa urgensi mengacu pada seberapa mendesak tugas harus dikerjakan berdasarkan kedekatan deadline.
2. WHEN pengguna menggeser Slider Urgensi ke nilai tertentu, THE AddEditTaskScreen SHALL memperbarui label nilai yang ditampilkan secara real-time menggunakan teks deskriptif: nilai 1 = "Sangat Rendah", nilai 2 = "Rendah", nilai 3 = "Sedang", nilai 4 = "Tinggi", nilai 5 = "Sangat Tinggi".
3. IF pengguna menekan ikon bantuan (info icon) di samping judul "Tingkat Urgensi", THEN THE AddEditTaskScreen SHALL menampilkan tooltip atau dialog yang menjelaskan: "Urgensi = seberapa mendesak tugas ini harus dikerjakan sekarang. Contoh: tugas dengan deadline besok lebih mendesak dari tugas dengan deadline 2 minggu lagi."
4. THE AddEditTaskScreen SHALL menampilkan ringkasan kombinasi nilai kepentingan dan urgensi yang dipilih dalam bentuk teks kuadran Eisenhower (misalnya "Penting & Mendesak → Kerjakan Sekarang") di bawah kedua slider, sehingga pengguna mendapat umpan balik langsung atas pilihan mereka.

---

### Requirement 3 — Badge Label Prioritas pada TaskCardWidget

**User Story:** Sebagai pengguna, saya ingin melihat label prioritas teks (Tinggi/Sedang/Rendah) pada setiap kartu tugas di daftar, sehingga saya dapat langsung mengetahui tingkat prioritas tanpa harus membuka detail tugas.

#### Acceptance Criteria

1. WHEN `task.ranking` lebih dari 0 dan `TaskProvider` memiliki setidaknya satu tugas aktif, THE TaskCardWidget SHALL menampilkan Badge Prioritas berisi teks Label Prioritas ("Tinggi", "Sedang", atau "Rendah") yang diperoleh dari `AppTheme.getPrioritasLabel(task.ranking, totalActiveTasks)`.
2. THE TaskCardWidget SHALL menerapkan warna latar belakang dan warna teks Badge Prioritas menggunakan `AppTheme.getPrioritasColor(task.ranking, totalActiveTasks)` sesuai dengan Label Prioritas yang ditampilkan.
3. THE TaskCardWidget SHALL menempatkan Badge Prioritas di baris header kartu, berdampingan dengan badge ranking (`#N`) yang sudah ada, sehingga keduanya terlihat dalam satu baris tanpa memotong nama tugas.
4. IF `task.ranking` bernilai 0 atau tugas berstatus `TaskStatus.selesai`, THEN THE TaskCardWidget SHALL tidak menampilkan Badge Prioritas.
5. THE TaskCardWidget SHALL memastikan Badge Prioritas memiliki ukuran font minimal 9sp dan padding horizontal minimal 6dp agar teks terbaca dengan jelas.

---

### Requirement 4 — Filter dan Sort Berdasarkan Prioritas di Daftar Tugas

**User Story:** Sebagai pengguna, saya ingin dapat memfilter dan mengurutkan daftar tugas berdasarkan prioritas, sehingga saya dapat fokus pada tugas-tugas yang paling penting terlebih dahulu.

#### Acceptance Criteria

1. THE layar daftar tugas SHALL menampilkan kontrol Filter Prioritas berupa chip atau dropdown dengan pilihan: "Semua", "Tinggi", "Sedang", "Rendah".
2. WHEN pengguna memilih salah satu opsi Filter Prioritas selain "Semua", THE layar daftar tugas SHALL menampilkan hanya tugas-tugas yang Label Prioritasnya sesuai dengan pilihan filter.
3. WHEN pengguna memilih opsi "Semua" pada Filter Prioritas, THE layar daftar tugas SHALL menampilkan seluruh tugas tanpa penyaringan berdasarkan prioritas.
4. THE layar daftar tugas SHALL menampilkan kontrol Sort yang menyertakan opsi "Prioritas Tertinggi" untuk mengurutkan tugas berdasarkan nilai `task.ranking` secara ascending (ranking 1 di atas).
5. WHEN pengguna memilih opsi sort "Prioritas Tertinggi", THE layar daftar tugas SHALL mengurutkan ulang daftar tugas sehingga tugas dengan `task.ranking` terkecil (prioritas tertinggi) muncul paling atas, dan tugas tanpa ranking (ranking = 0) ditempatkan di bagian bawah.
6. IF tidak ada tugas yang cocok dengan Filter Prioritas yang dipilih, THEN THE layar daftar tugas SHALL menampilkan pesan kosong yang informatif, misalnya "Tidak ada tugas dengan prioritas [label] saat ini."

---

### Requirement 5 — Eisenhower Matrix Grid 2×2 Kompak

**User Story:** Sebagai pengguna, saya ingin tampilan Eisenhower Matrix berupa grid 2×2 yang kompak dengan ringkasan jumlah tugas per kuadran, sehingga saya dapat memindai distribusi tugas secara cepat tanpa harus scroll panjang.

#### Acceptance Criteria

1. THE PriorityScreen SHALL menampilkan keempat Kuadran Eisenhower dalam layout grid 2×2 secara bersamaan pada satu layar tanpa memerlukan scroll vertikal pada perangkat dengan tinggi layar minimal 600dp.
2. THE PriorityScreen SHALL menampilkan jumlah tugas di setiap Kuadran sebagai angka ringkasan (badge count) yang terlihat jelas di header setiap kartu kuadran, menggunakan komponen `_countBadge()` yang sudah ada.
3. WHEN jumlah tugas dalam satu Kuadran melebihi kapasitas tampilan ringkasan, THE PriorityScreen SHALL menampilkan daftar tugas yang dapat di-scroll di dalam area kuadran tersebut tanpa memengaruhi layout kuadran lain.
4. THE PriorityScreen SHALL mempertahankan label kuadran (judul, subjudul, dan action label) yang sudah ada agar pengguna tetap memahami makna setiap kuadran.
5. WHILE layar berada dalam orientasi portrait dengan lebar kurang dari 680dp, THE PriorityScreen SHALL menggunakan layout grid 2×2 dengan `GridView` beraspek rasio yang memungkinkan keempat kuadran terlihat sekaligus, menggantikan layout kolom tunggal yang saat ini digunakan untuk lebar < 680dp.
6. THE PriorityScreen SHALL menampilkan ringkasan total tugas aktif dan distribusi per kuadran dalam bentuk teks singkat di kartu intro, sehingga pengguna mendapat gambaran keseluruhan sebelum melihat detail tiap kuadran.
