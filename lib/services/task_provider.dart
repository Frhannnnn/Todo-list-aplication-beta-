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

  List<Task> get overdueTasks => _tasks.where((t) => t.isOverdue).toList();

  List<Task> get dueSoonTasks =>
      _tasks.where((t) => t.isDueSoon && !t.isOverdue).toList();

  List<Task> get prioritizedTasks {
    final active = activeTasks;
    active.sort((a, b) => a.ranking.compareTo(b.ranking));
    return active;
  }

  List<Task> get individuTasks => _tasks
      .where((t) =>
          t.group == TaskGroup.individu && t.status != TaskStatus.selesai)
      .toList();

  List<Task> get kelompokTasks => _tasks
      .where((t) =>
          t.group == TaskGroup.kelompok && t.status != TaskStatus.selesai)
      .toList();

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

  /// Latest conflicts detected during the most recent scheduling run.
  List<ScheduleConflict> get latestConflicts => List.unmodifiable(_latestConflicts);

  /// Timestamp when conflicts were last detected (for notification timing).
  DateTime? get conflictsDetectedAt => _conflictsDetectedAt;

  /// Whether there are active conflicts to display.
  bool get hasConflicts => _latestConflicts.isNotEmpty;

  /// Dismisses the conflict notification.
  void dismissConflicts() {
    _latestConflicts = [];
    _conflictsDetectedAt = null;
    notifyListeners();
  }

  /// Returns time blocks whose startTime falls on the given date.
  List<TimeBlock> getTimeBlocksForDate(DateTime date) {
    return _timeBlocks.where((block) {
      return block.startTime.year == date.year &&
          block.startTime.month == date.month &&
          block.startTime.day == date.day;
    }).toList();
  }

  /// Returns time blocks with matching taskId.
  List<TimeBlock> getTimeBlocksForTask(String taskId) {
    return _timeBlocks.where((block) => block.taskId == taskId).toList();
  }

  TaskProvider() {
    _init();
  }

  Future<void> _init() async {
    await _notifService.initialize();
    await _loadNotifSettings();
    await _loadTasks();
    await _loadSchedule();
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
      await _runScheduler();
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

  /// Runs the smart scheduler after SAW recalculation completes.
  ///
  /// Waits for all SAW scores to be available (they are set synchronously
  /// by _recalculateSAW), then calls rescheduleAll with current tasks
  /// and manually placed blocks.
  ///
  /// On success: updates _timeBlocks and notifies listeners.
  /// On failure: retains last valid schedule (graceful degradation per Req 8.6).
  Future<void> _runScheduler() async {
    try {
      // Get manually placed blocks that should be preserved
      final manualBlocks = _timeBlocks
          .where((block) => block.isManuallyPlaced)
          .toList();

      // Run the scheduler with current tasks and config
      final result = _scheduler.rescheduleAll(
        tasks: _tasks,
        manualBlocks: manualBlocks,
        config: _scheduleConfig,
        now: DateTime.now(),
      );

      // Update time blocks with the scheduling result
      _timeBlocks = result.timeBlocks;

      // Update conflict notification state
      if (result.conflicts.isNotEmpty) {
        _latestConflicts = result.conflicts;
        _conflictsDetectedAt = DateTime.now();
      } else {
        _latestConflicts = [];
        _conflictsDetectedAt = null;
      }

      notifyListeners();

      // Persist the schedule
      await _saveSchedule();
    } catch (e) {
      // SAW Service or scheduler failure: retain last valid schedule
      // Don't crash — graceful degradation (Requirement 8.6)
      debugPrint('Smart Scheduler error: $e');
    }
  }

  /// Persists the current schedule (timeBlocks and scheduleConfig) to local storage.
  ///
  /// Serializes _timeBlocks to JSON list and _scheduleConfig to JSON object,
  /// then saves both to SharedPreferences under separate keys.
  Future<void> _saveSchedule() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Serialize timeBlocks
      final blocksJson = jsonEncode(
        _timeBlocks.map((block) => block.toJson()).toList(),
      );
      await prefs.setString('tugasku_schedule_blocks', blocksJson);

      // Serialize scheduleConfig
      final configJson = jsonEncode(_scheduleConfig.toJson());
      await prefs.setString('tugasku_schedule_config', configJson);
    } catch (e) {
      debugPrint('Error saving schedule: $e');
    }
  }

  /// Loads schedule data from local storage on app start.
  ///
  /// Deserializes timeBlocks and scheduleConfig from SharedPreferences.
  /// If data is corrupt or missing, uses empty schedule (no crash).
  /// After loading, marks missed blocks: blocks where endTime < now
  /// and the associated task is not complete get status = TimeBlockStatus.missed.
  Future<void> _loadSchedule() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load scheduleConfig
      final configString = prefs.getString('tugasku_schedule_config');
      if (configString != null) {
        try {
          final configMap = jsonDecode(configString) as Map<String, dynamic>;
          _scheduleConfig = ScheduleConfig.fromJson(configMap);
        } catch (e) {
          // Corrupt config data — use default
          debugPrint('Corrupt schedule config data, using default: $e');
          _scheduleConfig = ScheduleConfig();
        }
      }

      // Load timeBlocks
      final blocksString = prefs.getString('tugasku_schedule_blocks');
      if (blocksString != null) {
        try {
          final blocksList = jsonDecode(blocksString) as List<dynamic>;
          _timeBlocks = blocksList
              .map((json) => TimeBlock.fromJson(json as Map<String, dynamic>))
              .toList();
        } catch (e) {
          // Corrupt blocks data — use empty schedule
          debugPrint('Corrupt schedule blocks data, using empty schedule: $e');
          _timeBlocks = [];
        }
      }

      // Mark missed blocks: endTime < now and task not complete
      _markMissedBlocks();
    } catch (e) {
      // Any unexpected error — default to empty schedule
      debugPrint('Error loading schedule: $e');
      _timeBlocks = [];
      _scheduleConfig = ScheduleConfig();
    }
  }

  /// Marks time blocks as missed if their endTime has passed
  /// and the associated task is not yet complete.
  void _markMissedBlocks() {
    final now = DateTime.now();
    final updatedBlocks = <TimeBlock>[];

    for (final block in _timeBlocks) {
      if (block.endTime.isBefore(now) && block.status != TimeBlockStatus.missed) {
        // Check if the associated task is not complete
        final taskIndex = _tasks.indexWhere((t) => t.id == block.taskId);
        if (taskIndex != -1 && _tasks[taskIndex].status != TaskStatus.selesai) {
          updatedBlocks.add(block.copyWith(status: TimeBlockStatus.missed));
        } else if (taskIndex == -1) {
          // Task not found — still mark as missed (orphaned block)
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

  /// Updates the schedule configuration and triggers a full reschedule.
  ///
  /// Saves the new config to storage and runs the scheduler with the
  /// updated Primary Work Hours preferences.
  Future<void> updateScheduleConfig(ScheduleConfig config) async {
    _scheduleConfig = config;
    await _saveSchedule();
    await _runScheduler();
    notifyListeners();
  }

  /// Moves a TimeBlock to a new slot.
  ///
  /// Validates:
  /// - Block exists
  /// - newSlot is not occupied by another block
  /// - newSlot is before the task's deadline
  /// - newSlot is not in the past
  ///
  /// On success: updates block with new times, marks as manually placed.
  /// Returns a record with success flag and optional error message.
  Future<({bool success, String? error})> moveTimeBlock(
    String blockId,
    DateTime newSlot,
  ) async {
    // Find the block by ID
    final blockIndex = _timeBlocks.indexWhere((b) => b.id == blockId);
    if (blockIndex == -1) {
      return (success: false, error: 'Time block tidak ditemukan');
    }

    final block = _timeBlocks[blockIndex];

    // Normalize newSlot to hour boundary
    final normalizedSlot = DateTime(
      newSlot.year,
      newSlot.month,
      newSlot.day,
      newSlot.hour,
    );

    // Validate: newSlot is not in the past
    final now = DateTime.now();
    final normalizedNow = DateTime(now.year, now.month, now.day, now.hour);
    if (normalizedSlot.isBefore(normalizedNow)) {
      return (success: false, error: 'Tidak dapat memindahkan ke slot yang sudah lewat');
    }

    // Validate: newSlot is not occupied by another block
    final isOccupied = _timeBlocks.any((b) {
      if (b.id == blockId) return false; // Exclude the block being moved
      final bSlot = DateTime(
        b.startTime.year,
        b.startTime.month,
        b.startTime.day,
        b.startTime.hour,
      );
      return bSlot.isAtSameMomentAs(normalizedSlot);
    });
    if (isOccupied) {
      return (success: false, error: 'Slot tujuan sudah terisi oleh tugas lain');
    }

    // Validate: newSlot is before the task's deadline
    final taskIndex = _tasks.indexWhere((t) => t.id == block.taskId);
    if (taskIndex != -1) {
      final relatedTask = _tasks[taskIndex];
      if (!normalizedSlot.isBefore(relatedTask.deadline)) {
        return (success: false, error: 'Pemindahan melampaui deadline tugas');
      }
    }

    // All validations passed — update the block
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

  /// Deletes a TimeBlock by ID, freeing its slot.
  Future<void> deleteTimeBlock(String blockId) async {
    _timeBlocks.removeWhere((b) => b.id == blockId);
    await _saveSchedule();
    notifyListeners();
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

      // Handle task completion: remove all related TimeBlocks (Req 7.6)
      if (status == TaskStatus.selesai) {
        _timeBlocks.removeWhere((block) => block.taskId == id);
        await _saveSchedule();
      }

      // Reschedule: handles task edits (deadline/estimation changes)
      // preserving manual blocks of other tasks (Req 7.5)
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
    // Remove all TimeBlocks associated with the deleted task
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
