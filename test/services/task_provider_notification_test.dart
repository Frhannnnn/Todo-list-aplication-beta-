import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tugasku/services/task_provider.dart';
import 'package:tugasku/models/task_model.dart';

void main() {
  group('TaskProvider - Notification Settings Management', () {
    late TaskProvider taskProvider;

    setUp(() async {
      // Clear all persisted data first
      SharedPreferences.setMockInitialValues({});
      
      // Initialize TaskProvider
      taskProvider = TaskProvider();
      await taskProvider._init();
    });

    tearDown(() async {
      await taskProvider.clearAllTasks();
    });

    // ─────────────────────────────────────────────
    // 4.1 Test Notification Enable/Disable
    // ─────────────────────────────────────────────

    group('Notification Settings', () {
      test('Skenario Enable/Disable Notification: Enable notification', () async {
        // Arrange
        await taskProvider.setNotifEnabled(false);
        expect(taskProvider.notifEnabled, false);

        // Act
        await taskProvider.setNotifEnabled(true);

        // Assert
        expect(taskProvider.notifEnabled, true);
      });

      test('Skenario Enable/Disable Notification: Disable notification', () async {
        // Arrange
        expect(taskProvider.notifEnabled, true); // Default is enabled

        // Act
        await taskProvider.setNotifEnabled(false);

        // Assert
        expect(taskProvider.notifEnabled, false);
      });

      test('Skenario Persistent Notification Setting: Setting saved', () async {
        // Act
        await taskProvider.setNotifEnabled(false);

        // Assert
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('notif_enabled'), false);
      });

      test('Skenario Load Notification Setting: Setting loaded on init', () async {
        // Arrange
        await taskProvider.setNotifEnabled(false);

        // Act
        final newProvider = TaskProvider();
        await newProvider._init();

        // Assert
        expect(newProvider.notifEnabled, false);
      });
    });

    // ─────────────────────────────────────────────
    // 4.2 Test Daily Reminder Setup
    // ─────────────────────────────────────────────

    group('Daily Reminder Settings', () {
      test('Skenario Daily Reminder Setup: Set reminder dengan custom time', () async {
        // Act
        await taskProvider.setDailyReminder(
          enabled: true,
          hour: 9,
          minute: 30,
        );

        // Assert
        expect(taskProvider.dailyReminderEnabled, true);
        expect(taskProvider.dailyReminderHour, 9);
        expect(taskProvider.dailyReminderMinute, 30);
      });

      test('Skenario Daily Reminder Setup: Enable/disable reminder', () async {
        // Act
        await taskProvider.setDailyReminder(enabled: false);

        // Assert
        expect(taskProvider.dailyReminderEnabled, false);
      });

      test('Skenario Daily Reminder Persistent: Setting saved and loaded', () async {
        // Arrange
        await taskProvider.setDailyReminder(
          enabled: true,
          hour: 10,
          minute: 15,
        );

        // Act
        final newProvider = TaskProvider();
        await newProvider._init();

        // Assert
        expect(newProvider.dailyReminderEnabled, true);
        expect(newProvider.dailyReminderHour, 10);
        expect(newProvider.dailyReminderMinute, 15);
      });

      test('Skenario Invalid Time: Hour > 23', () async {
        // Act
        await taskProvider.setDailyReminder(
          enabled: true,
          hour: 25,
          minute: 0,
        );

        // Assert - Should still set (validation is optional or should be added)
        // This test documents the current behavior - adjust based on actual implementation
        expect(taskProvider.dailyReminderHour, 25);
      });

      test('Skenario Invalid Time: Minute > 59', () async {
        // Act
        await taskProvider.setDailyReminder(
          enabled: true,
          hour: 10,
          minute: 61,
        );

        // Assert
        expect(taskProvider.dailyReminderMinute, 61);
      });

      test('Skenario Default Reminder Settings: Default values', () async {
        // Assert
        expect(taskProvider.dailyReminderEnabled, true); // Default enabled
        expect(taskProvider.dailyReminderHour, 8); // Default 8 AM
        expect(taskProvider.dailyReminderMinute, 0); // Default 00 minutes
      });
    });

    // ─────────────────────────────────────────────
    // 4.3 Test Pending Notifications
    // ─────────────────────────────────────────────

    group('Pending Notifications', () {
      test('Skenario Get Pending: Retrieve pending notifications', () async {
        // Act
        final pendingNotifications = await taskProvider.getPendingNotifications();

        // Assert
        expect(pendingNotifications, isNotNull);
        expect(pendingNotifications is List, true);
      });

      test('Skenario Get Pending: Empty when no notifications', () async {
        // Act
        final pendingNotifications = await taskProvider.getPendingNotifications();

        // Assert
        expect(pendingNotifications.isEmpty, true);
      });

      test('Skenario Get Pending: With active tasks', () async {
        // Arrange
        await taskProvider.tambahTugas(
          namaTugas: 'Task with notification',
          lingkupTugas: 'Scope',
          deadline: DateTime.now().add(const Duration(days: 1)),
          tingkatKepentingan: 3,
          estimasiWaktu: 2,
          notifEnabled: true,
        );

        // Act
        final pendingNotifications = await taskProvider.getPendingNotifications();

        // Assert
        expect(pendingNotifications, isNotNull);
      });
    });

    // ─────────────────────────────────────────────
    // Edge Cases
    // ─────────────────────────────────────────────

    group('Notification Edge Cases', () {
      test('Skenario Toggle Notification Multiple Times', () async {
        // Act
        await taskProvider.setNotifEnabled(false);
        await taskProvider.setNotifEnabled(true);
        await taskProvider.setNotifEnabled(false);
        await taskProvider.setNotifEnabled(true);

        // Assert
        expect(taskProvider.notifEnabled, true);
      });

      test('Skenario Change Reminder Time Multiple Times', () async {
        // Act
        await taskProvider.setDailyReminder(enabled: true, hour: 8, minute: 0);
        await taskProvider.setDailyReminder(enabled: true, hour: 10, minute: 30);
        await taskProvider.setDailyReminder(enabled: true, hour: 14, minute: 45);

        // Assert
        expect(taskProvider.dailyReminderHour, 14);
        expect(taskProvider.dailyReminderMinute, 45);
      });

      test('Skenario Disable Notification with Active Tasks', () async {
        // Arrange
        await taskProvider.tambahTugas(
          namaTugas: 'Task 1',
          lingkupTugas: 'Scope',
          deadline: DateTime.now().add(const Duration(days: 1)),
          tingkatKepentingan: 3,
          estimasiWaktu: 2,
          notifEnabled: true,
        );

        // Act
        await taskProvider.setNotifEnabled(false);

        // Assert
        expect(taskProvider.notifEnabled, false);
      });
    });
  });
}
