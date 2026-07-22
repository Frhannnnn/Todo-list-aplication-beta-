// lib/services/notification_service.dart

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/task_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  // Channel IDs
  static const String _channelIdDeadline = 'tugasku_deadline';
  static const String _channelIdReminder = 'tugasku_reminder';
  static const String _channelIdOverdue = 'tugasku_overdue';
  static const String _channelIdFocus = 'tugasku_focus';

  // ID notifikasi sesi fokus (foreground)
  static const int _focusNotifId = 8888;

  /// Dipanggil saat aksi notifikasi sesi fokus ditekan ('focus_pause'/'focus_end').
  void Function(String actionId)? onFocusAction;

  Future<void> initialize() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();

    try {
      tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    await _createChannels();
    _isInitialized = true;
  }

  Future<void> _createChannels() async {
    const deadline = AndroidNotificationChannel(
      _channelIdDeadline,
      'Deadline Tugas',
      description: 'Notifikasi mendekati deadline tugas',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    const reminder = AndroidNotificationChannel(
      _channelIdReminder,
      'Pengingat Tugas',
      description: 'Pengingat harian tugas yang belum selesai',
      importance: Importance.defaultImportance,
      playSound: true,
    );

    const overdue = AndroidNotificationChannel(
      _channelIdOverdue,
      'Tugas Terlambat',
      description: 'Notifikasi tugas yang sudah melewati deadline',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    const focus = AndroidNotificationChannel(
      _channelIdFocus,
      'Sesi Fokus',
      description: 'Notifikasi sesi fokus yang sedang berjalan',
      importance: Importance.low,
      playSound: false,
    );

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(deadline);
    await androidPlugin?.createNotificationChannel(reminder);
    await androidPlugin?.createNotificationChannel(overdue);
    await androidPlugin?.createNotificationChannel(focus);
  }

  void _onNotificationTap(NotificationResponse response) {
    final actionId = response.actionId;
    if (actionId != null && actionId.isNotEmpty) {
      onFocusAction?.call(actionId);
    }
  }

  // ─────────────────────────────────────────────
  // NOTIFIKASI SESI FOKUS (foreground, ongoing)
  // ─────────────────────────────────────────────

  /// Tampilkan/perbarui notifikasi sesi fokus yang sedang berjalan.
  /// Saat [running], memakai chronometer Android (hitung mundur native).
  Future<void> showFocusNotification({
    required String taskName,
    required Duration remaining,
    required bool running,
    required bool isBreak,
  }) async {
    if (!_isInitialized) await initialize();

    final title = isBreak ? '☕ Istirahat' : '🎯 Sedang Fokus';
    final body = running
        ? taskName
        : '$taskName • Dijeda (${_fmtDuration(remaining)})';
    final endMs = DateTime.now().add(remaining).millisecondsSinceEpoch;

    final android = AndroidNotificationDetails(
      _channelIdFocus,
      'Sesi Fokus',
      channelDescription: 'Sesi fokus berjalan',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      onlyAlertOnce: true,
      showWhen: running,
      usesChronometer: running,
      chronometerCountDown: running,
      when: running ? endMs : null,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction('focus_pause', running ? 'Jeda' : 'Lanjut'),
        const AndroidNotificationAction('focus_end', 'Akhiri'),
      ],
    );

    await _plugin.show(
      _focusNotifId,
      title,
      body,
      NotificationDetails(android: android),
    );
  }

  Future<void> cancelFocusNotification() => _plugin.cancel(_focusNotifId);

  String _fmtDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  /// Minta izin notifikasi (Android 13+)
  Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final granted = await android?.requestNotificationsPermission();
    return granted ?? false;
  }

  // ─────────────────────────────────────────────
  // SCHEDULE NOTIFIKASI PER-TUGAS
  // Menghormati task.notifEnabled dan task.notifSchedule
  // ─────────────────────────────────────────────

  Future<void> scheduleTaskNotifications(Task task) async {
    if (!_isInitialized) await initialize();

    await cancelTaskNotifications(task.id);

    // Jika notif dinonaktifkan untuk tugas ini, stop.
    if (!task.notifEnabled) return;

    final now = DateTime.now();
    if (task.status == TaskStatus.selesai) return;

    if (task.deadline.isBefore(now)) {
      await _showOverdueNotification(task);
      return;
    }

    final schedule = task.notifSchedule;
    final sisaJam = task.deadline.difference(now).inHours;

    // H-3 hari
    if (schedule.contains('h-3') && sisaJam >= 72) {
      final notifTime = task.deadline.subtract(const Duration(days: 3));
      if (notifTime.isAfter(now)) {
        await _scheduleNotification(
          id: _taskNotifId(task.id, 1),
          title: '📅 Deadline 3 Hari Lagi',
          body: '"${task.namaTugas}" (${task.lingkupTugas}) deadline dalam 3 hari.',
          scheduledTime: notifTime,
          channelId: _channelIdReminder,
          payload: task.id,
        );
      }
    }

    // H-1 hari
    if (schedule.contains('h-1') && sisaJam >= 24) {
      final notifTime = task.deadline.subtract(const Duration(hours: 24));
      if (notifTime.isAfter(now)) {
        await _scheduleNotification(
          id: _taskNotifId(task.id, 2),
          title: '⚠️ Deadline Besok!',
          body: '"${task.namaTugas}" harus diselesaikan sebelum besok!',
          scheduledTime: notifTime,
          channelId: _channelIdDeadline,
          payload: task.id,
        );
      }
    }

    // H-3 jam
    if (schedule.contains('3jam') && sisaJam >= 3) {
      final notifTime = task.deadline.subtract(const Duration(hours: 3));
      if (notifTime.isAfter(now)) {
        await _scheduleNotification(
          id: _taskNotifId(task.id, 3),
          title: '🚨 Deadline 3 Jam Lagi!',
          body: '"${task.namaTugas}" deadline dalam 3 jam. Segera selesaikan!',
          scheduledTime: notifTime,
          channelId: _channelIdDeadline,
          payload: task.id,
        );
      }
    }

    // Tepat deadline
    if (schedule.contains('deadline') && task.deadline.isAfter(now)) {
      await _scheduleNotification(
        id: _taskNotifId(task.id, 4),
        title: '🔔 Deadline Sekarang!',
        body: '"${task.namaTugas}" sudah mencapai deadline!',
        scheduledTime: task.deadline,
        channelId: _channelIdOverdue,
        payload: task.id,
      );
    }
  }

  Future<void> _showOverdueNotification(Task task) async {
    await _plugin.show(
      _taskNotifId(task.id, 0),
      '❌ Tugas Terlambat!',
      '"${task.namaTugas}" sudah melewati deadline.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelIdOverdue,
          'Tugas Terlambat',
          importance: Importance.max,
          priority: Priority.high,
          color: Color(0xFFEF4444),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: task.id,
    );
  }

  Future<void> cancelTaskNotifications(String taskId) async {
    for (int i = 0; i <= 4; i++) {
      await _plugin.cancel(_taskNotifId(taskId, i));
    }
  }

  Future<void> cancelAllNotifications() async {
    await _plugin.cancelAll();
  }

  // ─────────────────────────────────────────────
  // PENGINGAT HARIAN (tetap global)
  // ─────────────────────────────────────────────

  Future<void> scheduleDailyReminder({
    int hour = 8,
    int minute = 0,
    required int activeTasks,
  }) async {
    if (!_isInitialized) await initialize();

    await _plugin.cancel(9999);

    if (activeTasks == 0) return;

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _zonedScheduleSafe(
      id: 9999,
      title: '📚 Selamat Pagi!',
      body: 'Kamu punya $activeTasks tugas yang belum selesai. Yuk cek Priora!',
      when: scheduledDate,
      details: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelIdReminder,
          'Pengingat Tugas',
          importance: Importance.defaultImportance,
          styleInformation: BigTextStyleInformation(''),
        ),
        iOS: DarwinNotificationDetails(),
      ),
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelDailyReminder() async {
    await _plugin.cancel(9999);
  }

  // ─────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required String channelId,
    String? payload,
  }) async {
    final tzTime = tz.TZDateTime.from(scheduledTime, tz.local);

    await _zonedScheduleSafe(
      id: id,
      title: title,
      body: body,
      when: tzTime,
      details: NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelId == _channelIdDeadline
              ? 'Deadline Tugas'
              : channelId == _channelIdOverdue
                  ? 'Tugas Terlambat'
                  : 'Pengingat Tugas',
          importance:
              channelId == _channelIdOverdue ? Importance.max : Importance.high,
          priority: Priority.high,
          color: channelId == _channelIdOverdue
              ? const Color(0xFFEF4444)
              : const Color(0xFF2563EB),
          styleInformation: BigTextStyleInformation(body),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }

  /// Jadwalkan notifikasi dengan mode alarm tepat. Bila izin
  /// SCHEDULE_EXACT_ALARM tidak tersedia (Android 12+), plugin melempar
  /// PlatformException — kita turunkan ke mode inexact agar notifikasi tetap
  /// terjadwal (meski tidak presisi ke detik) dan proses simpan tugas tidak
  /// ikut gagal. Kegagalan penjadwalan tidak boleh menggagalkan simpan tugas.
  Future<void> _zonedScheduleSafe({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime when,
    required NotificationDetails details,
    String? payload,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        when,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: matchDateTimeComponents,
      );
    } catch (_) {
      // Fallback: mode inexact tidak butuh izin exact alarm.
      try {
        await _plugin.zonedSchedule(
          id,
          title,
          body,
          when,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: payload,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: matchDateTimeComponents,
        );
      } catch (_) {
        // Platform tanpa dukungan penjadwalan — abaikan, jangan sampai
        // menggagalkan alur simpan tugas.
      }
    }
  }

  // Bug #8 Fix: Use larger range dan better hashing untuk prevent collision
  int _taskNotifId(String taskId, int type) {
    // 32-bit integer max is 2147483647. We need baseId * 10 + type < 2147483647
    // So baseId must be < 214748364
    final baseId = taskId.hashCode.abs() % 200000000;
    return baseId * 10 + type; // Ensure type differentiation
  }

  Future<bool> areNotificationsEnabled() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    return await android?.areNotificationsEnabled() ?? false;
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _plugin.pendingNotificationRequests();
  }
}
