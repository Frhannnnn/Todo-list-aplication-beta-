// test/screens/schedule_settings_screen_test.dart
//
// Unit tests for Primary Work Hours settings.
// Tests the ScheduleConfig model's default values, cross-midnight support,
// minimum range validation logic from the settings screen, and
// updateScheduleConfig triggering reschedule via TaskProvider.
//
// **Validates: Requirements 6.1**

import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tugasku/models/schedule_config_model.dart';
import 'package:tugasku/services/task_provider.dart';

/// Replicates the validation logic from ScheduleSettingsScreen.
/// Returns the duration in minutes between start and end,
/// supporting cross-midnight configurations.
int calculateDurationMinutes(int startHour, int startMinute, int endHour, int endMinute) {
  final startMinutes = startHour * 60 + startMinute;
  final endMinutes = endHour * 60 + endMinute;

  if (endMinutes > startMinutes) {
    return endMinutes - startMinutes;
  } else if (endMinutes < startMinutes) {
    // Cross-midnight: e.g., 22:00–06:00 = (24*60 - 22*60) + 6*60 = 480 min
    return (24 * 60 - startMinutes) + endMinutes;
  } else {
    // start == end means 0 duration
    return 0;
  }
}

/// Replicates the validation logic: returns error message or null if valid.
String? validateWorkHours(int startHour, int startMinute, int endHour, int endMinute) {
  final duration = calculateDurationMinutes(startHour, startMinute, endHour, endMinute);
  if (duration < 60) {
    return 'Rentang jam kerja minimal 1 jam';
  }
  return null;
}

void main() {
  group('Primary Work Hours Settings', () {
    group('Default values', () {
      test('ScheduleConfig default values are 08:00-17:00', () {
        final config = ScheduleConfig();
        expect(config.workStartHour, 8);
        expect(config.workStartMinute, 0);
        expect(config.workEndHour, 17);
        expect(config.workEndMinute, 0);
      });

      test('default config is not cross-midnight', () {
        final config = ScheduleConfig();
        expect(config.isCrossMidnight, false);
      });

      test('default config duration is 9 hours (540 minutes)', () {
        final duration = calculateDurationMinutes(8, 0, 17, 0);
        expect(duration, 540);
      });

      test('default config passes validation', () {
        final error = validateWorkHours(8, 0, 17, 0);
        expect(error, isNull);
      });
    });

    group('Cross-midnight configuration serialization', () {
      test('cross-midnight config (22:00-06:00) serializes correctly', () {
        final config = ScheduleConfig(
          workStartHour: 22,
          workStartMinute: 0,
          workEndHour: 6,
          workEndMinute: 0,
        );

        final json = config.toJson();
        expect(json['workStartHour'], 22);
        expect(json['workStartMinute'], 0);
        expect(json['workEndHour'], 6);
        expect(json['workEndMinute'], 0);
      });

      test('cross-midnight config (22:00-06:00) deserializes correctly', () {
        final json = {
          'workStartHour': 22,
          'workStartMinute': 0,
          'workEndHour': 6,
          'workEndMinute': 0,
        };
        final config = ScheduleConfig.fromJson(json);
        expect(config.workStartHour, 22);
        expect(config.workStartMinute, 0);
        expect(config.workEndHour, 6);
        expect(config.workEndMinute, 0);
        expect(config.isCrossMidnight, true);
      });

      test('cross-midnight config round-trip preserves values', () {
        final original = ScheduleConfig(
          workStartHour: 22,
          workStartMinute: 30,
          workEndHour: 6,
          workEndMinute: 15,
        );
        final restored = ScheduleConfig.fromJson(original.toJson());
        expect(restored.workStartHour, original.workStartHour);
        expect(restored.workStartMinute, original.workStartMinute);
        expect(restored.workEndHour, original.workEndHour);
        expect(restored.workEndMinute, original.workEndMinute);
        expect(restored.isCrossMidnight, original.isCrossMidnight);
      });

      test('cross-midnight config (23:00-01:00) duration is 2 hours', () {
        final duration = calculateDurationMinutes(23, 0, 1, 0);
        expect(duration, 120);
      });

      test('cross-midnight config (22:00-06:00) duration is 8 hours', () {
        final duration = calculateDurationMinutes(22, 0, 6, 0);
        expect(duration, 480);
      });

      test('cross-midnight config passes validation when >= 1 hour', () {
        final error = validateWorkHours(22, 0, 6, 0);
        expect(error, isNull);
      });
    });

    group('Minimum range validation', () {
      test('start == end (same time) should be invalid (0 duration)', () {
        final error = validateWorkHours(10, 0, 10, 0);
        expect(error, isNotNull);
        expect(error, 'Rentang jam kerja minimal 1 jam');
      });

      test('duration of 30 minutes should be invalid', () {
        final error = validateWorkHours(8, 0, 8, 30);
        expect(error, isNotNull);
        expect(error, 'Rentang jam kerja minimal 1 jam');
      });

      test('duration of 59 minutes should be invalid', () {
        final error = validateWorkHours(8, 0, 8, 59);
        expect(error, isNotNull);
        expect(error, 'Rentang jam kerja minimal 1 jam');
      });

      test('duration of exactly 60 minutes should be valid', () {
        final error = validateWorkHours(8, 0, 9, 0);
        expect(error, isNull);
      });

      test('cross-midnight with less than 1 hour should be invalid', () {
        // 23:30 to 00:00 = 30 minutes
        final error = validateWorkHours(23, 30, 0, 0);
        expect(error, isNotNull);
        expect(error, 'Rentang jam kerja minimal 1 jam');
      });

      test('cross-midnight with exactly 1 hour should be valid', () {
        // 23:00 to 00:00 = 60 minutes
        final error = validateWorkHours(23, 0, 0, 0);
        expect(error, isNull);
      });
    });

    group('updateScheduleConfig triggers reschedule', () {
      TestWidgetsFlutterBinding.ensureInitialized();

      setUp(() {
        // Mock the flutter_local_notifications plugin channel
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          const MethodChannel('dexterous.com/flutter/local_notifications'),
          (MethodCall methodCall) async {
            // Return appropriate mock responses for notification plugin
            if (methodCall.method == 'initialize') return true;
            if (methodCall.method == 'getNotificationAppLaunchDetails') return null;
            if (methodCall.method == 'pendingNotificationRequests') return <Map<String, dynamic>>[];
            if (methodCall.method == 'cancelAll') return null;
            if (methodCall.method == 'cancel') return null;
            if (methodCall.method == 'zonedSchedule') return null;
            if (methodCall.method == 'requestNotificationsPermission') return true;
            return null;
          },
        );

        // Set up mock SharedPreferences with empty data
        SharedPreferences.setMockInitialValues({});
      });

      tearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          const MethodChannel('dexterous.com/flutter/local_notifications'),
          null,
        );
      });

      test('updateScheduleConfig saves new config and triggers reschedule', () async {
        SharedPreferences.setMockInitialValues({
          'tugasku_tasks': jsonEncode([]),
          'tugasku_schedule_blocks': jsonEncode([]),
          'tugasku_schedule_config': jsonEncode(ScheduleConfig().toJson()),
        });

        final provider = TaskProvider();
        // Wait for initialization
        await Future.delayed(const Duration(milliseconds: 200));

        // Verify initial config is default
        expect(provider.scheduleConfig.workStartHour, 8);
        expect(provider.scheduleConfig.workEndHour, 17);

        // Update config to cross-midnight
        final newConfig = ScheduleConfig(
          workStartHour: 22,
          workStartMinute: 0,
          workEndHour: 6,
          workEndMinute: 0,
        );
        await provider.updateScheduleConfig(newConfig);

        // Verify config was updated
        expect(provider.scheduleConfig.workStartHour, 22);
        expect(provider.scheduleConfig.workStartMinute, 0);
        expect(provider.scheduleConfig.workEndHour, 6);
        expect(provider.scheduleConfig.workEndMinute, 0);

        // Verify config was persisted
        final prefs = await SharedPreferences.getInstance();
        final savedConfigStr = prefs.getString('tugasku_schedule_config');
        expect(savedConfigStr, isNotNull);
        final savedConfig = ScheduleConfig.fromJson(
          jsonDecode(savedConfigStr!) as Map<String, dynamic>,
        );
        expect(savedConfig.workStartHour, 22);
        expect(savedConfig.workEndHour, 6);
      });

      test('updateScheduleConfig reschedules existing tasks with new work hours', () async {
        final now = DateTime.now();
        final futureDeadline = DateTime(
          now.year, now.month, now.day + 2, 17, 0,
        );

        // Set up a task in SharedPreferences
        final taskData = {
          'id': 'test-task-1',
          'namaTugas': 'Test Task',
          'mataKuliah': 'Test MK',
          'deadline': futureDeadline.toIso8601String(),
          'tingkatKepentingan': 4,
          'tingkatUrgensi': 3,
          'estimasiWaktu': 2,
          'status': 0,
          'group': 0,
          'category': 0,
          'createdAt': now.subtract(const Duration(hours: 1)).toIso8601String(),
          'sawScore': 0.75,
          'ranking': 1,
        };

        SharedPreferences.setMockInitialValues({
          'tugasku_tasks': jsonEncode([taskData]),
          'tugasku_schedule_blocks': jsonEncode([]),
          'tugasku_schedule_config': jsonEncode(ScheduleConfig().toJson()),
        });

        final provider = TaskProvider();
        // Wait for initialization and scheduling
        await Future.delayed(const Duration(milliseconds: 500));

        // Should have time blocks scheduled for the task
        final blocksBeforeUpdate = provider.getTimeBlocksForTask('test-task-1');

        // Update config to different work hours
        final newConfig = ScheduleConfig(
          workStartHour: 10,
          workStartMinute: 0,
          workEndHour: 14,
          workEndMinute: 0,
        );
        await provider.updateScheduleConfig(newConfig);

        // After update, blocks should be rescheduled
        final blocksAfterUpdate = provider.getTimeBlocksForTask('test-task-1');

        // The task should still have time blocks (reschedule doesn't remove tasks)
        expect(blocksAfterUpdate, isNotEmpty);
        // The schedule config should be updated
        expect(provider.scheduleConfig.workStartHour, 10);
        expect(provider.scheduleConfig.workEndHour, 14);
      });
    });
  });
}
