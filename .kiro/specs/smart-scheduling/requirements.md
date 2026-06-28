# Requirements Document

## Introduction

Fitur Smart Scheduling menambahkan kemampuan penjadwalan cerdas pada aplikasi Tugasku. Fitur ini dibangun di atas tiga pilar utama: (1) Strict Monotasking — satu slot waktu hanya untuk satu tugas, menghilangkan context switching dan memaksimalkan kualitas output; (2) 24-Hour Flexibility — sistem terbuka 24 jam secara default untuk mengakomodasi berbagai gaya hidup (mahasiswa, freelancer, pekerja shift), dengan "Primary Work Hours" sebagai preferensi rekomendasi bukan pembatas; (3) Recursive & Priority-Based Scheduling — penjadwalan mundur dari deadline menggunakan SAW score sebagai hakim ketika terjadi konflik, tugas prioritas lebih tinggi mengamankan slot-nya dan tugas prioritas lebih rendah otomatis bergeser mundur ke slot tersedia berikutnya.

Fitur mencakup: deteksi konflik jadwal, time blocking untuk fokus kerja, dan opsi AI-powered auto task creation.

## Glossary

- **Tugasku**: Aplikasi Flutter manajemen tugas mahasiswa yang menjadi subjek pengembangan.
- **Smart_Scheduler**: Modul inti yang menjalankan algoritma penjadwalan cerdas, termasuk backward scheduling, conflict detection, dan slot allocation.
- **Time_Block**: Unit waktu terjadwal yang dialokasikan untuk mengerjakan satu tugas tertentu, memiliki waktu mulai dan waktu selesai.
- **Slot**: Periode waktu yang tersedia untuk dialokasikan sebagai Time_Block. Satu Slot hanya dapat diisi oleh satu tugas (strict monotasking).
- **Conflict**: Kondisi ketika dua atau lebih tugas membutuhkan Slot yang sama berdasarkan hasil backward scheduling dari deadline masing-masing.
- **Backward_Scheduling**: Algoritma penjadwalan yang menghitung mundur dari deadline tugas untuk menentukan kapan tugas harus mulai dikerjakan, berdasarkan estimasi waktu pengerjaan.
- **SAW_Score**: Nilai preferensi hasil perhitungan Simple Additive Weighting yang digunakan sebagai penentu prioritas ketika terjadi Conflict.
- **Primary_Work_Hours**: Preferensi jam kerja utama yang ditetapkan pengguna (default: 08:00–17:00). Digunakan hanya sebagai buffer rekomendasi penjadwalan, bukan pembatas sistem.
- **Conflict_Resolution**: Proses penyelesaian Conflict menggunakan SAW_Score sebagai hakim — tugas dengan skor lebih tinggi mempertahankan Slot-nya, tugas dengan skor lebih rendah bergeser mundur ke Slot tersedia berikutnya.
- **Schedule_View**: Tampilan visual yang menunjukkan Time_Block yang telah dialokasikan dalam format timeline harian.
- **TaskProvider**: Provider state management yang menyimpan dan mengelola daftar tugas serta jadwal.
- **SAW_Service**: Service yang menghitung prioritas tugas menggunakan metode Simple Additive Weighting.
- **Monotasking**: Prinsip bahwa satu Slot waktu hanya dialokasikan untuk satu tugas, tanpa multitasking atau overlap.
- **Recursive_Shift**: Proses berulang di mana tugas yang kalah dalam Conflict_Resolution bergeser mundur ke Slot sebelumnya, dan jika Slot tersebut juga penuh, proses berulang hingga Slot kosong ditemukan.
- **AI_Task_Creator**: Modul opsional yang menggunakan AI untuk membuat tugas secara otomatis berdasarkan input pengguna seperti silabus atau deskripsi proyek.

---

## Requirements

### Requirement 1: Backward Scheduling dari Deadline

**User Story:** Sebagai pengguna, saya ingin sistem secara otomatis menghitung mundur dari deadline tugas untuk menentukan kapan saya harus mulai mengerjakan, sehingga saya tidak perlu menghitung manual dan selalu punya waktu cukup.

#### Acceptance Criteria

1. WHEN pengguna menambahkan atau mengedit tugas dengan deadline dan estimasi waktu, THE Smart_Scheduler SHALL menghitung waktu mulai pengerjaan dengan cara mengurangi deadline dikurangi estimasi waktu (dalam jam) untuk menentukan Slot terakhir yang tersedia sebelum deadline, dan mengalokasikan sejumlah Time_Block yang sama dengan estimasi waktu (dalam jam) pada Slot-slot tersedia secara mundur dari deadline.
2. THE Smart_Scheduler SHALL membagi estimasi waktu tugas menjadi sejumlah Time_Block di mana setiap Time_Block berdurasi tepat 1 jam (sesuai ukuran satu Slot), sehingga jumlah Time_Block yang dihasilkan sama dengan estimasi waktu tugas dalam jam, dan mengalokasikan Time_Block tersebut pada Slot yang tersedia sebelum deadline.
3. WHEN Slot tepat sebelum deadline sudah terisi oleh tugas lain, THE Smart_Scheduler SHALL secara otomatis mencari Slot tersedia sebelumnya secara mundur (Recursive_Shift) hingga menemukan Slot kosong, dengan batas pencarian tidak melewati waktu saat ini (current time).
4. THE Smart_Scheduler SHALL memastikan setiap Time_Block memiliki durasi tepat 1 jam (satu Slot) dan tidak dialokasikan pada Slot yang sudah melewati waktu saat ini.
5. IF tidak ada Slot tersedia yang cukup antara waktu saat ini dan deadline tugas, THEN THE Smart_Scheduler SHALL menampilkan peringatan kepada pengguna yang menyebutkan nama tugas, jumlah jam yang tidak dapat dijadwalkan, dan deadline tugas tersebut.
6. IF pengguna memasukkan deadline yang sudah melewati waktu saat ini, THEN THE Smart_Scheduler SHALL menolak penjadwalan dan menampilkan pesan error yang menunjukkan bahwa deadline harus berada di masa depan.
7. IF estimasi waktu tugas melebihi jumlah Slot tersedia antara waktu saat ini dan deadline, THEN THE Smart_Scheduler SHALL menjadwalkan sebanyak mungkin Time_Block pada Slot yang tersedia dan menampilkan peringatan bahwa sisa waktu pengerjaan sebesar selisih jam tidak dapat dialokasikan sebelum deadline.

---

### Requirement 2: Strict Monotasking Enforcement

**User Story:** Sebagai pengguna, saya ingin sistem menjamin bahwa setiap slot waktu hanya berisi satu tugas, sehingga saya dapat fokus penuh tanpa context switching dan menghasilkan output berkualitas tinggi.

#### Acceptance Criteria

1. THE Smart_Scheduler SHALL mengalokasikan maksimal satu tugas untuk setiap Slot waktu (1 jam), sehingga tidak ada dua Time_Block yang menempati Slot yang sama secara bersamaan.
2. WHEN Smart_Scheduler mencoba mengalokasikan Time_Block pada Slot yang sudah terisi, THE Smart_Scheduler SHALL menolak alokasi tersebut dan memicu proses Conflict_Resolution.
3. WHEN operasi penjadwalan selesai (penambahan tugas, pengeditan tugas, pemindahan Time_Block, atau Conflict_Resolution), THE Smart_Scheduler SHALL memvalidasi bahwa tidak ada dua Time_Block yang memiliki rentang waktu yang saling tumpang tindih dalam seluruh jadwal.
4. IF validasi pasca-operasi mendeteksi overlap antar Time_Block, THEN THE Smart_Scheduler SHALL membatalkan operasi terakhir, mengembalikan jadwal ke kondisi valid sebelumnya, dan menampilkan pesan error yang menunjukkan Slot mana yang mengalami konflik.
5. WHEN pengguna melihat Schedule_View, THE Schedule_View SHALL menampilkan setiap Slot dengan tepat satu tugas atau kosong, tanpa menampilkan lebih dari satu nama tugas dalam satu Slot yang sama.

---

### Requirement 3: Conflict Detection dan Notification

**User Story:** Sebagai pengguna, saya ingin sistem mendeteksi ketika dua atau lebih tugas memiliki jadwal yang bertabrakan, sehingga saya mengetahui potensi masalah dan dapat mengambil tindakan.

#### Acceptance Criteria

1. WHEN dua atau lebih tugas membutuhkan Slot yang sama berdasarkan hasil Backward_Scheduling, THE Smart_Scheduler SHALL mendeteksi kondisi tersebut sebagai Conflict.
2. WHEN Conflict terdeteksi, THE Smart_Scheduler SHALL menampilkan notifikasi kepada pengguna dalam waktu maksimal 2 detik setelah deteksi, yang mencantumkan nama tugas-tugas yang berkonflik, waktu Slot yang diperebutkan (tanggal dan jam), serta SAW_Score masing-masing tugas.
3. WHEN Conflict terdeteksi, THE Smart_Scheduler SHALL menampilkan rekomendasi dalam notifikasi yang menunjukkan tugas dengan SAW_Score tertinggi sebagai pemenang Slot dan tugas lainnya sebagai yang akan digeser ke Slot sebelumnya.
4. WHEN Conflict terdeteksi, THE Smart_Scheduler SHALL secara otomatis menjalankan Conflict_Resolution dalam siklus penjadwalan yang sama tanpa memerlukan input manual dari pengguna.
5. WHEN Conflict_Resolution selesai dijalankan, THE Smart_Scheduler SHALL memperbarui notifikasi konflik dengan hasil resolusi yang mencantumkan Slot baru yang dialokasikan untuk setiap tugas yang digeser.

---

### Requirement 4: Priority-Based Conflict Resolution menggunakan SAW Score

**User Story:** Sebagai pengguna, saya ingin konflik jadwal diselesaikan secara otomatis berdasarkan prioritas tugas, sehingga tugas yang lebih penting selalu mendapat slot waktu yang optimal.

#### Acceptance Criteria

1. WHEN Conflict terjadi antara dua atau lebih tugas pada Slot yang sama, THE Smart_Scheduler SHALL membandingkan SAW_Score setiap tugas yang berkonflik.
2. THE Smart_Scheduler SHALL mengalokasikan Slot yang diperebutkan kepada tugas dengan SAW_Score tertinggi. IF dua atau lebih tugas memiliki SAW_Score yang sama, THEN THE Smart_Scheduler SHALL memprioritaskan tugas dengan deadline paling dekat sebagai pemenang Slot.
3. WHEN tugas kalah dalam Conflict_Resolution, THE Smart_Scheduler SHALL menjalankan Recursive_Shift untuk memindahkan tugas tersebut ke Slot tersedia sebelumnya (mundur dari Slot yang diperebutkan menuju waktu yang lebih awal).
4. IF Recursive_Shift menemukan Slot yang juga sudah terisi, THEN THE Smart_Scheduler SHALL mengulangi proses Conflict_Resolution pada Slot tersebut hingga tugas mendapat Slot kosong atau tidak ada Slot tersedia.
5. IF Recursive_Shift tidak menemukan Slot kosong yang tersedia sebelum batas waktu paling awal (Slot pertama yang tersedia dalam sistem), THEN THE Smart_Scheduler SHALL menandai tugas tersebut sebagai "tidak terjadwalkan" dan menampilkan notifikasi kepada pengguna yang menyebutkan nama tugas yang gagal dijadwalkan beserta alasan tidak tersedianya Slot.
6. THE Smart_Scheduler SHALL memastikan bahwa hasil akhir Conflict_Resolution menghasilkan jadwal tanpa overlap antar Time_Block, di mana setiap Slot berisi maksimal satu tugas dan seluruh tugas yang berhasil dijadwalkan memiliki Time_Block yang tidak tumpang tindih.

---

### Requirement 5: Time Block Scheduling dan Visualisasi

**User Story:** Sebagai pengguna, saya ingin melihat blok waktu yang telah dijadwalkan dalam tampilan visual, sehingga saya tahu kapan harus fokus mengerjakan tugas tertentu.

#### Acceptance Criteria

1. THE Schedule_View SHALL menampilkan Time_Block dalam format timeline harian 24 jam (00:00–23:59) dengan granularitas slot 1 jam, yang menunjukkan waktu mulai, waktu selesai, dan nama tugas untuk setiap blok.
2. THE Schedule_View SHALL menggunakan warna berbeda untuk setiap Time_Block berdasarkan kategori tugas (kuliah, praktikum, project, lainnya), di mana setiap kategori memiliki satu warna konsisten di seluruh tampilan.
3. WHEN pengguna mengetuk sebuah Time_Block pada Schedule_View, THE Schedule_View SHALL menampilkan detail tugas terkait termasuk nama tugas, mata kuliah, deadline, dan sisa estimasi waktu pengerjaan yang belum dijadwalkan (dalam jam).
4. THE Schedule_View SHALL menampilkan indikator visual yang membedakan Slot kosong, Slot terisi, dan Slot dalam Primary_Work_Hours, sehingga ketiga status tersebut dapat dibedakan secara simultan tanpa membaca teks tambahan.
5. WHILE pengguna berada pada Schedule_View, THE Schedule_View SHALL menampilkan penanda waktu saat ini (current time indicator) berupa garis horizontal pada posisi waktu aktual yang diperbarui setiap 60 detik.
6. WHEN pengguna melakukan swipe horizontal atau mengetuk tombol navigasi tanggal pada Schedule_View, THE Schedule_View SHALL berpindah ke timeline hari sebelumnya atau berikutnya dan menampilkan Time_Block yang dijadwalkan pada hari tersebut.
7. IF tidak ada Time_Block yang dijadwalkan pada hari yang sedang ditampilkan, THEN THE Schedule_View SHALL menampilkan pesan kosong yang menginformasikan bahwa belum ada jadwal untuk hari tersebut.

---

### Requirement 6: Primary Work Hours sebagai Preferensi Rekomendasi

**User Story:** Sebagai pengguna, saya ingin mengatur jam kerja utama sebagai preferensi, sehingga sistem memberikan rekomendasi penjadwalan yang sesuai dengan rutinitas saya tanpa membatasi fleksibilitas 24 jam.

#### Acceptance Criteria

1. THE Tugasku SHALL menyediakan pengaturan Primary_Work_Hours dengan nilai default 08:00–17:00 yang dapat diubah oleh pengguna, dengan rentang minimum 1 jam dan mendukung konfigurasi lintas tengah malam (contoh: 22:00–06:00) untuk mengakomodasi pekerja shift.
2. WHEN Smart_Scheduler menjalankan Backward_Scheduling, THE Smart_Scheduler SHALL mencoba mengalokasikan Time_Block pada Slot dalam rentang Primary_Work_Hours terlebih dahulu, dan hanya menggunakan Slot di luar Primary_Work_Hours setelah seluruh Slot dalam Primary_Work_Hours pada hari yang relevan sudah terisi.
3. WHEN semua Slot dalam Primary_Work_Hours sudah terisi, THE Smart_Scheduler SHALL mengalokasikan Time_Block pada Slot di luar Primary_Work_Hours tanpa menampilkan error atau pembatasan.
4. THE Smart_Scheduler SHALL tidak menolak atau memblokir alokasi Time_Block pada jam di luar Primary_Work_Hours dalam kondisi apapun.
5. WHEN Time_Block dialokasikan di luar Primary_Work_Hours, THE Schedule_View SHALL menampilkan indikator visual berupa perbedaan warna latar belakang yang lebih redup dibandingkan Time_Block dalam Primary_Work_Hours, tanpa menggunakan ikon peringatan, warna merah, atau elemen yang mengindikasikan error.
6. WHEN pengguna mengubah pengaturan Primary_Work_Hours dan terdapat Time_Block yang sudah terjadwal, THE Smart_Scheduler SHALL menghitung ulang alokasi seluruh Time_Block aktif berdasarkan rentang Primary_Work_Hours yang baru tanpa menghapus tugas yang sudah ada.

---

### Requirement 7: Manajemen dan Modifikasi Time Block oleh Pengguna

**User Story:** Sebagai pengguna, saya ingin dapat melihat, memindahkan, dan menghapus time block secara manual, sehingga saya tetap memiliki kontrol penuh atas jadwal saya.

#### Acceptance Criteria

1. WHEN pengguna melakukan drag-and-drop pada Time_Block di Schedule_View dan Slot tujuan kosong, THE Smart_Scheduler SHALL memindahkan Time_Block ke Slot tujuan dan memperbarui waktu mulai serta waktu selesai Time_Block sesuai posisi Slot baru.
2. IF pengguna mencoba memindahkan Time_Block ke Slot yang sudah terisi, THEN THE Smart_Scheduler SHALL menampilkan pesan bahwa Slot tujuan sudah terisi dan mengembalikan Time_Block ke posisi semula tanpa mengubah jadwal.
3. IF pengguna mencoba memindahkan Time_Block ke Slot yang melewati deadline tugas terkait, THEN THE Smart_Scheduler SHALL menampilkan pesan bahwa pemindahan melampaui deadline dan menolak pemindahan tersebut.
4. WHEN pengguna menghapus sebuah Time_Block, THE Smart_Scheduler SHALL menampilkan konfirmasi penghapusan, dan setelah pengguna mengonfirmasi, membebaskan Slot tersebut dan menandainya sebagai tersedia untuk alokasi tugas lain.
5. WHEN tugas diedit (deadline atau estimasi waktu berubah), THE Smart_Scheduler SHALL menghitung ulang dan mengalokasikan kembali Time_Block untuk tugas yang diedit tersebut tanpa mengubah posisi Time_Block milik tugas lain yang telah dipindahkan secara manual oleh pengguna.
6. WHEN tugas ditandai selesai, THE Smart_Scheduler SHALL menghapus semua Time_Block yang terkait dengan tugas tersebut dan membebaskan Slot-nya.

---

### Requirement 8: Integrasi dengan SAW Service yang Sudah Ada

**User Story:** Sebagai pengguna, saya ingin fitur penjadwalan cerdas terintegrasi dengan sistem prioritas SAW yang sudah ada, sehingga ranking prioritas yang sudah dihitung langsung digunakan untuk penjadwalan.

#### Acceptance Criteria

1. THE Smart_Scheduler SHALL menggunakan SAW_Score yang dihitung oleh SAW_Service sebagai satu-satunya penentu urutan prioritas dalam proses Conflict_Resolution.
2. WHEN SAW_Service menghitung ulang prioritas (setelah tambah, edit, atau hapus tugas), THE Smart_Scheduler SHALL menghitung ulang jadwal seluruh tugas aktif berdasarkan SAW_Score terbaru dalam waktu tidak lebih dari 3 detik setelah perhitungan SAW selesai.
3. THE Smart_Scheduler SHALL mempertahankan konsistensi antara ranking tugas di daftar prioritas dan alokasi Slot pada jadwal — tugas dengan ranking numerik lebih kecil (prioritas lebih tinggi) SHALL mendapat Time_Block pertama yang lebih dekat ke deadline-nya dibandingkan tugas dengan ranking numerik lebih besar (prioritas lebih rendah) pada Slot yang sama diperebutkan.
4. IF estimasi waktu tugas berubah, THEN THE Smart_Scheduler SHALL menghapus seluruh Time_Block lama tugas tersebut dan mengalokasikan ulang Time_Block baru sesuai estimasi terbaru (1–10 jam) tanpa mengubah SAW_Score tugas tersebut.
5. IF dua atau lebih tugas memiliki SAW_Score yang identik saat Conflict_Resolution, THEN THE Smart_Scheduler SHALL memprioritaskan tugas dengan deadline lebih awal, dan jika deadline juga sama, memprioritaskan tugas dengan createdAt lebih awal.
6. IF SAW_Service gagal menghitung SAW_Score (misalnya tidak ada tugas aktif atau terjadi error), THEN THE Smart_Scheduler SHALL mempertahankan jadwal terakhir yang valid dan menampilkan pesan error yang menginformasikan bahwa penjadwalan tidak dapat diperbarui hingga perhitungan prioritas berhasil.
7. WHEN SAW_Service selesai menghitung ulang prioritas, THE Smart_Scheduler SHALL menunggu hingga seluruh SAW_Score terbaru tersedia sebelum memulai proses penjadwalan ulang, sehingga tidak terjadi penjadwalan berdasarkan data parsial.

---

### Requirement 9: Persistensi Data Jadwal

**User Story:** Sebagai pengguna, saya ingin jadwal yang telah dibuat tersimpan dan tetap ada ketika saya membuka kembali aplikasi, sehingga saya tidak kehilangan perencanaan yang sudah dibuat.

#### Acceptance Criteria

1. THE Tugasku SHALL menyimpan seluruh data Time_Block (waktu mulai, waktu selesai, ID tugas terkait, status) ke penyimpanan lokal secara sinkron setiap kali terjadi perubahan jadwal, sebelum operasi berikutnya dijalankan.
2. WHEN aplikasi dibuka, THE Tugasku SHALL memuat data jadwal dari penyimpanan lokal dalam waktu maksimal 3 detik dan menampilkannya pada Schedule_View.
3. IF data jadwal pada penyimpanan lokal tidak ditemukan atau tidak dapat dibaca (corrupt), THEN THE Tugasku SHALL menampilkan Schedule_View dalam keadaan kosong tanpa error crash, dan menampilkan pesan yang menginformasikan bahwa data jadwal tidak tersedia.
4. WHEN data jadwal dimuat dan ditemukan Time_Block yang waktu selesainya sudah melewati waktu saat ini dan tugas terkait belum berstatus selesai, THE Smart_Scheduler SHALL menandai Time_Block tersebut sebagai "terlewat" tanpa menghapusnya dari riwayat.
5. THE Schedule_View SHALL menampilkan Time_Block berstatus "terlewat" dengan indikator visual yang berbeda dari Time_Block aktif (misalnya warna redup atau coret), sehingga pengguna dapat membedakan blok yang sudah terlewat dari blok yang masih akan datang.
6. THE Tugasku SHALL menyimpan pengaturan Primary_Work_Hours ke penyimpanan lokal setiap kali pengguna mengubah nilainya, dan memuatnya kembali saat aplikasi dibuka dengan nilai default 08:00–17:00 jika data pengaturan tidak ditemukan.

---

### Requirement 10: AI-Powered Auto Task Creation (Opsional)

**User Story:** Sebagai pengguna, saya ingin dapat membuat tugas secara otomatis menggunakan AI berdasarkan input teks seperti silabus atau deskripsi proyek, sehingga saya tidak perlu memasukkan setiap tugas satu per satu secara manual.

#### Acceptance Criteria

1. WHERE fitur AI_Task_Creator diaktifkan, THE Tugasku SHALL menampilkan opsi "Buat Tugas Otomatis" pada layar tambah tugas.
2. WHERE fitur AI_Task_Creator diaktifkan, WHEN pengguna memasukkan teks deskripsi dengan panjang antara 50 hingga 10.000 karakter (silabus, brief proyek, atau daftar tugas), THE AI_Task_Creator SHALL mengekstrak informasi dan menghasilkan maksimal 50 tugas yang direkomendasikan, di mana setiap tugas memiliki field: nama tugas, deadline, estimasi waktu pengerjaan (dalam jam), tingkat kepentingan (1–5), dan tingkat urgensi (1–5).
3. WHERE fitur AI_Task_Creator diaktifkan, WHEN AI_Task_Creator sedang memproses input teks, THE Tugasku SHALL menampilkan indikator loading beserta teks yang menunjukkan proses ekstraksi sedang berlangsung.
4. WHERE fitur AI_Task_Creator diaktifkan, WHEN AI_Task_Creator menghasilkan daftar tugas, THE Tugasku SHALL menampilkan preview daftar tugas yang direkomendasikan dan memungkinkan pengguna untuk mengedit, menghapus, atau mengonfirmasi setiap tugas sebelum disimpan.
5. WHERE fitur AI_Task_Creator diaktifkan, WHEN pengguna mengonfirmasi tugas hasil AI, THE Tugasku SHALL menyimpan tugas tersebut dan menjalankan SAW_Service serta Smart_Scheduler untuk menghitung prioritas dan mengalokasikan jadwal.
6. WHERE fitur AI_Task_Creator diaktifkan, IF AI_Task_Creator gagal mengekstrak tugas dari input teks atau tidak merespons dalam waktu 30 detik, THEN THE AI_Task_Creator SHALL menghentikan proses, menampilkan pesan error yang menjelaskan penyebab kegagalan (timeout atau input tidak dapat diproses), dan menyarankan pengguna untuk memperjelas input atau membuat tugas secara manual.
7. WHERE fitur AI_Task_Creator diaktifkan, IF panjang teks input kurang dari 50 karakter, THEN THE Tugasku SHALL menonaktifkan tombol proses dan menampilkan pesan bahwa input terlalu pendek untuk diekstrak.
