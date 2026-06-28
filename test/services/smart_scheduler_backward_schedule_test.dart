// test/services/smart_scheduler_backward_schedule_test.dart
//
// Unit tests for SmartSchedulerService.backwardSchedule() method.
// Validates: Requirements 1.1, 1.2, 1.3, 1.5, 1.6, 1.7, 6.2, 6.3

import 'package:flutter_test/flutter_test.dart';
import 'package:tugasku/models/task_model.dart';
import 'package:tugasku/models/schedule_config_model.dart';
import 'package:tugasku/services/smart_scheduler_service.dart';

void main() {
  late SmartSchedulerService scheduler;
  late ScheduleConfig defaultConfig;

  setUp(() {
    scheduler = SmartSchedulerService();
    defaultConfig = ScheduleConfig(); // 08:00-17:00
  });

  /// Helper to create a task with given parameters.
  Task createTask({
    String id = 'task-1',
    required DateTime deadline,
    int estimasiWaktu = 3,
    double sawScore = 0.5,
  }) {
    return Task(
      id: id,
      namaTugas: 'Test Task',
      mataKuliah: 'Test',
      deadline: deadline,
      tingkatKepentingan: 3,
      tingkatUrgensi: 3,
      estimasiWaktu: estimasiWaktu,
      createdAt: DateTime(2024, 1, 1),
      sawScore: sawScore,
    );
  }

  group('backwardSchedule - deadline validation', () {
    test('returns empty list when deadline is in the past', () {
      final now = DateTime(2024, 6, 15, 10, 0, 0);
      final task = createTask(
        deadline: DateTime(2024, 6, 14, 10, 0, 0), // yesterday
      );

      final result = scheduler.backwardSchedule(
        task: task,
        occupiedSlots: {},
        config: defaultConfig,
        now: now,
      );

      expect(result, isEmpty);
    });

    test('returns empty list when deadline equals now', () {
      final now = DateTime(2024, 6, 15, 10, 0, 0);
      final task = createTask(deadline: now);

      final result = scheduler.backwardSchedule(
        task: task,
        occupiedSlots: {},
        config: defaultConfig,
        now: now,
      );

      expect(result, isEmpty);
    });
  });

  group('backwardSchedule - basic allocation', () {
    test('allocates correct number of blocks for task with sufficient slots', () {
      final now = DateTime(2024, 6, 15, 8, 0, 0);
      final task = createTask(
        deadline: DateTime(2024, 6, 15, 17, 0, 0), // 9 hours available
        estimasiWaktu: 3,
      );

      final result = scheduler.backwardSchedule(
        task: task,
        occupiedSlots: {},
        config: defaultConfig,
        now: now,
      );

      expect(result.length, 3);
    });

    test('all blocks have correct taskId', () {
      final now = DateTime(2024, 6, 15, 8, 0, 0);
      final task = createTask(
        id: 'my-task',
        deadline: DateTime(2024, 6, 15, 17, 0, 0),
        estimasiWaktu: 2,
      );

      final result = scheduler.backwardSchedule(
        task: task,
        occupiedSlots: {},
        config: defaultConfig,
        now: now,
      );

      for (final block in result) {
        expect(block.taskId, 'my-task');
      }
    });

    test('all blocks have duration of exactly 1 hour', () {
      final now = DateTime(2024, 6, 15, 8, 0, 0);
      final task = createTask(
        deadline: DateTime(2024, 6, 15, 17, 0, 0),
        estimasiWaktu: 4,
      );

      final result = scheduler.backwardSchedule(
        task: task,
        occupiedSlots: {},
        config: defaultConfig,
        now: now,
      );

      for (final block in result) {
        final duration = block.endTime.difference(block.startTime);
        expect(duration, const Duration(hours: 1));
      }
    });

    test('all blocks have hour-aligned startTime', () {
      final now = DateTime(2024, 6, 15, 8, 0, 0);
      final task = createTask(
        deadline: DateTime(2024, 6, 15, 17, 0, 0),
        estimasiWaktu: 5,
      );

      final result = scheduler.backwardSchedule(
        task: task,
        occupiedSlots: {},
        config: defaultConfig,
        now: now,
      );

      for (final block in result) {
        expect(block.startTime.minute, 0);
        expect(block.startTime.second, 0);
        expect(block.startTime.millisecond, 0);
      }
    });

    test('all blocks are before deadline', () {
      final now = DateTime(2024, 6, 15, 8, 0, 0);
      final deadline = DateTime(2024, 6, 15, 17, 0, 0);
      final task = createTask(
        deadline: deadline,
        estimasiWaktu: 5,
      );

      final result = scheduler.backwardSchedule(
        task: task,
        occupiedSlots: {},
        config: defaultConfig,
        now: now,
      );

      for (final block in result) {
        expect(block.startTime.isBefore(deadline), isTrue);
      }
    });

    test('no block is allocated before current time', () {
      final now = DateTime(2024, 6, 15, 10, 0, 0);
      final task = createTask(
        deadline: DateTime(2024, 6, 15, 17, 0, 0),
        estimasiWaktu: 5,
      );

      final result = scheduler.backwardSchedule(
        task: task,
        occupiedSlots: {},
        config: defaultConfig,
        now: now,
      );

      for (final block in result) {
        expect(
          block.startTime.isAfter(now) || block.startTime.isAtSameMomentAs(now),
          isTrue,
        );
      }
    });

    test('each block has a unique id', () {
      final now = DateTime(2024, 6, 15, 8, 0, 0);
      final task = createTask(
        deadline: DateTime(2024, 6, 15, 17, 0, 0),
        estimasiWaktu: 5,
      );

      final result = scheduler.backwardSchedule(
        task: task,
        occupiedSlots: {},
        config: defaultConfig,
        now: now,
      );

      final ids = result.map((b) => b.id).toSet();
      expect(ids.length, result.length);
    });
  });

  group('backwardSchedule - PWH prioritization', () {
    test('prioritizes PWH slots over non-PWH slots', () {
      // now = 06:00, deadline = 20:00
      // PWH = 08:00-17:00 (9 slots)
      // non-PWH before PWH: 06:00, 07:00 (2 slots)
      // non-PWH after PWH: 17:00, 18:00, 19:00 (3 slots)
      // With estimasi=3, should get 3 PWH slots first
      final now = DateTime(2024, 6, 15, 6, 0, 0);
      final task = createTask(
        deadline: DateTime(2024, 6, 15, 20, 0, 0),
        estimasiWaktu: 3,
      );

      final result = scheduler.backwardSchedule(
        task: task,
        occupiedSlots: {},
        config: defaultConfig,
        now: now,
      );

      expect(result.length, 3);
      // All 3 blocks should be within PWH (08:00-17:00)
      for (final block in result) {
        expect(defaultConfig.isWithinWorkHours(block.startTime), isTrue,
            reason: 'Block at ${block.startTime} should be within PWH');
      }
    });

    test('uses non-PWH slots after PWH slots are exhausted', () {
      // now = 06:00, deadline = 20:00
      // PWH = 08:00-17:00 (9 slots)
      // Occupy all PWH slots
      final now = DateTime(2024, 6, 15, 6, 0, 0);
      final occupiedSlots = <DateTime>{};
      for (int h = 8; h < 17; h++) {
        occupiedSlots.add(DateTime(2024, 6, 15, h, 0, 0));
      }

      final task = createTask(
        deadline: DateTime(2024, 6, 15, 20, 0, 0),
        estimasiWaktu: 3,
      );

      final result = scheduler.backwardSchedule(
        task: task,
        occupiedSlots: occupiedSlots,
        config: defaultConfig,
        now: now,
      );

      expect(result.length, 3);
      // All blocks should be non-PWH since PWH is full
      for (final block in result) {
        expect(defaultConfig.isWithinWorkHours(block.startTime), isFalse,
            reason: 'Block at ${block.startTime} should be outside PWH');
      }
    });

    test('fills PWH first then non-PWH when estimation exceeds PWH capacity', () {
      // now = 06:00, deadline = 20:00
      // PWH = 08:00-17:00 (9 slots)
      // non-PWH: 06:00, 07:00, 17:00, 18:00, 19:00 (5 slots)
      // Total available: 14 slots
      // estimasi = 11 → should fill all 9 PWH + 2 non-PWH
      final now = DateTime(2024, 6, 15, 6, 0, 0);
      final task = createTask(
        deadline: DateTime(2024, 6, 15, 20, 0, 0),
        estimasiWaktu: 11,
      );

      final result = scheduler.backwardSchedule(
        task: task,
        occupiedSlots: {},
        config: defaultConfig,
        now: now,
      );

      expect(result.length, 11);

      final pwhBlocks = result.where(
        (b) => defaultConfig.isWithinWorkHours(b.startTime),
      );
      final nonPwhBlocks = result.where(
        (b) => !defaultConfig.isWithinWorkHours(b.startTime),
      );

      expect(pwhBlocks.length, 9); // All PWH slots used
      expect(nonPwhBlocks.length, 2); // 2 non-PWH slots used
    });
  });

  group('backwardSchedule - occupied slots', () {
    test('skips occupied slots', () {
      final now = DateTime(2024, 6, 15, 8, 0, 0);
      final occupiedSlots = {
        DateTime(2024, 6, 15, 9, 0, 0),
        DateTime(2024, 6, 15, 11, 0, 0),
      };

      final task = createTask(
        deadline: DateTime(2024, 6, 15, 17, 0, 0),
        estimasiWaktu: 3,
      );

      final result = scheduler.backwardSchedule(
        task: task,
        occupiedSlots: occupiedSlots,
        config: defaultConfig,
        now: now,
      );

      expect(result.length, 3);
      for (final block in result) {
        expect(occupiedSlots.contains(block.startTime), isFalse);
      }
    });
  });

  group('backwardSchedule - insufficient slots (partial scheduling)', () {
    test('allocates as many blocks as available when estimation exceeds capacity', () {
      // now = 14:00, deadline = 17:00 → only 3 slots available (14, 15, 16)
      // estimasi = 5 → should allocate 3
      final now = DateTime(2024, 6, 15, 14, 0, 0);
      final task = createTask(
        deadline: DateTime(2024, 6, 15, 17, 0, 0),
        estimasiWaktu: 5,
      );

      final result = scheduler.backwardSchedule(
        task: task,
        occupiedSlots: {},
        config: defaultConfig,
        now: now,
      );

      expect(result.length, 3); // min(5, 3) = 3
    });

    test('returns empty list when no slots available between now and deadline', () {
      // now = 16:30, deadline = 17:00 → after normalization, no full hour slot
      final now = DateTime(2024, 6, 15, 16, 30, 0);
      final task = createTask(
        deadline: DateTime(2024, 6, 15, 17, 0, 0),
        estimasiWaktu: 3,
      );

      final result = scheduler.backwardSchedule(
        task: task,
        occupiedSlots: {},
        config: defaultConfig,
        now: now,
      );

      expect(result, isEmpty);
    });

    test('allocates 1 block when only 1 slot available', () {
      // now = 16:00, deadline = 17:00 → 1 slot (16:00)
      final now = DateTime(2024, 6, 15, 16, 0, 0);
      final task = createTask(
        deadline: DateTime(2024, 6, 15, 17, 0, 0),
        estimasiWaktu: 5,
      );

      final result = scheduler.backwardSchedule(
        task: task,
        occupiedSlots: {},
        config: defaultConfig,
        now: now,
      );

      expect(result.length, 1);
      expect(result.first.startTime, DateTime(2024, 6, 15, 16, 0, 0));
    });
  });

  group('backwardSchedule - now normalization', () {
    test('normalizes non-hour-aligned now to next hour', () {
      // now = 08:45 → normalized to 09:00
      // deadline = 12:00 → slots: 09, 10, 11 (3 slots)
      final now = DateTime(2024, 6, 15, 8, 45, 0);
      final task = createTask(
        deadline: DateTime(2024, 6, 15, 12, 0, 0),
        estimasiWaktu: 3,
      );

      final result = scheduler.backwardSchedule(
        task: task,
        occupiedSlots: {},
        config: defaultConfig,
        now: now,
      );

      expect(result.length, 3);
      // First block should be at 09:00 (not 08:00)
      final startTimes = result.map((b) => b.startTime.hour).toList();
      expect(startTimes.contains(8), isFalse);
    });
  });

  group('backwardSchedule - no overlaps in result', () {
    test('all blocks have unique start times', () {
      final now = DateTime(2024, 6, 15, 8, 0, 0);
      final task = createTask(
        deadline: DateTime(2024, 6, 15, 17, 0, 0),
        estimasiWaktu: 7,
      );

      final result = scheduler.backwardSchedule(
        task: task,
        occupiedSlots: {},
        config: defaultConfig,
        now: now,
      );

      final startTimes = result.map((b) => b.startTime).toSet();
      expect(startTimes.length, result.length);
    });

    test('validateNoOverlaps returns true for backward schedule result', () {
      final now = DateTime(2024, 6, 15, 8, 0, 0);
      final task = createTask(
        deadline: DateTime(2024, 6, 15, 17, 0, 0),
        estimasiWaktu: 5,
      );

      final result = scheduler.backwardSchedule(
        task: task,
        occupiedSlots: {},
        config: defaultConfig,
        now: now,
      );

      expect(scheduler.validateNoOverlaps(result), isTrue);
    });
  });
}
