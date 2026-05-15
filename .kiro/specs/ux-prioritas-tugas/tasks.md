# Implementation Plan: UX Prioritas Tugas

## Overview

Implementasi perbaikan UX fitur penentuan prioritas tugas pada aplikasi Tugasku (Flutter). Semua perubahan bersifat UI/UX murni — tidak ada perubahan pada model data, algoritma SAW, atau TaskProvider. Empat area yang diubah: (1) enrichment slider SAW di `AddEditTaskScreen`, (2) badge label prioritas di `TaskCardWidget`, (3) filter & sort prioritas di `TaskListScreen`, dan (4) refactor layout Eisenhower Matrix di `PriorityScreen` menjadi grid 2×2 kompak.

## Tasks

- [x] 1. Tambahkan helper functions untuk label slider dan kuadran Eisenhower
  - [x] 1.1 Tambahkan static method `getLabelSlider(int value)` di `app_theme.dart`
    - Mengembalikan string deskriptif untuk nilai 1–5: "Sangat Rendah", "Rendah", "Sedang", "Tinggi", "Sangat Tinggi"
    - Nilai di luar rentang mengembalikan `'-'`
    - _Requirements: 1.2, 2.2_

  - [x] 1.2 Tambahkan static method `getEisenhowerLabel(int kepentingan, int urgensi)` di `app_theme.dart`
    - Threshold: nilai >= 4 dianggap "tinggi"
    - Mengembalikan salah satu dari 4 label: "Penting & Mendesak → Kerjakan Sekarang", "Penting, Tidak Mendesak → Jadwalkan", "Mendesak, Kurang Penting → Delegasikan", "Kurang Penting & Tidak Mendesak → Eliminasi"
    - _Requirements: 2.4_

  - [x] 1.3 Tulis property test untuk `getLabelSlider()`
    - **Property 1: Label Slider Selalu Valid untuk Semua Nilai**
    - **Validates: Requirements 1.2, 2.2**
    - Generate nilai acak dalam [1,5] → hasil harus salah satu dari 5 label yang valid dan non-kosong

  - [x] 1.4 Tulis property test untuk `getEisenhowerLabel()`
    - **Property 2: Label Kuadran Eisenhower Selalu Valid untuk Semua Kombinasi**
    - **Validates: Requirements 2.4**
    - Generate pasangan acak (kepentingan, urgensi) dalam [1,5]×[1,5] → hasil harus salah satu dari 4 label kuadran yang valid

- [x] 2. Perbaiki slider SAW di `AddEditTaskScreen`
  - [x] 2.1 Refactor `_buildSlider()` menjadi `_buildKepentinganSlider()` dan `_buildUrgensiSlider()`
    - `_buildKepentinganSlider()`: tampilkan teks deskripsi "Dampak jangka panjang terhadap tujuan akademik" di bawah judul
    - `_buildKepentinganSlider()`: tampilkan baris contoh "💡 Penting ≠ Mendesak: penting = berdampak besar pada nilai/tujuan; mendesak = deadline dekat"
    - `_buildKepentinganSlider()`: tambahkan ikon bantuan (info icon) di samping judul yang membuka `AlertDialog` dengan penjelasan kepentingan
    - `_buildUrgensiSlider()`: tampilkan teks deskripsi "Seberapa mendesak berdasarkan kedekatan deadline" di bawah judul
    - `_buildUrgensiSlider()`: tambahkan ikon bantuan (info icon) di samping judul yang membuka `AlertDialog` dengan penjelasan urgensi
    - Label nilai slider menggunakan `AppTheme.getLabelSlider()` dan diperbarui real-time saat slider digeser
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 2.1, 2.2, 2.3_

  - [x] 2.2 Tambahkan widget `_buildEisenhowerSummary()` di bawah kedua slider
    - Menampilkan teks kuadran Eisenhower menggunakan `AppTheme.getEisenhowerLabel(_kepentingan, _urgensi)`
    - Diperbarui secara reaktif setiap kali salah satu slider berubah (karena berada dalam `setState`)
    - Tampilkan dalam `Container` dengan warna latar sesuai kuadran
    - _Requirements: 2.4_

  - [x] 2.3 Update section "Parameter SAW" di `build()` untuk menggunakan method baru
    - Ganti pemanggilan `_buildSlider('Tingkat Kepentingan', ...)` dengan `_buildKepentinganSlider()`
    - Ganti pemanggilan `_buildSlider('Tingkat Urgensi', ...)` dengan `_buildUrgensiSlider()`
    - Tambahkan `_buildEisenhowerSummary()` setelah kedua slider
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 2.1, 2.2, 2.3, 2.4_

- [x] 3. Checkpoint — Pastikan semua tes lulus
  - Pastikan semua tes lulus, tanyakan kepada pengguna jika ada pertanyaan.

- [x] 4. Tambahkan badge label prioritas pada `TaskCardWidget`
  - [x] 4.1 Tambahkan parameter `totalActiveTasks` ke `TaskCardWidget`
    - Tambahkan field `final int totalActiveTasks` dengan default value `0`
    - Tambahkan getter `bool get _shouldShowPriorityBadge` yang mengembalikan `true` jika `task.ranking > 0 && task.status != TaskStatus.selesai && totalActiveTasks > 0`
    - _Requirements: 3.1, 3.4_

  - [x] 4.2 Implementasikan `_buildPriorityBadge()` di `TaskCardWidget`
    - Gunakan `AppTheme.getPrioritasLabel(task.ranking, totalActiveTasks)` untuk teks label
    - Gunakan `AppTheme.getPrioritasColor(task.ranking, totalActiveTasks)` untuk warna
    - Font size minimal 9sp, padding horizontal minimal 6dp
    - Tambahkan border tipis dengan warna yang sama (alpha 0.4)
    - _Requirements: 3.2, 3.5_

  - [x] 4.3 Update header row di `TaskCardWidget` untuk menyertakan badge prioritas
    - Tempatkan badge prioritas setelah badge ranking (`#N`) dan sebelum nama tugas (`Expanded`)
    - Tampilkan badge hanya jika `_shouldShowPriorityBadge` bernilai `true`
    - Pastikan nama tugas tetap menggunakan `Expanded` agar tidak terpotong
    - _Requirements: 3.1, 3.3, 3.4_

  - [x] 4.4 Tulis property test untuk logika badge prioritas
    - **Property 3: Badge Prioritas Muncul Jika dan Hanya Jika Kondisi Terpenuhi**
    - **Validates: Requirements 3.1, 3.4**
    - Generate `Task` acak dengan berbagai kombinasi `ranking` dan `status` → verifikasi `_shouldShowPriorityBadge` sesuai kondisi

  - [x] 4.5 Tulis property test untuk konsistensi warna badge
    - **Property 4: Warna Badge Konsisten dengan AppTheme**
    - **Validates: Requirements 3.2**
    - Generate pasangan (ranking, totalActiveTasks) acak yang valid → warna badge harus identik dengan `AppTheme.getPrioritasColor(ranking, totalActiveTasks)`

- [x] 5. Update semua pemanggil `TaskCardWidget` untuk meneruskan `totalActiveTasks`
  - [x] 5.1 Update `TaskListScreen` untuk meneruskan `totalActiveTasks` ke `TaskCardWidget`
    - Ambil `provider.activeTasks.length` dan teruskan sebagai `totalActiveTasks`
    - _Requirements: 3.1_

  - [x] 5.2 Periksa dan update pemanggil `TaskCardWidget` lain (misalnya di `DashboardScreen`)
    - Cari semua penggunaan `TaskCardWidget` di seluruh codebase
    - Teruskan `totalActiveTasks: provider.activeTasks.length` pada setiap pemanggil
    - _Requirements: 3.1_

- [x] 6. Tambahkan filter dan sort prioritas di `TaskListScreen`
  - [x] 6.1 Tambahkan state `_filterPrioritas` dan `_sortMode` ke `_TaskListScreenState`
    - `String _filterPrioritas = 'Semua'` — nilai valid: 'Semua', 'Tinggi', 'Sedang', 'Rendah'
    - `String _sortMode = 'Default'` — nilai valid: 'Default', 'Prioritas Tertinggi'
    - _Requirements: 4.1, 4.4_

  - [x] 6.2 Implementasikan method `_applyFilterAndSort(List<Task> tasks, int totalActive)`
    - Filter teks (sudah ada, pertahankan)
    - Filter prioritas: jika `_filterPrioritas != 'Semua'`, saring tugas berdasarkan `AppTheme.getPrioritasLabel(t.ranking, totalActive) == _filterPrioritas`; tugas dengan `ranking == 0` atau `status == selesai` tidak lolos filter
    - Sort: jika `_sortMode == 'Prioritas Tertinggi'`, urutkan ascending berdasarkan `ranking`; tugas dengan `ranking == 0` ditempatkan di bawah
    - _Requirements: 4.2, 4.3, 4.5_

  - [x] 6.3 Tambahkan widget `_buildFilterSortBar()` di `TaskListScreen`
    - Baris filter: `SingleChildScrollView` horizontal dengan `FilterChip` untuk "Semua", "Tinggi", "Sedang", "Rendah"
    - Baris sort: `FilterChip` atau `ChoiceChip` untuk "Default" dan "Prioritas Tertinggi"
    - Tempatkan di bawah search bar, sebelum `TabBarView`
    - Chip yang aktif ditandai dengan warna berbeda
    - _Requirements: 4.1, 4.4_

  - [x] 6.4 Implementasikan `_buildEmptyFilterState(String label)` di `TaskListScreen`
    - Tampilkan ikon `Icons.filter_list_off` dan teks "Tidak ada tugas dengan prioritas [label] saat ini."
    - Tampilkan hanya ketika hasil filter kosong dan `_filterPrioritas != 'Semua'`
    - _Requirements: 4.6_

  - [x] 6.5 Integrasikan `_applyFilterAndSort()` dan `_buildFilterSortBar()` ke dalam `_buildTaskList()` dan `build()`
    - Panggil `_applyFilterAndSort()` sebelum render daftar tugas
    - Tampilkan `_buildEmptyFilterState()` jika hasil kosong dan filter aktif
    - Teruskan `totalActiveTasks` ke setiap `TaskCardWidget`
    - _Requirements: 4.2, 4.3, 4.5, 4.6_

  - [x] 6.6 Tulis property test untuk filter prioritas
    - **Property 5: Filter Prioritas Hanya Menampilkan Tugas yang Sesuai**
    - **Validates: Requirements 4.2**
    - Generate daftar tugas acak + pilihan filter → semua tugas hasil filter harus memiliki label prioritas yang sesuai

  - [x] 6.7 Tulis property test untuk filter "Semua"
    - **Property 6: Filter "Semua" Tidak Menyaring Tugas**
    - **Validates: Requirements 4.3**
    - Generate daftar tugas acak → filter "Semua" tidak mengubah jumlah tugas (hanya filter teks yang berlaku)

  - [x] 6.8 Tulis property test untuk sort "Prioritas Tertinggi"
    - **Property 7: Sort "Prioritas Tertinggi" Menghasilkan Urutan Monoton**
    - **Validates: Requirements 4.5**
    - Generate daftar tugas acak → setelah sort, untuk setiap pasangan berurutan dengan `ranking > 0`, berlaku `tasks[i].ranking <= tasks[i+1].ranking`; tugas dengan `ranking == 0` selalu di bawah

- [x] 7. Checkpoint — Pastikan semua tes lulus
  - Pastikan semua tes lulus, tanyakan kepada pengguna jika ada pertanyaan.

- [x] 8. Refactor layout Eisenhower Matrix di `PriorityScreen` menjadi grid 2×2 kompak
  - [x] 8.1 Ubah layout portrait (`!isWide`) dari `Column` menjadi `GridView.count`
    - Gunakan `crossAxisCount: 2`, `crossAxisSpacing: 10`, `mainAxisSpacing: 10`
    - `shrinkWrap: true`, `physics: NeverScrollableScrollPhysics()`
    - `childAspectRatio: 0.72` agar keempat kuadran muat pada layar ≥ 600dp tinggi
    - _Requirements: 5.1, 5.5_

  - [x] 8.2 Optimalkan `_QuadrantCard` untuk ukuran kompak
    - Kurangi header padding dari `fromLTRB(14,14,14,10)` menjadi `fromLTRB(10,10,10,8)`
    - Kurangi ukuran icon container dari 38×38 menjadi 32×32
    - Kurangi font title dari 15 menjadi 13, subtitle dari 11 menjadi 10
    - Ubah `SizedBox(height: 210)` menjadi `Expanded` agar daftar tugas mengisi sisa ruang kartu secara fleksibel
    - _Requirements: 5.1, 5.3_

  - [x] 8.3 Perluas `_buildIntroCard()` untuk menampilkan distribusi per kuadran
    - Ubah signature menjadi `_buildIntroCard(int activeCount, Map<EisenhowerQuadrant, List<Task>> grouped)`
    - Tambahkan baris distribusi dengan `Row` berisi 4 kolom (satu per kuadran) menggunakan `_buildDistribItem()`
    - Implementasikan `_buildDistribItem(String label, int count, Color color)` yang menampilkan angka besar berwarna dan label kuadran kecil
    - Update pemanggil `_buildIntroCard()` di `build()` untuk meneruskan `grouped`
    - _Requirements: 5.6_

  - [x] 8.4 Tulis property test untuk badge count kuadran
    - **Property 8: Badge Count Kuadran Konsisten dengan Data Tugas**
    - **Validates: Requirements 5.2**
    - Generate daftar tugas acak → jumlah pada badge count setiap kuadran harus sama dengan jumlah tugas yang memenuhi kriteria kuadran tersebut

  - [x] 8.5 Tulis property test untuk ringkasan intro card
    - **Property 9: Ringkasan Intro Card Mencerminkan Data Aktual**
    - **Validates: Requirements 5.6**
    - Generate daftar tugas acak → jumlah per kuadran yang ditampilkan harus menjumlah ke total tugas aktif

- [x] 9. Checkpoint akhir — Pastikan semua tes lulus
  - Pastikan semua tes lulus, tanyakan kepada pengguna jika ada pertanyaan.

## Notes

- Task bertanda `*` bersifat opsional dan dapat dilewati untuk MVP yang lebih cepat
- Setiap task mereferensikan requirement spesifik untuk keterlacakan
- Semua perubahan bersifat UI/UX murni — tidak ada perubahan pada `Task`, `SAWService`, atau `TaskProvider`
- Property test menggunakan library `dart_test` dengan generator acak, minimal 100 iterasi per properti
- `AppTheme.getLabelSlider()` dan `AppTheme.getEisenhowerLabel()` ditambahkan ke `app_theme.dart` agar dapat diuji secara terisolasi
- Semua pemanggil `TaskCardWidget` harus diperbarui untuk meneruskan `totalActiveTasks`

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1", "1.2"] },
    { "id": 1, "tasks": ["1.3", "1.4", "4.1"] },
    { "id": 2, "tasks": ["2.1", "2.2", "4.2", "6.1", "6.2"] },
    { "id": 3, "tasks": ["2.3", "4.3", "4.4", "4.5", "6.3", "6.4"] },
    { "id": 4, "tasks": ["5.1", "5.2", "6.5", "8.1", "8.2"] },
    { "id": 5, "tasks": ["6.6", "6.7", "6.8", "8.3"] },
    { "id": 6, "tasks": ["8.4", "8.5"] }
  ]
}
```
