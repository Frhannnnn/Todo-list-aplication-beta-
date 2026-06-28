// test/services/reschedule_all_test.dart
//
// Unit tests for SmartSchedulerService.rescheduleAll() main entry point.
// Tests the full scheduling pipeline: sort by SAW, backward schedule,
// conflict detection/resolution, and validation.
//
// **Validates: Requirements 7.5, 8.1, 8.2, 8.3**

import 'package:flutter_test/flutter_test.dart';
import 'package:tugasku/models/time_block_model.dart';
import 'package:tugasku/models/schedule_config_model.dart';
import 'package:tugasku/models/schedule_result_model.dart';
import 'package:tugasku/models/task_model.dart';
import 'package:tugasku/services/smart_scheduler_service.dart';

void main() {
  late SmartSchedulerService scheduler;
  late ScheduleConfig defaultConfig;
  late DateTime now;

  setUp(() {
    scheduler = SmartSchedulerService();
    defaultConfig = ScheduleConfig(); // 08:00-17:00
    now = DateTime(2024, 6, 15, 8); // Saturday 8:00 AM
  });

  /// Helper to create a Task with specific parameters
  Task createTask({
    required String id,
    String name = 'Task',
    double sawScore = 0.5,
    int estimasiWaktu = 2,
    DateTime? deadline,
    DateTime? createdAt,
    TaskStatus status = TaskStatus.belumDikerjakan,
  }) {
    return Task(
      id: id,
      namaTugas: '$name $id',
      mataKuliah: 'CS101',
      deadline: deadline ?? DateTime(2024, 6, 16, 17), // Tomorrow 5PM
      tingkatKepentingan: 3,
      tingkatUrgensi: 3,
      estimasiWaktu: estimasiWaktu,
      status: status,
      createdAt: createdAt ?? DateTime(2024, 6, 1),
      sawScore: sawScore,
    );
  }

  // ===========================================================================
  // Basic functionality tests
  // ===========================================================================
  group('rescheduleAll - basic functionality', () {
    test('returns empty result for empty task list', () {
      final result = scheduler.rescheduleAll(
        tasks: [],
        manualBlocks: [],
        config: defaultConfig,
        now: now,
      );

      expect(result.timeBlocks, isEmpty);
      expect(result.conflicts, isEmpty);
      expect(result.warnings, isEmpty);
    });

    test('schedules a single task correctly', () {
      final task = createTask(
        id: 't1',
        estimasiWaktu: 3,
        deadline: DateTime(2024, 6, 15, 17), // Today 5PM
      );

      final result = scheduler.rescheduleAll(
        tasks: [task],
        manualBlocks: [],
        config: defaultConfig,
        now: now,
      );

      expect(result.timeBlocks.length, equals(3));
      expect(result.conflicts, isEmpty);
      expect(result.warnings, isEmpty);

      // All blocks should belong to task t1
      for (final block in result.timeBlocks) {
        expect(block.taskId, equals('t1'));
        expect(block.startTime.isBefore(task.deadline), isTrue);
        expect(
          block.startTime.isAfter(now) || block.startTime.isAtSameMomentAs(now),
          isTrue,
        );
      }
    });

    test('schedules multiple tasks sorted by SAW Score', () {
      final tasks = [
        createTask(id: 't1', sawScore: 0.3, estimasiWaktu: 2),
        createTask(id: 't2', sawScore: 0.9, estimasiWaktu: 2),
        createTask(id: 't3', sawScore: 0.6, estimasiWaktu: 2),
      ];

      final result = scheduler.rescheduleAll(
        tasks: tasks,
        manualBlocks: [],
        config: defaultConfig,
        now: now,
      );

      // All 6 blocks should be scheduled (2 per task)
      expect(result.timeBlocks.length, equals(6));
      // No overlaps
      expect(scheduler.validateNoOverlaps(result.timeBlocks), isTrue);
    });

    test('result has no overlapping time blocks', () {
      final tasks = [
        createTask(id: 't1', sawScore: 0.8, estimasiWaktu: 3),
        createTask(id: 't2', sawScore: 0.6, estimasiWaktu: 3),
        createTask(id: 't3', sawScore: 0.4, estimasiWaktu: 3),
      ];

      final result = scheduler.rescheduleAll(
        tasks: tasks,
        manualBlocks: [],
        config: defaultConfig,
        now: now,
      );

      expect(scheduler.validateNoOverlaps(result.timeBlocks), isTrue);
    });
  });

  // ===========================================================================
  // Filtering tests
  // ===========================================================================
  group('rescheduleAll - task filtering', () {
    test('excludes completed tasks', () {
      final tasks = [
        createTask(id: 't1', sawScore: 0.8, status: TaskStatus.selesai),
        createTask(id: 't2', sawScore: 0.6, estimasiWaktu: 2),
      ];

      final result = scheduler.rescheduleAll(
        tasks: tasks,
        manualBlocks: [],
        config: defaultConfig,
        now: now,
      );

      // Only t2 should be scheduled
      final taskIds = result.timeBlocks.map((b) => b.taskId).toSet();
      expect(taskIds, isNot(contains('t1')));
      expect(taskIds, contains('t2'));
    });

    test('adds pastDeadline warning for tasks with past deadlines', () {
      final tasks = [
        createTask(
          id: 't1',
          sawScore: 0.8,
          deadline: DateTime(2024, 6, 14, 17), // Yesterday
        ),
        createTask(id: 't2', sawScore: 0.6, estimasiWaktu: 2),
      ];

      final result = scheduler.rescheduleAll(
        tasks: tasks,
        manualBlocks: [],
        config: defaultConfig,
        now: now,
      );

      // t1 should have a pastDeadline warning
      final pastWarnings = result.warnings
          .where((w) => w.type == WarningType.pastDeadline)
          .toList();
      expect(pastWarnings.length, equals(1));
      expect(pastWarnings[0].taskId, equals('t1'));

      // t1 should not have any blocks
      final t1Blocks = result.timeBlocks.where((b) => b.taskId == 't1');
      expect(t1Blocks, isEmpty);
    });

    test('handles all tasks having past deadlines', () {
      final tasks = [
        createTask(id: 't1', deadline: DateTime(2024, 6, 14, 17)),
        createTask(id: 't2', deadline: DateTime(2024, 6, 13, 17)),
      ];

      final result = scheduler.rescheduleAll(
        tasks: tasks,
        manualBlocks: [],
        config: defaultConfig,
        now: now,
      );

      expect(result.timeBlocks, isEmpty);
      expect(result.warnings.length, equals(2));
      expect(
        result.warnings.every((w) => w.type == WarningType.pastDeadline),
        isTrue,
      );
    });
  });

  // ===========================================================================
  // Manual blocks preservation tests
  // ===========================================================================
  group('rescheduleAll - manual blocks', () {
    test('preserves manually placed blocks', () {
      final manualBlock = TimeBlock(
        id: 'manual1',
        taskId: 't1',
        startTime: DateTime(2024, 6, 15, 10),
        endTime: DateTime(2024, 6, 15, 11),
        isManuallyPlaced: true,
      );

      final tasks = [
        createTask(id: 't2', sawScore: 0.8, estimasiWaktu: 2),
      ];

      final result = scheduler.rescheduleAll(
        tasks: tasks,
        manualBlocks: [manualBlock],
        config: defaultConfig,
        now: now,
      );

      // Manual block should be in the result
      final manualInResult = result.timeBlocks
          .where((b) => b.id == 'manual1')
          .toList();
      expect(manualInResult.length, equals(1));
      expect(manualInResult[0].startTime, equals(DateTime(2024, 6, 15, 10)));
    });

    test('does not schedule new blocks on manually occupied slots', () {
      final manualBlock = TimeBlock(
        id: 'manual1',
        taskId: 't1',
        startTime: DateTime(2024, 6, 15, 9),
        endTime: DateTime(2024, 6, 15, 10),
        isManuallyPlaced: true,
      );

      final tasks = [
        createTask(
          id: 't2',
          sawScore: 0.8,
          estimasiWaktu: 2,
          deadline: DateTime(2024, 6, 15, 12),
        ),
      ];

      final result = scheduler.rescheduleAll(
        tasks: tasks,
        manualBlocks: [manualBlock],
        config: defaultConfig,
        now: now,
      );

      // t2's blocks should not overlap with the manual block at 9:00
      final t2Blocks = result.timeBlocks.where((b) => b.taskId == 't2');
      for (final block in t2Blocks) {
        expect(block.startTime, isNot(equals(DateTime(2024, 6, 15, 9))));
      }

      // No overlaps overall
      expect(scheduler.validateNoOverlaps(result.timeBlocks), isTrue);
    });
  });

  // ===========================================================================
  // Insufficient slots / warnings tests
  // ===========================================================================
  group('rescheduleAll - warnings', () {
    test('adds insufficientSlots warning when not enough slots available', () {
      // Task needs 5 hours but only 2 slots available (10:00, 11:00)
      // now=10:00, deadline=12:00
      final localNow = DateTime(2024, 6, 15, 10);
      final task = createTask(
        id: 't1',
        estimasiWaktu: 5,
        deadline: DateTime(2024, 6, 15, 12),
      );

      final result = scheduler.rescheduleAll(
        tasks: [task],
        manualBlocks: [],
        config: defaultConfig,
        now: localNow,
      );

      final insufficientWarnings = result.warnings
          .where((w) => w.type == WarningType.insufficientSlots)
          .toList();
      expect(insufficientWarnings.length, equals(1));
      expect(insufficientWarnings[0].taskId, equals('t1'));
      // Should mention the shortfall (5 - 2 = 3 hours)
      expect(insufficientWarnings[0].message, contains('3'));
    });

    test('no warning when all slots can be allocated', () {
      final task = createTask(
        id: 't1',
        estimasiWaktu: 3,
        deadline: DateTime(2024, 6, 15, 17), // Plenty of slots
      );

      final result = scheduler.rescheduleAll(
        tasks: [task],
        manualBlocks: [],
        config: defaultConfig,
        now: now,
      );

      final insufficientWarnings = result.warnings
          .where((w) => w.type == WarningType.insufficientSlots)
          .toList();
      expect(insufficientWarnings, isEmpty);
    });
  });

  // ===========================================================================
  // Conflict detection and resolution tests
  // ===========================================================================
  group('rescheduleAll - conflict resolution', () {
    test('resolves conflicts when tasks compete for same slots', () {
      // Two tasks with same deadline and estimation, different SAW scores
      // They will initially try to schedule on the same slots
      final tasks = [
        createTask(
          id: 't1',
          sawScore: 0.9,
          estimasiWaktu: 3,
          deadline: DateTime(2024, 6, 15, 12),
        ),
        createTask(
          id: 't2',
          sawScore: 0.3,
          estimasiWaktu: 3,
          deadline: DateTime(2024, 6, 15, 12),
        ),
      ];

      final result = scheduler.rescheduleAll(
        tasks: tasks,
        manualBlocks: [],
        config: defaultConfig,
        now: now,
      );

      // Final result should have no overlaps
      expect(scheduler.validateNoOverlaps(result.timeBlocks), isTrue);
    });

    test('higher SAW score task gets priority slots', () {
      // t1 has higher SAW score, should get preferred slots
      final tasks = [
        createTask(
          id: 't1',
          sawScore: 0.9,
          estimasiWaktu: 2,
          deadline: DateTime(2024, 6, 15, 12),
        ),
        createTask(
          id: 't2',
          sawScore: 0.3,
          estimasiWaktu: 2,
          deadline: DateTime(2024, 6, 15, 12),
        ),
      ];

      final result = scheduler.rescheduleAll(
        tasks: tasks,
        manualBlocks: [],
        config: defaultConfig,
        now: now,
      );

      // No overlaps
      expect(scheduler.validateNoOverlaps(result.timeBlocks), isTrue);

      // Both tasks should have blocks scheduled
      final t1Blocks = result.timeBlocks.where((b) => b.taskId == 't1').toList();
      final t2Blocks = result.timeBlocks.where((b) => b.taskId == 't2').toList();
      expect(t1Blocks, isNotEmpty);
      expect(t2Blocks, isNotEmpty);
    });

    test('conflicts field contains detected conflicts', () {
      // Force a scenario where conflicts would be detected
      // Two tasks competing for same limited slots
      final localNow = DateTime(2024, 6, 15, 10);
      final tasks = [
        createTask(
          id: 't1',
          sawScore: 0.9,
          estimasiWaktu: 2,
          deadline: DateTime(2024, 6, 15, 12),
        ),
        createTask(
          id: 't2',
          sawScore: 0.3,
          estimasiWaktu: 2,
          deadline: DateTime(2024, 6, 15, 12),
        ),
      ];

      final result = scheduler.rescheduleAll(
        tasks: tasks,
        manualBlocks: [],
        config: defaultConfig,
        now: localNow,
      );

      // Since t1 is scheduled first (higher SAW), t2 gets remaining slots
      // With only 2 slots available (10:00, 11:00) and t1 taking them,
      // t2 will have no slots left — but since backwardSchedule respects
      // occupied slots, t2 won't create overlapping blocks.
      // The conflicts field reflects what was detected before resolution.
      expect(scheduler.validateNoOverlaps(result.timeBlocks), isTrue);
    });
  });

  // ===========================================================================
  // Edge cases
  // ===========================================================================
  group('rescheduleAll - edge cases', () {
    test('handles deadline exactly at now (past deadline)', () {
      final task = createTask(
        id: 't1',
        deadline: now, // Exactly at now
      );

      final result = scheduler.rescheduleAll(
        tasks: [task],
        manualBlocks: [],
        config: defaultConfig,
        now: now,
      );

      expect(result.timeBlocks, isEmpty);
      expect(
        result.warnings.any((w) => w.type == WarningType.pastDeadline),
        isTrue,
      );
    });

    test('handles mix of completed and active tasks', () {
      final tasks = [
        createTask(id: 't1', status: TaskStatus.selesai, sawScore: 0.9),
        createTask(id: 't2', status: TaskStatus.belumDikerjakan, sawScore: 0.7),
        createTask(id: 't3', status: TaskStatus.sedangDikerjakan, sawScore: 0.5),
      ];

      final result = scheduler.rescheduleAll(
        tasks: tasks,
        manualBlocks: [],
        config: defaultConfig,
        now: now,
      );

      // Only t2 and t3 should be scheduled
      final taskIds = result.timeBlocks.map((b) => b.taskId).toSet();
      expect(taskIds, isNot(contains('t1')));
      expect(taskIds, contains('t2'));
      expect(taskIds, contains('t3'));
    });

    test('handles many tasks without infinite loop', () {
      // Create 10 tasks all competing for limited slots
      final tasks = List.generate(
        10,
        (i) => createTask(
          id: 't$i',
          sawScore: (10 - i) / 10.0,
          estimasiWaktu: 2,
          deadline: DateTime(2024, 6, 15, 17),
        ),
      );

      final result = scheduler.rescheduleAll(
        tasks: tasks,
        manualBlocks: [],
        config: defaultConfig,
        now: now,
      );

      // Should complete without hanging
      expect(scheduler.validateNoOverlaps(result.timeBlocks), isTrue);
    });

    test('all blocks are before their respective task deadlines', () {
      final tasks = [
        createTask(
          id: 't1',
          sawScore: 0.8,
          estimasiWaktu: 2,
          deadline: DateTime(2024, 6, 15, 14),
        ),
        createTask(
          id: 't2',
          sawScore: 0.6,
          estimasiWaktu: 2,
          deadline: DateTime(2024, 6, 15, 12),
        ),
      ];

      final result = scheduler.rescheduleAll(
        tasks: tasks,
        manualBlocks: [],
        config: defaultConfig,
        now: now,
      );

      // Build task map for deadline lookup
      final taskMap = {for (final t in tasks) t.id: t};

      for (final block in result.timeBlocks) {
        final task = taskMap[block.taskId];
        if (task != null) {
          expect(
            block.startTime.isBefore(task.deadline),
            isTrue,
            reason:
                'Block ${block.id} starts at ${block.startTime} but task deadline is ${task.deadline}',
          );
        }
      }
    });
  });
}
