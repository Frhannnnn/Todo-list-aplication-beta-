# Tugas Berulang (Recurring Tasks) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Tugas bisa berulang otomatis menurut pola (harian/mingguan/bulanan/tahunan/hari-kerja/custom); occurrence berikutnya lahir saat occurrence sekarang diselesaikan, dan occurrence mendatang tampil sebagai preview cincin berongga di kalender.

**Architecture:** Model lazy "satu occurrence terbuka per seri". Rule disimpan sebagai enum + param di `Task`. Occurrence baru di-spawn di `TaskProvider.editTugas` saat transisi status ke `selesai`. Mesin hitung tanggal & label ada di `lib/utils/recurrence.dart`. Preview kalender dihitung on-the-fly (tidak disimpan).

**Tech Stack:** Flutter, Provider, `intl` (DateFormat locale id_ID), shared_preferences.

## Global Constraints

- **UI senada**: reuse `AppTheme.*`; kartu `Colors.white` + `BorderRadius.circular(20)` + `Border.all(color: AppTheme.border)`; badge/chip pill `color.withValues(alpha: 0.1)` + border alpha 0.3; ikon `_rounded`; font Inter (default theme).
- **Enum kode Inggris, label Indonesia** via `DateFormat('EEEE'/'MMMM'/'d MMMM','id_ID')`. `initializeDateFormatting('id_ID')` sudah ada di `main()`.
- **Simpan rule sebagai enum + param**, bukan string label. Label selalu di-generate ulang dari tanggal terpilih.
- **Testing ditunda ke sesi akhir** (preferensi user). Gate tiap task = `flutter analyze` bersih (0 issue pada file yang disentuh) + untuk task UI: build & uji di HP Infinix (device id `143352554V103518`) via `flutter run`. Baseline `flutter test` saat ini +360/-40; jangan menambah kegagalan.
- **Migrasi JSON aman**: semua field baru defaulted/nullable; `fromJson` fallback ke `none`/default untuk data lama.
- Commit tiap akhir task.

---

### Task 1: Model — enum & field recurrence pada Task

**Files:**
- Modify: `lib/models/task_model.dart`

**Interfaces:**
- Produces:
  - `enum RecurrenceType { none, daily, weekly, monthly, yearly, weekday, custom }`
  - `enum RecurrenceUnit { day, week, month, year }`
  - `Task` field baru: `RecurrenceType recurrence`, `int recurrenceInterval`, `RecurrenceUnit? recurrenceUnit`, `DateTime? recurrenceEndDate`, `int? recurrenceCount`, `int recurrenceIndex`, `String? seriesId`.
  - `Task.copyWith` menerima param di atas + `bool clearRecurrenceUnit`, `bool clearRecurrenceEndDate`, `bool clearRecurrenceCount`, `bool clearSeriesId`.

- [ ] **Step 1: Tambah enum di atas kelas Task**

Di `lib/models/task_model.dart`, tepat setelah baris `enum TaskStatus { belumDikerjakan, sedangDikerjakan, selesai }` tambahkan:

```dart
enum RecurrenceType { none, daily, weekly, monthly, yearly, weekday, custom }

enum RecurrenceUnit { day, week, month, year }
```

- [ ] **Step 2: Tambah field ke kelas Task**

Setelah field `int totalFocusMinutes;` (deklarasi field), tambahkan:

```dart
  // Pengulangan (recurring). Rule disimpan sebagai enum + param, bukan label.
  RecurrenceType recurrence;
  int recurrenceInterval;      // "tiap N" untuk custom
  RecurrenceUnit? recurrenceUnit; // unit untuk custom
  DateTime? recurrenceEndDate; // berakhir pada tanggal
  int? recurrenceCount;        // berakhir setelah N kali (total)
  int recurrenceIndex;         // occurrence ke-berapa dalam seri
  String? seriesId;            // pengelompok occurrence satu seri
```

- [ ] **Step 3: Tambah param ke constructor**

Di constructor `Task({...})`, setelah `this.totalFocusMinutes = 0,` tambahkan sebelum `})`:

```dart
    this.recurrence = RecurrenceType.none,
    this.recurrenceInterval = 1,
    this.recurrenceUnit,
    this.recurrenceEndDate,
    this.recurrenceCount,
    this.recurrenceIndex = 1,
    this.seriesId,
```

- [ ] **Step 4: Tambah ke toJson**

Di `toJson()`, setelah baris `'totalFocusMinutes': totalFocusMinutes,` tambahkan:

```dart
      'recurrence': recurrence.index,
      'recurrenceInterval': recurrenceInterval,
      'recurrenceUnit': recurrenceUnit?.index,
      'recurrenceEndDate': recurrenceEndDate?.toIso8601String(),
      'recurrenceCount': recurrenceCount,
      'recurrenceIndex': recurrenceIndex,
      'seriesId': seriesId,
```

- [ ] **Step 5: Tambah ke fromJson**

Di `factory Task.fromJson`, sebelum `return Task(`, tambahkan parsing aman:

```dart
    final rawRecurrence = json['recurrence'];
    final recurrence = (rawRecurrence is int &&
            rawRecurrence >= 0 &&
            rawRecurrence < RecurrenceType.values.length)
        ? RecurrenceType.values[rawRecurrence]
        : RecurrenceType.none;
    final rawUnit = json['recurrenceUnit'];
    final recurrenceUnit = (rawUnit is int &&
            rawUnit >= 0 &&
            rawUnit < RecurrenceUnit.values.length)
        ? RecurrenceUnit.values[rawUnit]
        : null;
```

Lalu di dalam `return Task(...)`, setelah `totalFocusMinutes: json['totalFocusMinutes'] as int? ?? 0,` tambahkan:

```dart
      recurrence: recurrence,
      recurrenceInterval: json['recurrenceInterval'] as int? ?? 1,
      recurrenceUnit: recurrenceUnit,
      recurrenceEndDate: json['recurrenceEndDate'] != null
          ? DateTime.parse(json['recurrenceEndDate'] as String)
          : null,
      recurrenceCount: json['recurrenceCount'] as int?,
      recurrenceIndex: json['recurrenceIndex'] as int? ?? 1,
      seriesId: json['seriesId'] as String?,
```

- [ ] **Step 6: Tambah ke copyWith**

Di signature `copyWith({...})`, setelah `int? totalFocusMinutes,` tambahkan:

```dart
    RecurrenceType? recurrence,
    int? recurrenceInterval,
    RecurrenceUnit? recurrenceUnit,
    bool clearRecurrenceUnit = false,
    DateTime? recurrenceEndDate,
    bool clearRecurrenceEndDate = false,
    int? recurrenceCount,
    bool clearRecurrenceCount = false,
    int? recurrenceIndex,
    String? seriesId,
    bool clearSeriesId = false,
```

Di dalam `return Task(...)` copyWith, setelah `totalFocusMinutes: totalFocusMinutes ?? this.totalFocusMinutes,` tambahkan:

```dart
      recurrence: recurrence ?? this.recurrence,
      recurrenceInterval: recurrenceInterval ?? this.recurrenceInterval,
      recurrenceUnit:
          clearRecurrenceUnit ? null : (recurrenceUnit ?? this.recurrenceUnit),
      recurrenceEndDate: clearRecurrenceEndDate
          ? null
          : (recurrenceEndDate ?? this.recurrenceEndDate),
      recurrenceCount:
          clearRecurrenceCount ? null : (recurrenceCount ?? this.recurrenceCount),
      recurrenceIndex: recurrenceIndex ?? this.recurrenceIndex,
      seriesId: clearSeriesId ? null : (seriesId ?? this.seriesId),
```

- [ ] **Step 7: Analyze**

Run: `flutter analyze lib/models/task_model.dart`
Expected: `No issues found!`

- [ ] **Step 8: Commit**

```bash
git add lib/models/task_model.dart
git commit -m "feat(model): tambah field recurrence pada Task"
```

---

### Task 2: Mesin pengulangan — `recurrence.dart`

**Files:**
- Create: `lib/utils/recurrence.dart`

**Interfaces:**
- Consumes: `RecurrenceType`, `RecurrenceUnit`, `Task` (Task 1).
- Produces:
  - `int mingguKeBerapa(DateTime date)`
  - `String recurrenceLabel(RecurrenceType type, DateTime date, {int interval = 1, RecurrenceUnit? unit})`
  - `DateTime? nextOccurrenceDate(Task task)`
  - `List<DateTime> upcomingOccurrences(Task task, {required DateTime until, int maxCount = 60})`

- [ ] **Step 1: Buat file dengan seluruh isi berikut**

```dart
// lib/utils/recurrence.dart

import 'package:intl/intl.dart';
import '../models/task_model.dart';

/// Minggu ke-berapa suatu tanggal dalam bulannya (1..5).
int mingguKeBerapa(DateTime date) => ((date.day - 1) ~/ 7) + 1;

String _unitLabel(RecurrenceUnit u) {
  switch (u) {
    case RecurrenceUnit.day:
      return 'hari';
    case RecurrenceUnit.week:
      return 'minggu';
    case RecurrenceUnit.month:
      return 'bulan';
    case RecurrenceUnit.year:
      return 'tahun';
  }
}

/// Label Indonesia dinamis (dibentuk ulang dari tanggal terpilih).
String recurrenceLabel(RecurrenceType type, DateTime date,
    {int interval = 1, RecurrenceUnit? unit}) {
  switch (type) {
    case RecurrenceType.none:
      return 'Tidak berulang';
    case RecurrenceType.daily:
      return 'Setiap hari';
    case RecurrenceType.weekly:
      return 'Setiap minggu di hari ${DateFormat('EEEE', 'id_ID').format(date)}';
    case RecurrenceType.monthly:
      return 'Setiap bulan di ${DateFormat('EEEE', 'id_ID').format(date)} ke-${mingguKeBerapa(date)}';
    case RecurrenceType.yearly:
      return 'Setiap tahun di ${DateFormat('d MMMM', 'id_ID').format(date)}';
    case RecurrenceType.weekday:
      return 'Setiap hari kerja (Senin–Jumat)';
    case RecurrenceType.custom:
      return 'Ulangi setiap $interval ${_unitLabel(unit ?? RecurrenceUnit.day)}';
  }
}

DateTime _addDays(DateTime d, int n) =>
    DateTime(d.year, d.month, d.day + n, d.hour, d.minute);

DateTime _addMonths(DateTime d, int n) {
  final total = d.month - 1 + n;
  final year = d.year + (total ~/ 12);
  final month = (total % 12) + 1;
  final lastDay = DateTime(year, month + 1, 0).day;
  final day = d.day <= lastDay ? d.day : lastDay;
  return DateTime(year, month, day, d.hour, d.minute);
}

DateTime _addYears(DateTime d, int n) {
  final year = d.year + n;
  final lastDay = DateTime(year, d.month + 1, 0).day; // handle 29 Feb
  final day = d.day <= lastDay ? d.day : lastDay;
  return DateTime(year, d.month, day, d.hour, d.minute);
}

DateTime _nextWeekday(DateTime d) {
  var next = _addDays(d, 1);
  while (next.weekday == DateTime.saturday || next.weekday == DateTime.sunday) {
    next = _addDays(next, 1);
  }
  return next;
}

/// Hari-ke-N-minggu yang sama di bulan berikutnya (mis. "Minggu ke-2 berikutnya").
DateTime _nextNthWeekday(DateTime d) {
  final n = mingguKeBerapa(d);
  final weekday = d.weekday;
  final firstNext = DateTime(d.year, d.month + 1, 1, d.hour, d.minute);
  var offset = (weekday - firstNext.weekday) % 7;
  if (offset < 0) offset += 7;
  var day = 1 + offset + (n - 1) * 7;
  final lastDay = DateTime(firstNext.year, firstNext.month + 1, 0).day;
  if (day > lastDay) day -= 7; // clamp ke kemunculan terakhir
  return DateTime(firstNext.year, firstNext.month, day, d.hour, d.minute);
}

DateTime? _rawNext(DateTime d, Task t) {
  switch (t.recurrence) {
    case RecurrenceType.none:
      return null;
    case RecurrenceType.daily:
      return _addDays(d, 1);
    case RecurrenceType.weekly:
      return _addDays(d, 7);
    case RecurrenceType.weekday:
      return _nextWeekday(d);
    case RecurrenceType.monthly:
      return _nextNthWeekday(d);
    case RecurrenceType.yearly:
      return _addYears(d, 1);
    case RecurrenceType.custom:
      final n = t.recurrenceInterval;
      switch (t.recurrenceUnit ?? RecurrenceUnit.day) {
        case RecurrenceUnit.day:
          return _addDays(d, n);
        case RecurrenceUnit.week:
          return _addDays(d, 7 * n);
        case RecurrenceUnit.month:
          return _addMonths(d, n);
        case RecurrenceUnit.year:
          return _addYears(d, n);
      }
  }
}

bool _seriesEnded(Task t, DateTime candidate, int candidateIndex) {
  if (t.recurrenceEndDate != null && candidate.isAfter(t.recurrenceEndDate!)) {
    return true;
  }
  if (t.recurrenceCount != null && candidateIndex > t.recurrenceCount!) {
    return true;
  }
  return false;
}

/// Deadline occurrence berikutnya SETELAH task.deadline; null bila seri berakhir.
DateTime? nextOccurrenceDate(Task task) {
  final next = _rawNext(task.deadline, task);
  if (next == null) return null;
  if (_seriesEnded(task, next, task.recurrenceIndex + 1)) return null;
  return next;
}

/// Tanggal occurrence mendatang (setelah deadline) sampai [until] / [maxCount].
/// Dipakai untuk preview kalender (tidak memateralize tugas).
List<DateTime> upcomingOccurrences(Task task,
    {required DateTime until, int maxCount = 60}) {
  if (task.recurrence == RecurrenceType.none) return const [];
  final result = <DateTime>[];
  var cursor = task.deadline;
  var index = task.recurrenceIndex;
  for (var i = 0; i < maxCount; i++) {
    final next = _rawNext(cursor, task);
    if (next == null) break;
    final nextIndex = index + 1;
    if (_seriesEnded(task, next, nextIndex)) break;
    if (next.isAfter(until)) break;
    result.add(next);
    cursor = next;
    index = nextIndex;
  }
  return result;
}
```

- [ ] **Step 2: Analyze**

Run: `flutter analyze lib/utils/recurrence.dart`
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/utils/recurrence.dart
git commit -m "feat(recurrence): mesin hitung occurrence & label Indonesia"
```

---

### Task 3: Provider — spawn occurrence + param recurrence

**Files:**
- Modify: `lib/services/task_provider.dart`

**Interfaces:**
- Consumes: `nextOccurrenceDate` (Task 2); field recurrence (Task 1).
- Produces: `tambahTugas` & `editTugas` menerima param recurrence baru (lihat di bawah). Spawn occurrence berikutnya saat transisi ke `selesai`.

- [ ] **Step 1: Import mesin recurrence**

Di atas `lib/services/task_provider.dart`, setelah `import 'smart_scheduler_service.dart';` tambahkan:

```dart
import '../utils/recurrence.dart';
```

- [ ] **Step 2: Tambah param recurrence ke tambahTugas**

Di `tambahTugas({...})`, setelah `List<String>? notifSchedule,` tambahkan param:

```dart
    RecurrenceType recurrence = RecurrenceType.none,
    int recurrenceInterval = 1,
    RecurrenceUnit? recurrenceUnit,
    DateTime? recurrenceEndDate,
    int? recurrenceCount,
```

Lalu pada pembuatan `final task = Task(...)`, setelah `notifSchedule: notifSchedule,` tambahkan:

```dart
      recurrence: recurrence,
      recurrenceInterval: recurrenceInterval,
      recurrenceUnit: recurrenceUnit,
      recurrenceEndDate: recurrenceEndDate,
      recurrenceCount: recurrenceCount,
```

- [ ] **Step 3: Tambah param recurrence ke editTugas**

Di `editTugas(String id, {...})`, setelah `List<String>? notifSchedule,` tambahkan:

```dart
    RecurrenceType? recurrence,
    int? recurrenceInterval,
    RecurrenceUnit? recurrenceUnit,
    bool clearRecurrenceUnit = false,
    DateTime? recurrenceEndDate,
    bool clearRecurrenceEndDate = false,
    int? recurrenceCount,
    bool clearRecurrenceCount = false,
```

Pada `_tasks[index] = _tasks[index].copyWith(...)` di editTugas, setelah `clearCompletedAt: clearCompletedAt,` tambahkan:

```dart
      recurrence: recurrence,
      recurrenceInterval: recurrenceInterval,
      recurrenceUnit: recurrenceUnit,
      clearRecurrenceUnit: clearRecurrenceUnit,
      recurrenceEndDate: recurrenceEndDate,
      clearRecurrenceEndDate: clearRecurrenceEndDate,
      recurrenceCount: recurrenceCount,
      clearRecurrenceCount: clearRecurrenceCount,
```

- [ ] **Step 4: Spawn occurrence berikutnya di editTugas**

Di `editTugas`, cari blok:

```dart
    if (status == TaskStatus.selesai) {
      _timeBlocks.removeWhere((block) => block.taskId == id);
      await _saveSchedule();
    }
```

Tepat SEBELUM blok itu, sisipkan:

```dart
    // Spawn occurrence berikutnya bila tugas berulang baru saja diselesaikan.
    // (Model lazy: hanya saat transisi ke selesai, satu occurrence terbuka.)
    Task? spawned;
    if (status == TaskStatus.selesai &&
        oldStatus != TaskStatus.selesai &&
        _tasks[index].recurrence != RecurrenceType.none) {
      final base = _tasks[index];
      final nextDate = nextOccurrenceDate(base);
      if (nextDate != null) {
        final seriesId = base.seriesId ?? base.id;
        if (base.seriesId == null) {
          _tasks[index] = base.copyWith(seriesId: seriesId);
        }
        spawned = Task(
          id: _uuid.v4(),
          namaTugas: base.namaTugas,
          lingkupTugas: base.lingkupTugas,
          mataKuliah: base.mataKuliah,
          deadline: nextDate,
          tingkatKepentingan: base.tingkatKepentingan,
          estimasiWaktu: base.estimasiWaktu,
          category: base.category,
          catatan: base.catatan,
          createdAt: DateTime.now(),
          notifEnabled: base.notifEnabled,
          notifSchedule: List.from(base.notifSchedule),
          recurrence: base.recurrence,
          recurrenceInterval: base.recurrenceInterval,
          recurrenceUnit: base.recurrenceUnit,
          recurrenceEndDate: base.recurrenceEndDate,
          recurrenceCount: base.recurrenceCount,
          recurrenceIndex: base.recurrenceIndex + 1,
          seriesId: seriesId,
        );
        _tasks.add(spawned);
        _recalculateSAW(); // ranking occurrence baru ikut terhitung
      }
    }
```

- [ ] **Step 5: Jadwalkan notif untuk occurrence baru**

Di `editTugas`, cari blok notif di ekor method:

```dart
    if (_notifEnabled) {
      await _notifService.scheduleTaskNotifications(_tasks[index]);
    }
    notifyListeners();
    return saved;
```

Ganti menjadi:

```dart
    if (_notifEnabled) {
      await _notifService.scheduleTaskNotifications(_tasks[index]);
      if (spawned != null) {
        await _notifService.scheduleTaskNotifications(spawned);
        if (_dailyReminderEnabled) {
          await _notifService.scheduleDailyReminder(
            hour: _dailyReminderHour,
            minute: _dailyReminderMinute,
            activeTasks: tugasAktif,
          );
        }
      }
    }
    notifyListeners();
    return saved;
```

> Catatan: `_recalculateSAW()` dan `_runScheduler()` yang sudah ada di ekor editTugas otomatis memasukkan occurrence baru ke ranking SAW & scheduler karena ia sudah ada di `_tasks`. Occurrence yang selesai notifnya otomatis batal (`scheduleTaskNotifications` early-return saat `selesai`).

- [ ] **Step 6: Analyze**

Run: `flutter analyze lib/services/task_provider.dart`
Expected: `No issues found!`

- [ ] **Step 7: Commit**

```bash
git add lib/services/task_provider.dart
git commit -m "feat(provider): spawn occurrence berikutnya saat tugas berulang selesai"
```

---

### Task 4: UI Add/Edit — section "Pengulangan" + bottom sheet

**Files:**
- Modify: `lib/screens/add_edit_task_screen.dart`

**Interfaces:**
- Consumes: `recurrenceLabel` (Task 2), enum & field (Task 1), param `tambahTugas`/`editTugas` (Task 3).

- [ ] **Step 1: Import recurrence util**

Setelah `import 'ai_task_creator_screen.dart';` tambahkan:

```dart
import '../utils/recurrence.dart';
```

- [ ] **Step 2: Tambah state field**

Di `_AddEditTaskScreenState`, setelah `List<String> _notifSchedule = ['h-1', '3jam', 'deadline'];` tambahkan:

```dart
  RecurrenceType _recurrence = RecurrenceType.none;
  int _recurrenceInterval = 1;
  RecurrenceUnit _recurrenceUnit = RecurrenceUnit.day;
  DateTime? _recurrenceEndDate;
  int? _recurrenceCount;
```

- [ ] **Step 3: Muat state saat edit**

Di `initState()`, di dalam `if (isEdit) { ... }`, setelah `_notifSchedule = List.from(t.notifSchedule);` tambahkan:

```dart
      _recurrence = t.recurrence;
      _recurrenceInterval = t.recurrenceInterval;
      _recurrenceUnit = t.recurrenceUnit ?? RecurrenceUnit.day;
      _recurrenceEndDate = t.recurrenceEndDate;
      _recurrenceCount = t.recurrenceCount;
```

- [ ] **Step 4: Sisipkan section "Pengulangan" setelah section Deadline**

Cari blok section Deadline di `build`:

```dart
                _buildSection('Deadline', [
                  _buildDeadlinePicker(),
                  const SizedBox(height: 10),
                  _buildUrgensiIndicator(),
                ]),
```

Tepat SETELAH-nya (sebelum `const SizedBox(height: 16),` berikutnya) sisipkan:

```dart
                const SizedBox(height: 16),
                _buildSection('Pengulangan', [
                  _buildRecurrencePicker(),
                ]),
```

- [ ] **Step 5: Tambah widget picker + bottom sheet**

Sebelum method `void _save() async {`, tambahkan tiga method berikut:

```dart
  Widget _buildRecurrencePicker() {
    return InkWell(
      onTap: _showRecurrenceSheet,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.border),
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey.shade50,
        ),
        child: Row(
          children: [
            const Icon(Icons.repeat_rounded, color: AppTheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pengulangan',
                      style: TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary)),
                  Text(
                    recurrenceLabel(_recurrence, _deadline,
                        interval: _recurrenceInterval, unit: _recurrenceUnit),
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }

  void _showRecurrenceSheet() {
    const options = [
      RecurrenceType.none,
      RecurrenceType.daily,
      RecurrenceType.weekly,
      RecurrenceType.monthly,
      RecurrenceType.yearly,
      RecurrenceType.weekday,
      RecurrenceType.custom,
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text('Pengulangan',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary)),
            ),
            ...options.map((opt) {
              final selected = _recurrence == opt;
              final label = opt == RecurrenceType.custom
                  ? 'Custom…'
                  : recurrenceLabel(opt, _deadline);
              return ListTile(
                title: Text(label,
                    style: TextStyle(
                        color: selected
                            ? AppTheme.primary
                            : AppTheme.textPrimary,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500)),
                trailing: selected
                    ? const Icon(Icons.check_rounded, color: AppTheme.primary)
                    : null,
                onTap: () {
                  Navigator.pop(ctx);
                  if (opt == RecurrenceType.custom) {
                    _showCustomRecurrenceSheet();
                  } else {
                    setState(() => _recurrence = opt);
                  }
                },
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showCustomRecurrenceSheet() {
    var interval = _recurrenceInterval < 1 ? 1 : _recurrenceInterval;
    var unit = _recurrenceUnit;
    // endMode: 0 = tidak pernah, 1 = pada tanggal, 2 = setelah N kali
    var endMode = _recurrenceEndDate != null
        ? 1
        : (_recurrenceCount != null ? 2 : 0);
    var endDate = _recurrenceEndDate;
    var count = _recurrenceCount ?? 10;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Pengulangan Custom',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary)),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Ulangi setiap',
                      style: TextStyle(color: AppTheme.textPrimary)),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    color: AppTheme.primary,
                    onPressed: () => setSheet(() {
                      if (interval > 1) interval--;
                    }),
                  ),
                  Text('$interval',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    color: AppTheme.primary,
                    onPressed: () => setSheet(() => interval++),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<RecurrenceUnit>(
                    value: unit,
                    items: const [
                      DropdownMenuItem(
                          value: RecurrenceUnit.day, child: Text('hari')),
                      DropdownMenuItem(
                          value: RecurrenceUnit.week, child: Text('minggu')),
                      DropdownMenuItem(
                          value: RecurrenceUnit.month, child: Text('bulan')),
                      DropdownMenuItem(
                          value: RecurrenceUnit.year, child: Text('tahun')),
                    ],
                    onChanged: (v) =>
                        setSheet(() => unit = v ?? RecurrenceUnit.day),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text('Berakhir',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary)),
              const SizedBox(height: 4),
              _customEndRow(
                selected: endMode == 0,
                onTap: () => setSheet(() => endMode = 0),
                child: const Text('Tidak pernah'),
              ),
              _customEndRow(
                selected: endMode == 1,
                onTap: () => setSheet(() => endMode = 1),
                child: Row(
                  children: [
                    const Text('Pada tanggal'),
                    const SizedBox(width: 8),
                    if (endMode == 1)
                      TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: endDate ??
                                _deadline.add(const Duration(days: 30)),
                            firstDate: _deadline,
                            lastDate:
                                _deadline.add(const Duration(days: 365 * 5)),
                          );
                          if (picked != null) setSheet(() => endDate = picked);
                        },
                        child: Text(endDate == null
                            ? 'Pilih…'
                            : DateFormat('d MMM yyyy', 'id_ID')
                                .format(endDate!)),
                      ),
                  ],
                ),
              ),
              _customEndRow(
                selected: endMode == 2,
                onTap: () => setSheet(() => endMode = 2),
                child: Row(
                  children: [
                    const Text('Setelah'),
                    const SizedBox(width: 8),
                    if (endMode == 2) ...[
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, size: 20),
                        color: AppTheme.primary,
                        onPressed: () =>
                            setSheet(() => count = count > 1 ? count - 1 : 1),
                      ),
                      Text('$count'),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, size: 20),
                        color: AppTheme.primary,
                        onPressed: () => setSheet(() => count++),
                      ),
                      const Text('kali'),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _recurrence = RecurrenceType.custom;
                      _recurrenceInterval = interval;
                      _recurrenceUnit = unit;
                      _recurrenceEndDate = endMode == 1 ? endDate : null;
                      _recurrenceCount = endMode == 2 ? count : null;
                    });
                  },
                  child: const Text('Simpan'),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _customEndRow({
    required bool selected,
    required VoidCallback onTap,
    required Widget child,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected ? AppTheme.primary : AppTheme.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
```

- [ ] **Step 6: Teruskan param recurrence saat simpan**

Di `_save()`, pada pemanggilan `provider.editTugas(...)` tambahkan setelah `notifSchedule: _notifSchedule,`:

```dart
        recurrence: _recurrence,
        recurrenceInterval: _recurrenceInterval,
        recurrenceUnit:
            _recurrence == RecurrenceType.custom ? _recurrenceUnit : null,
        clearRecurrenceUnit: _recurrence != RecurrenceType.custom,
        recurrenceEndDate: _recurrenceEndDate,
        clearRecurrenceEndDate: _recurrenceEndDate == null,
        recurrenceCount: _recurrenceCount,
        clearRecurrenceCount: _recurrenceCount == null,
```

Pada pemanggilan `provider.tambahTugas(...)` tambahkan setelah `notifSchedule: _notifSchedule,`:

```dart
        recurrence: _recurrence,
        recurrenceInterval: _recurrenceInterval,
        recurrenceUnit:
            _recurrence == RecurrenceType.custom ? _recurrenceUnit : null,
        recurrenceEndDate: _recurrenceEndDate,
        recurrenceCount: _recurrenceCount,
```

- [ ] **Step 7: Analyze**

Run: `flutter analyze lib/screens/add_edit_task_screen.dart`
Expected: `No issues found!`

- [ ] **Step 8: Verifikasi di HP**

Run: `flutter run -d 143352554V103518`
Cek: buka Tambah Tugas → section "Pengulangan" tampil; pilih "Setiap minggu…" label sesuai hari deadline; pilih "Custom…" → bottom sheet interval/unit/berakhir muncul & bisa disimpan. Ambil screenshot via `adb shell screencap`.

- [ ] **Step 9: Commit**

```bash
git add lib/screens/add_edit_task_screen.dart
git commit -m "feat(ui): selector Pengulangan di form tambah/edit tugas"
```

---

### Task 5: Badge berulang di kartu tugas

**Files:**
- Modify: `lib/widgets/task_card_widget.dart`

**Interfaces:**
- Consumes: field `recurrence` (Task 1).

- [ ] **Step 1: Tambah badge di baris tags**

Di `build`, cari baris tags:

```dart
            Row(
              children: [
                _buildCategoryTag(),
                if (_shouldShowPriorityBadge) ...[
                  const SizedBox(width: 6),
                  _buildPriorityBadge(),
                ],
```

Sisipkan setelah `_buildCategoryTag(),`:

```dart
                if (task.recurrence != RecurrenceType.none) ...[
                  const SizedBox(width: 6),
                  _buildRecurringBadge(),
                ],
```

- [ ] **Step 2: Tambah method badge**

Sebelum `Widget _buildStatusBadge() {`, tambahkan:

```dart
  Widget _buildRecurringBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
      ),
      child: const Icon(Icons.repeat_rounded,
          size: 12, color: AppTheme.primary),
    );
  }
```

- [ ] **Step 3: Analyze**

Run: `flutter analyze lib/widgets/task_card_widget.dart`
Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add lib/widgets/task_card_widget.dart
git commit -m "feat(ui): badge repeat pada kartu tugas berulang"
```

---

### Task 6: Preview occurrence di layar Kalender

**Files:**
- Modify: `lib/screens/calendar_screen.dart`

**Interfaces:**
- Consumes: `upcomingOccurrences` (Task 2), field `recurrence` (Task 1).

- [ ] **Step 1: Import recurrence util**

Setelah `import 'add_edit_task_screen.dart';` tambahkan:

```dart
import '../utils/recurrence.dart';
```

- [ ] **Step 2: Hitung hari preview di `_buildCalendar`**

Di `_buildCalendar(List<Task> tasks)`, setelah `final days = _calendarDays(_visibleMonth);` tambahkan:

```dart
    final gridStart = DateTime(days.first.year, days.first.month, days.first.day);
    final gridEnd =
        DateTime(days.last.year, days.last.month, days.last.day, 23, 59);
    final previewDays = <DateTime>{};
    for (final t in tasks) {
      if (t.recurrence == RecurrenceType.none ||
          t.status == TaskStatus.selesai) {
        continue;
      }
      for (final d in upcomingOccurrences(t, until: gridEnd)) {
        final nd = DateTime(d.year, d.month, d.day);
        if (!nd.isBefore(gridStart)) previewDays.add(nd);
      }
    }
```

- [ ] **Step 3: Render cincin berongga di sel tanpa tugas nyata**

Di `itemBuilder` `_buildCalendar`, cari:

```dart
                      if (dayTasks.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? Colors.white
                                : hasOverdue
                                    ? AppTheme.danger
                                    : AppTheme.primary,
                          ),
                        ),
                      ],
```

Tepat SETELAH blok `if (dayTasks.isNotEmpty) ...[ ... ],` itu, tambahkan cabang preview:

```dart
                      if (dayTasks.isEmpty &&
                          previewDays.contains(
                              DateTime(date.year, date.month, date.day))) ...[
                        const SizedBox(height: 2),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: isSelected
                                    ? Colors.white
                                    : AppTheme.primary,
                                width: 1.2),
                          ),
                        ),
                      ],
```

- [ ] **Step 4: Analyze**

Run: `flutter analyze lib/screens/calendar_screen.dart`
Expected: `No issues found!`

- [ ] **Step 5: Verifikasi di HP**

Run/hot-reload `flutter run -d 143352554V103518`. Buat tugas "Setiap minggu…", buka Kalender → hari occurrence mendatang menampilkan cincin berongga ungu; hari dengan tugas nyata tetap titik solid. Screenshot.

- [ ] **Step 6: Commit**

```bash
git add lib/screens/calendar_screen.dart
git commit -m "feat(kalender): preview occurrence berulang (cincin berongga)"
```

---

### Task 7: Preview occurrence di mini-kalender Dashboard

**Files:**
- Modify: `lib/screens/dashboard_screen.dart`

**Interfaces:**
- Consumes: `upcomingOccurrences` (Task 2), field `recurrence` (Task 1).

- [ ] **Step 1: Import recurrence util**

Setelah `import 'add_edit_task_screen.dart';` tambahkan:

```dart
import '../utils/recurrence.dart';
```

- [ ] **Step 2: Hitung hari preview di `_buildTaskCalendar`**

Di `_buildTaskCalendar(TaskProvider provider)`, setelah `final totalCells = leadingBlanks + daysInMonth;` tambahkan:

```dart
    final monthEnd = DateTime(now.year, now.month, daysInMonth, 23, 59);
    final previewDays = <int>{};
    for (final t in provider.tasks) {
      if (t.recurrence == RecurrenceType.none ||
          t.status == TaskStatus.selesai) {
        continue;
      }
      for (final d in upcomingOccurrences(t, until: monthEnd)) {
        if (d.year == now.year && d.month == now.month) {
          previewDays.add(d.day);
        }
      }
    }
```

- [ ] **Step 3: Render cincin berongga**

Di `itemBuilder` `_buildTaskCalendar`, cari blok:

```dart
                    if (hasTask) ...[
                      const SizedBox(height: 2),
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isToday
                              ? Colors.white
                              : hasOverdue
                                  ? AppTheme.danger
                                  : AppTheme.primary,
                        ),
                      ),
                    ],
```

Tepat SETELAH-nya tambahkan:

```dart
                    if (!hasTask && !isToday && previewDays.contains(day)) ...[
                      const SizedBox(height: 2),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: AppTheme.primary, width: 1.2),
                        ),
                      ),
                    ],
```

- [ ] **Step 4: Analyze**

Run: `flutter analyze lib/screens/dashboard_screen.dart`
Expected: `No issues found!`

- [ ] **Step 5: Verifikasi di HP + regresi ringan**

Hot-reload. Dashboard mini-kalender menampilkan cincin berongga pada occurrence mendatang bulan ini. Uji end-to-end: selesaikan tugas berulang → occurrence berikutnya lahir (cek di Data Tugas & Kalender), badge repeat muncul, tidak ada overflow di log. Screenshot Dashboard.

Run: `flutter analyze` (seluruh proyek) — Expected: `No issues found!`
Run: `flutter test` — Expected: masih `+360 -40` (tidak ada tambahan gagal).

- [ ] **Step 6: Commit**

```bash
git add lib/screens/dashboard_screen.dart
git commit -m "feat(dashboard): preview occurrence berulang di mini-kalender"
```

---

## Catatan eksekusi

- Urutan wajib: Task 1 → 2 → 3 dulu (model & logika), baru 4–7 (UI). Task 5/6/7 tidak saling bergantung setelah 1–3 selesai.
- Tiap task UI diverifikasi di HP Infinix; screenshot lewat `adb ... screencap` (catatan: layar Impeller device ini tetap tertangkap screencap).
- Test unit untuk `recurrence.dart` & spawn provider ditulis di sesi testing akhir (preferensi user).
