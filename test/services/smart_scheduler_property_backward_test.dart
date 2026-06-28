// test/services/smart_scheduler_property_backward_test.dart
//
// Property-Based Tests for Smart Scheduler backward scheduling.
//
// Feature: smart-scheduling, Property 3: Backward Scheduling Respects Deadline
// Feature: smart-scheduling, Property 6: Primary Work Hours Preference Ordering
// Feature: smart-scheduling, Property 8: Partial Scheduling Maximizes Allocation
//
// **Validates: Requirements 1.1, 1.3, 1.4, 1.5, 1.7, 6.2, 6.3, 6.4**

import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:tugasku/models/task_model.dart';
import 'package:tugasku/models/time_block_model.dart';
import 'package:tugasku/models/schedule_config_model.dart';
import 'package:tugasku/services/smart_scheduler_service.dart';

// ---------------------------------------------------------------------------
// Generators
// ---------------------------------------------------------------------------

/// Generates a random hour-aligned DateTime in the future relative to [now].
/// Returns a DateTime between 1 and [maxHoursAhead] hours ahead of [now].
DateTime _generateFutureHourAligned(Random rng, DateTime now,
    {int maxHoursAhead = 72}) {
  final hoursAhead = 1 + rng.nextInt(maxHoursAhead);
  final future = now.add(Duration(hours: hoursAhead));
  return DateTime(future.year, future.month, future.day, future.hour);
}

/// Generates a random Task with valid parameters for scheduling.
/// - estimasiWaktu: 1-10
/// - deadline: future (relative to [now])
/// - sawScore: 0.0-1.0
Task _generateRandomTask(Random rng, DateTime now) {
  final estimasi = 1 + rng.nextInt(10); // 1-10 hours
  // Deadline must be far enough in the future to potentially fit the estimation
  final minHoursAhead = estimasi + 1;
  final maxHoursAhead = estimasi + 48;
  final hoursAhead = minHoursAhead + rng.nextInt(maxHoursAhead - minHoursAhead);
  final deadline = DateTime(
    now.year,
    now.month,
    now.day,
    now.hour,
  ).add(Duration(hours: hoursAhead));

  final sawScore = rng.nextDouble(); // 0.0 - 1.0

  return Task(
    id: 'task-${rng.nextInt(100000)}',
    namaTugas: 'Tugas ${rng.nextInt(1000)}',
    mataKuliah: 'MK ${rng.nextInt(100)}',
    deadline: deadline,
    tingkatKepentingan: 1 + rng.nextInt(5),
    tingkatUrgensi: 1 + rng.nextInt(5),
    estimasiWaktu: estimasi,
    createdAt: now.subtract(Duration(days: rng.nextInt(30))),
    sawScore: sawScore,
    ranking: 1 + rng.nextInt(10),
  );
}

/// Generates a random ScheduleConfig with valid work hours.
/// Includes both normal and cross-midnight configurations.
ScheduleConfig _generateRandomScheduleConfig(Random rng) {
  final isCrossMidnight = rng.nextBool();

  if (isCrossMidnight) {
    // Cross-midnight: e.g., 20:00-06:00, 22:00-08:00
    final startHour = 18 + rng.nextInt(6); // 18-23
    final endHour = 1 + rng.nextInt(10); // 1-10
    return ScheduleConfig(
      workStartHour: startHour,
      workStartMinute: 0,
      workEndHour: endHour,
      workEndMinute: 0,
    );
  } else {
    // Normal: e.g., 06:00-18:00, 08:00-17:00
    final startHour = rng.nextInt(14); // 0-13
    final endHour = startHour + 2 + rng.nextInt(10); // at least 2 hours range
    return ScheduleConfig(
      workStartHour: startHour,
      workStartMinute: 0,
      workEndHour: endHour > 23 ? 23 : endHour,
      workEndMinute: 0,
    );
  }
}

/// Generates a set of occupied slots (hour-aligned DateTimes) between [from] and [until].
/// Occupies a random fraction of available slots.
Set<DateTime> _generateOccupiedSlots(
    Random rng, DateTime from, DateTime until,
    {double maxOccupancyFraction = 0.5}) {
  final occupied = <DateTime>{};
  final normalizedFrom = DateTime(from.year, from.month, from.day, from.hour);

  DateTime cursor = normalizedFrom;
  while (cursor.isBefore(until)) {
    // Randomly occupy some slots
    if (rng.nextDouble() < maxOccupancyFraction * rng.nextDouble()) {
      occupied.add(cursor);
    }
    cursor = cursor.add(const Duration(hours: 1));
  }
  return occupied;
}

void main() {
  final scheduler = SmartSchedulerService();

  // ===========================================================================
  // Feature: smart-scheduling, Property 3: Backward Scheduling Respects Deadline
  // **Validates: Requirements 1.1, 1.4**
  // ===========================================================================
  group('Property 3: Backward Scheduling Respects Deadline', () {
    test(
      'all allocated TimeBlocks have startTime strictly before deadline',
      () {
        final rng = Random(42);
        var iterationCount = 0;

        for (var i = 0; i < 100; i++) {
          final now = DateTime(2024, 6, 15, 10, 0, 0);
          final task = _generateRandomTask(rng, now);
          final config = _generateRandomScheduleConfig(rng);
          final occupied = _generateOccupiedSlots(
            rng,
            now,
            task.deadline,
            maxOccupancyFraction: 0.3,
          );

          final blocks = scheduler.backwardSchedule(
            task: task,
            occupiedSlots: occupied,
            config: config,
            now: now,
          );

          for (final block in blocks) {
            expect(
              block.startTime.isBefore(task.deadline),
              isTrue,
              reason:
                  'Iteration $i: TimeBlock startTime=${block.startTime} '
                  'is not before deadline=${task.deadline}',
            );
          }

          iterationCount++;
        }
        expect(iterationCount, greaterThanOrEqualTo(100));
      },
    );

    test(
      'no TimeBlock has startTime before current time',
      () {
        final rng = Random(123);
        var iterationCount = 0;

        for (var i = 0; i < 100; i++) {
          final now = DateTime(2024, 6, 15, 10, 0, 0);
          final task = _generateRandomTask(rng, now);
          final config = _generateRandomScheduleConfig(rng);
          final occupied = _generateOccupiedSlots(
            rng,
            now,
            task.deadline,
            maxOccupancyFraction: 0.3,
          );

          final blocks = scheduler.backwardSchedule(
            task: task,
            occupiedSlots: occupied,
            config: config,
            now: now,
          );

          for (final block in blocks) {
            // Block startTime must be >= now (hour-aligned)
            final normalizedNow =
                DateTime(now.year, now.month, now.day, now.hour);
            expect(
              block.startTime.isAtSameMomentAs(normalizedNow) ||
                  block.startTime.isAfter(normalizedNow),
              isTrue,
              reason:
                  'Iteration $i: TimeBlock startTime=${block.startTime} '
                  'is before current time=$now',
            );
          }

          iterationCount++;
        }
        expect(iterationCount, greaterThanOrEqualTo(100));
      },
    );

    test(
      'blocks are within valid range [now, deadline) with random occupied slots',
      () {
        final rng = Random(456);
        var iterationCount = 0;

        for (var i = 0; i < 100; i++) {
          final now = DateTime(2024, 6, 15, 8, 0, 0);
          final task = _generateRandomTask(rng, now);
          final config = _generateRandomScheduleConfig(rng);
          final occupied = _generateOccupiedSlots(
            rng,
            now,
            task.deadline,
            maxOccupancyFraction: 0.5,
          );

          final blocks = scheduler.backwardSchedule(
            task: task,
            occupiedSlots: occupied,
            config: config,
            now: now,
          );

          final normalizedNow =
              DateTime(now.year, now.month, now.day, now.hour);

          for (final block in blocks) {
            // startTime >= now
            expect(
              block.startTime.isAtSameMomentAs(normalizedNow) ||
                  block.startTime.isAfter(normalizedNow),
              isTrue,
              reason:
                  'Iteration $i: block.startTime=${block.startTime} < now=$normalizedNow',
            );
            // startTime < deadline
            expect(
              block.startTime.isBefore(task.deadline),
              isTrue,
              reason:
                  'Iteration $i: block.startTime=${block.startTime} >= deadline=${task.deadline}',
            );
          }

          iterationCount++;
        }
        expect(iterationCount, greaterThanOrEqualTo(100));
      },
    );
  });

  // ===========================================================================
  // Feature: smart-scheduling, Property 6: Primary Work Hours Preference Ordering
  // **Validates: Requirements 6.2, 6.3, 6.4**
  // ===========================================================================
  group('Property 6: Primary Work Hours Preference Ordering', () {
    test(
      'PWH slots are filled before non-PWH slots in scheduling result',
      () {
        final rng = Random(789);
        var iterationCount = 0;

        for (var i = 0; i < 100; i++) {
          final now = DateTime(2024, 6, 15, 0, 0, 0); // Start at midnight
          final config = _generateRandomScheduleConfig(rng);
          // Create a task with enough estimation to potentially use both PWH and non-PWH
          final estimasi = 3 + rng.nextInt(8); // 3-10 hours
          final deadline = now.add(Duration(hours: 24 + rng.nextInt(48)));
          final task = Task(
            id: 'task-$i',
            namaTugas: 'Tugas $i',
            mataKuliah: 'MK $i',
            deadline: deadline,
            tingkatKepentingan: 3,
            tingkatUrgensi: 3,
            estimasiWaktu: estimasi,
            createdAt: now.subtract(const Duration(days: 1)),
            sawScore: 0.5,
            ranking: 1,
          );

          final occupied = <DateTime>{}; // No occupied slots

          final blocks = scheduler.backwardSchedule(
            task: task,
            occupiedSlots: occupied,
            config: config,
            now: now,
          );

          if (blocks.isEmpty) {
            iterationCount++;
            continue;
          }

          // Classify blocks into PWH and non-PWH
          final pwhBlocks = <TimeBlock>[];
          final nonPwhBlocks = <TimeBlock>[];
          for (final block in blocks) {
            if (config.isWithinWorkHours(block.startTime)) {
              pwhBlocks.add(block);
            } else {
              nonPwhBlocks.add(block);
            }
          }

          // If there are non-PWH blocks, verify that all available PWH slots
          // between now and deadline are used (i.e., PWH was filled first)
          if (nonPwhBlocks.isNotEmpty) {
            // Count total available PWH slots between now and deadline
            final availablePwhSlots = <DateTime>[];
            DateTime cursor = DateTime(now.year, now.month, now.day, now.hour);
            while (cursor.isBefore(task.deadline)) {
              if (config.isWithinWorkHours(cursor)) {
                availablePwhSlots.add(cursor);
              }
              cursor = cursor.add(const Duration(hours: 1));
            }

            // All available PWH slots should be used before any non-PWH slot
            // (up to the estimation limit)
            final usedPwhCount = pwhBlocks.length;
            final totalAvailablePwh = availablePwhSlots.length;

            // If estimation > available PWH, all PWH should be used
            if (estimasi > totalAvailablePwh) {
              expect(
                usedPwhCount,
                equals(totalAvailablePwh),
                reason:
                    'Iteration $i: estimation=$estimasi > availablePWH=$totalAvailablePwh, '
                    'but only $usedPwhCount PWH slots used. '
                    'Config: ${config.workStartHour}:00-${config.workEndHour}:00',
              );
            } else {
              // If estimation <= available PWH, all blocks should be PWH
              // (no non-PWH should be used)
              expect(
                nonPwhBlocks.isEmpty,
                isTrue,
                reason:
                    'Iteration $i: estimation=$estimasi <= availablePWH=$totalAvailablePwh, '
                    'but ${nonPwhBlocks.length} non-PWH blocks were used. '
                    'Config: ${config.workStartHour}:00-${config.workEndHour}:00',
              );
            }
          }

          iterationCount++;
        }
        expect(iterationCount, greaterThanOrEqualTo(100));
      },
    );

    test(
      'non-PWH allocation is never blocked or rejected',
      () {
        final rng = Random(321);
        var iterationCount = 0;

        for (var i = 0; i < 100; i++) {
          final now = DateTime(2024, 6, 15, 0, 0, 0);
          final config = _generateRandomScheduleConfig(rng);

          // Create a task with high estimation that will need non-PWH slots
          final estimasi = 8 + rng.nextInt(3); // 8-10 hours
          final deadline = now.add(const Duration(hours: 48));
          final task = Task(
            id: 'task-$i',
            namaTugas: 'Tugas $i',
            mataKuliah: 'MK $i',
            deadline: deadline,
            tingkatKepentingan: 3,
            tingkatUrgensi: 3,
            estimasiWaktu: estimasi,
            createdAt: now.subtract(const Duration(days: 1)),
            sawScore: 0.5,
            ranking: 1,
          );

          // Occupy all PWH slots to force non-PWH allocation
          final occupied = <DateTime>{};
          DateTime cursor = DateTime(now.year, now.month, now.day, now.hour);
          while (cursor.isBefore(deadline)) {
            if (config.isWithinWorkHours(cursor)) {
              occupied.add(cursor);
            }
            cursor = cursor.add(const Duration(hours: 1));
          }

          final blocks = scheduler.backwardSchedule(
            task: task,
            occupiedSlots: occupied,
            config: config,
            now: now,
          );

          // Non-PWH allocation should not be blocked — blocks should be allocated
          // from non-PWH slots since all PWH are occupied
          // Count available non-PWH slots
          int availableNonPwh = 0;
          cursor = DateTime(now.year, now.month, now.day, now.hour);
          while (cursor.isBefore(deadline)) {
            if (!config.isWithinWorkHours(cursor) &&
                !occupied.contains(cursor)) {
              availableNonPwh++;
            }
            cursor = cursor.add(const Duration(hours: 1));
          }

          final expectedBlocks =
              estimasi < availableNonPwh ? estimasi : availableNonPwh;

          expect(
            blocks.length,
            equals(expectedBlocks),
            reason:
                'Iteration $i: expected $expectedBlocks blocks from non-PWH slots, '
                'got ${blocks.length}. estimasi=$estimasi, availableNonPwh=$availableNonPwh. '
                'Config: ${config.workStartHour}:00-${config.workEndHour}:00',
          );

          // Verify all allocated blocks are in non-PWH slots
          for (final block in blocks) {
            expect(
              config.isWithinWorkHours(block.startTime),
              isFalse,
              reason:
                  'Iteration $i: block at ${block.startTime} should be non-PWH '
                  'since all PWH slots are occupied',
            );
          }

          iterationCount++;
        }
        expect(iterationCount, greaterThanOrEqualTo(100));
      },
    );

    test(
      'PWH preference works correctly with cross-midnight configurations',
      () {
        final rng = Random(654);
        var iterationCount = 0;

        for (var i = 0; i < 100; i++) {
          final now = DateTime(2024, 6, 15, 0, 0, 0);
          // Force cross-midnight config
          final startHour = 18 + rng.nextInt(6); // 18-23
          final endHour = 1 + rng.nextInt(8); // 1-8
          final config = ScheduleConfig(
            workStartHour: startHour,
            workStartMinute: 0,
            workEndHour: endHour,
            workEndMinute: 0,
          );

          expect(config.isCrossMidnight, isTrue);

          final estimasi = 2 + rng.nextInt(6); // 2-7 hours
          final deadline = now.add(Duration(hours: 24 + rng.nextInt(24)));
          final task = Task(
            id: 'task-$i',
            namaTugas: 'Tugas $i',
            mataKuliah: 'MK $i',
            deadline: deadline,
            tingkatKepentingan: 3,
            tingkatUrgensi: 3,
            estimasiWaktu: estimasi,
            createdAt: now.subtract(const Duration(days: 1)),
            sawScore: 0.5,
            ranking: 1,
          );

          final blocks = scheduler.backwardSchedule(
            task: task,
            occupiedSlots: <DateTime>{},
            config: config,
            now: now,
          );

          if (blocks.isEmpty) {
            iterationCount++;
            continue;
          }

          // Classify blocks
          final pwhBlocks =
              blocks.where((b) => config.isWithinWorkHours(b.startTime)).toList();
          final nonPwhBlocks =
              blocks.where((b) => !config.isWithinWorkHours(b.startTime)).toList();

          // If non-PWH blocks exist, all available PWH slots should be used first
          if (nonPwhBlocks.isNotEmpty) {
            int availablePwhCount = 0;
            DateTime cursor = DateTime(now.year, now.month, now.day, now.hour);
            while (cursor.isBefore(task.deadline)) {
              if (config.isWithinWorkHours(cursor)) {
                availablePwhCount++;
              }
              cursor = cursor.add(const Duration(hours: 1));
            }

            // All available PWH slots should be used
            if (estimasi > availablePwhCount) {
              expect(
                pwhBlocks.length,
                equals(availablePwhCount),
                reason:
                    'Iteration $i: cross-midnight config $startHour:00-$endHour:00, '
                    'estimasi=$estimasi > availablePWH=$availablePwhCount, '
                    'but only ${pwhBlocks.length} PWH slots used',
              );
            }
          }

          iterationCount++;
        }
        expect(iterationCount, greaterThanOrEqualTo(100));
      },
    );
  });

  // ===========================================================================
  // Feature: smart-scheduling, Property 8: Partial Scheduling Maximizes Allocation
  // **Validates: Requirements 1.5, 1.7**
  // ===========================================================================
  group('Property 8: Partial Scheduling Maximizes Allocation', () {
    test(
      'allocates exactly min(estimation, availableSlots) blocks',
      () {
        final rng = Random(111);
        var iterationCount = 0;

        for (var i = 0; i < 100; i++) {
          final now = DateTime(2024, 6, 15, 10, 0, 0);
          final config = _generateRandomScheduleConfig(rng);
          final task = _generateRandomTask(rng, now);
          final occupied = _generateOccupiedSlots(
            rng,
            now,
            task.deadline,
            maxOccupancyFraction: 0.6,
          );

          final blocks = scheduler.backwardSchedule(
            task: task,
            occupiedSlots: occupied,
            config: config,
            now: now,
          );

          // Count available slots manually
          final availableSlots = scheduler.getAvailableSlots(
            from: now,
            until: task.deadline,
            occupiedSlots: occupied,
            config: config,
          );

          final expectedBlockCount = task.estimasiWaktu < availableSlots.length
              ? task.estimasiWaktu
              : availableSlots.length;

          expect(
            blocks.length,
            equals(expectedBlockCount),
            reason:
                'Iteration $i: expected min(estimation=${task.estimasiWaktu}, '
                'available=${availableSlots.length})=$expectedBlockCount blocks, '
                'got ${blocks.length}',
          );

          iterationCount++;
        }
        expect(iterationCount, greaterThanOrEqualTo(100));
      },
    );

    test(
      'when estimation <= available slots, allocates exactly estimation blocks',
      () {
        final rng = Random(222);
        var iterationCount = 0;

        for (var i = 0; i < 100; i++) {
          final now = DateTime(2024, 6, 15, 8, 0, 0);
          final config = ScheduleConfig(); // Default 8-17
          // Create task with small estimation and far deadline (plenty of slots)
          final estimasi = 1 + rng.nextInt(5); // 1-5 hours
          final deadline = now.add(Duration(hours: 48 + rng.nextInt(48)));
          final task = Task(
            id: 'task-$i',
            namaTugas: 'Tugas $i',
            mataKuliah: 'MK $i',
            deadline: deadline,
            tingkatKepentingan: 3,
            tingkatUrgensi: 3,
            estimasiWaktu: estimasi,
            createdAt: now.subtract(const Duration(days: 1)),
            sawScore: 0.5,
            ranking: 1,
          );

          // No occupied slots — plenty of room
          final blocks = scheduler.backwardSchedule(
            task: task,
            occupiedSlots: <DateTime>{},
            config: config,
            now: now,
          );

          expect(
            blocks.length,
            equals(estimasi),
            reason:
                'Iteration $i: with plenty of available slots, '
                'expected exactly estimation=$estimasi blocks, got ${blocks.length}',
          );

          iterationCount++;
        }
        expect(iterationCount, greaterThanOrEqualTo(100));
      },
    );

    test(
      'when estimation exceeds available slots, allocates all available slots',
      () {
        final rng = Random(333);
        var iterationCount = 0;

        for (var i = 0; i < 100; i++) {
          final now = DateTime(2024, 6, 15, 10, 0, 0);
          final config = ScheduleConfig(); // Default 8-17

          // Create task with high estimation but short deadline window
          final hoursUntilDeadline = 3 + rng.nextInt(5); // 3-7 hours
          final deadline = now.add(Duration(hours: hoursUntilDeadline));
          final estimasi = hoursUntilDeadline + 2 + rng.nextInt(5); // Always more than available

          final task = Task(
            id: 'task-$i',
            namaTugas: 'Tugas $i',
            mataKuliah: 'MK $i',
            deadline: deadline,
            tingkatKepentingan: 3,
            tingkatUrgensi: 3,
            estimasiWaktu: estimasi,
            createdAt: now.subtract(const Duration(days: 1)),
            sawScore: 0.5,
            ranking: 1,
          );

          // Add some occupied slots to further constrain
          final occupied = _generateOccupiedSlots(
            rng,
            now,
            deadline,
            maxOccupancyFraction: 0.4,
          );

          final blocks = scheduler.backwardSchedule(
            task: task,
            occupiedSlots: occupied,
            config: config,
            now: now,
          );

          // Count actual available slots
          final availableSlots = scheduler.getAvailableSlots(
            from: now,
            until: deadline,
            occupiedSlots: occupied,
            config: config,
          );

          // Should allocate all available slots (since estimation > available)
          expect(
            blocks.length,
            equals(availableSlots.length),
            reason:
                'Iteration $i: estimation=$estimasi > available=${availableSlots.length}, '
                'should allocate all ${availableSlots.length} available slots, '
                'got ${blocks.length}',
          );

          iterationCount++;
        }
        expect(iterationCount, greaterThanOrEqualTo(100));
      },
    );

    test(
      'partial scheduling with various occupied slot patterns',
      () {
        final rng = Random(444);
        var iterationCount = 0;

        for (var i = 0; i < 100; i++) {
          final now = DateTime(2024, 6, 15, 8, 0, 0);
          final config = _generateRandomScheduleConfig(rng);
          final task = _generateRandomTask(rng, now);

          // Generate occupied slots with varying density
          final occupancyFraction = rng.nextDouble() * 0.8; // 0-80% occupancy
          final occupied = <DateTime>{};
          DateTime cursor = DateTime(now.year, now.month, now.day, now.hour);
          while (cursor.isBefore(task.deadline)) {
            if (rng.nextDouble() < occupancyFraction) {
              occupied.add(cursor);
            }
            cursor = cursor.add(const Duration(hours: 1));
          }

          final blocks = scheduler.backwardSchedule(
            task: task,
            occupiedSlots: occupied,
            config: config,
            now: now,
          );

          // Verify: allocated = min(estimation, available)
          final availableSlots = scheduler.getAvailableSlots(
            from: now,
            until: task.deadline,
            occupiedSlots: occupied,
            config: config,
          );

          final expectedCount = task.estimasiWaktu < availableSlots.length
              ? task.estimasiWaktu
              : availableSlots.length;

          expect(
            blocks.length,
            equals(expectedCount),
            reason:
                'Iteration $i: expected min(${task.estimasiWaktu}, '
                '${availableSlots.length})=$expectedCount, got ${blocks.length}. '
                'Occupancy fraction: ${occupancyFraction.toStringAsFixed(2)}',
          );

          iterationCount++;
        }
        expect(iterationCount, greaterThanOrEqualTo(100));
      },
    );
  });
}
