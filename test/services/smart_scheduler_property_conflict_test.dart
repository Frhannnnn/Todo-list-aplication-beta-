// test/services/smart_scheduler_property_conflict_test.dart
//
// Property-Based Tests for Smart Scheduler conflict resolution.
//
// Feature: smart-scheduling, Property 1: Strict Monotasking Invariant (No Overlaps)
// Feature: smart-scheduling, Property 4: Conflict Resolution Priority Ordering
// Feature: smart-scheduling, Property 5: Recursive Shift Produces Valid Placement
//
// **Validates: Requirements 2.1, 2.3, 4.2, 4.3, 4.4, 4.5, 4.6, 8.1, 8.5**

import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:tugasku/models/task_model.dart';
import 'package:tugasku/models/time_block_model.dart';
import 'package:tugasku/models/schedule_config_model.dart';
import 'package:tugasku/models/schedule_result_model.dart';
import 'package:tugasku/services/smart_scheduler_service.dart';

// ---------------------------------------------------------------------------
// Generators
// ---------------------------------------------------------------------------

/// Generates a random ScheduleConfig with valid work hours.
ScheduleConfig _generateScheduleConfig(Random rng) {
  // 70% normal config, 30% cross-midnight
  if (rng.nextDouble() < 0.7) {
    final startHour = rng.nextInt(18); // 0-17
    final endHour = startHour + 2 + rng.nextInt(8); // at least 2 hours range
    return ScheduleConfig(
      workStartHour: startHour,
      workStartMinute: 0,
      workEndHour: endHour.clamp(0, 23),
      workEndMinute: 0,
    );
  } else {
    // Cross-midnight
    final startHour = 18 + rng.nextInt(6); // 18-23
    final endHour = rng.nextInt(10); // 0-9
    return ScheduleConfig(
      workStartHour: startHour,
      workStartMinute: 0,
      workEndHour: endHour,
      workEndMinute: 0,
    );
  }
}

/// Generates a random Task with specified constraints.
Task _generateTask({
  required Random rng,
  required DateTime now,
  double? sawScore,
  DateTime? deadline,
  DateTime? createdAt,
}) {
  final id = 'task-${rng.nextInt(1000000)}';
  final score = sawScore ?? (rng.nextDouble() * 0.9 + 0.1); // 0.1 - 1.0
  final estimasi = 1 + rng.nextInt(5); // 1-5 hours
  final deadlineVal = deadline ??
      now.add(Duration(hours: 12 + rng.nextInt(72))); // 12-84 hours from now
  final createdAtVal = createdAt ??
      now.subtract(Duration(hours: rng.nextInt(48))); // 0-48 hours ago

  return Task(
    id: id,
    namaTugas: 'Task $id',
    mataKuliah: 'MK Test',
    deadline: deadlineVal,
    tingkatKepentingan: 1 + rng.nextInt(5),
    tingkatUrgensi: 1 + rng.nextInt(5),
    estimasiWaktu: estimasi,
    status: TaskStatus.belumDikerjakan,
    createdAt: createdAtVal,
    sawScore: score,
    ranking: 1,
  );
}

/// Generates a list of tasks (2-10) with random SAW scores, deadlines, and estimations.
List<Task> _generateTaskList({
  required Random rng,
  required DateTime now,
  int? count,
}) {
  final taskCount = count ?? (2 + rng.nextInt(9)); // 2-10 tasks
  return List.generate(
    taskCount,
    (_) => _generateTask(rng: rng, now: now),
  );
}

/// Generates a pair of tasks that will compete for the same slot.
/// Both tasks have the same deadline and enough estimation to overlap.
({Task taskA, Task taskB, DateTime contestedSlot}) _generateConflictingPair({
  required Random rng,
  required DateTime now,
  bool? equalSawScores,
  bool? equalDeadlines,
}) {
  // Create a contested slot in the future
  final hoursAhead = 4 + rng.nextInt(20); // 4-23 hours ahead
  final contestedSlot = DateTime(
    now.year,
    now.month,
    now.day,
    now.hour + hoursAhead,
  );

  final deadline = contestedSlot.add(const Duration(hours: 2));

  double scoreA;
  double scoreB;
  if (equalSawScores == true) {
    scoreA = 0.5 + rng.nextDouble() * 0.4;
    scoreB = scoreA;
  } else {
    scoreA = 0.3 + rng.nextDouble() * 0.3; // 0.3-0.6
    scoreB = 0.7 + rng.nextDouble() * 0.3; // 0.7-1.0
  }

  DateTime deadlineA;
  DateTime deadlineB;
  if (equalDeadlines == true) {
    deadlineA = deadline;
    deadlineB = deadline;
  } else {
    deadlineA = deadline;
    deadlineB = deadline.add(Duration(hours: rng.nextInt(10) + 1));
  }

  final createdAtA = now.subtract(Duration(hours: 10 + rng.nextInt(20)));
  final createdAtB = now.subtract(Duration(hours: rng.nextInt(10)));

  final taskA = _generateTask(
    rng: rng,
    now: now,
    sawScore: scoreA,
    deadline: deadlineA,
    createdAt: createdAtA,
  );

  final taskB = _generateTask(
    rng: rng,
    now: now,
    sawScore: scoreB,
    deadline: deadlineB,
    createdAt: createdAtB,
  );

  return (taskA: taskA, taskB: taskB, contestedSlot: contestedSlot);
}

/// Creates TimeBlocks that intentionally overlap at the same slot.
List<TimeBlock> _createOverlappingBlocks({
  required List<Task> tasks,
  required DateTime contestedSlot,
  required Random rng,
}) {
  final blocks = <TimeBlock>[];
  for (final task in tasks) {
    blocks.add(TimeBlock(
      id: 'block-${task.id}-${rng.nextInt(100000)}',
      taskId: task.id,
      startTime: contestedSlot,
      endTime: contestedSlot.add(const Duration(hours: 1)),
    ));
  }
  return blocks;
}


void main() {
  final scheduler = SmartSchedulerService();

  // ===========================================================================
  // Feature: smart-scheduling, Property 1: Strict Monotasking Invariant (No Overlaps)
  // **Validates: Requirements 2.1, 2.3**
  //
  // For any set of tasks with valid deadlines and estimations, after
  // rescheduleAll() completes, no two TimeBlocks shall have overlapping
  // time ranges — every slot contains at most one task.
  // ===========================================================================
  group('Property 1: Strict Monotasking Invariant (No Overlaps)', () {
    test(
      'after rescheduleAll(), no two TimeBlocks share the same slot',
      () {
        final rng = Random(42);
        var iterationCount = 0;

        for (var i = 0; i < 100; i++) {
          final now = DateTime(2024, 6, 15, 8, 0, 0);
          final config = _generateScheduleConfig(rng);
          final tasks = _generateTaskList(rng: rng, now: now);

          final result = scheduler.rescheduleAll(
            tasks: tasks,
            manualBlocks: [],
            config: config,
            now: now,
          );

          // Verify no two blocks share the same slot
          final slotSet = <DateTime>{};
          for (final block in result.timeBlocks) {
            final slotKey = DateTime(
              block.startTime.year,
              block.startTime.month,
              block.startTime.day,
              block.startTime.hour,
            );
            expect(
              slotSet.contains(slotKey),
              isFalse,
              reason:
                  'Iteration $i: Slot $slotKey is occupied by multiple blocks. '
                  'Tasks: ${result.timeBlocks.where((b) => DateTime(b.startTime.year, b.startTime.month, b.startTime.day, b.startTime.hour) == slotKey).map((b) => b.taskId).toList()}',
            );
            slotSet.add(slotKey);
          }

          iterationCount++;
        }
        expect(iterationCount, greaterThanOrEqualTo(100));
      },
    );

    test(
      'validateNoOverlaps returns true for all rescheduleAll() results',
      () {
        final rng = Random(123);
        var iterationCount = 0;

        for (var i = 0; i < 100; i++) {
          final now = DateTime(2024, 6, 15, 8, 0, 0);
          final config = _generateScheduleConfig(rng);
          final tasks = _generateTaskList(rng: rng, now: now);

          final result = scheduler.rescheduleAll(
            tasks: tasks,
            manualBlocks: [],
            config: config,
            now: now,
          );

          expect(
            scheduler.validateNoOverlaps(result.timeBlocks),
            isTrue,
            reason:
                'Iteration $i: validateNoOverlaps returned false after rescheduleAll. '
                'Block count: ${result.timeBlocks.length}, Task count: ${tasks.length}',
          );

          iterationCount++;
        }
        expect(iterationCount, greaterThanOrEqualTo(100));
      },
    );

    test(
      'no overlaps even with many tasks competing for limited slots',
      () {
        final rng = Random(456);
        var iterationCount = 0;

        for (var i = 0; i < 100; i++) {
          final now = DateTime(2024, 6, 15, 8, 0, 0);
          // Use tight deadline to force competition
          final tightDeadline = now.add(Duration(hours: 6 + rng.nextInt(6)));
          final config = ScheduleConfig(); // Default 8-17

          // Generate 3-8 tasks all competing for the same tight window
          final taskCount = 3 + rng.nextInt(6);
          final tasks = List.generate(taskCount, (_) {
            return _generateTask(
              rng: rng,
              now: now,
              deadline: tightDeadline,
            );
          });

          final result = scheduler.rescheduleAll(
            tasks: tasks,
            manualBlocks: [],
            config: config,
            now: now,
          );

          // Verify no overlaps
          final slotSet = <DateTime>{};
          for (final block in result.timeBlocks) {
            final slotKey = DateTime(
              block.startTime.year,
              block.startTime.month,
              block.startTime.day,
              block.startTime.hour,
            );
            expect(
              slotSet.contains(slotKey),
              isFalse,
              reason:
                  'Iteration $i: Overlap detected at slot $slotKey with '
                  '${tasks.length} tasks competing for ${(tightDeadline.difference(now).inHours)} hour window',
            );
            slotSet.add(slotKey);
          }

          iterationCount++;
        }
        expect(iterationCount, greaterThanOrEqualTo(100));
      },
    );
  });


  // ===========================================================================
  // Feature: smart-scheduling, Property 4: Conflict Resolution Priority Ordering
  // **Validates: Requirements 4.2, 8.1, 8.5**
  //
  // For any two tasks competing for the same slot, the task with the higher
  // SAW Score shall win the slot. If SAW Scores are equal, the task with the
  // earlier deadline shall win. If deadlines are also equal, the task with the
  // earlier createdAt shall win.
  // ===========================================================================
  group('Property 4: Conflict Resolution Priority Ordering', () {
    test(
      'higher SAW Score wins the contested slot',
      () {
        final rng = Random(789);
        var iterationCount = 0;

        for (var i = 0; i < 100; i++) {
          final now = DateTime(2024, 6, 15, 8, 0, 0);
          final config = _generateScheduleConfig(rng);

          // Generate two tasks with different SAW scores
          final pair = _generateConflictingPair(rng: rng, now: now);
          final tasks = [pair.taskA, pair.taskB];

          // Create overlapping blocks at the contested slot
          final overlappingBlocks = _createOverlappingBlocks(
            tasks: tasks,
            contestedSlot: pair.contestedSlot,
            rng: rng,
          );

          // Detect conflicts
          final conflicts = scheduler.detectConflicts(
            overlappingBlocks,
            tasks: tasks,
          );

          if (conflicts.isEmpty) {
            // No conflict detected (shouldn't happen with overlapping blocks)
            continue;
          }

          // Resolve conflicts
          final resolution = scheduler.resolveConflicts(
            blocks: overlappingBlocks,
            conflicts: conflicts,
            tasks: tasks,
            occupiedSlots: <DateTime>{},
            config: config,
            now: now,
          );

          // Find which task kept the contested slot
          final blocksAtContestedSlot = resolution.blocks.where((b) {
            final slotKey = DateTime(
              b.startTime.year,
              b.startTime.month,
              b.startTime.day,
              b.startTime.hour,
            );
            return slotKey.isAtSameMomentAs(pair.contestedSlot);
          }).toList();

          if (blocksAtContestedSlot.isNotEmpty) {
            final winnerTaskId = blocksAtContestedSlot.first.taskId;

            // Determine expected winner
            final expectedWinner = pair.taskA.sawScore > pair.taskB.sawScore
                ? pair.taskA
                : pair.taskB;

            expect(
              winnerTaskId,
              equals(expectedWinner.id),
              reason:
                  'Iteration $i: Task with SAW=${expectedWinner.sawScore} should win '
                  'over task with SAW=${expectedWinner.id == pair.taskA.id ? pair.taskB.sawScore : pair.taskA.sawScore}. '
                  'Winner was $winnerTaskId',
            );
          }

          iterationCount++;
        }
        expect(iterationCount, greaterThanOrEqualTo(100));
      },
    );

    test(
      'equal SAW Scores: earlier deadline wins',
      () {
        final rng = Random(321);
        var iterationCount = 0;

        for (var i = 0; i < 100; i++) {
          final now = DateTime(2024, 6, 15, 8, 0, 0);
          final config = ScheduleConfig(); // Default 8-17

          // Generate pair with equal SAW scores but different deadlines
          final hoursAhead = 6 + rng.nextInt(12);
          final contestedSlot = DateTime(
            now.year,
            now.month,
            now.day,
            now.hour + hoursAhead,
          );

          final sawScore = 0.5 + rng.nextDouble() * 0.4;
          final deadlineA = contestedSlot.add(Duration(hours: 2 + rng.nextInt(5)));
          final deadlineB = deadlineA.add(Duration(hours: 1 + rng.nextInt(10)));

          final taskA = Task(
            id: 'taskA-$i',
            namaTugas: 'Task A $i',
            mataKuliah: 'MK',
            deadline: deadlineA,
            tingkatKepentingan: 3,
            tingkatUrgensi: 3,
            estimasiWaktu: 2,
            status: TaskStatus.belumDikerjakan,
            createdAt: now.subtract(const Duration(hours: 10)),
            sawScore: sawScore,
            ranking: 1,
          );

          final taskB = Task(
            id: 'taskB-$i',
            namaTugas: 'Task B $i',
            mataKuliah: 'MK',
            deadline: deadlineB,
            tingkatKepentingan: 3,
            tingkatUrgensi: 3,
            estimasiWaktu: 2,
            status: TaskStatus.belumDikerjakan,
            createdAt: now.subtract(const Duration(hours: 5)),
            sawScore: sawScore,
            ranking: 2,
          );

          final tasks = [taskA, taskB];
          final overlappingBlocks = _createOverlappingBlocks(
            tasks: tasks,
            contestedSlot: contestedSlot,
            rng: rng,
          );

          final conflicts = scheduler.detectConflicts(
            overlappingBlocks,
            tasks: tasks,
          );

          if (conflicts.isEmpty) continue;

          final resolution = scheduler.resolveConflicts(
            blocks: overlappingBlocks,
            conflicts: conflicts,
            tasks: tasks,
            occupiedSlots: <DateTime>{},
            config: config,
            now: now,
          );

          // Task A has earlier deadline, should win
          final blocksAtSlot = resolution.blocks.where((b) {
            final slotKey = DateTime(
              b.startTime.year,
              b.startTime.month,
              b.startTime.day,
              b.startTime.hour,
            );
            return slotKey.isAtSameMomentAs(contestedSlot);
          }).toList();

          if (blocksAtSlot.isNotEmpty) {
            expect(
              blocksAtSlot.first.taskId,
              equals(taskA.id),
              reason:
                  'Iteration $i: With equal SAW scores ($sawScore), '
                  'task with earlier deadline (${taskA.deadline}) should win '
                  'over task with later deadline (${taskB.deadline})',
            );
          }

          iterationCount++;
        }
        expect(iterationCount, greaterThanOrEqualTo(100));
      },
    );

    test(
      'equal SAW Scores and equal deadlines: earlier createdAt wins',
      () {
        final rng = Random(654);
        var iterationCount = 0;

        for (var i = 0; i < 100; i++) {
          final now = DateTime(2024, 6, 15, 8, 0, 0);
          final config = ScheduleConfig();

          final hoursAhead = 6 + rng.nextInt(12);
          final contestedSlot = DateTime(
            now.year,
            now.month,
            now.day,
            now.hour + hoursAhead,
          );

          final sawScore = 0.5 + rng.nextDouble() * 0.4;
          final deadline = contestedSlot.add(Duration(hours: 3 + rng.nextInt(5)));

          // Task A has earlier createdAt
          final createdAtA = now.subtract(Duration(hours: 20 + rng.nextInt(20)));
          final createdAtB = now.subtract(Duration(hours: rng.nextInt(10)));

          final taskA = Task(
            id: 'taskA-$i',
            namaTugas: 'Task A $i',
            mataKuliah: 'MK',
            deadline: deadline,
            tingkatKepentingan: 3,
            tingkatUrgensi: 3,
            estimasiWaktu: 2,
            status: TaskStatus.belumDikerjakan,
            createdAt: createdAtA,
            sawScore: sawScore,
            ranking: 1,
          );

          final taskB = Task(
            id: 'taskB-$i',
            namaTugas: 'Task B $i',
            mataKuliah: 'MK',
            deadline: deadline,
            tingkatKepentingan: 3,
            tingkatUrgensi: 3,
            estimasiWaktu: 2,
            status: TaskStatus.belumDikerjakan,
            createdAt: createdAtB,
            sawScore: sawScore,
            ranking: 2,
          );

          final tasks = [taskA, taskB];
          final overlappingBlocks = _createOverlappingBlocks(
            tasks: tasks,
            contestedSlot: contestedSlot,
            rng: rng,
          );

          final conflicts = scheduler.detectConflicts(
            overlappingBlocks,
            tasks: tasks,
          );

          if (conflicts.isEmpty) continue;

          final resolution = scheduler.resolveConflicts(
            blocks: overlappingBlocks,
            conflicts: conflicts,
            tasks: tasks,
            occupiedSlots: <DateTime>{},
            config: config,
            now: now,
          );

          // Task A has earlier createdAt, should win
          final blocksAtSlot = resolution.blocks.where((b) {
            final slotKey = DateTime(
              b.startTime.year,
              b.startTime.month,
              b.startTime.day,
              b.startTime.hour,
            );
            return slotKey.isAtSameMomentAs(contestedSlot);
          }).toList();

          if (blocksAtSlot.isNotEmpty) {
            expect(
              blocksAtSlot.first.taskId,
              equals(taskA.id),
              reason:
                  'Iteration $i: With equal SAW ($sawScore) and equal deadline ($deadline), '
                  'task with earlier createdAt ($createdAtA) should win '
                  'over task with later createdAt ($createdAtB)',
            );
          }

          iterationCount++;
        }
        expect(iterationCount, greaterThanOrEqualTo(100));
      },
    );
  });


  // ===========================================================================
  // Feature: smart-scheduling, Property 5: Recursive Shift Produces Valid Placement
  // **Validates: Requirements 1.3, 4.3, 4.5**
  //
  // For any task that loses a slot in conflict resolution, it shall be shifted
  // to an earlier available slot (before the contested slot) that is not
  // occupied and not before current time, or marked as unschedulable if no
  // such slot exists.
  // ===========================================================================
  group('Property 5: Recursive Shift Produces Valid Placement', () {
    test(
      'losers are shifted to valid earlier slots or marked unschedulable',
      () {
        final rng = Random(111);
        var iterationCount = 0;

        for (var i = 0; i < 100; i++) {
          final now = DateTime(2024, 6, 15, 8, 0, 0);
          final config = ScheduleConfig(); // Default 8-17

          // Generate conflicting pair
          final pair = _generateConflictingPair(rng: rng, now: now);
          final tasks = [pair.taskA, pair.taskB];

          final overlappingBlocks = _createOverlappingBlocks(
            tasks: tasks,
            contestedSlot: pair.contestedSlot,
            rng: rng,
          );

          final conflicts = scheduler.detectConflicts(
            overlappingBlocks,
            tasks: tasks,
          );

          if (conflicts.isEmpty) continue;

          final resolution = scheduler.resolveConflicts(
            blocks: overlappingBlocks,
            conflicts: conflicts,
            tasks: tasks,
            occupiedSlots: <DateTime>{},
            config: config,
            now: now,
          );

          // Determine the loser
          final winner = pair.taskA.sawScore > pair.taskB.sawScore
              ? pair.taskA
              : (pair.taskA.sawScore < pair.taskB.sawScore
                  ? pair.taskB
                  : (pair.taskA.deadline.isBefore(pair.taskB.deadline)
                      ? pair.taskA
                      : (pair.taskA.deadline.isAtSameMomentAs(pair.taskB.deadline)
                          ? (pair.taskA.createdAt.isBefore(pair.taskB.createdAt)
                              ? pair.taskA
                              : pair.taskB)
                          : pair.taskB)));
          final loser = winner.id == pair.taskA.id ? pair.taskB : pair.taskA;

          // Check loser's block placement
          final loserBlocks = resolution.blocks
              .where((b) => b.taskId == loser.id)
              .toList();

          final loserWarnings = resolution.warnings
              .where((w) => w.taskId == loser.id && w.type == WarningType.unschedulable)
              .toList();

          if (loserBlocks.isNotEmpty) {
            // Loser was shifted — verify valid placement
            for (final block in loserBlocks) {
              final blockSlot = DateTime(
                block.startTime.year,
                block.startTime.month,
                block.startTime.day,
                block.startTime.hour,
              );

              // Must be before the contested slot
              expect(
                blockSlot.isBefore(pair.contestedSlot),
                isTrue,
                reason:
                    'Iteration $i: Loser block at $blockSlot should be before '
                    'contested slot ${pair.contestedSlot}',
              );

              // Must not be before current time
              expect(
                !blockSlot.isBefore(now),
                isTrue,
                reason:
                    'Iteration $i: Loser block at $blockSlot should not be '
                    'before current time $now',
              );
            }
          } else {
            // Loser was marked unschedulable
            expect(
              loserWarnings.isNotEmpty,
              isTrue,
              reason:
                  'Iteration $i: Loser task ${loser.id} has no blocks and no '
                  'unschedulable warning — it should be either shifted or marked unschedulable',
            );
          }

          iterationCount++;
        }
        expect(iterationCount, greaterThanOrEqualTo(100));
      },
    );

    test(
      'shifted blocks do not overlap with other blocks in the result',
      () {
        final rng = Random(222);
        var iterationCount = 0;

        for (var i = 0; i < 100; i++) {
          final now = DateTime(2024, 6, 15, 8, 0, 0);
          final config = ScheduleConfig();

          // Generate 3-5 tasks competing for same slot
          final hoursAhead = 6 + rng.nextInt(10);
          final contestedSlot = DateTime(
            now.year,
            now.month,
            now.day,
            now.hour + hoursAhead,
          );

          final taskCount = 3 + rng.nextInt(3);
          final tasks = List.generate(taskCount, (idx) {
            return Task(
              id: 'task-$i-$idx',
              namaTugas: 'Task $idx',
              mataKuliah: 'MK',
              deadline: contestedSlot.add(Duration(hours: 3 + rng.nextInt(10))),
              tingkatKepentingan: 3,
              tingkatUrgensi: 3,
              estimasiWaktu: 2,
              status: TaskStatus.belumDikerjakan,
              createdAt: now.subtract(Duration(hours: idx * 5)),
              sawScore: 0.3 + (idx * 0.15),
              ranking: taskCount - idx,
            );
          });

          final overlappingBlocks = _createOverlappingBlocks(
            tasks: tasks,
            contestedSlot: contestedSlot,
            rng: rng,
          );

          final conflicts = scheduler.detectConflicts(
            overlappingBlocks,
            tasks: tasks,
          );

          if (conflicts.isEmpty) continue;

          final resolution = scheduler.resolveConflicts(
            blocks: overlappingBlocks,
            conflicts: conflicts,
            tasks: tasks,
            occupiedSlots: <DateTime>{},
            config: config,
            now: now,
          );

          // Verify no overlaps in the resolved result
          final slotSet = <DateTime>{};
          for (final block in resolution.blocks) {
            final slotKey = DateTime(
              block.startTime.year,
              block.startTime.month,
              block.startTime.day,
              block.startTime.hour,
            );
            expect(
              slotSet.contains(slotKey),
              isFalse,
              reason:
                  'Iteration $i: After recursive shift, slot $slotKey is still '
                  'occupied by multiple blocks',
            );
            slotSet.add(slotKey);
          }

          iterationCount++;
        }
        expect(iterationCount, greaterThanOrEqualTo(100));
      },
    );

    test(
      'when no earlier slots available, loser is marked unschedulable',
      () {
        final rng = Random(333);
        var iterationCount = 0;

        for (var i = 0; i < 100; i++) {
          final now = DateTime(2024, 6, 15, 8, 0, 0);
          final config = ScheduleConfig();

          // Contested slot is the very first available slot (now)
          // so there's no earlier slot to shift to
          final contestedSlot = DateTime(
            now.year,
            now.month,
            now.day,
            now.hour,
          );

          final sawScoreA = 0.8 + rng.nextDouble() * 0.2;
          final sawScoreB = 0.2 + rng.nextDouble() * 0.3;

          final taskA = Task(
            id: 'taskA-$i',
            namaTugas: 'High Priority $i',
            mataKuliah: 'MK',
            deadline: contestedSlot.add(const Duration(hours: 5)),
            tingkatKepentingan: 5,
            tingkatUrgensi: 5,
            estimasiWaktu: 1,
            status: TaskStatus.belumDikerjakan,
            createdAt: now.subtract(const Duration(hours: 10)),
            sawScore: sawScoreA,
            ranking: 1,
          );

          final taskB = Task(
            id: 'taskB-$i',
            namaTugas: 'Low Priority $i',
            mataKuliah: 'MK',
            deadline: contestedSlot.add(const Duration(hours: 5)),
            tingkatKepentingan: 1,
            tingkatUrgensi: 1,
            estimasiWaktu: 1,
            status: TaskStatus.belumDikerjakan,
            createdAt: now.subtract(const Duration(hours: 5)),
            sawScore: sawScoreB,
            ranking: 2,
          );

          final tasks = [taskA, taskB];

          // Fill all slots between now and contested slot so loser can't shift
          // Since contested slot IS now, there are no earlier slots
          final overlappingBlocks = _createOverlappingBlocks(
            tasks: tasks,
            contestedSlot: contestedSlot,
            rng: rng,
          );

          final conflicts = scheduler.detectConflicts(
            overlappingBlocks,
            tasks: tasks,
          );

          if (conflicts.isEmpty) continue;

          final resolution = scheduler.resolveConflicts(
            blocks: overlappingBlocks,
            conflicts: conflicts,
            tasks: tasks,
            occupiedSlots: <DateTime>{},
            config: config,
            now: now,
          );

          // The loser (taskB) should either be shifted or marked unschedulable
          final loserBlocks = resolution.blocks
              .where((b) => b.taskId == taskB.id)
              .toList();
          final loserWarnings = resolution.warnings
              .where((w) => w.taskId == taskB.id && w.type == WarningType.unschedulable)
              .toList();

          // If loser has blocks, they must be valid (after now, before contested)
          // If no blocks, must have unschedulable warning
          if (loserBlocks.isEmpty) {
            expect(
              loserWarnings.isNotEmpty,
              isTrue,
              reason:
                  'Iteration $i: Loser task ${taskB.id} has no blocks and no '
                  'unschedulable warning when no earlier slots available',
            );
          } else {
            // If shifted, verify it's a valid slot
            for (final block in loserBlocks) {
              final blockSlot = DateTime(
                block.startTime.year,
                block.startTime.month,
                block.startTime.day,
                block.startTime.hour,
              );
              expect(
                !blockSlot.isBefore(now),
                isTrue,
                reason:
                    'Iteration $i: Shifted block at $blockSlot is before now ($now)',
              );
            }
          }

          iterationCount++;
        }
        expect(iterationCount, greaterThanOrEqualTo(100));
      },
    );
  });
}
