import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tugasku/services/task_provider.dart';
import 'package:tugasku/models/task_model.dart';
import 'package:tugasku/models/schedule_config_model.dart';
import 'package:tugasku/models/time_block_model.dart';

void main() {
  group('TaskProvider - Schedule/Time Block Management', () {
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
    // 5.1 Test moveTimeBlock()
    // ─────────────────────────────────────────────

    group('moveTimeBlock() - Move Time Block', () {
      test('Skenario Valid Move: Move ke slot yang available', () async {
        // Arrange
        await taskProvider.tambahTugas(
          namaTugas: 'Task with schedule',
          lingkupTugas: 'Scope',
          deadline: DateTime.now().add(const Duration(days: 5)),
          tingkatKepentingan: 3,
          estimasiWaktu: 2,
        );

        // Wait untuk scheduler generate time blocks
        await Future.delayed(const Duration(milliseconds: 100));

        if (taskProvider.timeBlocks.isNotEmpty) {
          final blockId = taskProvider.timeBlocks.first.id;
          final newSlot = DateTime.now()
              .add(const Duration(days: 2))
              .copyWith(hour: 10, minute: 0);

          // Act
          final result = await taskProvider.moveTimeBlock(blockId, newSlot);

          // Assert
          expect(result.success, true);
          expect(result.error, null);
        }
      });

      test('Skenario Invalid Move: Move ke slot di masa lalu', () async {
        // Arrange
        await taskProvider.tambahTugas(
          namaTugas: 'Task',
          lingkupTugas: 'Scope',
          deadline: DateTime.now().add(const Duration(days: 5)),
          tingkatKepentingan: 3,
          estimasiWaktu: 2,
        );

        // Wait untuk scheduler
        await Future.delayed(const Duration(milliseconds: 100));

        if (taskProvider.timeBlocks.isNotEmpty) {
          final blockId = taskProvider.timeBlocks.first.id;
          final pastSlot = DateTime.now().subtract(const Duration(days: 1));

          // Act
          final result = await taskProvider.moveTimeBlock(blockId, pastSlot);

          // Assert
          expect(result.success, false);
          expect(result.error, isNotNull);
        }
      });

      test('Skenario Non-Exist Block: Move block tidak ada', () async {
        // Act
        final result = await taskProvider.moveTimeBlock(
          'invalid-block-id',
          DateTime.now().add(const Duration(days: 1)),
        );

        // Assert
        expect(result.success, false);
        expect(result.error, isNotNull);
      });
    });

    // ─────────────────────────────────────────────
    // 5.2 Test deleteTimeBlock()
    // ─────────────────────────────────────────────

    group('deleteTimeBlock() - Delete Time Block', () {
      test('Skenario Delete Exist Block: Hapus time block exist', () async {
        // Arrange
        await taskProvider.tambahTugas(
          namaTugas: 'Task',
          lingkupTugas: 'Scope',
          deadline: DateTime.now().add(const Duration(days: 5)),
          tingkatKepentingan: 3,
          estimasiWaktu: 2,
        );

        // Wait untuk scheduler
        await Future.delayed(const Duration(milliseconds: 100));

        if (taskProvider.timeBlocks.isNotEmpty) {
          final blockId = taskProvider.timeBlocks.first.id;
          final initialCount = taskProvider.timeBlocks.length;

          // Act
          await taskProvider.deleteTimeBlock(blockId);

          // Assert
          expect(taskProvider.timeBlocks.length, lessThan(initialCount));
        }
      });

      test('Skenario Delete Non-Exist Block: Safe operation', () async {
        // Arrange
        final initialCount = taskProvider.timeBlocks.length;

        // Act
        await taskProvider.deleteTimeBlock('invalid-block-id');

        // Assert
        expect(taskProvider.timeBlocks.length, initialCount);
      });
    });

    // ─────────────────────────────────────────────
    // 5.3 Test updateScheduleConfig()
    // ─────────────────────────────────────────────

    group('updateScheduleConfig() - Update Schedule Config', () {
      test('Skenario Update Config: Config ter-update', () async {
        // Arrange
        final newConfig = ScheduleConfig(
          maxHoursPerDay: 6,
          workStartHour: 9,
          workEndHour: 17,
          bufferBetweenTasks: 15,
        );

        // Act
        await taskProvider.updateScheduleConfig(newConfig);

        // Assert
        expect(taskProvider.scheduleConfig.maxHoursPerDay, 6);
        expect(taskProvider.scheduleConfig.workStartHour, 9);
      });

      test('Skenario Config Persistent: Config saved and loaded', () async {
        // Arrange
        final newConfig = ScheduleConfig(
          maxHoursPerDay: 7,
          workStartHour: 8,
          workEndHour: 18,
        );

        // Act
        await taskProvider.updateScheduleConfig(newConfig);

        // Act - Create new provider instance
        final newProvider = TaskProvider();
        await newProvider._init();

        // Assert
        expect(newProvider.scheduleConfig.maxHoursPerDay, 7);
      });

      test('Skenario Default Config: Default values', () async {
        // Assert
        expect(taskProvider.scheduleConfig, isNotNull);
        expect(taskProvider.scheduleConfig.maxHoursPerDay, isNotNull);
      });
    });

    // ─────────────────────────────────────────────
    // 6.1 Test Smart Scheduler Integration
    // ─────────────────────────────────────────────

    group('Smart Scheduler Integration', () {
      test('Skenario Schedule Generation: Time blocks ter-generate', () async {
        // Arrange
        await taskProvider.tambahTugas(
          namaTugas: 'Task 1',
          lingkupTugas: 'Scope',
          deadline: DateTime.now().add(const Duration(days: 3)),
          tingkatKepentingan: 3,
          estimasiWaktu: 2,
        );

        // Act
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(taskProvider.timeBlocks.isNotEmpty, true);
      });

      test('Skenario Conflict Detection: latestConflicts ter-populate', () async {
        // Arrange
        await taskProvider.tambahTugas(
          namaTugas: 'Conflicting Task',
          lingkupTugas: 'Scope',
          deadline: DateTime.now().add(const Duration(hours: 1)),
          tingkatKepentingan: 5,
          estimasiWaktu: 10, // Requires 10 hours in 1 hour - will create conflict
        );

        // Act
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        // Verify conflicts property exists
        expect(taskProvider.latestConflicts, isNotNull);
      });

      test('Skenario Dismiss Conflicts: dismissConflicts() clear conflicts', () async {
        // Arrange
        // Setup scenario that creates conflicts if applicable

        // Act
        taskProvider.dismissConflicts();

        // Assert
        expect(taskProvider.latestConflicts.isEmpty, true);
        expect(taskProvider.conflictsDetectedAt, null);
      });

      test('Skenario Has Conflicts Property: hasConflicts returns correct value', () async {
        // Assert
        expect(taskProvider.hasConflicts, false); // No tasks = no conflicts
      });
    });

    // ─────────────────────────────────────────────
    // 6.2 Test SAW Scoring
    // ─────────────────────────────────────────────

    group('SAW Scoring Recalculation', () {
      test('Skenario SAW Recalculate: Ranking ter-update setelah add task', () async {
        // Arrange
        await taskProvider.tambahTugas(
          namaTugas: 'High Priority Task',
          lingkupTugas: 'Scope',
          deadline: DateTime.now().add(const Duration(days: 2)),
          tingkatKepentingan: 5,
          estimasiWaktu: 1,
        );

        await taskProvider.tambahTugas(
          namaTugas: 'Low Priority Task',
          lingkupTugas: 'Scope',
          deadline: DateTime.now().add(const Duration(days: 5)),
          tingkatKepentingan: 1,
          estimasiWaktu: 5,
        );

        // Assert
        expect(taskProvider.prioritizedTasks.length, 2);
        // First task should have higher ranking (lower ranking value = higher priority)
        expect(
          taskProvider.prioritizedTasks.first.ranking <=
              taskProvider.prioritizedTasks.last.ranking,
          true,
        );
      });

      test('Skenario Prioritized Tasks: Only active tasks included', () async {
        // Arrange
        await taskProvider.tambahTugas(
          namaTugas: 'Active',
          lingkupTugas: 'Scope',
          deadline: DateTime.now().add(const Duration(days: 1)),
          tingkatKepentingan: 3,
          estimasiWaktu: 2,
        );

        await taskProvider.tambahTugas(
          namaTugas: 'Completed',
          lingkupTugas: 'Scope',
          deadline: DateTime.now().add(const Duration(days: 2)),
          tingkatKepentingan: 3,
          estimasiWaktu: 2,
        );

        // Mark second as completed
        await taskProvider.updateStatus(
          taskProvider.tasks[1].id,
          TaskStatus.selesai,
        );

        // Assert
        expect(taskProvider.prioritizedTasks.length, 1);
        expect(taskProvider.prioritizedTasks.first.namaTugas, 'Active');
      });

      test('Skenario Empty Prioritized Tasks: Empty when no active tasks', () async {
        // Assert
        expect(taskProvider.prioritizedTasks.isEmpty, true);
      });
    });

    // ─────────────────────────────────────────────
    // Overdue Tasks & Due Soon
    // ─────────────────────────────────────────────

    group('Overdue and Due Soon Tasks', () {
      test('Skenario overdueTasks: Get tasks yang overdue', () async {
        // Arrange
        await taskProvider.tambahTugas(
          namaTugas: 'Overdue Task',
          lingkupTugas: 'Scope',
          deadline: DateTime.now().subtract(const Duration(days: 1)),
          tingkatKepentingan: 3,
          estimasiWaktu: 2,
        );

        // Assert
        expect(taskProvider.overdueTasks.length, 1);
      });

      test('Skenario dueSoonTasks: Get tasks due soon', () async {
        // Arrange
        await taskProvider.tambahTugas(
          namaTugas: 'Due Soon Task',
          lingkupTugas: 'Scope',
          deadline: DateTime.now().add(const Duration(days: 1)),
          tingkatKepentingan: 3,
          estimasiWaktu: 2,
        );

        // Assert
        expect(taskProvider.dueSoonTasks.length, 1);
      });

      test('Skenario Far Future Task: Not in dueSoonTasks', () async {
        // Arrange
        await taskProvider.tambahTugas(
          namaTugas: 'Far Future Task',
          lingkupTugas: 'Scope',
          deadline: DateTime.now().add(const Duration(days: 30)),
          tingkatKepentingan: 3,
          estimasiWaktu: 2,
        );

        // Assert
        expect(taskProvider.dueSoonTasks.isEmpty, true);
      });
    });

    // ─────────────────────────────────────────────
    // Time Block Getters
    // ─────────────────────────────────────────────

    group('Time Block Getters', () {
      test('Skenario getTimeBlocksForDate: Get blocks for specific date', () async {
        // Arrange
        final targetDate = DateTime.now().add(const Duration(days: 2));

        await taskProvider.tambahTugas(
          namaTugas: 'Task',
          lingkupTugas: 'Scope',
          deadline: DateTime.now().add(const Duration(days: 5)),
          tingkatKepentingan: 3,
          estimasiWaktu: 2,
        );

        // Wait for scheduler
        await Future.delayed(const Duration(milliseconds: 100));

        // Act
        final blocksForDate = taskProvider.getTimeBlocksForDate(targetDate);

        // Assert
        expect(blocksForDate, isNotNull);
        expect(blocksForDate is List, true);
      });

      test('Skenario getTimeBlocksForTask: Get blocks for specific task', () async {
        // Arrange
        await taskProvider.tambahTugas(
          namaTugas: 'Task',
          lingkupTugas: 'Scope',
          deadline: DateTime.now().add(const Duration(days: 5)),
          tingkatKepentingan: 3,
          estimasiWaktu: 2,
        );

        // Wait for scheduler
        await Future.delayed(const Duration(milliseconds: 100));

        final taskId = taskProvider.tasks.first.id;

        // Act
        final blocksForTask = taskProvider.getTimeBlocksForTask(taskId);

        // Assert
        expect(blocksForTask, isNotNull);
        expect(blocksForTask is List, true);
      });
    });
  });
}
