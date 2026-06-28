# Issue: Refaktor Kriteria dan Bobot Prioritas SAW

## Deskripsi Masalah
Saat ini aplikasi menggunakan 4 kriteria dalam perhitungan metode SAW (Simple Additive Weighting) untuk menentukan prioritas tugas. Namun, kriteria **"Kedekatan Deadline"** dan **"Tingkat Urgensi"** merepresentasikan hal yang sama dan tumpang tindih.

## Tujuan Perubahan
Menyederhanakan perhitungan metode SAW dari 4 kriteria menjadi hanya **3 kriteria utama** untuk menghindari redundansi dan membuat perhitungan bobot menjadi lebih masuk akal.

## Kriteria & Bobot Baru
Perbarui logika perhitungan SAW dengan menggunakan susunan bobot berikut:
1. **Tingkat Urgensi**: 40% (0.4)
2. **Tingkat Kepentingan**: 40% (0.4)
3. **Estimasi Waktu**: 20% (0.2)

*(Total Bobot: 100% atau 1.0)*

## Instruksi Implementasi (High Level)
Kepada Junior Programmer / Implementer AI, harap lakukan langkah-langkah berikut:

1. **Update Model Data & Konstanta**:
   - Cari dan hapus referensi variabel terkait "Kedekatan Deadline" (jika ada sebagai kriteria terpisah) dari model data tugas (misalnya `TaskModel`).
   - Ubah definisi konstanta atau konfigurasi bobot SAW di dalam service atau pengaturan aplikasi menjadi 3 kriteria di atas dengan persentase yang baru.

2. **Refaktor Logika Perhitungan SAW**:
   - Update file service/fungsi yang menangani kalkulasi algoritma SAW (kemungkinan berada di `saw_service.dart` atau file sejenis).
   - Pastikan proses normalisasi matriks dan perhitungan akhir nilai preferensi (Vi) hanya memproses 3 kriteria tersebut.

3. **Update Antarmuka Pengguna (UI)**:
   - Sesuaikan halaman **Form Tambah/Edit Tugas** jika sebelumnya meminta input khusus untuk "Kedekatan Deadline" (bila inputnya terpisah dari sekadar tanggal kalender). Pastikan tidak membingungkan pengguna terkait kriteria urgensi.
   - Update halaman **Pengaturan / Informasi Bobot** (`settings_screen.dart` atau sejenisnya) agar menampilkan teks keterangan bobot SAW yang baru (40%, 40%, 20%).

4. **Update Dokumentasi**:
   - Perbarui file `README.md` pada bagian "Metode SAW" agar sesuai dengan 3 kriteria baru dan rumus pembobotannya.

## Kriteria Penerimaan (Acceptance Criteria)
- [ ] Aplikasi berhasil di-build dan berjalan tanpa error.
- [ ] Perhitungan skor SAW yang baru (3 kriteria) dapat merangking tugas dengan tepat sesuai dengan bobot baru (40-40-20).
- [ ] Halaman informasi SAW di UI dan README sudah diperbarui agar sinkron dengan bobot terbaru.
- [ ] Tidak ada referensi ke kriteria bobot lama yang tertinggal dalam source code.
