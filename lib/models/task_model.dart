// lib/models/task_model.dart

enum TaskStatus { belumDikerjakan, sedangDikerjakan, selesai }

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
  DateTime deadline;
  int tingkatKepentingan; // 1-5 (input manual)
  int tingkatUrgensi;     // 1-5 (dihitung otomatis dari deadline, bukan input)
  int estimasiWaktu;      // dalam jam (1-10)
  TaskStatus status;
  String category;        // String bebas (custom)
  String? catatan;
  DateTime createdAt;

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
    required this.deadline,
    required this.tingkatKepentingan,
    int? tingkatUrgensi,
    required this.estimasiWaktu,
    this.status = TaskStatus.belumDikerjakan,
    this.category = 'Tugas',
    this.catatan,
    required this.createdAt,
    this.notifEnabled = true,
    List<String>? notifSchedule,
    this.sawScore = 0.0,
    this.ranking = 0,
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

  /// Alias untuk lingkupTugas (backward compat)
  String get mataKuliah => lingkupTugas;

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
      'deadline': deadline.toIso8601String(),
      'tingkatKepentingan': tingkatKepentingan,
      'tingkatUrgensi': tingkatUrgensi,
      'estimasiWaktu': estimasiWaktu,
      'status': status.index,
      'category': category,
      'catatan': catatan,
      'createdAt': createdAt.toIso8601String(),
      'notifEnabled': notifEnabled,
      'notifSchedule': notifSchedule,
      'sawScore': sawScore,
      'ranking': ranking,
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

    return Task(
      id: json['id'],
      namaTugas: json['namaTugas'],
      lingkupTugas: lingkup,
      deadline: deadline,
      tingkatKepentingan: json['tingkatKepentingan'],
      tingkatUrgensi: Task._hitungUrgensiDariDeadline(deadline),
      estimasiWaktu: json['estimasiWaktu'],
      status: TaskStatus.values[json['status']],
      category: category,
      catatan: json['catatan'],
      createdAt: DateTime.parse(json['createdAt']),
      notifEnabled: json['notifEnabled'] as bool? ?? true,
      notifSchedule: notifSchedule,
      sawScore: (json['sawScore'] as num).toDouble(),
      ranking: json['ranking'],
    );
  }

  Task copyWith({
    String? namaTugas,
    String? lingkupTugas,
    DateTime? deadline,
    int? tingkatKepentingan,
    int? tingkatUrgensi,
    int? estimasiWaktu,
    TaskStatus? status,
    String? category,
    String? catatan,
    bool? notifEnabled,
    List<String>? notifSchedule,
    double? sawScore,
    int? ranking,
  }) {
    final newDeadline = deadline ?? this.deadline;
    return Task(
      id: id,
      namaTugas: namaTugas ?? this.namaTugas,
      lingkupTugas: lingkupTugas ?? this.lingkupTugas,
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
      notifEnabled: notifEnabled ?? this.notifEnabled,
      notifSchedule: notifSchedule ?? List.from(this.notifSchedule),
      sawScore: sawScore ?? this.sawScore,
      ranking: ranking ?? this.ranking,
    );
  }
}
