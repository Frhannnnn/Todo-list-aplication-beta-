# Design Document — UX Prioritas Tugas

## Overview

Dokumen ini menjabarkan arsitektur dan desain implementasi perbaikan UX fitur penentuan prioritas tugas pada aplikasi **Tugasku** (Flutter). Perbaikan mencakup tiga area: (1) enrichment slider SAW pada `AddEditTaskScreen`, (2) badge label prioritas pada `TaskCardWidget`, (3) filter & sort prioritas pada `TaskListScreen`, dan (4) refactor layout Eisenhower Matrix pada `PriorityScreen` menjadi grid 2×2 kompak.

Tidak ada perubahan pada model data (`Task`), algoritma SAW (`SAWService`), atau `TaskProvider` — semua perbaikan bersifat UI/UX murni.

---

## Architecture

Aplikasi menggunakan arsitektur **Provider + Widget** standar Flutter:

```
TaskProvider (ChangeNotifier)
    └── SAWService.hitungPrioritas()  ← tidak berubah
    └── AppTheme.getPrioritasLabel()  ← sudah ada, dipakai lebih luas
    └── AppTheme.getPrioritasColor()  ← sudah ada, dipakai lebih luas

UI Layer (perubahan di sini):
    ├── AddEditTaskScreen      ← enriched slider (Req 1, 2)
    ├── TaskCardWidget         ← badge prioritas (Req 3)
    ├── TaskListScreen         ← filter & sort prioritas (Req 4)
    └── PriorityScreen         ← grid 2×2 kompak (Req 5)
```

Semua state filter/sort pada `TaskListScreen` bersifat **lokal** (`StatefulWidget`) — tidak perlu dipersist ke `TaskProvider` karena hanya memengaruhi tampilan sementara.

---

## Components and Interfaces

### 1. `AddEditTaskScreen` — Enriched SAW Sliders

#### 1.1 Helper Functions (pure, dapat diuji)

Dua fungsi helper statis ditambahkan, bisa ditempatkan di `app_theme.dart` atau sebagai static method di dalam screen:

```dart
/// Mengembalikan label deskriptif untuk nilai slider kepentingan/urgensi (1–5).
static String getLabelSlider(int value) {
  const labels = {
    1: 'Sangat Rendah',
    2: 'Rendah',
    3: 'Sedang',
    4: 'Tinggi',
    5: 'Sangat Tinggi',
  };
  return labels[value] ?? '-';
}

/// Mengembalikan label kuadran Eisenhower berdasarkan kombinasi kepentingan & urgensi.
/// Threshold: nilai >= 4 dianggap "tinggi".
static String getEisenhowerLabel(int kepentingan, int urgensi) {
  final isImportant = kepentingan >= 4;
  final isUrgent = urgensi >= 4;
  if (isImportant && isUrgent) return 'Penting & Mendesak → Kerjakan Sekarang';
  if (isImportant && !isUrgent) return 'Penting, Tidak Mendesak → Jadwalkan';
  if (!isImportant && isUrgent) return 'Mendesak, Kurang Penting → Delegasikan';
  return 'Kurang Penting & Tidak Mendesak → Eliminasi';
}
```

#### 1.2 Perubahan pada `_buildSlider()`

Method `_buildSlider()` yang sudah ada direfactor menjadi dua method terpisah:
- `_buildKepentinganSlider()` — menampilkan deskripsi, contoh perbedaan penting vs mendesak, dan info icon dengan tooltip.
- `_buildUrgensiSlider()` — menampilkan deskripsi, info icon dengan tooltip.
- `_buildEisenhowerSummary()` — widget ringkasan kuadran yang muncul di bawah kedua slider, diperbarui setiap kali salah satu slider berubah.

#### 1.3 Layout Slider Baru

```
┌─────────────────────────────────────────────────────┐
│ Parameter SAW                                       │
├─────────────────────────────────────────────────────┤
│ Tingkat Kepentingan  [ℹ]              [Sedang]      │
│ Dampak jangka panjang terhadap tujuan akademik.     │
│ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  │
│ 💡 Penting ≠ Mendesak: penting = berdampak besar    │
│    pada nilai/tujuan; mendesak = deadline dekat.    │
│                                                     │
│ Tingkat Urgensi      [ℹ]              [Sedang]      │
│ Seberapa mendesak berdasarkan kedekatan deadline.   │
│ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  │
│                                                     │
│ ┌─────────────────────────────────────────────────┐ │
│ │ 📊 Penting, Tidak Mendesak → Jadwalkan          │ │
│ └─────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────┘
```

Info icon menggunakan `showDialog` dengan `AlertDialog` (bukan `Tooltip` bawaan Flutter) agar teks panjang dapat ditampilkan dengan nyaman di mobile.

---

### 2. `TaskCardWidget` — Badge Label Prioritas

#### 2.1 Perubahan Signature

`TaskCardWidget` menerima parameter tambahan `totalActiveTasks`:

```dart
class TaskCardWidget extends StatelessWidget {
  final Task task;
  final bool showRanking;
  final int totalActiveTasks;   // ← baru, default 0
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final Function(TaskStatus)? onStatusChange;

  const TaskCardWidget({
    super.key,
    required this.task,
    this.showRanking = false,
    this.totalActiveTasks = 0,  // ← baru
    this.onTap,
    this.onDelete,
    this.onStatusChange,
  });
}
```

Semua pemanggil `TaskCardWidget` yang sudah ada perlu meneruskan `totalActiveTasks: provider.tugasAktif`.

#### 2.2 Logika Badge

```dart
bool get _shouldShowPriorityBadge =>
    task.ranking > 0 &&
    task.status != TaskStatus.selesai &&
    totalActiveTasks > 0;
```

#### 2.3 Layout Header Row

```
┌──────────────────────────────────────────────────────┐
│ [#1] [Tinggi]  Nama Tugas...              [Sedang ▶] │
└──────────────────────────────────────────────────────┘
```

Badge ranking (`#N`) dan badge prioritas (`Tinggi`/`Sedang`/`Rendah`) ditempatkan berdampingan di sisi kiri header row, diikuti nama tugas (`Expanded`), lalu badge status di kanan.

```dart
Row(
  children: [
    if (showRanking && task.ranking > 0) ...[
      _buildRankingBadge(prioritasColor),
      const SizedBox(width: 4),
    ],
    if (_shouldShowPriorityBadge) ...[
      _buildPriorityBadge(),
      const SizedBox(width: 6),
    ],
    Expanded(child: Text(task.namaTugas, ...)),
    _buildStatusBadge(),
  ],
)
```

#### 2.4 Widget Badge Prioritas

```dart
Widget _buildPriorityBadge() {
  final label = AppTheme.getPrioritasLabel(task.ranking, totalActiveTasks);
  final color = AppTheme.getPrioritasColor(task.ranking, totalActiveTasks);
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: color.withValues(alpha: 0.4)),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.w800,
        color: color,
      ),
    ),
  );
}
```

---

### 3. `TaskListScreen` — Filter & Sort Prioritas

#### 3.1 State Baru

```dart
class _TaskListScreenState extends State<TaskListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  String _filterPrioritas = 'Semua';   // ← baru: 'Semua'|'Tinggi'|'Sedang'|'Rendah'
  String _sortMode = 'Default';         // ← baru: 'Default'|'Prioritas Tertinggi'
}
```

#### 3.2 Filter Bar Widget

Filter bar ditempatkan di bawah search bar, sebelum `TabBarView`. Menggunakan `SingleChildScrollView` horizontal dengan `FilterChip`:

```
┌──────────────────────────────────────────────────────┐
│ 🔍 Cari tugas...                                     │
├──────────────────────────────────────────────────────┤
│ Filter: [Semua ✓] [Tinggi] [Sedang] [Rendah]         │
│ Urutkan: [Default] [Prioritas Tertinggi ✓]           │
└──────────────────────────────────────────────────────┘
```

Kedua baris (filter dan sort) digabung dalam satu `Container` dengan `Wrap` atau dua `SingleChildScrollView` horizontal terpisah.

#### 3.3 Logika Filter & Sort

```dart
List<Task> _applyFilterAndSort(List<Task> tasks, int totalActive) {
  // 1. Filter pencarian teks
  if (_searchQuery.isNotEmpty) {
    final q = _searchQuery.toLowerCase();
    tasks = tasks.where((t) =>
      t.namaTugas.toLowerCase().contains(q) ||
      t.mataKuliah.toLowerCase().contains(q)
    ).toList();
  }

  // 2. Filter prioritas
  if (_filterPrioritas != 'Semua') {
    tasks = tasks.where((t) {
      if (t.ranking == 0 || t.status == TaskStatus.selesai) return false;
      return AppTheme.getPrioritasLabel(t.ranking, totalActive) == _filterPrioritas;
    }).toList();
  }

  // 3. Sort
  if (_sortMode == 'Prioritas Tertinggi') {
    tasks.sort((a, b) {
      if (a.ranking == 0 && b.ranking == 0) return 0;
      if (a.ranking == 0) return 1;   // ranking 0 ke bawah
      if (b.ranking == 0) return -1;
      return a.ranking.compareTo(b.ranking);
    });
  }

  return tasks;
}
```

#### 3.4 Empty State Filter

Ketika filter menghasilkan daftar kosong, tampilkan pesan spesifik:

```dart
if (tasks.isEmpty && _filterPrioritas != 'Semua') {
  return _buildEmptyFilterState(_filterPrioritas);
}
```

```dart
Widget _buildEmptyFilterState(String label) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.filter_list_off, size: 64, color: AppTheme.textSecondary),
        const SizedBox(height: 16),
        Text(
          'Tidak ada tugas dengan prioritas $label saat ini.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
      ],
    ),
  );
}
```

---

### 4. `PriorityScreen` — Grid 2×2 Kompak

#### 4.1 Perubahan Layout

Kondisi `!isWide` (lebar < 680dp) yang saat ini menggunakan `Column` diubah menjadi `GridView` dengan `childAspectRatio` yang dikalibrasi agar keempat kuadran muat dalam satu layar tanpa scroll pada perangkat dengan tinggi ≥ 600dp.

```dart
// Sebelum (portrait):
if (!isWide) {
  return Column(children: cards.map(...).toList());
}

// Sesudah (portrait):
if (!isWide) {
  return GridView.count(
    crossAxisCount: 2,
    crossAxisSpacing: 10,
    mainAxisSpacing: 10,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    childAspectRatio: 0.72,  // dikalibrasi untuk tinggi layar 600dp+
    children: cards,
  );
}
```

`childAspectRatio: 0.72` dipilih agar pada layar 360dp lebar, setiap kartu berukuran ~175×243dp — cukup untuk menampilkan header kuadran, action label, dan 2–3 tugas sebelum scroll internal.

#### 4.2 Kartu Kuadran Kompak

`_QuadrantCard` dioptimalkan untuk ukuran lebih kecil:
- Header padding dikurangi dari `fromLTRB(14,14,14,10)` menjadi `fromLTRB(10,10,10,8)`.
- Icon container dikurangi dari 38×38 menjadi 32×32.
- Font title dari 15 menjadi 13, subtitle dari 11 menjadi 10.
- Tinggi area daftar tugas (`SizedBox(height: 210)`) diubah menjadi `Expanded` agar mengisi sisa ruang kartu secara fleksibel.

#### 4.3 Kartu Intro — Ringkasan Distribusi

`_buildIntroCard()` diperluas untuk menampilkan distribusi per kuadran:

```dart
Widget _buildIntroCard(int activeCount, Map<EisenhowerQuadrant, List<Task>> grouped) {
  // ...existing header...
  // Tambah baris distribusi:
  Row(
    mainAxisAlignment: MainAxisAlignment.spaceAround,
    children: EisenhowerQuadrant.values.map((q) {
      final count = grouped[q]?.length ?? 0;
      final config = _configFor(q);
      return _buildDistribItem(config.title, count, config.color);
    }).toList(),
  )
}

Widget _buildDistribItem(String label, int count, Color color) {
  return Column(
    children: [
      Text('$count', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
      Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
    ],
  );
}
```

---

## Data Models

Tidak ada perubahan pada model data. `Task`, `TaskStatus`, `TaskGroup`, `TaskCategory` tetap sama.

`AppTheme.getPrioritasLabel()` dan `AppTheme.getPrioritasColor()` sudah ada dan digunakan lebih luas.

---

## Error Handling

| Kondisi | Penanganan |
|---|---|
| `task.ranking == 0` | Badge prioritas tidak ditampilkan (Req 3.4) |
| `totalActiveTasks == 0` | `AppTheme.getPrioritasLabel()` mengembalikan `'-'`; badge tidak ditampilkan karena kondisi `totalActiveTasks > 0` |
| Filter prioritas tidak cocok | Empty state dengan pesan informatif (Req 4.6) |
| Kuadran kosong | Teks "Tidak ada tugas" tetap ditampilkan (sudah ada) |
| Slider nilai di luar [1,5] | Tidak mungkin terjadi karena `Slider` dibatasi `min:1, max:5` |

---

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system — essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Label Slider Selalu Valid untuk Semua Nilai

*For any* nilai integer `v` dalam rentang [1, 5], fungsi `getLabelSlider(v)` harus mengembalikan string non-kosong yang merupakan salah satu dari: "Sangat Rendah", "Rendah", "Sedang", "Tinggi", "Sangat Tinggi".

**Validates: Requirements 1.2, 2.2**

---

### Property 2: Label Kuadran Eisenhower Selalu Valid untuk Semua Kombinasi

*For any* pasangan nilai integer `(kepentingan, urgensi)` masing-masing dalam rentang [1, 5], fungsi `getEisenhowerLabel(kepentingan, urgensi)` harus mengembalikan string non-kosong yang merupakan salah satu dari empat label kuadran yang valid ("Kerjakan Sekarang", "Jadwalkan", "Delegasikan", "Eliminasi").

**Validates: Requirements 2.4**

---

### Property 3: Badge Prioritas Muncul Jika dan Hanya Jika Kondisi Terpenuhi

*For any* objek `Task` dan nilai `totalActiveTasks`:
- Jika `task.ranking > 0` DAN `task.status != TaskStatus.selesai` DAN `totalActiveTasks > 0`, maka `TaskCardWidget` HARUS menampilkan badge prioritas dengan teks yang sesuai.
- Jika `task.ranking == 0` ATAU `task.status == TaskStatus.selesai`, maka `TaskCardWidget` TIDAK BOLEH menampilkan badge prioritas.

**Validates: Requirements 3.1, 3.4**

---

### Property 4: Warna Badge Konsisten dengan AppTheme

*For any* pasangan `(ranking, totalActiveTasks)` yang valid (ranking > 0, totalActiveTasks > 0), warna yang digunakan pada badge prioritas di `TaskCardWidget` harus identik dengan nilai yang dikembalikan oleh `AppTheme.getPrioritasColor(ranking, totalActiveTasks)`.

**Validates: Requirements 3.2**

---

### Property 5: Filter Prioritas Hanya Menampilkan Tugas yang Sesuai

*For any* daftar tugas dan pilihan filter prioritas `f` ∈ {"Tinggi", "Sedang", "Rendah"}, setelah filter diterapkan, setiap tugas yang ditampilkan harus memenuhi: `AppTheme.getPrioritasLabel(task.ranking, totalActive) == f`.

**Validates: Requirements 4.2**

---

### Property 6: Filter "Semua" Tidak Menyaring Tugas

*For any* daftar tugas, menerapkan filter "Semua" harus menghasilkan jumlah tugas yang sama dengan daftar sebelum filter diterapkan (hanya filter teks yang tetap berlaku).

**Validates: Requirements 4.3**

---

### Property 7: Sort "Prioritas Tertinggi" Menghasilkan Urutan Monoton

*For any* daftar tugas setelah sort "Prioritas Tertinggi" diterapkan, untuk setiap pasangan tugas berurutan `(tasks[i], tasks[i+1])` di mana keduanya memiliki `ranking > 0`, harus berlaku `tasks[i].ranking <= tasks[i+1].ranking`. Tugas dengan `ranking == 0` harus selalu berada di posisi setelah semua tugas dengan `ranking > 0`.

**Validates: Requirements 4.5**

---

### Property 8: Badge Count Kuadran Konsisten dengan Data Tugas

*For any* daftar tugas aktif, jumlah yang ditampilkan pada badge count setiap kuadran di `PriorityScreen` harus sama dengan jumlah tugas dalam daftar yang memenuhi kriteria kuadran tersebut (kepentingan ≥ 4 dan urgensi ≥ 4 untuk "Kerjakan", dst.).

**Validates: Requirements 5.2**

---

### Property 9: Ringkasan Intro Card Mencerminkan Data Aktual

*For any* daftar tugas aktif, teks ringkasan total di kartu intro `PriorityScreen` harus mencerminkan jumlah total tugas aktif yang benar, dan jumlah per kuadran yang ditampilkan harus menjumlah ke total tugas aktif tersebut.

**Validates: Requirements 5.6**

---

## Testing Strategy

### Unit Tests (Example-Based)

Fokus pada kasus spesifik dan kondisi batas:

- **`getLabelSlider()`**: Verifikasi setiap nilai 1–5 menghasilkan label yang benar.
- **`getEisenhowerLabel()`**: Verifikasi keempat kombinasi kuadran (tinggi/tinggi, tinggi/rendah, rendah/tinggi, rendah/rendah).
- **`TaskCardWidget` — badge tidak muncul**: Verifikasi badge tidak muncul saat `ranking == 0` atau `status == selesai`.
- **`TaskCardWidget` — badge muncul**: Verifikasi badge muncul dengan teks dan warna yang benar saat kondisi terpenuhi.
- **`_applyFilterAndSort()` — filter "Semua"**: Verifikasi tidak ada tugas yang disaring.
- **`_applyFilterAndSort()` — empty state**: Verifikasi pesan kosong muncul saat filter tidak cocok.
- **`PriorityScreen` — label kuadran**: Verifikasi keempat label kuadran tetap ada.
- **`PriorityScreen` — layout portrait**: Verifikasi `GridView` dengan `crossAxisCount: 2` digunakan untuk lebar < 680dp.

### Property-Based Tests

Menggunakan library `dart_test` dengan generator acak untuk memvalidasi properti universal:

- **Property 1**: Generate nilai acak dalam [1,5] → `getLabelSlider()` selalu mengembalikan string valid.
- **Property 2**: Generate pasangan acak (kepentingan, urgensi) dalam [1,5]×[1,5] → `getEisenhowerLabel()` selalu mengembalikan salah satu dari 4 label kuadran.
- **Property 3**: Generate `Task` acak dengan berbagai kombinasi `ranking` dan `status` → badge muncul/tidak sesuai kondisi.
- **Property 4**: Generate pasangan (ranking, total) acak → warna badge konsisten dengan `AppTheme.getPrioritasColor()`.
- **Property 5**: Generate daftar tugas acak + pilihan filter → semua tugas yang ditampilkan memiliki label prioritas yang sesuai.
- **Property 6**: Generate daftar tugas acak → filter "Semua" tidak mengubah jumlah tugas.
- **Property 7**: Generate daftar tugas acak → sort "Prioritas Tertinggi" menghasilkan urutan monoton ascending.
- **Property 8**: Generate daftar tugas acak → badge count kuadran konsisten dengan data.
- **Property 9**: Generate daftar tugas acak → ringkasan intro card mencerminkan data aktual.

Setiap property test dijalankan minimal 100 iterasi dengan input yang di-generate secara acak.
