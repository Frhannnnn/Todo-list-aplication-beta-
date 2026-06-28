// test/services/smart_scheduling_integration_test.dart
//
// Integration tests for the Smart Scheduling feature.
// Tests the full integration flow between SAW Service, Smart Scheduler Service,
// TaskProvider, and SharedPreferences persistence.
//
// Validates: Requirements 8.2, 9.1, 9.2, 10.5

import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tugasku/models/task_model.dart';
import 'package:tugasku/models/time_block_model.dart';
import 'package:tugasku/models/schedule_config_model.dart';
import 'package:tugasku/services/task_provider.dart';
import 'package:tugasku/services/ai_task_creator_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Mock the flutter_local_notifications plugin channel
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dexterous.com/flutter/local_notifications'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'initialize') return true;
        if (methodCall.method == 'getNotificationAppLaunchDetails') return null;
        if (methodCall.method == 'pendingNotificationRequests') {
          return <Map<String, dynamic>>[];
        }
        if (methodCall.method == 'cancelAll') return null;
        if (methodCall.method == 'cancel') return null;
        if (methodCall.method == 'zonedSchedule') return null;
        if (methodCall.method == 'requestNotificationsPermission') return true;
        return null;
      },
    );

    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dexterous.com/flutter/local_notifications'),
      null,
    );
  });

  // =========================================================================
  // Test 1: Full flow - add task → SAW calculation → scheduling → persistence → reload
  // Validates: Requirements 8.2, 9.1, 9.2
  // =========================================================================
  group('Full flow: add task → SAW → scheduling → persistence → reload', () {
    test('adding a task persists schedule that can be reloaded', () async {
      SharedPreferences.setMockInitialValues({
        'tugasku_tasks': jsonEncode([]),
        'tugasku_schedule_blocks': jsonEncode([]),
        'tugasku_schedule_config': jsonEncode(ScheduleConfig().toJson()),
      });

      final provider = TaskProvider();
      await Future.delayed(const Duration(milliseconds: 200));

      final deadline = DateTime.now().add(const Duration(hours: 48));

      // Step 1: Add task (triggers SAW → scheduling → persistence)
      await provider.tambahTugas(
        namaTugas: 'Integration Test Task',
        mataKuliah: 'CS201',
        deadline: deadline,
        tingkatKepentingan: 4,
        tingkatUrgensi: 4,
        estimasiWaktu: 3,
      );

      // Step 2: Verify SAW score was calculated
      final task = provider.activeTasks.first;
      expect(task.sawScore, greaterThan(0),
          reason: 'SAW score should be calculated');

      // Step 3: Verify time blocks were generated
      final blocks = provider.getTimeBlocksForTask(task.id);
      expect(blocks.length, equals(3),
          reason: 'Should have 3 time blocks for 3-hour estimation');

      // Step 4: Verify blocks are valid (before deadline, 1-hour duration)
      for (final block in blocks) {
        expect(block.startTime.isBefore(deadline), isTrue);
        expect(block.endTime.difference(block.startTime).inHours, equals(1));
        expect(block.startTime.minute, equals(0));
        expect(block.startTime.second, equals(0));
      }

      // Step 5: Verify persistence - read SharedPreferences directly
      final prefs = await SharedPreferences.getInstance();
      final savedBlocksJson = prefs.getString('tugasku_schedule_blocks');
      expect(savedBlocksJson, isNotNull,
          reason: 'Schedule blocks should be persisted to SharedPreferences');

      final savedBlocks = jsonDecode(savedBlocksJson!) as List<dynamic>;
      expect(savedBlocks.length, equals(3),
          reason: 'Persisted blocks count should match');

      // Step 6: Simulate app reload - create new provider with persisted data
      final provider2 = TaskProvider();
      await Future.delayed(const Duration(milliseconds: 300));

      // Verify reloaded schedule matches
      final reloadedBlocks = provider2.timeBlocks;
      expect(reloadedBlocks.length, greaterThanOrEqualTo(3),
          reason: 'Reloaded provider should have the persisted time blocks');
    });

    test('multiple tasks produce correct schedule after full pipeline', () async {
      SharedPreferences.setMockInitialValues({
        'tugasku_tasks': jsonEncode([]),
        'tugasku_schedule_blocks': jsonEncode([]),
        'tugasku_schedule_config': jsonEncode(ScheduleConfig().toJson()),
      });

      final provider = TaskProvider();
      await Future.delayed(const Duration(milliseconds: 200));

      final deadline1 = DateTime.now().add(const Duration(hours: 48));
      final deadline2 = DateTime.now().add(const Duration(hours: 72));

      // Add first task
      await provider.tambahTugas(
        namaTugas: 'High Priority Task',
        mataKuliah: 'CS201',
        deadline: deadline1,
        tingkatKepentingan: 5,
        tingkatUrgensi: 5,
        estimasiWaktu: 2,
      );

      // Add second task
      await provider.tambahTugas(
        namaTugas: 'Low Priority Task',
        mataKuliah: 'CS202',
        deadline: deadline2,
        tingkatKepentingan: 2,
        tingkatUrgensi: 2,
        estimasiWaktu: 2,
      );

      // Verify both tasks have SAW scores
      final highTask = provider.activeTasks
          .firstWhere((t) => t.namaTugas == 'High Priority Task');
      final lowTask = provider.activeTasks
          .firstWhere((t) => t.namaTugas == 'Low Priority Task');

      expect(highTask.sawScore, greaterThan(0));
      expect(lowTask.sawScore, greaterThan(0));

      // Verify both tasks have time blocks
      final highBlocks = provider.getTimeBlocksForTask(highTask.id);
      final lowBlocks = provider.getTimeBlocksForTask(lowTask.id);
      expect(highBlocks.length, equals(2));
      expect(lowBlocks.length, equals(2));

      // Verify no overlaps (strict monotasking)
      final allSlots = provider.timeBlocks
          .map((b) => b.startTime)
          .toSet();
      expect(allSlots.length, equals(provider.timeBlocks.length),
          reason: 'No two blocks should occupy the same slot');

      // Verify persistence
      final prefs = await SharedPreferences.getInstance();
      final savedJson = prefs.getString('tugasku_schedule_blocks');
      expect(savedJson, isNotNull);
      final savedList = jsonDecode(savedJson!) as List;
      expect(savedList.length, equals(4),
          reason: 'All 4 blocks (2+2) should be persisted');
    });

    test('schedule config is persisted and reloaded correctly', () async {
      SharedPreferences.setMockInitialValues({
        'tugasku_tasks': jsonEncode([]),
        'tugasku_schedule_blocks': jsonEncode([]),
        'tugasku_schedule_config': jsonEncode(ScheduleConfig().toJson()),
      });

      final provider = TaskProvider();
      await Future.delayed(const Duration(milliseconds: 300));

      // Update config via the proper API (which persists it)
      final customConfig = ScheduleConfig(
        workStartHour: 10,
        workStartMinute: 0,
        workEndHour: 20,
        workEndMinute: 0,
      );
      await provider.updateScheduleConfig(customConfig);

      // Verify config was updated in provider
      expect(provider.scheduleConfig.workStartHour, equals(10));
      expect(provider.scheduleConfig.workEndHour, equals(20));

      // Verify config was persisted to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final savedConfigJson = prefs.getString('tugasku_schedule_config');
      expect(savedConfigJson, isNotNull);
      final savedConfig = ScheduleConfig.fromJson(
        jsonDecode(savedConfigJson!) as Map<String, dynamic>,
      );
      expect(savedConfig.workStartHour, equals(10));
      expect(savedConfig.workEndHour, equals(20));
    });
  });

  // =========================================================================
  // Test 2: SAW recalculation triggers rescheduling within 3 seconds
  // Validates: Requirement 8.2
  // =========================================================================
  group('SAW recalculation triggers rescheduling within 3 seconds', () {
    test('editing a task triggers SAW recalculation and rescheduling within 3s',
        () async {
      SharedPreferences.setMockInitialValues({
        'tugasku_tasks': jsonEncode([]),
        'tugasku_schedule_blocks': jsonEncode([]),
        'tugasku_schedule_config': jsonEncode(ScheduleConfig().toJson()),
      });

      final provider = TaskProvider();
      await Future.delayed(const Duration(milliseconds: 200));

      final deadline = DateTime.now().add(const Duration(hours: 72));

      await provider.tambahTugas(
        namaTugas: 'Timing Test Task',
        mataKuliah: 'CS301',
        deadline: deadline,
        tingkatKepentingan: 3,
        tingkatUrgensi: 3,
        estimasiWaktu: 2,
      );

      final task = provider.activeTasks.first;
      final originalSawScore = task.sawScore;
      final originalBlocks = provider.getTimeBlocksForTask(task.id).length;

      // Measure time for edit → SAW recalculation → rescheduling
      final stopwatch = Stopwatch()..start();

      await provider.editTugas(
        task.id,
        tingkatKepentingan: 5,
        tingkatUrgensi: 5,
        estimasiWaktu: 4,
      );

      stopwatch.stop();

      // Verify SAW was recalculated (score should change with new importance/urgency)
      final updatedTask = provider.activeTasks.first;
      expect(updatedTask.sawScore, greaterThanOrEqualTo(originalSawScore),
          reason: 'SAW score should be recalculated after edit');

      // Verify rescheduling happened (block count changed from 2 to 4)
      final updatedBlocks = provider.getTimeBlocksForTask(task.id);
      expect(updatedBlocks.length, equals(4),
          reason: 'Rescheduling should produce 4 blocks for new 4-hour estimation');

      // Verify timing: entire operation within 3 seconds
      expect(stopwatch.elapsedMilliseconds, lessThan(3000),
          reason: 'SAW recalculation + rescheduling must complete within 3 seconds');
    });

    test('adding multiple tasks maintains 3-second scheduling per operation',
        () async {
      SharedPreferences.setMockInitialValues({
        'tugasku_tasks': jsonEncode([]),
        'tugasku_schedule_blocks': jsonEncode([]),
        'tugasku_schedule_config': jsonEncode(ScheduleConfig().toJson()),
      });

      final provider = TaskProvider();
      await Future.delayed(const Duration(milliseconds: 200));

      final deadline = DateTime.now().add(const Duration(hours: 96));

      // Add 5 tasks and measure each operation
      for (var i = 0; i < 5; i++) {
        final stopwatch = Stopwatch()..start();

        await provider.tambahTugas(
          namaTugas: 'Task $i',
          mataKuliah: 'CS302',
          deadline: deadline.add(Duration(hours: i * 24)),
          tingkatKepentingan: 1 + (i % 5),
          tingkatUrgensi: 1 + (i % 5),
          estimasiWaktu: 2,
        );

        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(3000),
            reason: 'Task $i: SAW + scheduling should complete within 3 seconds');
      }

      // Verify all tasks have blocks
      expect(provider.timeBlocks.isNotEmpty, isTrue);
      for (final task in provider.activeTasks) {
        expect(provider.getTimeBlocksForTask(task.id).isNotEmpty, isTrue,
            reason: '${task.namaTugas} should have time blocks');
      }
    });

    test('deleting a task triggers rescheduling within 3 seconds', () async {
      SharedPreferences.setMockInitialValues({
        'tugasku_tasks': jsonEncode([]),
        'tugasku_schedule_blocks': jsonEncode([]),
        'tugasku_schedule_config': jsonEncode(ScheduleConfig().toJson()),
      });

      final provider = TaskProvider();
      await Future.delayed(const Duration(milliseconds: 200));

      final deadline = DateTime.now().add(const Duration(hours: 48));

      await provider.tambahTugas(
        namaTugas: 'Task A',
        mataKuliah: 'CS303',
        deadline: deadline,
        tingkatKepentingan: 5,
        tingkatUrgensi: 5,
        estimasiWaktu: 3,
      );

      await provider.tambahTugas(
        namaTugas: 'Task B',
        mataKuliah: 'CS303',
        deadline: deadline,
        tingkatKepentingan: 3,
        tingkatUrgensi: 3,
        estimasiWaktu: 3,
      );

      final taskA = provider.activeTasks
          .firstWhere((t) => t.namaTugas == 'Task A');

      final stopwatch = Stopwatch()..start();
      await provider.hapusTugas(taskA.id);
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(3000),
          reason: 'Delete + SAW recalculation + rescheduling within 3 seconds');

      // Task B should still have blocks after rescheduling
      final taskB = provider.activeTasks
          .firstWhere((t) => t.namaTugas == 'Task B');
      expect(provider.getTimeBlocksForTask(taskB.id).isNotEmpty, isTrue);
    });
  });

  // =========================================================================
  // Test 3: AI task creation → confirmation → SAW + scheduling pipeline
  // Validates: Requirement 10.5
  // =========================================================================
  group('AI task creation → confirmation → SAW + scheduling pipeline', () {
    test('AI-extracted tasks trigger SAW and scheduling after confirmation',
        () async {
      SharedPreferences.setMockInitialValues({
        'tugasku_tasks': jsonEncode([]),
        'tugasku_schedule_blocks': jsonEncode([]),
        'tugasku_schedule_config': jsonEncode(ScheduleConfig().toJson()),
      });

      final provider = TaskProvider();
      await Future.delayed(const Duration(milliseconds: 200));

      // Step 1: Use AI service to extract tasks from text
      final aiService = AITaskCreatorService();
      const inputText = '''
Tugas Besar Pemrograman Web - membuat aplikasi full stack
Laporan Praktikum Basis Data - normalisasi dan query
Quiz Algoritma dan Struktur Data minggu ini
Presentasi Project Machine Learning
Makalah Etika Profesi tentang AI
''';

      final suggestions = await aiService.extractTasks(inputText);
      expect(suggestions.isNotEmpty, isTrue,
          reason: 'AI should extract tasks from input text');

      // Step 2: Simulate user confirmation - add selected tasks to provider
      final deadline = DateTime.now().add(const Duration(hours: 96));
      for (final suggestion in suggestions.take(3)) {
        await provider.tambahTugas(
          namaTugas: suggestion.namaTugas,
          mataKuliah: 'AI Generated',
          deadline: deadline,
          tingkatKepentingan: suggestion.tingkatKepentingan,
          tingkatUrgensi: suggestion.tingkatUrgensi,
          estimasiWaktu: suggestion.estimasiWaktu,
        );
      }

      // Step 3: Verify SAW scores are calculated for all tasks
      for (final task in provider.activeTasks) {
        expect(task.sawScore, greaterThan(0),
            reason: '${task.namaTugas} should have SAW score after pipeline');
      }

      // Step 4: Verify scheduling produced time blocks for all tasks
      for (final task in provider.activeTasks) {
        final blocks = provider.getTimeBlocksForTask(task.id);
        expect(blocks.isNotEmpty, isTrue,
            reason: '${task.namaTugas} should have time blocks after pipeline');
        expect(blocks.length, equals(task.estimasiWaktu),
            reason: 'Block count should match estimation');
      }

      // Step 5: Verify no overlaps in the combined schedule
      final allSlots = provider.timeBlocks.map((b) => b.startTime).toSet();
      expect(allSlots.length, equals(provider.timeBlocks.length),
          reason: 'No overlaps should exist after AI task scheduling');
    });

    test('AI extraction validates input length before processing', () async {
      final aiService = AITaskCreatorService();

      // Input too short (< 50 characters)
      expect(
        () => aiService.extractTasks('Short input'),
        throwsA(isA<AIExtractionException>().having(
          (e) => e.reason,
          'reason',
          AIExtractionFailureReason.inputTooShort,
        )),
      );
    });

    test('AI-created tasks integrate with existing tasks in schedule',
        () async {
      SharedPreferences.setMockInitialValues({
        'tugasku_tasks': jsonEncode([]),
        'tugasku_schedule_blocks': jsonEncode([]),
        'tugasku_schedule_config': jsonEncode(ScheduleConfig().toJson()),
      });

      final provider = TaskProvider();
      await Future.delayed(const Duration(milliseconds: 200));

      final deadline = DateTime.now().add(const Duration(hours: 72));

      // Add a manual task first
      await provider.tambahTugas(
        namaTugas: 'Existing Manual Task',
        mataKuliah: 'CS401',
        deadline: deadline,
        tingkatKepentingan: 5,
        tingkatUrgensi: 5,
        estimasiWaktu: 2,
      );

      final manualTask = provider.activeTasks.first;
      final manualBlocks = provider.getTimeBlocksForTask(manualTask.id);
      expect(manualBlocks.length, equals(2));

      // Simulate AI task confirmation
      await provider.tambahTugas(
        namaTugas: 'AI Generated Task',
        mataKuliah: 'AI Course',
        deadline: deadline,
        tingkatKepentingan: 3,
        tingkatUrgensi: 3,
        estimasiWaktu: 2,
      );

      // Both tasks should have blocks
      final aiTask = provider.activeTasks
          .firstWhere((t) => t.namaTugas == 'AI Generated Task');
      expect(provider.getTimeBlocksForTask(aiTask.id).length, equals(2));

      // No overlaps between manual and AI tasks
      final allSlots = provider.timeBlocks.map((b) => b.startTime).toSet();
      expect(allSlots.length, equals(provider.timeBlocks.length),
          reason: 'AI tasks should not overlap with existing tasks');
    });
  });

  // =========================================================================
  // Test 4: SharedPreferences read/write cycle for schedule data
  // Validates: Requirements 9.1, 9.2
  // =========================================================================
  group('SharedPreferences read/write cycle for schedule data', () {
    test('time blocks are serialized and deserialized correctly', () async {
      SharedPreferences.setMockInitialValues({
        'tugasku_tasks': jsonEncode([]),
        'tugasku_schedule_blocks': jsonEncode([]),
        'tugasku_schedule_config': jsonEncode(ScheduleConfig().toJson()),
      });

      final provider = TaskProvider();
      await Future.delayed(const Duration(milliseconds: 200));

      final deadline = DateTime.now().add(const Duration(hours: 48));

      await provider.tambahTugas(
        namaTugas: 'Persistence Test',
        mataKuliah: 'CS501',
        deadline: deadline,
        tingkatKepentingan: 4,
        tingkatUrgensi: 4,
        estimasiWaktu: 3,
      );

      final originalBlocks = provider.timeBlocks;
      expect(originalBlocks.length, equals(3));

      // Read persisted data directly from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final blocksJson = prefs.getString('tugasku_schedule_blocks');
      expect(blocksJson, isNotNull);

      // Deserialize and verify round-trip
      final decoded = jsonDecode(blocksJson!) as List<dynamic>;
      final deserializedBlocks = decoded
          .map((json) => TimeBlock.fromJson(json as Map<String, dynamic>))
          .toList();

      expect(deserializedBlocks.length, equals(originalBlocks.length));

      for (var i = 0; i < originalBlocks.length; i++) {
        final original = originalBlocks[i];
        final deserialized = deserializedBlocks[i];
        expect(deserialized.id, equals(original.id));
        expect(deserialized.taskId, equals(original.taskId));
        expect(deserialized.startTime, equals(original.startTime));
        expect(deserialized.endTime, equals(original.endTime));
        expect(deserialized.status, equals(original.status));
        expect(deserialized.isManuallyPlaced, equals(original.isManuallyPlaced));
      }
    });

    test('schedule config is serialized and deserialized correctly', () async {
      SharedPreferences.setMockInitialValues({
        'tugasku_tasks': jsonEncode([]),
        'tugasku_schedule_blocks': jsonEncode([]),
        'tugasku_schedule_config': jsonEncode(ScheduleConfig().toJson()),
      });

      final provider = TaskProvider();
      await Future.delayed(const Duration(milliseconds: 300));

      // Update to cross-midnight config via proper API
      final crossMidnightConfig = ScheduleConfig(
        workStartHour: 22,
        workStartMinute: 0,
        workEndHour: 6,
        workEndMinute: 0,
      );
      await provider.updateScheduleConfig(crossMidnightConfig);

      // Verify config was updated
      expect(provider.scheduleConfig.workStartHour, equals(22));
      expect(provider.scheduleConfig.workStartMinute, equals(0));
      expect(provider.scheduleConfig.workEndHour, equals(6));
      expect(provider.scheduleConfig.workEndMinute, equals(0));

      // Verify cross-midnight detection
      expect(provider.scheduleConfig.isCrossMidnight, isTrue);

      // Verify persistence
      final prefs = await SharedPreferences.getInstance();
      final savedJson = prefs.getString('tugasku_schedule_config');
      expect(savedJson, isNotNull);
      final savedConfig = ScheduleConfig.fromJson(
        jsonDecode(savedJson!) as Map<String, dynamic>,
      );
      expect(savedConfig.workStartHour, equals(22));
      expect(savedConfig.workEndHour, equals(6));
      expect(savedConfig.isCrossMidnight, isTrue);
    });

    test('corrupt schedule data results in empty schedule without crash',
        () async {
      SharedPreferences.setMockInitialValues({
        'tugasku_tasks': jsonEncode([]),
        'tugasku_schedule_blocks': 'invalid json {{{',
        'tugasku_schedule_config': 'also invalid',
      });

      final provider = TaskProvider();
      await Future.delayed(const Duration(milliseconds: 200));

      // Should not crash, should have empty schedule
      expect(provider.timeBlocks, isEmpty,
          reason: 'Corrupt data should result in empty schedule');

      // Config should fall back to default
      expect(provider.scheduleConfig.workStartHour, equals(8));
      expect(provider.scheduleConfig.workEndHour, equals(17));
    });

    test('missing schedule data results in empty schedule without crash',
        () async {
      SharedPreferences.setMockInitialValues({
        'tugasku_tasks': jsonEncode([]),
        // No schedule_blocks or schedule_config keys
      });

      final provider = TaskProvider();
      await Future.delayed(const Duration(milliseconds: 200));

      expect(provider.timeBlocks, isEmpty,
          reason: 'Missing data should result in empty schedule');
      expect(provider.scheduleConfig.workStartHour, equals(8),
          reason: 'Missing config should use default');
    });

    test('updateScheduleConfig persists and triggers reschedule', () async {
      SharedPreferences.setMockInitialValues({
        'tugasku_tasks': jsonEncode([]),
        'tugasku_schedule_blocks': jsonEncode([]),
        'tugasku_schedule_config': jsonEncode(ScheduleConfig().toJson()),
      });

      final provider = TaskProvider();
      await Future.delayed(const Duration(milliseconds: 200));

      final deadline = DateTime.now().add(const Duration(hours: 72));

      await provider.tambahTugas(
        namaTugas: 'Config Change Test',
        mataKuliah: 'CS502',
        deadline: deadline,
        tingkatKepentingan: 4,
        tingkatUrgensi: 4,
        estimasiWaktu: 3,
      );

      final blocksBefore = List<TimeBlock>.from(provider.timeBlocks);

      // Update config to different work hours
      final newConfig = ScheduleConfig(
        workStartHour: 14,
        workStartMinute: 0,
        workEndHour: 22,
        workEndMinute: 0,
      );
      await provider.updateScheduleConfig(newConfig);

      // Verify config was updated
      expect(provider.scheduleConfig.workStartHour, equals(14));
      expect(provider.scheduleConfig.workEndHour, equals(22));

      // Verify config was persisted
      final prefs = await SharedPreferences.getInstance();
      final savedConfigJson = prefs.getString('tugasku_schedule_config');
      expect(savedConfigJson, isNotNull);
      final savedConfig = ScheduleConfig.fromJson(
        jsonDecode(savedConfigJson!) as Map<String, dynamic>,
      );
      expect(savedConfig.workStartHour, equals(14));
      expect(savedConfig.workEndHour, equals(22));

      // Verify rescheduling happened (blocks should still exist)
      expect(provider.timeBlocks.isNotEmpty, isTrue,
          reason: 'Rescheduling should produce blocks with new config');
    });

    test('schedule persists after each modification', () async {
      SharedPreferences.setMockInitialValues({
        'tugasku_tasks': jsonEncode([]),
        'tugasku_schedule_blocks': jsonEncode([]),
        'tugasku_schedule_config': jsonEncode(ScheduleConfig().toJson()),
      });

      final provider = TaskProvider();
      await Future.delayed(const Duration(milliseconds: 200));

      final deadline = DateTime.now().add(const Duration(hours: 48));

      // Add task
      await provider.tambahTugas(
        namaTugas: 'Persist After Modify',
        mataKuliah: 'CS503',
        deadline: deadline,
        tingkatKepentingan: 4,
        tingkatUrgensi: 4,
        estimasiWaktu: 2,
      );

      final prefs = await SharedPreferences.getInstance();

      // Verify persisted after add
      var savedJson = prefs.getString('tugasku_schedule_blocks');
      expect(savedJson, isNotNull);
      var savedBlocks = jsonDecode(savedJson!) as List;
      expect(savedBlocks.length, equals(2));

      // Edit task estimation
      final task = provider.activeTasks.first;
      await provider.editTugas(task.id, estimasiWaktu: 4);

      // Verify persisted after edit
      savedJson = prefs.getString('tugasku_schedule_blocks');
      savedBlocks = jsonDecode(savedJson!) as List;
      expect(savedBlocks.length, equals(4),
          reason: 'Schedule should be persisted after edit');

      // Delete task
      await provider.hapusTugas(task.id);

      // Verify persisted after delete (empty)
      savedJson = prefs.getString('tugasku_schedule_blocks');
      savedBlocks = jsonDecode(savedJson!) as List;
      expect(savedBlocks.length, equals(0),
          reason: 'Schedule should be persisted after delete');
    });
  });
}
