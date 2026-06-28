// test/services/resolve_conflicts_test.dart
//
// Unit tests for SmartSchedulerService.resolveConflicts() method.
// Tests conflict resolution with recursive shift algorithm.
//
// **Validates: Requirements 4.1, 4.2, 4.3, 4.4, 4.5, 4.6**

import 'package:flutter_test/flutter_test.dart';
import 'package:tugasku/models/time_block_model.dart';
import 'package:tugasku/models/schedule_config_model.dart';
import 'package:tugasku/models/schedule_result_model.dart';
import 'package:tugasku/models/task_model.dart';
import 'package:tugasku/services/smart_scheduler_service.dart';

void main() {
  late SmartSchedulerService scheduler;

  setUp(() {
    scheduler = SmartSchedulerService();
  });

  /// Helper to create a Task with specific SAW score, deadline, and createdAt
  Task createTask({
    required String id,
    double sawScore = 0.5,
    DateTime? deadline,
    DateTime? createdAt,
    int estimasiWaktu = 2,
  }) {
    return Task(
      id: id,
      namaTugas: 'Task $id',
      mataKuliah: 'CS101',
      deadline: deadline ?? DateTime(2024, 6, 20, 17),
      tingkatKepentingan: 3,
      tingkatUrgensi: 3,
      estimasiWaktu: estimasiWaktu,
      createdAt: createdAt ?? DateTime(2024, 6, 1),
      sawScore: sawScore,
    );
  }

  group('resolveConflicts', () {
    test('returns blocks unchanged when no conflicts exist', () {
      final now = DateTime(2024, 6, 15, 7);
      final config = ScheduleConfig();
      final blocks = [
        TimeBlock(
          id: 'b1',
          taskId: 't1',
          startTime: DateTime(2024, 6, 15, 8),
          endTime: DateTime(2024, 6, 15, 9),
        ),
        TimeBlock(
          id: 'b2',
          taskId: 't2',
          startTime: DateTime(2024, 6, 15, 9),
          endTime: DateTime(2024, 6, 15, 10),
        ),
      ];
      final tasks = [
        createTask(id: 't1', sawScore: 0.8),
        createTask(id: 't2', sawScore: 0.6),
      ];
      final conflicts = <ScheduleConflict>[];

      final result = scheduler.resolveConflicts(
        blocks: blocks,
        conflicts: conflicts,
        tasks: tasks,
        occupiedSlots: <DateTime>{},
        config: config,
        now: now,
      );

      expect(result.blocks.length, equals(2));
      expect(result.warnings, isEmpty);
    });

    test('higher SAW score wins the slot', () {
      final now = DateTime(2024, 6, 15, 6);
      final config = ScheduleConfig();
      final blocks = [
        TimeBlock(
          id: 'b1',
          taskId: 't1',
          startTime: DateTime(2024, 6, 15, 8),
          endTime: DateTime(2024, 6, 15, 9),
        ),
        TimeBlock(
          id: 'b2',
          taskId: 't2',
          startTime: DateTime(2024, 6, 15, 8),
          endTime: DateTime(2024, 6, 15, 9),
        ),
      ];
      final tasks = [
        createTask(id: 't1', sawScore: 0.9),
        createTask(id: 't2', sawScore: 0.5),
      ];
      final conflicts = scheduler.detectConflicts(blocks, tasks: tasks);

      final result = scheduler.resolveConflicts(
        blocks: blocks,
        conflicts: conflicts,
        tasks: tasks,
        occupiedSlots: <DateTime>{},
        config: config,
        now: now,
      );

      // No overlaps in result
      expect(scheduler.validateNoOverlaps(result.blocks), isTrue);
      // Winner (t1) keeps the 8:00 slot
      final t1Block = result.blocks.where((b) => b.taskId == 't1').first;
      expect(t1Block.startTime, equals(DateTime(2024, 6, 15, 8)));
      // Loser (t2) is shifted to a different slot
      final t2Blocks = result.blocks.where((b) => b.taskId == 't2');
      expect(t2Blocks.length, equals(1));
      expect(t2Blocks.first.startTime, isNot(equals(DateTime(2024, 6, 15, 8))));
    });

    test('tiebreaker: earliest deadline wins when SAW scores are equal', () {
      final now = DateTime(2024, 6, 15, 6);
      final config = ScheduleConfig();
      final blocks = [
        TimeBlock(
          id: 'b1',
          taskId: 't1',
          startTime: DateTime(2024, 6, 15, 8),
          endTime: DateTime(2024, 6, 15, 9),
        ),
        TimeBlock(
          id: 'b2',
          taskId: 't2',
          startTime: DateTime(2024, 6, 15, 8),
          endTime: DateTime(2024, 6, 15, 9),
        ),
      ];
      final tasks = [
        createTask(
          id: 't1',
          sawScore: 0.7,
          deadline: DateTime(2024, 6, 25, 17),
        ),
        createTask(
          id: 't2',
          sawScore: 0.7,
          deadline: DateTime(2024, 6, 18, 17), // Earlier deadline
        ),
      ];
      final conflicts = scheduler.detectConflicts(blocks, tasks: tasks);

      final result = scheduler.resolveConflicts(
        blocks: blocks,
        conflicts: conflicts,
        tasks: tasks,
        occupiedSlots: <DateTime>{},
        config: config,
        now: now,
      );

      // t2 (earlier deadline) wins the 8:00 slot
      final t2Block = result.blocks.where((b) => b.taskId == 't2').first;
      expect(t2Block.startTime, equals(DateTime(2024, 6, 15, 8)));
      expect(scheduler.validateNoOverlaps(result.blocks), isTrue);
    });

    test('tiebreaker: earliest createdAt wins when SAW and deadline are equal', () {
      final now = DateTime(2024, 6, 15, 6);
      final config = ScheduleConfig();
      final blocks = [
        TimeBlock(
          id: 'b1',
          taskId: 't1',
          startTime: DateTime(2024, 6, 15, 8),
          endTime: DateTime(2024, 6, 15, 9),
        ),
        TimeBlock(
          id: 'b2',
          taskId: 't2',
          startTime: DateTime(2024, 6, 15, 8),
          endTime: DateTime(2024, 6, 15, 9),
        ),
      ];
      final tasks = [
        createTask(
          id: 't1',
          sawScore: 0.7,
          deadline: DateTime(2024, 6, 20, 17),
          createdAt: DateTime(2024, 6, 5),
        ),
        createTask(
          id: 't2',
          sawScore: 0.7,
          deadline: DateTime(2024, 6, 20, 17),
          createdAt: DateTime(2024, 6, 2), // Earlier createdAt
        ),
      ];
      final conflicts = scheduler.detectConflicts(blocks, tasks: tasks);

      final result = scheduler.resolveConflicts(
        blocks: blocks,
        conflicts: conflicts,
        tasks: tasks,
        occupiedSlots: <DateTime>{},
        config: config,
        now: now,
      );

      // t2 (earlier createdAt) wins the 8:00 slot
      final t2Block = result.blocks.where((b) => b.taskId == 't2').first;
      expect(t2Block.startTime, equals(DateTime(2024, 6, 15, 8)));
      expect(scheduler.validateNoOverlaps(result.blocks), isTrue);
    });

    test('loser is shifted backward to available slot', () {
      final now = DateTime(2024, 6, 15, 6);
      final config = ScheduleConfig();
      final blocks = [
        TimeBlock(
          id: 'b1',
          taskId: 't1',
          startTime: DateTime(2024, 6, 15, 10),
          endTime: DateTime(2024, 6, 15, 11),
        ),
        TimeBlock(
          id: 'b2',
          taskId: 't2',
          startTime: DateTime(2024, 6, 15, 10),
          endTime: DateTime(2024, 6, 15, 11),
        ),
      ];
      final tasks = [
        createTask(id: 't1', sawScore: 0.9),
        createTask(id: 't2', sawScore: 0.4),
      ];
      final conflicts = scheduler.detectConflicts(blocks, tasks: tasks);

      final result = scheduler.resolveConflicts(
        blocks: blocks,
        conflicts: conflicts,
        tasks: tasks,
        occupiedSlots: <DateTime>{},
        config: config,
        now: now,
      );

      // t2 should be shifted to a slot before 10:00 (but after now)
      final t2Block = result.blocks.where((b) => b.taskId == 't2').first;
      expect(t2Block.startTime.isBefore(DateTime(2024, 6, 15, 10)), isTrue);
      expect(
        t2Block.startTime.isAfter(now) || t2Block.startTime.isAtSameMomentAs(now),
        isTrue,
      );
      expect(scheduler.validateNoOverlaps(result.blocks), isTrue);
    });

    test('marks task as unschedulable when no slot available', () {
      final now = DateTime(2024, 6, 15, 9);
      final config = ScheduleConfig();
      // Conflict at 10:00, but all slots between now (9:00) and 10:00 are occupied
      final blocks = [
        TimeBlock(
          id: 'b1',
          taskId: 't1',
          startTime: DateTime(2024, 6, 15, 10),
          endTime: DateTime(2024, 6, 15, 11),
        ),
        TimeBlock(
          id: 'b2',
          taskId: 't2',
          startTime: DateTime(2024, 6, 15, 10),
          endTime: DateTime(2024, 6, 15, 11),
        ),
      ];
      final tasks = [
        createTask(id: 't1', sawScore: 0.9),
        createTask(id: 't2', sawScore: 0.4),
      ];
      final conflicts = scheduler.detectConflicts(blocks, tasks: tasks);

      // Occupy the only slot between now and the conflict (9:00)
      final occupiedSlots = <DateTime>{DateTime(2024, 6, 15, 9)};

      final result = scheduler.resolveConflicts(
        blocks: blocks,
        conflicts: conflicts,
        tasks: tasks,
        occupiedSlots: occupiedSlots,
        config: config,
        now: now,
      );

      // t2 should be marked as unschedulable (removed from blocks)
      final t2Blocks = result.blocks.where((b) => b.taskId == 't2');
      expect(t2Blocks, isEmpty);
      // Warning should be emitted
      expect(result.warnings.length, equals(1));
      expect(result.warnings[0].taskId, equals('t2'));
      expect(result.warnings[0].type, equals(WarningType.unschedulable));
    });

    test('resolves cascading conflicts (recursive shift)', () {
      final now = DateTime(2024, 6, 15, 6);
      final config = ScheduleConfig();
      // Three tasks all want the same slot at 10:00
      final blocks = [
        TimeBlock(
          id: 'b1',
          taskId: 't1',
          startTime: DateTime(2024, 6, 15, 10),
          endTime: DateTime(2024, 6, 15, 11),
        ),
        TimeBlock(
          id: 'b2',
          taskId: 't2',
          startTime: DateTime(2024, 6, 15, 10),
          endTime: DateTime(2024, 6, 15, 11),
        ),
        TimeBlock(
          id: 'b3',
          taskId: 't3',
          startTime: DateTime(2024, 6, 15, 10),
          endTime: DateTime(2024, 6, 15, 11),
        ),
      ];
      final tasks = [
        createTask(id: 't1', sawScore: 0.9),
        createTask(id: 't2', sawScore: 0.6),
        createTask(id: 't3', sawScore: 0.3),
      ];
      final conflicts = scheduler.detectConflicts(blocks, tasks: tasks);

      final result = scheduler.resolveConflicts(
        blocks: blocks,
        conflicts: conflicts,
        tasks: tasks,
        occupiedSlots: <DateTime>{},
        config: config,
        now: now,
      );

      // All three tasks should have blocks, no overlaps
      expect(result.blocks.length, equals(3));
      expect(scheduler.validateNoOverlaps(result.blocks), isTrue);
      // Winner keeps the slot
      final t1Block = result.blocks.where((b) => b.taskId == 't1').first;
      expect(t1Block.startTime, equals(DateTime(2024, 6, 15, 10)));
      expect(result.warnings, isEmpty);
    });

    test('loop terminates when all conflicts are resolved', () {
      final now = DateTime(2024, 6, 15, 6);
      final config = ScheduleConfig();
      // Two conflicts on different slots
      final blocks = [
        TimeBlock(
          id: 'b1',
          taskId: 't1',
          startTime: DateTime(2024, 6, 15, 8),
          endTime: DateTime(2024, 6, 15, 9),
        ),
        TimeBlock(
          id: 'b2',
          taskId: 't2',
          startTime: DateTime(2024, 6, 15, 8),
          endTime: DateTime(2024, 6, 15, 9),
        ),
        TimeBlock(
          id: 'b3',
          taskId: 't3',
          startTime: DateTime(2024, 6, 15, 9),
          endTime: DateTime(2024, 6, 15, 10),
        ),
        TimeBlock(
          id: 'b4',
          taskId: 't4',
          startTime: DateTime(2024, 6, 15, 9),
          endTime: DateTime(2024, 6, 15, 10),
        ),
      ];
      final tasks = [
        createTask(id: 't1', sawScore: 0.9),
        createTask(id: 't2', sawScore: 0.5),
        createTask(id: 't3', sawScore: 0.8),
        createTask(id: 't4', sawScore: 0.4),
      ];
      final conflicts = scheduler.detectConflicts(blocks, tasks: tasks);

      final result = scheduler.resolveConflicts(
        blocks: blocks,
        conflicts: conflicts,
        tasks: tasks,
        occupiedSlots: <DateTime>{},
        config: config,
        now: now,
      );

      // All blocks should be resolved without overlaps
      expect(result.blocks.length, equals(4));
      expect(scheduler.validateNoOverlaps(result.blocks), isTrue);
      expect(result.warnings, isEmpty);
    });

    test('respects occupied slots when shifting', () {
      final now = DateTime(2024, 6, 15, 7);
      final config = ScheduleConfig();
      final blocks = [
        TimeBlock(
          id: 'b1',
          taskId: 't1',
          startTime: DateTime(2024, 6, 15, 9),
          endTime: DateTime(2024, 6, 15, 10),
        ),
        TimeBlock(
          id: 'b2',
          taskId: 't2',
          startTime: DateTime(2024, 6, 15, 9),
          endTime: DateTime(2024, 6, 15, 10),
        ),
      ];
      final tasks = [
        createTask(id: 't1', sawScore: 0.9),
        createTask(id: 't2', sawScore: 0.4),
      ];
      final conflicts = scheduler.detectConflicts(blocks, tasks: tasks);

      // Slot 8:00 is already occupied by another task
      final occupiedSlots = <DateTime>{DateTime(2024, 6, 15, 8)};

      final result = scheduler.resolveConflicts(
        blocks: blocks,
        conflicts: conflicts,
        tasks: tasks,
        occupiedSlots: occupiedSlots,
        config: config,
        now: now,
      );

      // t2 should NOT be placed at 8:00 (occupied), should go to 7:00
      final t2Block = result.blocks.where((b) => b.taskId == 't2').first;
      expect(t2Block.startTime, isNot(equals(DateTime(2024, 6, 15, 8))));
      expect(t2Block.startTime, isNot(equals(DateTime(2024, 6, 15, 9))));
      expect(scheduler.validateNoOverlaps(result.blocks), isTrue);
    });

    test('final result has no overlaps (requirement 4.6)', () {
      final now = DateTime(2024, 6, 15, 5);
      final config = ScheduleConfig();
      // Multiple conflicts
      final blocks = [
        TimeBlock(
          id: 'b1',
          taskId: 't1',
          startTime: DateTime(2024, 6, 15, 8),
          endTime: DateTime(2024, 6, 15, 9),
        ),
        TimeBlock(
          id: 'b2',
          taskId: 't2',
          startTime: DateTime(2024, 6, 15, 8),
          endTime: DateTime(2024, 6, 15, 9),
        ),
        TimeBlock(
          id: 'b3',
          taskId: 't3',
          startTime: DateTime(2024, 6, 15, 8),
          endTime: DateTime(2024, 6, 15, 9),
        ),
        TimeBlock(
          id: 'b4',
          taskId: 't4',
          startTime: DateTime(2024, 6, 15, 9),
          endTime: DateTime(2024, 6, 15, 10),
        ),
        TimeBlock(
          id: 'b5',
          taskId: 't5',
          startTime: DateTime(2024, 6, 15, 9),
          endTime: DateTime(2024, 6, 15, 10),
        ),
      ];
      final tasks = [
        createTask(id: 't1', sawScore: 0.9),
        createTask(id: 't2', sawScore: 0.7),
        createTask(id: 't3', sawScore: 0.5),
        createTask(id: 't4', sawScore: 0.8),
        createTask(id: 't5', sawScore: 0.3),
      ];
      final conflicts = scheduler.detectConflicts(blocks, tasks: tasks);

      final result = scheduler.resolveConflicts(
        blocks: blocks,
        conflicts: conflicts,
        tasks: tasks,
        occupiedSlots: <DateTime>{},
        config: config,
        now: now,
      );

      // Final result must have no overlaps
      expect(scheduler.validateNoOverlaps(result.blocks), isTrue);
      expect(result.warnings, isEmpty);
    });
  });
}
