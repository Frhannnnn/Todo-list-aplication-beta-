// lib/models/task_model.dart

import 'dart:convert';

enum TaskStatus { belumDikerjakan, sedangDikerjakan, selesai }
enum TaskGroup { individu, kelompok }
enum TaskCategory { kuliah, praktikum, project, lainnya }

class Task {
  final String id;
  String namaTugas;
  String mataKuliah;
  DateTime deadline;
  int tingkatKepentingan; // 1-5
  int tingkatUrgensi;     // 1-5
  int estimasiWaktu;      // dalam jam (1-10)
  TaskStatus status;
  TaskGroup group;
  TaskCategory category;
  String? catatan;
  DateTime createdAt;

  // SAW result
  double sawScore;
  int ranking;

  Task({
    required this.id,
    required this.namaTugas,
    required this.mataKuliah,
    required this.deadline,
    required this.tingkatKepentingan,
    required this.tingkatUrgensi,
    required this.estimasiWaktu,
    this.status = TaskStatus.belumDikerjakan,
    this.group = TaskGroup.individu,
    this.category = TaskCategory.kuliah,
    this.catatan,
    required this.createdAt,
    this.sawScore = 0.0,
    this.ranking = 0,
  });

  // Hitung sisa hari menuju deadline
  int get sisaHari {
    final now = DateTime.now();
    return deadline.difference(now).inDays;
  }

  bool get isOverdue => DateTime.now().isAfter(deadline) && status != TaskStatus.selesai;
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

  String get groupLabel {
    switch (group) {
      case TaskGroup.individu:
        return 'Tugas Individu';
      case TaskGroup.kelompok:
        return 'Tugas Kelompok';
    }
  }

  String get categoryLabel {
    switch (category) {
      case TaskCategory.kuliah:
        return 'Kuliah';
      case TaskCategory.praktikum:
        return 'Praktikum';
      case TaskCategory.project:
        return 'Project';
      case TaskCategory.lainnya:
        return 'Lainnya';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'namaTugas': namaTugas,
      'mataKuliah': mataKuliah,
      'deadline': deadline.toIso8601String(),
      'tingkatKepentingan': tingkatKepentingan,
      'tingkatUrgensi': tingkatUrgensi,
      'estimasiWaktu': estimasiWaktu,
      'status': status.index,
      'group': group.index,
      'category': category.index,
      'catatan': catatan,
      'createdAt': createdAt.toIso8601String(),
      'sawScore': sawScore,
      'ranking': ranking,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      namaTugas: json['namaTugas'],
      mataKuliah: json['mataKuliah'],
      deadline: DateTime.parse(json['deadline']),
      tingkatKepentingan: json['tingkatKepentingan'],
      tingkatUrgensi: json['tingkatUrgensi'],
      estimasiWaktu: json['estimasiWaktu'],
      status: TaskStatus.values[json['status']],
      group: TaskGroup.values[json['group']],
      category: TaskCategory.values[json['category']],
      catatan: json['catatan'],
      createdAt: DateTime.parse(json['createdAt']),
      sawScore: (json['sawScore'] as num).toDouble(),
      ranking: json['ranking'],
    );
  }

  Task copyWith({
    String? namaTugas,
    String? mataKuliah,
    DateTime? deadline,
    int? tingkatKepentingan,
    int? tingkatUrgensi,
    int? estimasiWaktu,
    TaskStatus? status,
    TaskGroup? group,
    TaskCategory? category,
    String? catatan,
    double? sawScore,
    int? ranking,
  }) {
    return Task(
      id: id,
      namaTugas: namaTugas ?? this.namaTugas,
      mataKuliah: mataKuliah ?? this.mataKuliah,
      deadline: deadline ?? this.deadline,
      tingkatKepentingan: tingkatKepentingan ?? this.tingkatKepentingan,
      tingkatUrgensi: tingkatUrgensi ?? this.tingkatUrgensi,
      estimasiWaktu: estimasiWaktu ?? this.estimasiWaktu,
      status: status ?? this.status,
      group: group ?? this.group,
      category: category ?? this.category,
      catatan: catatan ?? this.catatan,
      createdAt: createdAt,
      sawScore: sawScore ?? this.sawScore,
      ranking: ranking ?? this.ranking,
    );
  }
}
