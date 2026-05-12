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

  Future<void> initialize() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();

    // Coba set timezone lokal - fallback ke Asia/Jakarta
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

    // Buat notification channels (Android 8+)
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

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(deadline);
    await androidPlugin?.createNotificationChannel(reminder);
    await androidPlugin?.createNotificationChannel(overdue);
  }

  void _onNotificationTap(NotificationResponse response) {
    debugPrint('Notifikasi ditekan: ${response.payload}');
  }

  /// Minta izin notifikasi (Android 13+)
  Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final granted = await android?.requestNotificationsPermission();
    return granted ?? false;
  }

  // ─────────────────────────────────────────────
  // SCHEDULE NOTIFIKASI UNTUK SATU TUGAS
  // ─────────────────────────────────────────────

  Future<void> scheduleTaskNotifications(Task task) async {
    if (!_isInitialized) await initialize();

    await cancelTaskNotifications(task.id);

    final now = DateTime.now();

    if (task.status == TaskStatus.selesai) return;

    if (task.deadline.isBefore(now)) {
      await _showOverdueNotification(task);
      return;
    }

    final sisaJam = task.deadline.difference(now).inHours;

    if (sisaJam >= 72) {
      final notifTime = task.deadline.subtract(const Duration(days: 3));
      if (notifTime.isAfter(now)) {
        await _scheduleNotification(
          id: _taskNotifId(task.id, 1),
          title: '📅 Deadline 3 Hari Lagi',
          body:
              '"${task.namaTugas}" (${task.mataKuliah}) deadline dalam 3 hari.',
          scheduledTime: notifTime,
          channelId: _channelIdReminder,
          payload: task.id,
        );
      }
    }

    if (sisaJam >= 24) {
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

    if (sisaJam >= 3) {
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

    if (task.deadline.isAfter(now)) {
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
      '"${task.namaTugas}" sudah melewati deadline. Segera hubungi dosen!',
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
  // PENGINGAT HARIAN
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

    await _plugin.zonedSchedule(
      9999,
      '📚 Selamat Pagi, Mahasiswa!',
      'Kamu punya $activeTasks tugas yang belum selesai. Yuk cek TugasKu!',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelIdReminder,
          'Pengingat Tugas',
          importance: Importance.defaultImportance,
          styleInformation: BigTextStyleInformation(''),
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation
              .absoluteTime, // Diperbaiki di sini
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

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tzTime,
      NotificationDetails(
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
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation
              .absoluteTime, // Diperbaiki di sini
    );
  }

  int _taskNotifId(String taskId, int type) {
    final hash = taskId.replaceAll('-', '').substring(0, 7);
    return int.parse(hash, radix: 16) % 100000 + type;
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
