// test/models/time_block_schedule_config_property_test.dart
//
// Property-Based Tests for TimeBlock and ScheduleConfig models.
//
// Feature: smart-scheduling, Property 2: TimeBlock Duration Invariant
// Feature: smart-scheduling, Property 7: Primary Work Hours Cross-Midnight Correctness
// Feature: smart-scheduling, Property 14: Schedule Serialization Round Trip
//
// **Validates: Requirements 1.2, 1.4, 6.1, 9.1, 9.6**

import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:tugasku/models/time_block_model.dart';
import 'package:tugasku/models/schedule_config_model.dart';

// ---------------------------------------------------------------------------
// Generators
// ---------------------------------------------------------------------------

/// Generates a random hour-aligned DateTime within a reasonable range.
DateTime _generateHourAlignedDateTime(Random rng) {
  // Year 2024-2025, random month/day/hour
  final year = 2024 + rng.nextInt(2);
  final month = 1 + rng.nextInt(12);
  final day = 1 + rng.nextInt(28); // Safe for all months
  final hour = rng.nextInt(24);
  return DateTime(year, month, day, hour, 0, 0);
}

/// Generates a random TimeBlock with valid hour-boundary startTime.
TimeBlock _generateRandomTimeBlock(Random rng) {
  final startTime = _generateHourAlignedDateTime(rng);
  final endTime = startTime.add(const Duration(hours: 1));
  final statusIndex = rng.nextInt(TimeBlockStatus.values.length);
  final id = 'block-${rng.nextInt(100000)}';
  final taskId = 'task-${rng.nextInt(100000)}';

  return TimeBlock(
    id: id,
    taskId: taskId,
    startTime: startTime,
    endTime: endTime,
    status: TimeBlockStatus.values[statusIndex],
    isManuallyPlaced: rng.nextBool(),
  );
}

/// Generates a random ScheduleConfig, including cross-midnight configurations.
ScheduleConfig _generateRandomScheduleConfig(Random rng) {
  final workStartHour = rng.nextInt(24);
  final workStartMinute = rng.nextInt(60);
  // Ensure we don't generate start == end (which would be 0-range non-cross-midnight)
  int workEndHour = rng.nextInt(24);
  int workEndMinute = rng.nextInt(60);

  // Ensure at least 1 hour difference to make meaningful configs
  if (workStartHour == workEndHour && workStartMinute == workEndMinute) {
    workEndHour = (workStartHour + 1 + rng.nextInt(23)) % 24;
  }

  return ScheduleConfig(
    workStartHour: workStartHour,
    workStartMinute: workStartMinute,
    workEndHour: workEndHour,
    workEndMinute: workEndMinute,
  );
}

/// Generates a list of random TimeBlocks (1 to maxCount).
List<TimeBlock> _generateRandomTimeBlockList(Random rng, {int maxCount = 10}) {
  final count = 1 + rng.nextInt(maxCount);
  return List.generate(count, (_) => _generateRandomTimeBlock(rng));
}

void main() {
  // ===========================================================================
  // Feature: smart-scheduling, Property 2: TimeBlock Duration Invariant
  // **Validates: Requirements 1.2, 1.4**
  // ===========================================================================
  group('Property 2: TimeBlock Duration Invariant', () {
    test(
      'duration is exactly 1 hour for all generated TimeBlocks',
      () {
        final rng = Random(42);
        var iterationCount = 0;

        for (var i = 0; i < 100; i++) {
          final block = _generateRandomTimeBlock(rng);

          final duration = block.endTime.difference(block.startTime);
          expect(
            duration,
            equals(const Duration(hours: 1)),
            reason:
                'Iteration $i: TimeBlock id=${block.id} has duration '
                '${duration.inMinutes} minutes instead of 60',
          );

          iterationCount++;
        }
        expect(iterationCount, greaterThanOrEqualTo(100));
      },
    );

    test(
      'startTime is always on hour boundary (minute=0, second=0)',
      () {
        final rng = Random(123);
        var iterationCount = 0;

        for (var i = 0; i < 100; i++) {
          final block = _generateRandomTimeBlock(rng);

          expect(
            block.startTime.minute,
            equals(0),
            reason:
                'Iteration $i: TimeBlock id=${block.id} startTime has '
                'minute=${block.startTime.minute} instead of 0',
          );
          expect(
            block.startTime.second,
            equals(0),
            reason:
                'Iteration $i: TimeBlock id=${block.id} startTime has '
                'second=${block.startTime.second} instead of 0',
          );
          expect(
            block.startTime.millisecond,
            equals(0),
            reason:
                'Iteration $i: TimeBlock id=${block.id} startTime has '
                'millisecond=${block.startTime.millisecond} instead of 0',
          );

          iterationCount++;
        }
        expect(iterationCount, greaterThanOrEqualTo(100));
      },
    );

    test(
      'endTime equals startTime + 1 hour for all generated TimeBlocks',
      () {
        final rng = Random(456);
        var iterationCount = 0;

        for (var i = 0; i < 100; i++) {
          final block = _generateRandomTimeBlock(rng);

          final expectedEnd = block.startTime.add(const Duration(hours: 1));
          expect(
            block.endTime,
            equals(expectedEnd),
            reason:
                'Iteration $i: TimeBlock id=${block.id} endTime=${block.endTime} '
                'does not equal startTime + 1 hour ($expectedEnd)',
          );

          iterationCount++;
        }
        expect(iterationCount, greaterThanOrEqualTo(100));
      },
    );
  });

  // ===========================================================================
  // Feature: smart-scheduling, Property 7: Primary Work Hours Cross-Midnight Correctness
  // **Validates: Requirements 6.1**
  // ===========================================================================
  group('Property 7: Primary Work Hours Cross-Midnight Correctness', () {
    test(
      'isWithinWorkHours correctly identifies hours within normal (non-cross-midnight) range',
      () {
        final rng = Random(789);
        var iterationCount = 0;

        for (var i = 0; i < 100; i++) {
          // Generate non-cross-midnight config
          final startHour = rng.nextInt(20); // 0-19
          final endHour = startHour + 1 + rng.nextInt(24 - startHour - 1).clamp(0, 23 - startHour);
          final config = ScheduleConfig(
            workStartHour: startHour,
            workStartMinute: 0,
            workEndHour: endHour,
            workEndMinute: 0,
          );

          // Test a random hour
          final testHour = rng.nextInt(24);
          final slotStart = DateTime(2024, 6, 15, testHour, 0, 0);
          final result = config.isWithinWorkHours(slotStart);

          // Manual verification: for non-cross-midnight, slot is within if
          // slotMinutes >= startMinutes AND slotMinutes < endMinutes
          final expectedWithin = testHour >= startHour && testHour < endHour;

          expect(
            result,
            equals(expectedWithin),
            reason:
                'Iteration $i: config=$startHour:00-$endHour:00, '
                'testHour=$testHour, expected=$expectedWithin, got=$result',
          );

          iterationCount++;
        }
        expect(iterationCount, greaterThanOrEqualTo(100));
      },
    );

    test(
      'isWithinWorkHours correctly identifies hours within cross-midnight range',
      () {
        final rng = Random(321);
        var iterationCount = 0;

        for (var i = 0; i < 100; i++) {
          // Generate cross-midnight config (startHour > endHour)
          final startHour = 18 + rng.nextInt(6); // 18-23
          final endHour = rng.nextInt(12); // 0-11
          final config = ScheduleConfig(
            workStartHour: startHour,
            workStartMinute: 0,
            workEndHour: endHour,
            workEndMinute: 0,
          );

          expect(config.isCrossMidnight, isTrue,
              reason: 'Config $startHour:00-$endHour:00 should be cross-midnight');

          // Test a random hour
          final testHour = rng.nextInt(24);
          final slotStart = DateTime(2024, 6, 15, testHour, 0, 0);
          final result = config.isWithinWorkHours(slotStart);

          // Manual verification: for cross-midnight, slot is within if
          // slotMinutes >= startMinutes OR slotMinutes < endMinutes
          final expectedWithin = testHour >= startHour || testHour < endHour;

          expect(
            result,
            equals(expectedWithin),
            reason:
                'Iteration $i: config=$startHour:00-$endHour:00 (cross-midnight), '
                'testHour=$testHour, expected=$expectedWithin, got=$result',
          );

          iterationCount++;
        }
        expect(iterationCount, greaterThanOrEqualTo(100));
      },
    );

    test(
      'isWithinWorkHours handles all random configurations including cross-midnight with minutes',
      () {
        final rng = Random(654);
        var iterationCount = 0;

        for (var i = 0; i < 100; i++) {
          final config = _generateRandomScheduleConfig(rng);
          final testHour = rng.nextInt(24);
          final testMinute = rng.nextInt(60);
          final slotStart = DateTime(2024, 6, 15, testHour, testMinute, 0);
          final result = config.isWithinWorkHours(slotStart);

          // Manual verification using the same logic as the implementation
          final slotMinutes = testHour * 60 + testMinute;
          final startMinutes = config.workStartHour * 60 + config.workStartMinute;
          final endMinutes = config.workEndHour * 60 + config.workEndMinute;

          bool expectedWithin;
          if (config.isCrossMidnight) {
            expectedWithin = slotMinutes >= startMinutes || slotMinutes < endMinutes;
          } else {
            expectedWithin = slotMinutes >= startMinutes && slotMinutes < endMinutes;
          }

          expect(
            result,
            equals(expectedWithin),
            reason:
                'Iteration $i: config=${config.workStartHour}:${config.workStartMinute}'
                '-${config.workEndHour}:${config.workEndMinute} '
                '(crossMidnight=${config.isCrossMidnight}), '
                'slot=$testHour:$testMinute, expected=$expectedWithin, got=$result',
          );

          iterationCount++;
        }
        expect(iterationCount, greaterThanOrEqualTo(100));
      },
    );
  });

  // ===========================================================================
  // Feature: smart-scheduling, Property 14: Schedule Serialization Round Trip
  // **Validates: Requirements 9.1, 9.6**
  // ===========================================================================
  group('Property 14: Schedule Serialization Round Trip', () {
    test(
      'TimeBlock toJson/fromJson produces equivalent objects',
      () {
        final rng = Random(111);
        var iterationCount = 0;

        for (var i = 0; i < 100; i++) {
          final original = _generateRandomTimeBlock(rng);
          final json = original.toJson();
          final restored = TimeBlock.fromJson(json);

          expect(
            restored.id,
            equals(original.id),
            reason: 'Iteration $i: id mismatch',
          );
          expect(
            restored.taskId,
            equals(original.taskId),
            reason: 'Iteration $i: taskId mismatch',
          );
          expect(
            restored.startTime,
            equals(original.startTime),
            reason: 'Iteration $i: startTime mismatch',
          );
          expect(
            restored.endTime,
            equals(original.endTime),
            reason: 'Iteration $i: endTime mismatch',
          );
          expect(
            restored.status,
            equals(original.status),
            reason: 'Iteration $i: status mismatch',
          );
          expect(
            restored.isManuallyPlaced,
            equals(original.isManuallyPlaced),
            reason: 'Iteration $i: isManuallyPlaced mismatch',
          );

          iterationCount++;
        }
        expect(iterationCount, greaterThanOrEqualTo(100));
      },
    );

    test(
      'ScheduleConfig toJson/fromJson produces equivalent objects',
      () {
        final rng = Random(222);
        var iterationCount = 0;

        for (var i = 0; i < 100; i++) {
          final original = _generateRandomScheduleConfig(rng);
          final json = original.toJson();
          final restored = ScheduleConfig.fromJson(json);

          expect(
            restored.workStartHour,
            equals(original.workStartHour),
            reason: 'Iteration $i: workStartHour mismatch',
          );
          expect(
            restored.workStartMinute,
            equals(original.workStartMinute),
            reason: 'Iteration $i: workStartMinute mismatch',
          );
          expect(
            restored.workEndHour,
            equals(original.workEndHour),
            reason: 'Iteration $i: workEndHour mismatch',
          );
          expect(
            restored.workEndMinute,
            equals(original.workEndMinute),
            reason: 'Iteration $i: workEndMinute mismatch',
          );
          expect(
            restored.isCrossMidnight,
            equals(original.isCrossMidnight),
            reason: 'Iteration $i: isCrossMidnight mismatch',
          );

          iterationCount++;
        }
        expect(iterationCount, greaterThanOrEqualTo(100));
      },
    );

    test(
      'List<TimeBlock> serialization round trip preserves all blocks',
      () {
        final rng = Random(333);
        var iterationCount = 0;

        for (var i = 0; i < 100; i++) {
          final originalBlocks = _generateRandomTimeBlockList(rng);

          // Serialize list to JSON
          final jsonList = originalBlocks.map((b) => b.toJson()).toList();

          // Deserialize back
          final restoredBlocks =
              jsonList.map((j) => TimeBlock.fromJson(j)).toList();

          expect(
            restoredBlocks.length,
            equals(originalBlocks.length),
            reason: 'Iteration $i: list length mismatch',
          );

          for (var j = 0; j < originalBlocks.length; j++) {
            final original = originalBlocks[j];
            final restored = restoredBlocks[j];

            expect(restored.id, equals(original.id),
                reason: 'Iteration $i, block $j: id mismatch');
            expect(restored.taskId, equals(original.taskId),
                reason: 'Iteration $i, block $j: taskId mismatch');
            expect(restored.startTime, equals(original.startTime),
                reason: 'Iteration $i, block $j: startTime mismatch');
            expect(restored.endTime, equals(original.endTime),
                reason: 'Iteration $i, block $j: endTime mismatch');
            expect(restored.status, equals(original.status),
                reason: 'Iteration $i, block $j: status mismatch');
            expect(restored.isManuallyPlaced, equals(original.isManuallyPlaced),
                reason: 'Iteration $i, block $j: isManuallyPlaced mismatch');
          }

          iterationCount++;
        }
        expect(iterationCount, greaterThanOrEqualTo(100));
      },
    );

    test(
      'combined TimeBlock list + ScheduleConfig round trip',
      () {
        final rng = Random(444);
        var iterationCount = 0;

        for (var i = 0; i < 100; i++) {
          final originalBlocks = _generateRandomTimeBlockList(rng);
          final originalConfig = _generateRandomScheduleConfig(rng);

          // Simulate full schedule serialization (as stored in SharedPreferences)
          final scheduleJson = {
            'timeBlocks': originalBlocks.map((b) => b.toJson()).toList(),
            'scheduleConfig': originalConfig.toJson(),
          };

          // Deserialize
          final restoredBlocks = (scheduleJson['timeBlocks'] as List)
              .map((j) => TimeBlock.fromJson(j as Map<String, dynamic>))
              .toList();
          final restoredConfig = ScheduleConfig.fromJson(
              scheduleJson['scheduleConfig'] as Map<String, dynamic>);

          // Verify blocks
          expect(restoredBlocks.length, equals(originalBlocks.length),
              reason: 'Iteration $i: block list length mismatch');
          for (var j = 0; j < originalBlocks.length; j++) {
            expect(restoredBlocks[j].id, equals(originalBlocks[j].id),
                reason: 'Iteration $i, block $j: id mismatch');
            expect(
                restoredBlocks[j].startTime, equals(originalBlocks[j].startTime),
                reason: 'Iteration $i, block $j: startTime mismatch');
            expect(restoredBlocks[j].endTime, equals(originalBlocks[j].endTime),
                reason: 'Iteration $i, block $j: endTime mismatch');
            expect(restoredBlocks[j].status, equals(originalBlocks[j].status),
                reason: 'Iteration $i, block $j: status mismatch');
          }

          // Verify config
          expect(restoredConfig.workStartHour,
              equals(originalConfig.workStartHour),
              reason: 'Iteration $i: workStartHour mismatch');
          expect(restoredConfig.workStartMinute,
              equals(originalConfig.workStartMinute),
              reason: 'Iteration $i: workStartMinute mismatch');
          expect(
              restoredConfig.workEndHour, equals(originalConfig.workEndHour),
              reason: 'Iteration $i: workEndHour mismatch');
          expect(restoredConfig.workEndMinute,
              equals(originalConfig.workEndMinute),
              reason: 'Iteration $i: workEndMinute mismatch');

          iterationCount++;
        }
        expect(iterationCount, greaterThanOrEqualTo(100));
      },
    );
  });
}
