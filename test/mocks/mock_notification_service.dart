import 'package:tugasku/services/notification_service.dart';
import 'package:tugasku/models/task_model.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class MockNotificationService implements NotificationService {
  @override
  Future<void> initialize() async {}

  @override
  Future<void> scheduleTaskNotifications(Task task) async {}

  @override
  Future<void> cancelTaskNotifications(String taskId) async {}

  @override
  Future<void> cancelAllNotifications() async {}

  @override
  Future<void> scheduleDailyReminder({
    int hour = 8,
    int minute = 0,
    required int activeTasks,
  }) async {}

  @override
  Future<void> cancelDailyReminder() async {}

  @override
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return [];
  }

  @override
  Future<bool> requestPermission() async {
    return true;
  }

  @override
  Future<bool> areNotificationsEnabled() async {
    return true;
  }
}
