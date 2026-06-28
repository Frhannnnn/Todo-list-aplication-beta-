// test/services/smart_scheduler_service_test.dart
//
// Unit tests for SmartSchedulerService slot utilities and conflict detection.
// Tests getAvailableSlots(), validateNoOverlaps(), and detectConflicts() methods.
//
// **Validates: Requirements 1.1, 2.1, 3.1, 3.2, 6.2**

import 'package:flutter_test/flutter_test.dart';
import 'package:tugasku/models/time_block_model.dart';
import 'package:tugasku/models/schedule_config_model.dart';
import 'package:tugasku/models/task_model.dart';
import 'package:tugasku/services/smart_scheduler_service.dart';

void main() {
  late SmartSchedulerService scheduler;

  setUp(() {
    scheduler = SmartSchedulerService();
  });

  // ===========================================================================
  // getAvailableSlots() tests
  // ===========================================================================
  group('getAvailableSlots', () {
    test('returns empty list when from >= until', () {
      final config = ScheduleConfig();
      final from = DateTime(2024, 6, 15, 10);
      final until = DateTime(2024, 6, 15, 10);

      final slots = scheduler.getAvailableSlots(
        from: from,
        until: until,
        occupiedSlots: {},
        config: config,
      );

      expect(slots, isEmpty);
    });

    test('returns empty list when from is after until', () {
      final config = ScheduleConfig();
      final from = DateTime(2024, 6, 15, 12);
      final until = DateTime(2024, 6, 15, 10);

      final slots = scheduler.getAvailableSlots(
        from: from,
        until: until,
        occupiedSlots: {},
        config: config,
      );

      expect(slots, isEmpty);
    });

    test('returns all hour-aligned slots between from and until', () {
      final config = ScheduleConfig();
      final from = DateTime(2024, 6, 15, 8);
      final until = DateTime(2024, 6, 15, 12);

      final slots = scheduler.getAvailableSlots(
        from: from,
        until: until,
        occupiedSlots: {},
        config: config,
      );

      // 8:00, 9:00, 10:00, 11:00 — all within PWH (8-17)
      expect(slots.length, equals(4));
      expect(slots[0], equals(DateTime(2024, 6, 15, 8)));
      expect(slots[1], equals(DateTime(2024, 6, 15, 9)));
      expect(slots[2], equals(DateTime(2024, 6, 15, 10)));
      expect(slots[3], equals(DateTime(2024, 6, 15, 11)));
    });

    test('excludes occupied slots', () {
      final config = ScheduleConfig();
      final from = DateTime(2024, 6, 15, 8);
      final until = DateTime(2024, 6, 15, 12);
      final occupied = {
        DateTime(2024, 6, 15, 9),
        DateTime(2024, 6, 15, 11),
      };

      final slots = scheduler.getAvailableSlots(
        from: from,
        until: until,
        occupiedSlots: occupied,
        config: config,
      );

      expect(slots.length, equals(2));
      expect(slots[0], equals(DateTime(2024, 6, 15, 8)));
      expect(slots[1], equals(DateTime(2024, 6, 15, 10)));
    });

    test('prioritizes PWH slots before non-PWH slots', () {
      // Config: PWH 9:00-11:00
      final config = ScheduleConfig(
        workStartHour: 9,
        workStartMinute: 0,
        workEndHour: 11,
        workEndMinute: 0,
      );
      final from = DateTime(2024, 6, 15, 7);
      final until = DateTime(2024, 6, 15, 14);

      final slots = scheduler.getAvailableSlots(
        from: from,
        until: until,
        occupiedSlots: {},
        config: config,
      );

      // Total slots: 7:00, 8:00, 9:00, 10:00, 11:00, 12:00, 13:00
      // PWH (9-11): 9:00, 10:00
      // Non-PWH: 7:00, 8:00, 11:00, 12:00, 13:00
      expect(slots.length, equals(7));
      // PWH slots first
      expect(slots[0], equals(DateTime(2024, 6, 15, 9)));
      expect(slots[1], equals(DateTime(2024, 6, 15, 10)));
      // Then non-PWH slots
      expect(slots[2], equals(DateTime(2024, 6, 15, 7)));
      expect(slots[3], equals(DateTime(2024, 6, 15, 8)));
      expect(slots[4], equals(DateTime(2024, 6, 15, 11)));
      expect(slots[5], equals(DateTime(2024, 6, 15, 12)));
      expect(slots[6], equals(DateTime(2024, 6, 15, 13)));
    });

    test('normalizes non-hour-aligned from to next hour', () {
      final config = ScheduleConfig();
      // from is 8:30, should be normalized to 9:00
      final from = DateTime(2024, 6, 15, 8, 30);
      final until = DateTime(2024, 6, 15, 12);

      final slots = scheduler.getAvailableSlots(
        from: from,
        until: until,
        occupiedSlots: {},
        config: config,
      );

      // Should start from 9:00: 9:00, 10:00, 11:00
      expect(slots.length, equals(3));
      expect(slots[0], equals(DateTime(2024, 6, 15, 9)));
      expect(slots[1], equals(DateTime(2024, 6, 15, 10)));
      expect(slots[2], equals(DateTime(2024, 6, 15, 11)));
    });

    test('handles cross-midnight PWH config', () {
      // Config: PWH 22:00-06:00 (cross-midnight)
      final config = ScheduleConfig(
        workStartHour: 22,
        workStartMinute: 0,
        workEndHour: 6,
        workEndMinute: 0,
      );
      final from = DateTime(2024, 6, 15, 20);
      final until = DateTime(2024, 6, 16, 4);

      final slots = scheduler.getAvailableSlots(
        from: from,
        until: until,
        occupiedSlots: {},
        config: config,
      );

      // Total slots: 20:00, 21:00, 22:00, 23:00, 0:00, 1:00, 2:00, 3:00
      // PWH (22:00-06:00): 22:00, 23:00, 0:00, 1:00, 2:00, 3:00
      // Non-PWH: 20:00, 21:00
      expect(slots.length, equals(8));
      // PWH slots first
      expect(slots[0], equals(DateTime(2024, 6, 15, 22)));
      expect(slots[1], equals(DateTime(2024, 6, 15, 23)));
      expect(slots[2], equals(DateTime(2024, 6, 16, 0)));
      expect(slots[3], equals(DateTime(2024, 6, 16, 1)));
      expect(slots[4], equals(DateTime(2024, 6, 16, 2)));
      expect(slots[5], equals(DateTime(2024, 6, 16, 3)));
      // Non-PWH slots
      expect(slots[6], equals(DateTime(2024, 6, 15, 20)));
      expect(slots[7], equals(DateTime(2024, 6, 15, 21)));
    });

    test('returns empty when all slots are occupied', () {
      final config = ScheduleConfig();
      final from = DateTime(2024, 6, 15, 8);
      final until = DateTime(2024, 6, 15, 11);
      final occupied = {
        DateTime(2024, 6, 15, 8),
        DateTime(2024, 6, 15, 9),
        DateTime(2024, 6, 15, 10),
      };

      final slots = scheduler.getAvailableSlots(
        from: from,
        until: until,
        occupiedSlots: occupied,
        config: config,
      );

      expect(slots, isEmpty);
    });

    test('handles single slot range', () {
      final config = ScheduleConfig();
      final from = DateTime(2024, 6, 15, 10);
      final until = DateTime(2024, 6, 15, 11);

      final slots = scheduler.getAvailableSlots(
        from: from,
        until: until,
        occupiedSlots: {},
        config: config,
      );

      expect(slots.length, equals(1));
      expect(slots[0], equals(DateTime(2024, 6, 15, 10)));
    });
  });

  // ===========================================================================
  // validateNoOverlaps() tests
  // ===========================================================================
  group('validateNoOverlaps', () {
    test('returns true for empty list', () {
      expect(scheduler.validateNoOverlaps([]), isTrue);
    });

    test('returns true for single block', () {
      final block = TimeBlock(
        id: 'b1',
        taskId: 't1',
        startTime: DateTime(2024, 6, 15, 8),
        endTime: DateTime(2024, 6, 15, 9),
      );

      expect(scheduler.validateNoOverlaps([block]), isTrue);
    });

    test('returns true for non-overlapping blocks', () {
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
        TimeBlock(
          id: 'b3',
          taskId: 't1',
          startTime: DateTime(2024, 6, 15, 10),
          endTime: DateTime(2024, 6, 15, 11),
        ),
      ];

      expect(scheduler.validateNoOverlaps(blocks), isTrue);
    });

    test('returns false when two blocks share the same slot', () {
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

      expect(scheduler.validateNoOverlaps(blocks), isFalse);
    });

    test('returns false when overlap exists among many blocks', () {
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
        TimeBlock(
          id: 'b3',
          taskId: 't3',
          startTime: DateTime(2024, 6, 15, 10),
          endTime: DateTime(2024, 6, 15, 11),
        ),
        TimeBlock(
          id: 'b4',
          taskId: 't4',
          startTime: DateTime(2024, 6, 15, 9), // Overlaps with b2
          endTime: DateTime(2024, 6, 15, 10),
        ),
      ];

      expect(scheduler.validateNoOverlaps(blocks), isFalse);
    });

    test('returns true for blocks on different days at same hour', () {
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
          startTime: DateTime(2024, 6, 16, 8),
          endTime: DateTime(2024, 6, 16, 9),
        ),
      ];

      expect(scheduler.validateNoOverlaps(blocks), isTrue);
    });
  });

  // ===========================================================================
  // detectConflicts() tests
  // ===========================================================================
  group('detectConflicts', () {
    /// Helper to create a Task with specific SAW score, deadline, and createdAt
    Task createTask({
      required String id,
      double sawScore = 0.5,
      DateTime? deadline,
      DateTime? createdAt,
    }) {
      return Task(
        id: id,
        namaTugas: 'Task $id',
        mataKuliah: 'CS101',
        deadline: deadline ?? DateTime(2024, 6, 20, 17),
        tingkatKepentingan: 3,
        tingkatUrgensi: 3,
        estimasiWaktu: 2,
        createdAt: createdAt ?? DateTime(2024, 6, 1),
        sawScore: sawScore,
      );
    }

    test('returns empty list when no blocks provided', () {
      final conflicts = scheduler.detectConflicts([], tasks: []);
      expect(conflicts, isEmpty);
    });

    test('returns empty list for single block', () {
      final blocks = [
        TimeBlock(
          id: 'b1',
          taskId: 't1',
          startTime: DateTime(2024, 6, 15, 8),
          endTime: DateTime(2024, 6, 15, 9),
        ),
      ];
      final tasks = [createTask(id: 't1')];

      final conflicts = scheduler.detectConflicts(blocks, tasks: tasks);
      expect(conflicts, isEmpty);
    });

    test('returns empty list when no overlapping blocks', () {
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

      final conflicts = scheduler.detectConflicts(blocks, tasks: tasks);
      expect(conflicts, isEmpty);
    });

    test('detects conflict when two blocks share the same slot', () {
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
        createTask(id: 't1', sawScore: 0.8),
        createTask(id: 't2', sawScore: 0.6),
      ];

      final conflicts = scheduler.detectConflicts(blocks, tasks: tasks);

      expect(conflicts.length, equals(1));
      expect(conflicts[0].slotTime, equals(DateTime(2024, 6, 15, 8).toIso8601String()));
      expect(conflicts[0].taskIds, containsAll(['t1', 't2']));
      expect(conflicts[0].winnerId, equals('t1')); // Higher SAW score
      expect(conflicts[0].sawScores['t1'], equals(0.8));
      expect(conflicts[0].sawScores['t2'], equals(0.6));
    });

    test('detects multiple conflicts on different slots', () {
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
          taskId: 't1',
          startTime: DateTime(2024, 6, 15, 10),
          endTime: DateTime(2024, 6, 15, 11),
        ),
        TimeBlock(
          id: 'b4',
          taskId: 't3',
          startTime: DateTime(2024, 6, 15, 10),
          endTime: DateTime(2024, 6, 15, 11),
        ),
      ];
      final tasks = [
        createTask(id: 't1', sawScore: 0.8),
        createTask(id: 't2', sawScore: 0.6),
        createTask(id: 't3', sawScore: 0.9),
      ];

      final conflicts = scheduler.detectConflicts(blocks, tasks: tasks);

      expect(conflicts.length, equals(2));
    });

    test('winner is task with highest SAW score', () {
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
      ];
      final tasks = [
        createTask(id: 't1', sawScore: 0.3),
        createTask(id: 't2', sawScore: 0.9),
        createTask(id: 't3', sawScore: 0.5),
      ];

      final conflicts = scheduler.detectConflicts(blocks, tasks: tasks);

      expect(conflicts.length, equals(1));
      expect(conflicts[0].winnerId, equals('t2')); // Highest SAW score
      expect(conflicts[0].taskIds.length, equals(3));
    });

    test('tiebreaker: earliest deadline wins when SAW scores are equal', () {
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
        ),
        createTask(
          id: 't2',
          sawScore: 0.7,
          deadline: DateTime(2024, 6, 18, 17), // Earlier deadline
        ),
      ];

      final conflicts = scheduler.detectConflicts(blocks, tasks: tasks);

      expect(conflicts.length, equals(1));
      expect(conflicts[0].winnerId, equals('t2')); // Earlier deadline
    });

    test('tiebreaker: earliest createdAt wins when SAW and deadline are equal', () {
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

      expect(conflicts.length, equals(1));
      expect(conflicts[0].winnerId, equals('t2')); // Earlier createdAt
    });

    test('handles three-way conflict correctly', () {
      final blocks = [
        TimeBlock(
          id: 'b1',
          taskId: 't1',
          startTime: DateTime(2024, 6, 15, 14),
          endTime: DateTime(2024, 6, 15, 15),
        ),
        TimeBlock(
          id: 'b2',
          taskId: 't2',
          startTime: DateTime(2024, 6, 15, 14),
          endTime: DateTime(2024, 6, 15, 15),
        ),
        TimeBlock(
          id: 'b3',
          taskId: 't3',
          startTime: DateTime(2024, 6, 15, 14),
          endTime: DateTime(2024, 6, 15, 15),
        ),
      ];
      final tasks = [
        createTask(id: 't1', sawScore: 0.4),
        createTask(id: 't2', sawScore: 0.6),
        createTask(id: 't3', sawScore: 0.8),
      ];

      final conflicts = scheduler.detectConflicts(blocks, tasks: tasks);

      expect(conflicts.length, equals(1));
      expect(conflicts[0].winnerId, equals('t3'));
      expect(conflicts[0].sawScores.length, equals(3));
      expect(conflicts[0].sawScores['t1'], equals(0.4));
      expect(conflicts[0].sawScores['t2'], equals(0.6));
      expect(conflicts[0].sawScores['t3'], equals(0.8));
    });

    test('slotTime is in ISO 8601 format', () {
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
        createTask(id: 't1', sawScore: 0.8),
        createTask(id: 't2', sawScore: 0.6),
      ];

      final conflicts = scheduler.detectConflicts(blocks, tasks: tasks);

      // Verify it's a valid ISO 8601 string
      expect(conflicts[0].slotTime, isNotEmpty);
      expect(() => DateTime.parse(conflicts[0].slotTime), returnsNormally);
    });

    test('does not report non-conflicting slots alongside conflicting ones', () {
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
          taskId: 't1',
          startTime: DateTime(2024, 6, 15, 9),
          endTime: DateTime(2024, 6, 15, 10),
        ),
        TimeBlock(
          id: 'b4',
          taskId: 't2',
          startTime: DateTime(2024, 6, 15, 10),
          endTime: DateTime(2024, 6, 15, 11),
        ),
      ];
      final tasks = [
        createTask(id: 't1', sawScore: 0.8),
        createTask(id: 't2', sawScore: 0.6),
      ];

      final conflicts = scheduler.detectConflicts(blocks, tasks: tasks);

      // Only the 8:00 slot has a conflict
      expect(conflicts.length, equals(1));
      expect(conflicts[0].slotTime, equals(DateTime(2024, 6, 15, 8).toIso8601String()));
    });
  });
}
