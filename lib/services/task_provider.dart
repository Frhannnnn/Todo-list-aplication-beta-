// lib/services/task_provider.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/task_model.dart';
import 'saw_service.dart';
import 'notification_service.dart';

class TaskProvider with ChangeNotifier {
  List<Task> _tasks = [];
  final _uuid = const Uuid();
  static const String _storageKey = 'tugasku_tasks';
  final _notifService = NotificationService();

  // Pengaturan notifikasi
  bool _notifEnabled = true;
  bool _dailyReminderEnabled = true;
  int _dailyReminderHour = 8;
  int _dailyReminderMinute = 0;

  bool get notifEnabled => _notifEnabled;
  bool get dailyReminderEnabled => _dailyReminderEnabled;
  int get dailyReminderHour => _dailyReminderHour;
  int get dailyReminderMinute => _dailyReminderMinute;

  List<Task> get tasks => _tasks;

  List<Task> get activeTasks =>
      _tasks.where((t) => t.status != TaskStatus.selesai).toList();

  List<Task> get completedTasks =>
      _tasks.where((t) => t.status == TaskStatus.selesai).toList();

  List<Task> get overdueTasks =>
      _tasks.where((t) => t.isOverdue).toList();

  List<Task> get dueSoonTasks =>
      _tasks.where((t) => t.isDueSoon && !t.isOverdue).toList();

  List<Task> get prioritizedTasks {
    final active = activeTasks;
    active.sort((a, b) => a.ranking.compareTo(b.ranking));
    return active;
  }

  List<Task> get individuTasks =>
      _tasks.where((t) => t.group == TaskGroup.individu && t.status != TaskStatus.selesai).toList();

  List<Task> get kelompokTasks =>
      _tasks.where((t) => t.group == TaskGroup.kelompok && t.status != TaskStatus.selesai).toList();

  int get totalTugas => _tasks.length;
  int get tugasSelesai => completedTasks.length;
  int get tugasAktif => activeTasks.length;

  double get persentaseSelesai {
    if (_tasks.isEmpty) return 0;
    return (tugasSelesai / totalTugas) * 100;
  }

  TaskProvider() {
    _init();
  }

  Future<void> _init() async {
    await _notifService.initialize();
    await _loadNotifSettings();
    await _loadTasks();
  }

  Future<void> _loadNotifSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _notifEnabled = prefs.getBool('notif_enabled') ?? true;
    _dailyReminderEnabled = prefs.getBool('daily_reminder_enabled') ?? true;
    _dailyReminderHour = prefs.getInt('daily_reminder_hour') ?? 8;
    _dailyReminderMinute = prefs.getInt('daily_reminder_minute') ?? 0;
  }

  Future<void> setNotifEnabled(bool value) async {
    _notifEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_enabled', value);
    if (!value) {
      await _notifService.cancelAllNotifications();
    } else {
      await _rescheduleAllNotifications();
    }
    notifyListeners();
  }

  Future<void> setDailyReminder({
    required bool enabled,
    int hour = 8,
    int minute = 0,
  }) async {
    _dailyReminderEnabled = enabled;
    _dailyReminderHour = hour;
    _dailyReminderMinute = minute;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('daily_reminder_enabled', enabled);
    await prefs.setInt('daily_reminder_hour', hour);
    await prefs.setInt('daily_reminder_minute', minute);

    if (enabled && _notifEnabled) {
      await _notifService.scheduleDailyReminder(
        hour: hour,
        minute: minute,
        activeTasks: tugasAktif,
      );
    } else {
      await _notifService.cancelDailyReminder();
    }
    notifyListeners();
  }

  Future<void> _rescheduleAllNotifications() async {
    if (!_notifEnabled) return;
    for (final task in _tasks) {
      await _notifService.scheduleTaskNotifications(task);
    }
    if (_dailyReminderEnabled) {
      await _notifService.scheduleDailyReminder(
        hour: _dailyReminderHour,
        minute: _dailyReminderMinute,
        activeTasks: tugasAktif,
      );
    }
  }

  Future<List<dynamic>> getPendingNotifications() =>
      _notifService.getPendingNotifications();

  Future<bool> requestNotificationPermission() =>
      _notifService.requestPermission();

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String? tasksJson = prefs.getString(_storageKey);
    if (tasksJson != null) {
      final List<dynamic> decoded = jsonDecode(tasksJson);
      _tasks = decoded.map((t) => Task.fromJson(t)).toList();
      _recalculateSAW();
    }
    notifyListeners();
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(_tasks.map((t) => t.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  void _recalculateSAW() {
    _tasks = SAWService.hitungPrioritas(_tasks);
  }

  Future<void> tambahTugas({
    required String namaTugas,
    required String mataKuliah,
    required DateTime deadline,
    required int tingkatKepentingan,
    required int tingkatUrgensi,
    required int estimasiWaktu,
    TaskGroup group = TaskGroup.individu,
    TaskCategory category = TaskCategory.kuliah,
    String? catatan,
  }) async {
    final task = Task(
      id: _uuid.v4(),
      namaTugas: namaTugas,
      mataKuliah: mataKuliah,
      deadline: deadline,
      tingkatKepentingan: tingkatKepentingan,
      tingkatUrgensi: tingkatUrgensi,
      estimasiWaktu: estimasiWaktu,
      group: group,
      category: category,
      catatan: catatan,
      createdAt: DateTime.now(),
    );
    _tasks.add(task);
    _recalculateSAW();
    await _saveTasks();
    if (_notifEnabled) {
      await _notifService.scheduleTaskNotifications(task);
      if (_dailyReminderEnabled) {
        await _notifService.scheduleDailyReminder(
          hour: _dailyReminderHour,
          minute: _dailyReminderMinute,
          activeTasks: tugasAktif,
        );
      }
    }
    notifyListeners();
  }

  Future<void> editTugas(String id, {
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
  }) async {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      _tasks[index] = _tasks[index].copyWith(
        namaTugas: namaTugas,
        mataKuliah: mataKuliah,
        deadline: deadline,
        tingkatKepentingan: tingkatKepentingan,
        tingkatUrgensi: tingkatUrgensi,
        estimasiWaktu: estimasiWaktu,
        status: status,
        group: group,
        category: category,
        catatan: catatan,
      );
      _recalculateSAW();
      await _saveTasks();
      if (_notifEnabled) {
        await _notifService.scheduleTaskNotifications(_tasks[index]);
      }
      notifyListeners();
    }
  }

  Future<void> hapusTugas(String id) async {
    await _notifService.cancelTaskNotifications(id);
    _tasks.removeWhere((t) => t.id == id);
    _recalculateSAW();
    await _saveTasks();
    notifyListeners();
  }

  Future<void> updateStatus(String id, TaskStatus status) async {
    await editTugas(id, status: status);
  }

  Future<void> clearAllTasks() async {
    await _notifService.cancelAllNotifications();
    _tasks.clear();
    await _saveTasks();
    notifyListeners();
  }
}
