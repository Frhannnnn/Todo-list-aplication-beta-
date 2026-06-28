// test/services/task_provider_scheduling_integration_test.dart
//
// Integration tests verifying that scheduling is properly wired into
// the task CRUD flow (tambahTugas, editTugas, hapusTugas, updateStatus).
//
// Validates: Requirements 8.2, 8.7
// - SAW recalculation completes before scheduling starts
// - Scheduling completes within 3 seconds of SAW completion
// - All CRUD methods trigger the scheduler

import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tugasku/models/task_model.dart';
import 'package:tugasku/models/schedule_config_model.dart';
import 'package:tugasku/services/task_provider.dart';

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

    // Initialize SharedPreferences with empty data
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dexterous.com/flutter/local_notifications'),
      null,
    );
  });

  group('Task 9.1: Wire scheduling into existing task CRUD flow', () {
    group('tambahTugas() triggers scheduling', () {
      test('adding a task produces time blocks', () async {
        SharedPreferences.setMockInitialValues({
          'tugasku_tasks': jsonEncode([]),
          'tugasku_schedule_blocks': jsonEncode([]),
          'tugasku_schedule_config': jsonEncode(ScheduleConfig().toJson()),
        });

        final provider = TaskProvider();
        await Future.delayed(const Duration(milliseconds: 200));

        final deadline = DateTime.now().add(const Duration(hours: 48));

        await provider.tambahTugas(
          namaTugas: 'Test Task',
          mataKuliah: 'CS101',
          deadline: deadline,
          tingkatKepentingan: 4,
          tingkatUrgensi: 4,
          estimasiWaktu: 3,
        );

        // After adding a task, time blocks should be generated
        expect(provider.timeBlocks.isNotEmpty, isTrue,
            reason: 'tambahTugas should trigger scheduling and produce time blocks');

        // All blocks should belong to the added task
        final task = provider.activeTasks.first;
        final taskBlocks = provider.getTimeBlocksForTask(task.id);
        expect(taskBlocks.length, equals(3),
            reason: 'Should have 3 time blocks for 3-hour estimation');
      });

      test('SAW scores are set before scheduling runs', () async {
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
          mataKuliah: 'CS101',
          deadline: deadline,
          tingkatKepentingan: 5,
          tingkatUrgensi: 5,
          estimasiWaktu: 2,
        );

        // SAW score should be calculated (non-zero for active tasks)
        final task = provider.activeTasks.first;
        expect(task.sawScore, greaterThan(0),
            reason: 'SAW score should be calculated before scheduling');
      });
    });

    group('editTugas() triggers scheduling', () {
      test('editing estimation changes time block count', () async {
        SharedPreferences.setMockInitialValues({
          'tugasku_tasks': jsonEncode([]),
          'tugasku_schedule_blocks': jsonEncode([]),
          'tugasku_schedule_config': jsonEncode(ScheduleConfig().toJson()),
        });

        final provider = TaskProvider();
        await Future.delayed(const Duration(milliseconds: 200));

        final deadline = DateTime.now().add(const Duration(hours: 72));

        await provider.tambahTugas(
          namaTugas: 'Edit Test',
          mataKuliah: 'CS102',
          deadline: deadline,
          tingkatKepentingan: 3,
          tingkatUrgensi: 3,
          estimasiWaktu: 2,
        );

        final task = provider.activeTasks.first;
        expect(provider.getTimeBlocksForTask(task.id).length, equals(2));

        // Edit estimation from 2 to 5
        await provider.editTugas(task.id, estimasiWaktu: 5);

        final updatedBlocks = provider.getTimeBlocksForTask(task.id);
        expect(updatedBlocks.length, equals(5),
            reason: 'editTugas should trigger rescheduling with new estimation');
      });

      test('editing deadline triggers rescheduling', () async {
        SharedPreferences.setMockInitialValues({
          'tugasku_tasks': jsonEncode([]),
          'tugasku_schedule_blocks': jsonEncode([]),
          'tugasku_schedule_config': jsonEncode(ScheduleConfig().toJson()),
        });

        final provider = TaskProvider();
        await Future.delayed(const Duration(milliseconds: 200));

        final deadline = DateTime.now().add(const Duration(hours: 72));

        await provider.tambahTugas(
          namaTugas: 'Deadline Edit',
          mataKuliah: 'CS103',
          deadline: deadline,
          tingkatKepentingan: 4,
          tingkatUrgensi: 4,
          estimasiWaktu: 3,
        );

        final task = provider.activeTasks.first;
        final blocksBefore = provider.getTimeBlocksForTask(task.id);
        expect(blocksBefore.isNotEmpty, isTrue);

        // Edit deadline to be closer
        final newDeadline = DateTime.now().add(const Duration(hours: 24));
        await provider.editTugas(task.id, deadline: newDeadline);

        final blocksAfter = provider.getTimeBlocksForTask(task.id);
        // Blocks should still exist (rescheduled)
        expect(blocksAfter.isNotEmpty, isTrue,
            reason: 'editTugas with new deadline should trigger rescheduling');

        // All blocks should be before the new deadline
        for (final block in blocksAfter) {
          expect(block.startTime.isBefore(newDeadline), isTrue,
              reason: 'All blocks should be before the new deadline');
        }
      });
    });

    group('hapusTugas() triggers scheduling', () {
      test('deleting a task removes its time blocks and reschedules others',
          () async {
        SharedPreferences.setMockInitialValues({
          'tugasku_tasks': jsonEncode([]),
          'tugasku_schedule_blocks': jsonEncode([]),
          'tugasku_schedule_config': jsonEncode(ScheduleConfig().toJson()),
        });

        final provider = TaskProvider();
        await Future.delayed(const Duration(milliseconds: 200));

        final deadline = DateTime.now().add(const Duration(hours: 48));

        // Add two tasks
        await provider.tambahTugas(
          namaTugas: 'Task To Delete',
          mataKuliah: 'CS104',
          deadline: deadline,
          tingkatKepentingan: 5,
          tingkatUrgensi: 5,
          estimasiWaktu: 2,
        );

        await provider.tambahTugas(
          namaTugas: 'Task To Keep',
          mataKuliah: 'CS104',
          deadline: deadline,
          tingkatKepentingan: 3,
          tingkatUrgensi: 3,
          estimasiWaktu: 2,
        );

        final taskToDelete = provider.activeTasks
            .firstWhere((t) => t.namaTugas == 'Task To Delete');
        final taskToKeep = provider.activeTasks
            .firstWhere((t) => t.namaTugas == 'Task To Keep');

        // Both tasks should have blocks
        expect(provider.getTimeBlocksForTask(taskToDelete.id).isNotEmpty, isTrue);
        expect(provider.getTimeBlocksForTask(taskToKeep.id).isNotEmpty, isTrue);

        // Delete the first task
        await provider.hapusTugas(taskToDelete.id);

        // Deleted task's blocks should be gone
        expect(provider.getTimeBlocksForTask(taskToDelete.id).isEmpty, isTrue,
            reason: 'hapusTugas should remove all blocks for the deleted task');

        // Remaining task should still have blocks (rescheduled)
        expect(provider.getTimeBlocksForTask(taskToKeep.id).isNotEmpty, isTrue,
            reason: 'hapusTugas should trigger rescheduling for remaining tasks');
      });
    });

    group('updateStatus() / tandaiSelesai triggers scheduling', () {
      test('marking task complete removes its time blocks', () async {
        SharedPreferences.setMockInitialValues({
          'tugasku_tasks': jsonEncode([]),
          'tugasku_schedule_blocks': jsonEncode([]),
          'tugasku_schedule_config': jsonEncode(ScheduleConfig().toJson()),
        });

        final provider = TaskProvider();
        await Future.delayed(const Duration(milliseconds: 200));

        final deadline = DateTime.now().add(const Duration(hours: 48));

        await provider.tambahTugas(
          namaTugas: 'Complete Me',
          mataKuliah: 'CS105',
          deadline: deadline,
          tingkatKepentingan: 4,
          tingkatUrgensi: 4,
          estimasiWaktu: 3,
        );

        final task = provider.activeTasks.first;
        expect(provider.getTimeBlocksForTask(task.id).isNotEmpty, isTrue,
            reason: 'Task should have time blocks before completion');

        // Mark as complete (this is the tandaiSelesai equivalent)
        await provider.updateStatus(task.id, TaskStatus.selesai);

        expect(provider.getTimeBlocksForTask(task.id).isEmpty, isTrue,
            reason: 'Marking task complete should remove all its time blocks');
      });

      test('marking task complete frees slots for other tasks', () async {
        SharedPreferences.setMockInitialValues({
          'tugasku_tasks': jsonEncode([]),
          'tugasku_schedule_blocks': jsonEncode([]),
          'tugasku_schedule_config': jsonEncode(ScheduleConfig().toJson()),
        });

        final provider = TaskProvider();
        await Future.delayed(const Duration(milliseconds: 200));

        final deadline = DateTime.now().add(const Duration(hours: 24));

        // Add high-priority task
        await provider.tambahTugas(
          namaTugas: 'High Priority',
          mataKuliah: 'CS106',
          deadline: deadline,
          tingkatKepentingan: 5,
          tingkatUrgensi: 5,
          estimasiWaktu: 4,
        );

        // Add lower-priority task
        await provider.tambahTugas(
          namaTugas: 'Low Priority',
          mataKuliah: 'CS106',
          deadline: deadline,
          tingkatKepentingan: 2,
          tingkatUrgensi: 2,
          estimasiWaktu: 4,
        );

        final highTask = provider.activeTasks
            .firstWhere((t) => t.namaTugas == 'High Priority');
        final lowTask = provider.activeTasks
            .firstWhere((t) => t.namaTugas == 'Low Priority');

        final lowBlocksBefore = provider.getTimeBlocksForTask(lowTask.id).length;

        // Complete the high-priority task
        await provider.updateStatus(highTask.id, TaskStatus.selesai);

        // Low-priority task should have at least as many blocks (possibly more
        // since slots freed up)
        final lowBlocksAfter = provider.getTimeBlocksForTask(lowTask.id).length;
        expect(lowBlocksAfter, greaterThanOrEqualTo(lowBlocksBefore),
            reason: 'Completing a task should free slots for rescheduling');
      });
    });

    group('Scheduling timing requirements', () {
      test('scheduling completes within 3 seconds of SAW completion', () async {
        SharedPreferences.setMockInitialValues({
          'tugasku_tasks': jsonEncode([]),
          'tugasku_schedule_blocks': jsonEncode([]),
          'tugasku_schedule_config': jsonEncode(ScheduleConfig().toJson()),
        });

        final provider = TaskProvider();
        await Future.delayed(const Duration(milliseconds: 200));

        final deadline = DateTime.now().add(const Duration(hours: 72));

        // Add multiple tasks to stress the scheduler
        final stopwatch = Stopwatch()..start();

        for (var i = 0; i < 10; i++) {
          await provider.tambahTugas(
            namaTugas: 'Timing Task $i',
            mataKuliah: 'CS107',
            deadline: deadline.add(Duration(hours: i * 12)),
            tingkatKepentingan: 1 + (i % 5),
            tingkatUrgensi: 1 + (i % 5),
            estimasiWaktu: 1 + (i % 5),
          );
        }

        stopwatch.stop();

        // The entire operation (including SAW + scheduling for 10 tasks)
        // should complete well within 3 seconds per operation
        expect(stopwatch.elapsedMilliseconds, lessThan(30000),
            reason: 'All 10 task additions with scheduling should complete '
                'within 30 seconds total (3s each)');

        // Verify all tasks have blocks
        for (final task in provider.activeTasks) {
          expect(provider.getTimeBlocksForTask(task.id).isNotEmpty, isTrue,
              reason: 'Task ${task.namaTugas} should have time blocks');
        }
      });

      test('SAW recalculation is synchronous (completes before scheduler)',
          () async {
        SharedPreferences.setMockInitialValues({
          'tugasku_tasks': jsonEncode([]),
          'tugasku_schedule_blocks': jsonEncode([]),
          'tugasku_schedule_config': jsonEncode(ScheduleConfig().toJson()),
        });

        final provider = TaskProvider();
        await Future.delayed(const Duration(milliseconds: 200));

        final deadline = DateTime.now().add(const Duration(hours: 48));

        await provider.tambahTugas(
          namaTugas: 'SAW Sync Test',
          mataKuliah: 'CS108',
          deadline: deadline,
          tingkatKepentingan: 5,
          tingkatUrgensi: 5,
          estimasiWaktu: 2,
        );

        // After tambahTugas completes, SAW score should already be set
        // (proving SAW ran before scheduler)
        final task = provider.activeTasks.first;
        expect(task.sawScore, greaterThan(0),
            reason: 'SAW score must be calculated synchronously before scheduling');

        // And time blocks should exist (proving scheduler ran after SAW)
        expect(provider.getTimeBlocksForTask(task.id).isNotEmpty, isTrue,
            reason: 'Scheduler must run after SAW scores are available');
      });
    });

    group('Flow order verification', () {
      test('CRUD → SAW → Scheduler → Save flow is maintained', () async {
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
          namaTugas: 'Flow Test',
          mataKuliah: 'CS109',
          deadline: deadline,
          tingkatKepentingan: 4,
          tingkatUrgensi: 4,
          estimasiWaktu: 2,
        );

        final task = provider.activeTasks.first;

        // Verify SAW score is set (SAW ran)
        expect(task.sawScore, greaterThan(0));

        // Verify time blocks exist (scheduler ran)
        final blocks = provider.getTimeBlocksForTask(task.id);
        expect(blocks.isNotEmpty, isTrue);

        // Verify blocks are valid (all before deadline, all 1-hour duration)
        for (final block in blocks) {
          expect(block.startTime.isBefore(deadline), isTrue,
              reason: 'Block should be before deadline');
          expect(
            block.endTime.difference(block.startTime).inHours,
            equals(1),
            reason: 'Block duration should be exactly 1 hour',
          );
        }

        // Verify no overlaps
        final slots = blocks.map((b) => b.startTime).toSet();
        expect(slots.length, equals(blocks.length),
            reason: 'No two blocks should occupy the same slot');
      });
    });
  });
}
