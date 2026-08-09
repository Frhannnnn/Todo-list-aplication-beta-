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
import '../utils/recurrence.dart';

class TaskProvider with ChangeNotifier {
  List<Task> _tasks = [];
  final _uuid = const Uuid();
  static const String _storageKey = 'tugasku_tasks';
  NotificationService _notifService = NotificationService();

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
  // Kategori kini per-lingkup: tiap lingkup punya daftar kategorinya sendiri,
  // tidak dibagi-pakai dengan lingkup lain (boleh kebetulan sama nama).
  List<String> _customScopes = ['Perkuliahan', 'Tugas Rumah', 'Pekerjaan'];
  Map<String, List<String>> _categoriesByScope = {};

  // Kapan data terakhir dicadangkan (ekspor). Untuk pengingat backup.
  DateTime? _lastBackupAt;
  DateTime? get lastBackupAt => _lastBackupAt;

  /// Tandai bahwa data baru saja dicadangkan (dipanggil setelah ekspor sukses).
  Future<void> markBackupDone() async {
    _lastBackupAt = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_backup_at', _lastBackupAt!.toIso8601String());
    notifyListeners();
  }

  bool get notifEnabled => _notifEnabled;
  bool get dailyReminderEnabled => _dailyReminderEnabled;
  int get dailyReminderHour => _dailyReminderHour;
  int get dailyReminderMinute => _dailyReminderMinute;

  List<String> get customScopes => List.unmodifiable(_customScopes);

  /// Daftar kategori milik satu lingkup tertentu.
  List<String> categoriesForScope(String scope) =>
      List.unmodifiable(_categoriesByScope[scope] ?? const []);

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

  /// Streak = jumlah hari berturut-turut (berakhir hari ini atau kemarin) di
  /// mana minimal satu tugas ditandai selesai. Hanya menghitung tugas yang
  /// punya [Task.completedAt] — tugas yang sudah selesai sebelum fitur ini ada
  /// (tanpa timestamp) tidak ikut dihitung, jadi streak tumbuh dari sekarang.
  int get currentStreak {
    final completedDays = _tasks
        .where((t) => t.completedAt != null)
        .map((t) => DateTime(
            t.completedAt!.year, t.completedAt!.month, t.completedAt!.day))
        .toSet();
    if (completedDays.isEmpty) return 0;

    final now = DateTime.now();
    var cursor = DateTime(now.year, now.month, now.day);
    // Streak masih "hidup" bila selesai hari ini ATAU kemarin.
    if (!completedDays.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
      if (!completedDays.contains(cursor)) return 0;
    }

    var streak = 0;
    while (completedDays.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
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

  TaskProvider({NotificationService? notifService}) {
    if (notifService != null) {
      _notifService = notifService;
    }
    _init();
  }

  @visibleForTesting
  Future<void> init() async => _init();

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

  static const String _categoriesByScopeKey = 'categories_by_scope';

  Future<void> _loadCustomData() async {
    final prefs = await SharedPreferences.getInstance();

    final rawBackup = prefs.getString('last_backup_at');
    if (rawBackup != null) _lastBackupAt = DateTime.tryParse(rawBackup);

    final rawScopes = prefs.getStringList('custom_scopes');
    if (rawScopes != null && rawScopes.isNotEmpty) {
      _customScopes = rawScopes;
    }

    final rawCategoriesByScope = prefs.getString(_categoriesByScopeKey);
    if (rawCategoriesByScope != null) {
      try {
        final decoded = jsonDecode(rawCategoriesByScope) as Map<String, dynamic>;
        _categoriesByScope = decoded.map(
          (scope, cats) => MapEntry(scope, List<String>.from(cats as List)),
        );
      } catch (e) {
        debugPrint('Corrupt categories_by_scope data, fallback ke migrasi: $e');
      }
    }

    if (_categoriesByScope.isEmpty) {
      // Migrasi sekali-jalan dari skema lama (kategori global 'custom_categories')
      // ke skema baru (per-lingkup): salin daftar lama ke SETIAP lingkup yang ada.
      final legacyFlat =
          prefs.getStringList('custom_categories') ?? List.from(kDefaultCategories);
      for (final scope in _customScopes) {
        _categoriesByScope[scope] = List.from(legacyFlat);
      }
      await _saveCustomData();
    } else {
      // Pastikan tiap lingkup yang ada (termasuk yang baru ditambah setelah
      // migrasi) selalu punya entry kategori sendiri, tidak pernah kosong.
      var changed = false;
      for (final scope in _customScopes) {
        if (!_categoriesByScope.containsKey(scope)) {
          _categoriesByScope[scope] = List.from(kDefaultCategories);
          changed = true;
        }
      }
      if (changed) await _saveCustomData();
    }
  }

  Future<void> _saveCustomData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('custom_scopes', _customScopes);
    await prefs.setString(_categoriesByScopeKey, jsonEncode(_categoriesByScope));
  }

  Future<void> addScope(String scope) async {
    final trimmed = scope.trim();
    if (trimmed.isEmpty || _customScopes.contains(trimmed)) return;
    _customScopes.add(trimmed);
    _categoriesByScope.putIfAbsent(trimmed, () => List.from(kDefaultCategories));
    await _saveCustomData();
    notifyListeners();
  }

  /// Hapus lingkup [scope]. Jika masih ada tugas yang memakai lingkup ini dan
  /// [reassignTasksTo] tidak diisi, penghapusan DIBATALKAN (return
  /// success:false) supaya UI bisa meminta konfirmasi/pemindahan tugas dulu —
  /// tidak pernah diam-diam meninggalkan tugas "yatim".
  Future<({bool success, int affectedTasks})> removeScope(
    String scope, {
    String? reassignTasksTo,
  }) async {
    final affected = _tasks.where((t) => t.lingkupTugas == scope).toList();

    if (affected.isNotEmpty) {
      if (reassignTasksTo == null || reassignTasksTo == scope) {
        return (success: false, affectedTasks: affected.length);
      }
      for (final task in affected) {
        final index = _tasks.indexWhere((t) => t.id == task.id);
        if (index != -1) {
          _tasks[index] = _tasks[index].copyWith(lingkupTugas: reassignTasksTo);
        }
      }
      _recalculateSAW();
      await _saveTasks();
    }

    _customScopes.remove(scope);
    _categoriesByScope.remove(scope);
    await _saveCustomData();
    notifyListeners();
    return (success: true, affectedTasks: affected.length);
  }

  /// Ganti nama lingkup [oldName] jadi [newName], termasuk memindahkan semua
  /// tugas yang memakainya (cascade) dan daftar kategorinya. Ditolak jika
  /// [newName] sudah dipakai lingkup lain.
  Future<bool> renameScope(String oldName, String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty || trimmed == oldName) return false;
    if (_customScopes.contains(trimmed)) return false;
    if (!_customScopes.contains(oldName)) return false;

    final idx = _customScopes.indexOf(oldName);
    _customScopes[idx] = trimmed;
    _categoriesByScope[trimmed] = _categoriesByScope.remove(oldName) ??
        List.from(kDefaultCategories);

    for (var i = 0; i < _tasks.length; i++) {
      if (_tasks[i].lingkupTugas == oldName) {
        _tasks[i] = _tasks[i].copyWith(lingkupTugas: trimmed);
      }
    }

    _recalculateSAW();
    await _saveTasks();
    await _saveCustomData();
    notifyListeners();
    return true;
  }

  Future<void> addCategoryToScope(String scope, String category) async {
    final trimmed = category.trim();
    if (trimmed.isEmpty) return;
    final list = _categoriesByScope.putIfAbsent(scope, () => []);
    if (list.contains(trimmed)) return;
    list.add(trimmed);
    await _saveCustomData();
    notifyListeners();
  }

  Future<void> removeCategoryFromScope(String scope, String category) async {
    _categoriesByScope[scope]?.remove(category);
    await _saveCustomData();
    notifyListeners();
  }

  /// Ganti nama kategori [oldCat] → [newCat] di dalam lingkup [scope],
  /// termasuk memindahkan semua tugas di lingkup itu yang memakai kategori
  /// lama (cascade). Ditolak jika [newCat] sudah dipakai di lingkup yang sama.
  Future<bool> renameCategoryInScope(
    String scope,
    String oldCat,
    String newCat,
  ) async {
    final trimmed = newCat.trim();
    final list = _categoriesByScope[scope];
    if (list == null || trimmed.isEmpty || trimmed == oldCat) return false;
    if (list.contains(trimmed)) return false;
    if (!list.contains(oldCat)) return false;

    final idx = list.indexOf(oldCat);
    list[idx] = trimmed;

    for (var i = 0; i < _tasks.length; i++) {
      if (_tasks[i].lingkupTugas == scope && _tasks[i].category == oldCat) {
        _tasks[i] = _tasks[i].copyWith(category: trimmed);
      }
    }

    await _saveTasks();
    await _saveCustomData();
    notifyListeners();
    return true;
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

  /// Muat ulang data dari penyimpanan & hitung ulang peringkat SAW.
  /// Dipakai untuk pull-to-refresh pada daftar tugas.
  Future<void> refresh() => _loadTasks();

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
  /// Return `true` bila berhasil tersimpan, `false` bila gagal — supaya
  /// pemanggil (tambahTugas/editTugas/hapusTugas) bisa memberi tahu user,
  /// bukan diam-diam menganggap sukses saat penyimpanan sebenarnya gagal.
  Future<bool> _saveTasks() async {
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
      return true;
    } catch (e) {
      debugPrint('Failed to save tasks: $e');
      return false;
    }
  }

  /// Hitung ulang urgensi/ranking SAW tanpa menjalankan scheduler (murah,
  /// aman dipanggil sering — mis. saat app resume atau berkala/Fase 7).
  void refreshUrgensi() {
    _recalculateSAW();
    notifyListeners();
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

  Future<bool> _saveSchedule() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final blocksJson =
          jsonEncode(_timeBlocks.map((block) => block.toJson()).toList());
      await prefs.setString('tugasku_schedule_blocks', blocksJson);
      final configJson = jsonEncode(_scheduleConfig.toJson());
      await prefs.setString('tugasku_schedule_config', configJson);
      return true;
    } catch (e) {
      debugPrint('Error saving schedule: $e');
      return false;
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

  /// Return `true` bila konfigurasi berhasil tersimpan, `false` bila gagal
  /// (Issue #7) — UI wajib menampilkan ini ke user.
  Future<bool> updateScheduleConfig(ScheduleConfig config) async {
    _scheduleConfig = config;
    final saved = await _saveSchedule();
    await _runScheduler();
    notifyListeners();
    return saved;
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

  /// Jaga agar data tak valid tidak pernah masuk ke daftar tugas. Form UI
  /// sudah memvalidasi, tapi provider adalah lapisan logika bisnis sehingga
  /// tidak boleh bergantung pada pemanggilnya. Estimasi 0 khususnya berbahaya:
  /// normalisasi SAW membagi dengan nilai maksimum, sehingga seluruh estimasi
  /// bernilai 0 akan menghasilkan pembagian nol.
  void _validasiInputTugas({
    required String namaTugas,
    required int tingkatKepentingan,
    required int estimasiWaktu,
  }) {
    if (namaTugas.trim().isEmpty) {
      throw ArgumentError.value(
          namaTugas, 'namaTugas', 'Nama tugas tidak boleh kosong');
    }
    if (tingkatKepentingan < 1 || tingkatKepentingan > 5) {
      throw ArgumentError.value(tingkatKepentingan, 'tingkatKepentingan',
          'Tingkat kepentingan harus 1-5');
    }
    if (estimasiWaktu < 1) {
      throw ArgumentError.value(
          estimasiWaktu, 'estimasiWaktu', 'Estimasi waktu minimal 1 jam');
    }
  }

  /// Return `true` bila tugas berhasil ditambah & tersimpan, `false` bila
  /// penyimpanan gagal (lihat [_saveTasks]) — UI wajib menampilkan ini ke
  /// user, bukan mengasumsikan sukses.
  ///
  /// Melempar [ArgumentError] bila nama kosong, kepentingan di luar 1-5, atau
  /// estimasi kurang dari 1 jam.
  Future<bool> tambahTugas({
    required String namaTugas,
    required String lingkupTugas,
    String? mataKuliah,
    required DateTime deadline,
    required int tingkatKepentingan,
    required int estimasiWaktu,
    String category = 'Tugas',
    String? catatan,
    bool notifEnabled = true,
    List<String>? notifSchedule,
    RecurrenceType recurrence = RecurrenceType.none,
    int recurrenceInterval = 1,
    RecurrenceUnit? recurrenceUnit,
    DateTime? recurrenceEndDate,
    int? recurrenceCount,
  }) async {
    _validasiInputTugas(
      namaTugas: namaTugas,
      tingkatKepentingan: tingkatKepentingan,
      estimasiWaktu: estimasiWaktu,
    );

    final task = Task(
      id: _uuid.v4(),
      namaTugas: namaTugas,
      lingkupTugas: lingkupTugas,
      mataKuliah: mataKuliah,
      deadline: deadline,
      tingkatKepentingan: tingkatKepentingan,
      // tingkatUrgensi dihitung otomatis di constructor Task
      estimasiWaktu: estimasiWaktu,
      category: category,
      catatan: catatan,
      createdAt: DateTime.now(),
      notifEnabled: notifEnabled,
      notifSchedule: notifSchedule,
      recurrence: recurrence,
      recurrenceInterval: recurrenceInterval,
      recurrenceUnit: recurrenceUnit,
      recurrenceEndDate: recurrenceEndDate,
      recurrenceCount: recurrenceCount,
    );
    _tasks.add(task);
    _recalculateSAW();
    await _runScheduler();
    final saved = await _saveTasks();
    // Penjadwalan notifikasi bersifat best-effort — kegagalannya tidak boleh
    // menggagalkan simpan tugas (mis. izin exact alarm tidak tersedia).
    if (_notifEnabled) {
      try {
        await _notifService.scheduleTaskNotifications(task);
        if (_dailyReminderEnabled) {
          await _notifService.scheduleDailyReminder(
            hour: _dailyReminderHour,
            minute: _dailyReminderMinute,
            activeTasks: tugasAktif,
          );
        }
      } catch (e) {
        debugPrint('Gagal menjadwalkan notifikasi tugas: $e');
      }
    }
    notifyListeners();
    return saved;
  }

  /// Re-insert tugas yang sebelumnya dihapus, mempertahankan id aslinya
  /// (dipakai untuk fitur "Urungkan" setelah hapus — lihat [hapusTugas]).
  Future<bool> restoreTugas(Task task) async {
    if (_tasks.any((t) => t.id == task.id)) return false;
    _tasks.add(task);
    _recalculateSAW();
    await _runScheduler();
    final saved = await _saveTasks();
    if (_notifEnabled) {
      try {
        await _notifService.scheduleTaskNotifications(task);
      } catch (e) {
        debugPrint('Gagal menjadwalkan notifikasi tugas: $e');
      }
    }
    notifyListeners();
    return saved;
  }

  /// Tambahkan akumulasi menit fokus (dari sesi Pomodoro yang selesai) ke
  /// tugas [taskId]. Tidak mengubah status tugas.
  Future<void> addFocusMinutes(String taskId, int minutes) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index == -1 || minutes <= 0) return;
    _tasks[index] = _tasks[index].copyWith(
      totalFocusMinutes: _tasks[index].totalFocusMinutes + minutes,
    );
    await _saveTasks();
    notifyListeners();
  }

  /// Return `true` bila perubahan berhasil tersimpan, `false` bila id tidak
  /// ditemukan atau penyimpanan gagal.
  Future<bool> editTugas(
    String id, {
    String? namaTugas,
    String? lingkupTugas,
    String? mataKuliah,
    bool clearMataKuliah = false,
    DateTime? deadline,
    int? tingkatKepentingan,
    int? estimasiWaktu,
    TaskStatus? status,
    String? category,
    String? catatan,
    bool? notifEnabled,
    List<String>? notifSchedule,
    RecurrenceType? recurrence,
    int? recurrenceInterval,
    RecurrenceUnit? recurrenceUnit,
    bool clearRecurrenceUnit = false,
    DateTime? recurrenceEndDate,
    bool clearRecurrenceEndDate = false,
    int? recurrenceCount,
    bool clearRecurrenceCount = false,
  }) async {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index == -1) return false;

    // Catat/hapus waktu penyelesaian saat status berpindah ke/dari 'selesai'
    // (dipakai untuk menghitung streak di Dashboard). Hanya berubah saat
    // status benar-benar transisi, bukan tiap edit.
    final oldStatus = _tasks[index].status;
    DateTime? completedAt;
    var clearCompletedAt = false;
    if (status != null && status != oldStatus) {
      if (status == TaskStatus.selesai) {
        completedAt = DateTime.now();
      } else if (oldStatus == TaskStatus.selesai) {
        clearCompletedAt = true;
      }
    }

    _tasks[index] = _tasks[index].copyWith(
      namaTugas: namaTugas,
      lingkupTugas: lingkupTugas,
      mataKuliah: mataKuliah,
      clearMataKuliah: clearMataKuliah,
      deadline: deadline,
      tingkatKepentingan: tingkatKepentingan,
      estimasiWaktu: estimasiWaktu,
      status: status,
      category: category,
      catatan: catatan,
      completedAt: completedAt,
      clearCompletedAt: clearCompletedAt,
      notifEnabled: notifEnabled,
      notifSchedule: notifSchedule,
      recurrence: recurrence,
      recurrenceInterval: recurrenceInterval,
      recurrenceUnit: recurrenceUnit,
      clearRecurrenceUnit: clearRecurrenceUnit,
      recurrenceEndDate: recurrenceEndDate,
      clearRecurrenceEndDate: clearRecurrenceEndDate,
      recurrenceCount: recurrenceCount,
      clearRecurrenceCount: clearRecurrenceCount,
    );
    // Tangkap tugas yang baru diselesaikan berdasarkan IDENTITAS sebelum
    // _recalculateSAW() mengurutkan ulang _tasks (tugas selesai dipindah ke
    // akhir), sehingga _tasks[index] tak lagi menunjuk ke tugas ini.
    final base = _tasks[index];
    _recalculateSAW();

    // Spawn occurrence berikutnya bila tugas berulang baru saja diselesaikan.
    // (Model lazy: hanya saat transisi ke selesai, satu occurrence terbuka.)
    Task? spawned;
    if (status == TaskStatus.selesai &&
        oldStatus != TaskStatus.selesai &&
        base.recurrence != RecurrenceType.none) {
      final nextDate = nextOccurrenceDate(base);
      if (nextDate != null) {
        final seriesId = base.seriesId ?? base.id;
        if (base.seriesId == null) {
          final ci = _tasks.indexWhere((t) => t.id == base.id);
          if (ci != -1) _tasks[ci] = _tasks[ci].copyWith(seriesId: seriesId);
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

    if (status == TaskStatus.selesai) {
      _timeBlocks.removeWhere((block) => block.taskId == id);
      await _saveSchedule();
    }

    await _runScheduler();
    final saved = await _saveTasks();
    if (_notifEnabled) {
      try {
        await _notifService.scheduleTaskNotifications(base);
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
      } catch (e) {
        debugPrint('Gagal menjadwalkan notifikasi tugas: $e');
      }
    }
    notifyListeners();
    return saved;
  }

  /// Return `true` bila tugas berhasil dihapus & tersimpan, `false` bila id
  /// tidak ditemukan atau penyimpanan gagal.
  Future<bool> hapusTugas(String id) async {
    if (!_tasks.any((t) => t.id == id)) return false;

    try {
      await _notifService.cancelTaskNotifications(id);
    } catch (e) {
      // Ignore notification cancellation errors to ensure task is deleted
    }
    _timeBlocks.removeWhere((block) => block.taskId == id);
    _tasks.removeWhere((t) => t.id == id);
    _recalculateSAW();
    await _runScheduler();
    final saved = await _saveTasks();
    notifyListeners();
    return saved;
  }

  Future<void> updateStatus(String id, TaskStatus status) async {
    await editTugas(id, status: status);
  }

  /// Hapus seluruh tugas. Prioritaskan pembersihan + penyimpanan lebih dulu;
  /// pembatalan notifikasi bersifat best-effort agar kegagalan/hang di plugin
  /// notifikasi tidak membuat penghapusan tidak jadi.
  Future<bool> clearAllTasks() async {
    _tasks.clear();
    _timeBlocks = [];
    final saved = await _saveTasks();
    notifyListeners();
    try {
      await _notifService.cancelAllNotifications();
    } catch (e) {
      debugPrint('Gagal membatalkan notifikasi saat hapus semua: $e');
    }
    return saved;
  }

  // ─────────────────────────────────────────────
  // EKSPOR & IMPOR DATA (Issue #6)
  // ─────────────────────────────────────────────

  static const int _exportFormatVersion = 1;

  /// Bundel seluruh data pengguna (tugas, lingkup, kategori per-lingkup,
  /// konfigurasi jadwal, pengaturan notifikasi) jadi satu Map siap
  /// di-jsonEncode. Dipakai untuk backup manual sebelum ganti perangkat
  /// atau uninstall.
  Map<String, dynamic> exportData() {
    return {
      'formatVersion': _exportFormatVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'tasks': _tasks.map((t) => t.toJson()).toList(),
      'customScopes': _customScopes,
      'categoriesByScope': _categoriesByScope,
      'scheduleConfig': _scheduleConfig.toJson(),
      'notifSettings': {
        'notifEnabled': _notifEnabled,
        'dailyReminderEnabled': _dailyReminderEnabled,
        'dailyReminderHour': _dailyReminderHour,
        'dailyReminderMinute': _dailyReminderMinute,
      },
    };
  }

  /// Terapkan data hasil ekspor, MENGGANTIKAN seluruh data saat ini.
  /// Parsing dilakukan ke variabel lokal dulu — kalau ADA bagian yang
  /// gagal/tidak valid, seluruh proses dibatalkan dan data yang sedang
  /// berjalan tidak tersentuh sama sekali (tidak ada penerapan sebagian).
  Future<({bool success, String? error})> importData(
    Map<String, dynamic> json,
  ) async {
    try {
      final version = json['formatVersion'];
      if (version is! int || version > _exportFormatVersion) {
        return (
          success: false,
          error: 'Format file tidak dikenali atau berasal dari versi aplikasi yang lebih baru.'
        );
      }

      final rawTasks = json['tasks'];
      final rawScopes = json['customScopes'];
      final rawCategories = json['categoriesByScope'];
      if (rawTasks is! List || rawScopes is! List || rawCategories is! Map) {
        return (success: false, error: 'Struktur file tidak lengkap atau rusak.');
      }

      final newTasks = rawTasks
          .map((t) => Task.fromJson(t as Map<String, dynamic>))
          .toList();
      final newScopes = List<String>.from(rawScopes);
      final newCategories = rawCategories.map(
        (scope, cats) =>
            MapEntry(scope as String, List<String>.from(cats as List)),
      );

      ScheduleConfig? newScheduleConfig;
      final rawConfig = json['scheduleConfig'];
      if (rawConfig is Map<String, dynamic>) {
        newScheduleConfig = ScheduleConfig.fromJson(rawConfig);
      }

      final rawNotif = json['notifSettings'];
      var newNotifEnabled = _notifEnabled;
      var newDailyReminderEnabled = _dailyReminderEnabled;
      var newDailyReminderHour = _dailyReminderHour;
      var newDailyReminderMinute = _dailyReminderMinute;
      if (rawNotif is Map<String, dynamic>) {
        newNotifEnabled = rawNotif['notifEnabled'] as bool? ?? newNotifEnabled;
        newDailyReminderEnabled =
            rawNotif['dailyReminderEnabled'] as bool? ?? newDailyReminderEnabled;
        newDailyReminderHour =
            rawNotif['dailyReminderHour'] as int? ?? newDailyReminderHour;
        newDailyReminderMinute =
            rawNotif['dailyReminderMinute'] as int? ?? newDailyReminderMinute;
      }

      // Semua berhasil di-parse — baru terapkan.
      await _notifService.cancelAllNotifications();
      _tasks = newTasks;
      _customScopes = newScopes;
      _categoriesByScope = newCategories;
      if (newScheduleConfig != null) _scheduleConfig = newScheduleConfig;
      _notifEnabled = newNotifEnabled;
      _dailyReminderEnabled = newDailyReminderEnabled;
      _dailyReminderHour = newDailyReminderHour;
      _dailyReminderMinute = newDailyReminderMinute;

      _recalculateSAW();
      await _runScheduler();
      await _saveTasks();
      await _saveCustomData();
      await _saveSchedule();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notif_enabled', _notifEnabled);
      await prefs.setBool('daily_reminder_enabled', _dailyReminderEnabled);
      await prefs.setInt('daily_reminder_hour', _dailyReminderHour);
      await prefs.setInt('daily_reminder_minute', _dailyReminderMinute);
      if (_notifEnabled) await _rescheduleAllNotifications();

      notifyListeners();
      return (success: true, error: null);
    } catch (e) {
      return (success: false, error: 'Gagal membaca file: $e');
    }
  }
}
