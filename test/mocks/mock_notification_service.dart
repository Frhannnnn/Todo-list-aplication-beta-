import 'package:mockito/mockito.dart';
import 'package:tugasku/services/notification_service.dart';
import 'package:tugasku/models/task_model.dart';

class MockNotificationService extends Mock implements NotificationService {
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
    required int hour,
    required int minute,
    required int activeTasks,
  }) async {}

  @override
  Future<void> cancelDailyReminder() async {}

  @override
  Future<List<dynamic>> getPendingNotifications() async {
    return [];
  }

  @override
  Future<bool> requestPermission() async {
    return true;
  }
}
