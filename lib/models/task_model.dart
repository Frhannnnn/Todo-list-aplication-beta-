// lib/models/task_model.dart

enum TaskStatus { belumDikerjakan, sedangDikerjakan, selesai }

enum RecurrenceType { none, daily, weekly, monthly, yearly, weekday, custom }

enum RecurrenceUnit { day, week, month, year }

// Default scopes (jika user belum mengatur scope custom)
const List<String> kDefaultScopes = ['Perkuliahan', 'Tugas Rumah', 'Pekerjaan'];

// Default categories
const List<String> kDefaultCategories = ['Tugas', 'Ujian', 'Proyek', 'Lainnya'];

// Kategori & Lingkup kini berbasis String (custom oleh user).
// Default lingkup: Perkuliahan, Tugas Rumah, Pekerjaan
// Default kategori: Tugas, Ujian, Proyek, Lainnya

class Task {
  final String id;
  String namaTugas;
  String lingkupTugas; // gantikan mataKuliah & TaskGroup
  String? mataKuliah;  // hanya relevan saat lingkupTugas == 'Perkuliahan'
  DateTime deadline;
  int tingkatKepentingan; // 1-5 (input manual)
  int tingkatUrgensi;     // 1-5 (dihitung otomatis dari deadline, bukan input)
  int estimasiWaktu;      // dalam jam (1-10)
  TaskStatus status;
  String category;        // String bebas (custom)
  String? catatan;
  DateTime createdAt;
  DateTime? completedAt;  // kapan tugas ditandai selesai (untuk streak); null bila belum
  int totalFocusMinutes;  // akumulasi menit fokus dari sesi Pomodoro

  // Pengulangan (recurring). Rule disimpan sebagai enum + param, bukan label.
  RecurrenceType recurrence;
  int recurrenceInterval;      // "tiap N" untuk custom
  RecurrenceUnit? recurrenceUnit; // unit untuk custom
  DateTime? recurrenceEndDate; // berakhir pada tanggal
  int? recurrenceCount;        // berakhir setelah N kali (total)
  int recurrenceIndex;         // occurrence ke-berapa dalam seri
  String? seriesId;            // pengelompok occurrence satu seri

  // Notifikasi per-tugas
  bool notifEnabled;
  List<String> notifSchedule; // 'h-3', 'h-1', '3jam', 'deadline'

  // SAW result
  double sawScore;
  int ranking;

  Task({
    required this.id,
    required this.namaTugas,
    required this.lingkupTugas,
    this.mataKuliah,
    required this.deadline,
    required this.tingkatKepentingan,
    int? tingkatUrgensi,
    required this.estimasiWaktu,
    this.status = TaskStatus.belumDikerjakan,
    this.category = 'Tugas',
    this.catatan,
    required this.createdAt,
    this.completedAt,
    this.notifEnabled = true,
    List<String>? notifSchedule,
    this.sawScore = 0.0,
    this.ranking = 0,
    this.totalFocusMinutes = 0,
    this.recurrence = RecurrenceType.none,
    this.recurrenceInterval = 1,
    this.recurrenceUnit,
    this.recurrenceEndDate,
    this.recurrenceCount,
    this.recurrenceIndex = 1,
    this.seriesId,
  })  : tingkatUrgensi = tingkatUrgensi ?? _hitungUrgensiDariDeadline(deadline),
        notifSchedule = notifSchedule ?? ['h-1', '3jam', 'deadline'];

  /// Hitung urgensi (1–5) otomatis berdasarkan sisa jam menuju deadline.
  static int hitungUrgensiDariDeadline(DateTime deadline) {
    final sisa = deadline.difference(DateTime.now()).inHours;
    if (sisa <= 3) return 5;
    if (sisa <= 24) return 4;
    if (sisa <= 72) return 3;
    if (sisa <= 168) return 2; // 7 hari
    return 1;
  }

  // Alias private untuk internal use
  static int _hitungUrgensiDariDeadline(DateTime deadline) =>
      hitungUrgensiDariDeadline(deadline);

  // Hitung sisa hari menuju deadline
  int get sisaHari {
    final now = DateTime.now();
    return deadline.difference(now).inDays;
  }

  bool get isOverdue =>
      DateTime.now().isAfter(deadline) && status != TaskStatus.selesai;
  bool get isDueToday => sisaHari == 0 && !isOverdue;
  bool get isDueSoon => sisaHari <= 3 && sisaHari >= 0;

  String get statusLabel {
    switch (status) {
      case TaskStatus.belumDikerjakan:
        return 'Belum Dikerjakan';
      case TaskStatus.sedangDikerjakan:
        return 'Sedang Dikerjakan';
      case TaskStatus.selesai:
        return 'Selesai';
    }
  }

  /// Label kategori untuk ditampilkan di UI
  String get categoryLabel => category;

  /// Label urgensi otomatis untuk ditampilkan di UI
  String get urgensiLabel {
    final sisa = deadline.difference(DateTime.now()).inHours;
    if (sisa <= 0) return '🔴 Sudah Lewat';
    if (sisa <= 3) return '🔴 Sangat Mendesak';
    if (sisa <= 24) return '🟠 Mendesak';
    if (sisa <= 72) return '🟡 Perlu Perhatian';
    if (sisa <= 168) return '🟢 Masih Aman';
    return '✅ Santai';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'namaTugas': namaTugas,
      'lingkupTugas': lingkupTugas,
      'mataKuliah': mataKuliah,
      'deadline': deadline.toIso8601String(),
      'tingkatKepentingan': tingkatKepentingan,
      'tingkatUrgensi': tingkatUrgensi,
      'estimasiWaktu': estimasiWaktu,
      'status': status.index,
      'category': category,
      'catatan': catatan,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'notifEnabled': notifEnabled,
      'notifSchedule': notifSchedule,
      'sawScore': sawScore,
      'ranking': ranking,
      'totalFocusMinutes': totalFocusMinutes,
      'recurrence': recurrence.index,
      'recurrenceInterval': recurrenceInterval,
      'recurrenceUnit': recurrenceUnit?.index,
      'recurrenceEndDate': recurrenceEndDate?.toIso8601String(),
      'recurrenceCount': recurrenceCount,
      'recurrenceIndex': recurrenceIndex,
      'seriesId': seriesId,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    // Migrasi: data lama pakai 'mataKuliah' → fallback ke lingkupTugas
    final lingkup = json['lingkupTugas'] as String? ??
        json['mataKuliah'] as String? ??
        'Perkuliahan';

    // Migrasi: data lama pakai 'category' int (enum index) → konversi ke String
    String category = 'Tugas';
    final rawCategory = json['category'];
    if (rawCategory is String) {
      category = rawCategory;
    } else if (rawCategory is int) {
      const oldCategoryLabels = ['Kuliah', 'Praktikum', 'Proyek', 'Lainnya'];
      category = rawCategory < oldCategoryLabels.length
          ? oldCategoryLabels[rawCategory]
          : 'Lainnya';
    }

    // Migrasi: notifSchedule (field baru, data lama tidak punya)
    List<String> notifSchedule = ['h-1', '3jam', 'deadline'];
    final rawSchedule = json['notifSchedule'];
    if (rawSchedule is List) {
      notifSchedule = List<String>.from(rawSchedule);
    }

    final deadline = DateTime.parse(json['deadline']);

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

    return Task(
      id: json['id'],
      namaTugas: json['namaTugas'],
      lingkupTugas: lingkup,
      mataKuliah: json['mataKuliah'] as String?,
      deadline: deadline,
      tingkatKepentingan: json['tingkatKepentingan'],
      tingkatUrgensi: Task._hitungUrgensiDariDeadline(deadline),
      estimasiWaktu: json['estimasiWaktu'],
      status: TaskStatus.values[json['status']],
      category: category,
      catatan: json['catatan'],
      createdAt: DateTime.parse(json['createdAt']),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      notifEnabled: json['notifEnabled'] as bool? ?? true,
      notifSchedule: notifSchedule,
      sawScore: (json['sawScore'] as num).toDouble(),
      ranking: json['ranking'],
      totalFocusMinutes: json['totalFocusMinutes'] as int? ?? 0,
      recurrence: recurrence,
      recurrenceInterval: json['recurrenceInterval'] as int? ?? 1,
      recurrenceUnit: recurrenceUnit,
      recurrenceEndDate: json['recurrenceEndDate'] != null
          ? DateTime.parse(json['recurrenceEndDate'] as String)
          : null,
      recurrenceCount: json['recurrenceCount'] as int?,
      recurrenceIndex: json['recurrenceIndex'] as int? ?? 1,
      seriesId: json['seriesId'] as String?,
    );
  }

  Task copyWith({
    String? namaTugas,
    String? lingkupTugas,
    String? mataKuliah,
    bool clearMataKuliah = false,
    DateTime? deadline,
    int? tingkatKepentingan,
    int? tingkatUrgensi,
    int? estimasiWaktu,
    TaskStatus? status,
    String? category,
    String? catatan,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    bool? notifEnabled,
    List<String>? notifSchedule,
    double? sawScore,
    int? ranking,
    int? totalFocusMinutes,
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
  }) {
    final newDeadline = deadline ?? this.deadline;
    return Task(
      id: id,
      namaTugas: namaTugas ?? this.namaTugas,
      lingkupTugas: lingkupTugas ?? this.lingkupTugas,
      mataKuliah: clearMataKuliah ? null : (mataKuliah ?? this.mataKuliah),
      deadline: newDeadline,
      tingkatKepentingan: tingkatKepentingan ?? this.tingkatKepentingan,
      // Recalculate urgensi whenever deadline changes
      tingkatUrgensi: deadline != null
          ? Task._hitungUrgensiDariDeadline(newDeadline)
          : (tingkatUrgensi ?? this.tingkatUrgensi),
      estimasiWaktu: estimasiWaktu ?? this.estimasiWaktu,
      status: status ?? this.status,
      category: category ?? this.category,
      catatan: catatan ?? this.catatan,
      createdAt: createdAt,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      notifEnabled: notifEnabled ?? this.notifEnabled,
      notifSchedule: notifSchedule ?? List.from(this.notifSchedule),
      sawScore: sawScore ?? this.sawScore,
      ranking: ranking ?? this.ranking,
      totalFocusMinutes: totalFocusMinutes ?? this.totalFocusMinutes,
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
    );
  }
}
