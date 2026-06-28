// lib/services/task_provider.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/task_model.dart';
import '../models/time_block_model.dart';
import '../models/schedule_config_model.dart';
import '../models/schedule_result_model.dart';
import 'saw_service.dart';
import 'notification_service.dart';
import 'smart_scheduler_service.dart';

class TaskProvider with ChangeNotifier {
  List<Task> _tasks = [];
  final _uuid = const Uuid();
  static const String _storageKey = 'tugasku_tasks';
  final _notifService = NotificationService();

  // Smart Scheduling fields
  List<TimeBlock> _timeBlocks = [];
  ScheduleConfig _scheduleConfig = ScheduleConfig();
  final SmartSchedulerService _scheduler = SmartSchedulerService();

  // Conflict notification state
  List<ScheduleConflict> _latestConflicts = [];
  DateTime? _conflictsDetectedAt;

  // Pengaturan notifikasi global (hanya daily reminder & izin)
  bool _notifEnabled = true;
  bool _dailyReminderEnabled = true;
  int _dailyReminderHour = 8;
  int _dailyReminderMinute = 0;

  // Custom scopes & categories (disimpan di SharedPreferences)
  List<String> _customScopes = ['Perkuliahan', 'Tugas Rumah', 'Pekerjaan'];
  List<String> _customCategories = ['Tugas', 'Ujian', 'Proyek', 'Lainnya'];

  bool get notifEnabled => _notifEnabled;
  bool get dailyReminderEnabled => _dailyReminderEnabled;
  int get dailyReminderHour => _dailyReminderHour;
  int get dailyReminderMinute => _dailyReminderMinute;

  List<String> get customScopes => List.unmodifiable(_customScopes);
  List<String> get customCategories => List.unmodifiable(_customCategories);

  List<Task> get tasks => _tasks;

  List<Task> get activeTasks =>
      _tasks.where((t) => t.status != TaskStatus.selesai).toList();

  List<Task> get completedTasks =>
      _tasks.where((t) => t.status == TaskStatus.selesai).toList();

  List<Task> get overdueTasks => _tasks.where((t) => t.isOverdue).toList();

  List<Task> get dueSoonTasks =>
      _tasks.where((t) => t.isDueSoon && !t.isOverdue).toList();

  List<Task> get prioritizedTasks {
    final active = activeTasks;
    active.sort((a, b) => a.ranking.compareTo(b.ranking));
    return active;
  }

  /// Dapatkan tugas berdasarkan lingkupTugas tertentu
  List<Task> getTasksByScope(String scope) =>
      _tasks.where((t) => t.lingkupTugas == scope).toList();

  /// Daftar lingkup tugas yang unik dari semua tugas yang ada
  List<String> get usedScopes {
    final set = _tasks.map((t) => t.lingkupTugas).toSet();
    return set.toList();
  }

  int get totalTugas => _tasks.length;
  int get tugasSelesai => completedTasks.length;
  int get tugasAktif => activeTasks.length;

  double get persentaseSelesai {
    if (_tasks.isEmpty) return 0;
    return (tugasSelesai / totalTugas) * 100;
  }

  // Smart Scheduling getters
  List<TimeBlock> get timeBlocks => List.unmodifiable(_timeBlocks);
  ScheduleConfig get scheduleConfig => _scheduleConfig;

  List<ScheduleConflict> get latestConflicts =>
      List.unmodifiable(_latestConflicts);
  DateTime? get conflictsDetectedAt => _conflictsDetectedAt;
  bool get hasConflicts => _latestConflicts.isNotEmpty;

  void dismissConflicts() {
    _latestConflicts = [];
    _conflictsDetectedAt = null;
    notifyListeners();
  }

  List<TimeBlock> getTimeBlocksForDate(DateTime date) {
    return _timeBlocks.where((block) {
      return block.startTime.year == date.year &&
          block.startTime.month == date.month &&
          block.startTime.day == date.day;
    }).toList();
  }

  List<TimeBlock> getTimeBlocksForTask(String taskId) {
    return _timeBlocks.where((block) => block.taskId == taskId).toList();
  }

  TaskProvider() {
    _init();
  }

  Future<void> _init() async {
    await _notifService.initialize();
    await _loadNotifSettings();
    await _loadCustomData();
    await _loadTasks();
    await _loadSchedule();
  }

  // ─────────────────────────────────────────────
  // CUSTOM SCOPES & CATEGORIES
  // ─────────────────────────────────────────────

  Future<void> _loadCustomData() async {
    final prefs = await SharedPreferences.getInstance();

    final rawScopes = prefs.getStringList('custom_scopes');
    if (rawScopes != null && rawScopes.isNotEmpty) {
      _customScopes = rawScopes;
    }

    final rawCats = prefs.getStringList('custom_categories');
    if (rawCats != null && rawCats.isNotEmpty) {
      _customCategories = rawCats;
    }
  }

  Future<void> _saveCustomData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('custom_scopes', _customScopes);
    await prefs.setStringList('custom_categories', _customCategories);
  }

  Future<void> addScope(String scope) async {
    final trimmed = scope.trim();
    if (trimmed.isEmpty || _customScopes.contains(trimmed)) return;
    _customScopes.add(trimmed);
    await _saveCustomData();
    notifyListeners();
  }

  Future<void> removeScope(String scope) async {
    _customScopes.remove(scope);
    await _saveCustomData();
    notifyListeners();
  }

  Future<void> addCategory(String category) async {
    final trimmed = category.trim();
    if (trimmed.isEmpty || _customCategories.contains(trimmed)) return;
    _customCategories.add(trimmed);
    await _saveCustomData();
    notifyListeners();
  }

  Future<void> removeCategory(String category) async {
    _customCategories.remove(category);
    await _saveCustomData();
    notifyListeners();
  }

  // ─────────────────────────────────────────────
  // NOTIFIKASI GLOBAL (daily reminder & izin)
  // ─────────────────────────────────────────────

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
      // Tiap tugas menjadwalkan notifnya sendiri berdasarkan notifEnabled & notifSchedule
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

  // ─────────────────────────────────────────────
  // TASKS CRUD
  // ─────────────────────────────────────────────

  // Bug #5 Fix: Add try-catch and backup mechanism for JSON corruption
  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Try load main data
    try {
      final String? tasksJson = prefs.getString(_storageKey);
      if (tasksJson != null) {
        final List<dynamic> decoded = jsonDecode(tasksJson);
        _tasks = decoded.map((t) => Task.fromJson(t)).toList();
        _recalculateSAW();
        await _runScheduler();
        notifyListeners();
        return;
      }
    } catch (e) {
      debugPrint('Failed to load tasks, trying backup: $e');
      
      // Try backup
      try {
        final String? backupJson = prefs.getString('${_storageKey}_backup');
        if (backupJson != null) {
          final List<dynamic> decoded = jsonDecode(backupJson);
          _tasks = decoded.map((t) => Task.fromJson(t)).toList();
          _recalculateSAW();
          await _runScheduler();
          notifyListeners();
          return;
        }
      } catch (backupError) {
        debugPrint('Backup also failed: $backupError');
      }
    }
    
    // Fallback to empty
    _tasks = [];
    debugPrint('Starting with empty task list');
    notifyListeners();
  }

  // Bug #5 Fix: Add backup before saving new data
  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    
    try {
      // Backup old data first
      final oldData = prefs.getString(_storageKey);
      if (oldData != null) {
        await prefs.setString('${_storageKey}_backup', oldData);
      }
      
      // Save new data
      final String encoded = jsonEncode(_tasks.map((t) => t.toJson()).toList());
      await prefs.setString(_storageKey, encoded);
    } catch (e) {
      debugPrint('Failed to save tasks: $e');
    }
  }

  void _recalculateSAW() {
    _tasks = SAWService.hitungPrioritas(_tasks);
  }

  Future<void> _runScheduler() async {
    try {
      final manualBlocks =
          _timeBlocks.where((block) => block.isManuallyPlaced).toList();

      final result = _scheduler.rescheduleAll(
        tasks: _tasks,
        manualBlocks: manualBlocks,
        config: _scheduleConfig,
        now: DateTime.now(),
      );

      _timeBlocks = result.timeBlocks;

      if (result.conflicts.isNotEmpty) {
        _latestConflicts = result.conflicts;
        _conflictsDetectedAt = DateTime.now();
      } else {
        _latestConflicts = [];
        _conflictsDetectedAt = null;
      }

      notifyListeners();
      await _saveSchedule();
    } catch (e) {
      debugPrint('Smart Scheduler error: $e');
    }
  }

  Future<void> _saveSchedule() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final blocksJson =
          jsonEncode(_timeBlocks.map((block) => block.toJson()).toList());
      await prefs.setString('tugasku_schedule_blocks', blocksJson);
      final configJson = jsonEncode(_scheduleConfig.toJson());
      await prefs.setString('tugasku_schedule_config', configJson);
    } catch (e) {
      debugPrint('Error saving schedule: $e');
    }
  }

  Future<void> _loadSchedule() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final configString = prefs.getString('tugasku_schedule_config');
      if (configString != null) {
        try {
          final configMap = jsonDecode(configString) as Map<String, dynamic>;
          _scheduleConfig = ScheduleConfig.fromJson(configMap);
        } catch (e) {
          debugPrint('Corrupt schedule config data, using default: $e');
          _scheduleConfig = ScheduleConfig();
        }
      }

      final blocksString = prefs.getString('tugasku_schedule_blocks');
      if (blocksString != null) {
        try {
          final blocksList = jsonDecode(blocksString) as List<dynamic>;
          _timeBlocks = blocksList
              .map((json) => TimeBlock.fromJson(json as Map<String, dynamic>))
              .toList();
        } catch (e) {
          debugPrint('Corrupt schedule blocks data, using empty schedule: $e');
          _timeBlocks = [];
        }
      }

      _markMissedBlocks();
    } catch (e) {
      debugPrint('Error loading schedule: $e');
      _timeBlocks = [];
      _scheduleConfig = ScheduleConfig();
    }
  }

  void _markMissedBlocks() {
    final now = DateTime.now();
    final updatedBlocks = <TimeBlock>[];

    for (final block in _timeBlocks) {
      if (block.endTime.isBefore(now) &&
          block.status != TimeBlockStatus.missed) {
        final taskIndex = _tasks.indexWhere((t) => t.id == block.taskId);
        if (taskIndex != -1 &&
            _tasks[taskIndex].status != TaskStatus.selesai) {
          updatedBlocks.add(block.copyWith(status: TimeBlockStatus.missed));
        } else if (taskIndex == -1) {
          updatedBlocks.add(block.copyWith(status: TimeBlockStatus.missed));
        } else {
          updatedBlocks.add(block);
        }
      } else {
        updatedBlocks.add(block);
      }
    }

    _timeBlocks = updatedBlocks;
  }

  Future<void> updateScheduleConfig(ScheduleConfig config) async {
    _scheduleConfig = config;
    await _saveSchedule();
    await _runScheduler();
    notifyListeners();
  }

  Future<({bool success, String? error})> moveTimeBlock(
    String blockId,
    DateTime newSlot,
  ) async {
    final blockIndex = _timeBlocks.indexWhere((b) => b.id == blockId);
    if (blockIndex == -1) {
      return (success: false, error: 'Time block tidak ditemukan');
    }

    final block = _timeBlocks[blockIndex];

    final normalizedSlot = DateTime(
      newSlot.year,
      newSlot.month,
      newSlot.day,
      newSlot.hour,
    );

    final now = DateTime.now();
    final normalizedNow = DateTime(now.year, now.month, now.day, now.hour);
    if (normalizedSlot.isBefore(normalizedNow)) {
      return (
        success: false,
        error: 'Tidak dapat memindahkan ke slot yang sudah lewat'
      );
    }

    final isOccupied = _timeBlocks.any((b) {
      if (b.id == blockId) return false;
      final bSlot = DateTime(
        b.startTime.year,
        b.startTime.month,
        b.startTime.day,
        b.startTime.hour,
      );
      return bSlot.isAtSameMomentAs(normalizedSlot);
    });
    if (isOccupied) {
      return (
        success: false,
        error: 'Slot tujuan sudah terisi oleh tugas lain'
      );
    }

    final taskIndex = _tasks.indexWhere((t) => t.id == block.taskId);
    if (taskIndex != -1) {
      final relatedTask = _tasks[taskIndex];
      if (!normalizedSlot.isBefore(relatedTask.deadline)) {
        return (success: false, error: 'Pemindahan melampaui deadline tugas');
      }
    }

    _timeBlocks[blockIndex] = block.copyWith(
      startTime: normalizedSlot,
      endTime: normalizedSlot.add(const Duration(hours: 1)),
      isManuallyPlaced: true,
      status: TimeBlockStatus.manuallyMoved,
    );

    await _saveSchedule();
    notifyListeners();
    return (success: true, error: null);
  }

  Future<void> deleteTimeBlock(String blockId) async {
    _timeBlocks.removeWhere((b) => b.id == blockId);
    await _saveSchedule();
    notifyListeners();
  }

  Future<void> tambahTugas({
    required String namaTugas,
    required String lingkupTugas,
    required DateTime deadline,
    required int tingkatKepentingan,
    required int estimasiWaktu,
    String category = 'Tugas',
    String? catatan,
    bool notifEnabled = true,
    List<String>? notifSchedule,
  }) async {
    final task = Task(
      id: _uuid.v4(),
      namaTugas: namaTugas,
      lingkupTugas: lingkupTugas,
      deadline: deadline,
      tingkatKepentingan: tingkatKepentingan,
      // tingkatUrgensi dihitung otomatis di constructor Task
      estimasiWaktu: estimasiWaktu,
      category: category,
      catatan: catatan,
      createdAt: DateTime.now(),
      notifEnabled: notifEnabled,
      notifSchedule: notifSchedule,
    );
    _tasks.add(task);
    _recalculateSAW();
    await _runScheduler();
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

  Future<void> editTugas(
    String id, {
    String? namaTugas,
    String? lingkupTugas,
    DateTime? deadline,
    int? tingkatKepentingan,
    int? estimasiWaktu,
    TaskStatus? status,
    String? category,
    String? catatan,
    bool? notifEnabled,
    List<String>? notifSchedule,
  }) async {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      _tasks[index] = _tasks[index].copyWith(
        namaTugas: namaTugas,
        lingkupTugas: lingkupTugas,
        deadline: deadline,
        tingkatKepentingan: tingkatKepentingan,
        estimasiWaktu: estimasiWaktu,
        status: status,
        category: category,
        catatan: catatan,
        notifEnabled: notifEnabled,
        notifSchedule: notifSchedule,
      );
      _recalculateSAW();

      if (status == TaskStatus.selesai) {
        _timeBlocks.removeWhere((block) => block.taskId == id);
        await _saveSchedule();
      }

      await _runScheduler();
      await _saveTasks();
      if (_notifEnabled) {
        await _notifService.scheduleTaskNotifications(_tasks[index]);
      }
      notifyListeners();
    }
  }

  Future<void> hapusTugas(String id) async {
    await _notifService.cancelTaskNotifications(id);
    _timeBlocks.removeWhere((block) => block.taskId == id);
    _tasks.removeWhere((t) => t.id == id);
    _recalculateSAW();
    await _runScheduler();
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
