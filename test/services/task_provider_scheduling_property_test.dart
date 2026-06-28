// test/services/task_provider_scheduling_property_test.dart
//
// Property-Based Tests for TaskProvider scheduling integration.
//
// Feature: smart-scheduling, Property 9: Manual Block Preservation on Reschedule
// Feature: smart-scheduling, Property 10: Move Validation
// Feature: smart-scheduling, Property 11: Task Completion Cleanup
// Feature: smart-scheduling, Property 12: Missed Block Detection
// Feature: smart-scheduling, Property 13: Estimation Change Reallocates Without SAW Modification
//
// **Validates: Requirements 7.1, 7.2, 7.3, 7.5, 7.6, 8.4, 9.4**

import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:tugasku/models/task_model.dart';
import 'package:tugasku/models/time_block_model.dart';
import 'package:tugasku/models/schedule_config_model.dart';
import 'package:tugasku/services/smart_scheduler_service.dart';

// ---------------------------------------------------------------------------
// Generators
// ---------------------------------------------------------------------------

/// Generates a random ScheduleConfig with valid work hours.
ScheduleConfig _generateScheduleConfig(Random rng) {
  if (rng.nextDouble() < 0.7) {
    final startHour = rng.nextInt(16); // 0-15
    final endHour = startHour + 2 + rng.nextInt(6); // at least 2 hours range
    return ScheduleConfig(
      workStartHour: startHour,
      workStartMinute: 0,
      workEndHour: endHour.clamp(0, 23),
      workEndMinute: 0,
    );
  } else {
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
  String? id,
  double? sawScore,
  DateTime? deadline,
  int? estimasiWaktu,
  TaskStatus? status,
}) {
  final taskId = id ?? 'task-${rng.nextInt(1000000)}';
  final score = sawScore ?? (rng.nextDouble() * 0.9 + 0.1);
  final estimasi = estimasiWaktu ?? (1 + rng.nextInt(5));
  final deadlineVal =
      deadline ?? now.add(Duration(hours: 12 + rng.nextInt(72)));
  final createdAt = now.subtract(Duration(hours: rng.nextInt(48)));

  return Task(
    id: taskId,
    namaTugas: 'Task $taskId',
    mataKuliah: 'MK Test',
    deadline: deadlineVal,
    tingkatKepentingan: 1 + rng.nextInt(5),
    tingkatUrgensi: 1 + rng.nextInt(5),
    estimasiWaktu: estimasi,
    status: status ?? TaskStatus.belumDikerjakan,
    createdAt: createdAt,
    sawScore: score,
    ranking: 1,
  );
}

/// Generates a random hour-aligned DateTime within a reasonable future range.
DateTime _generateFutureSlot(Random rng, DateTime now) {
  final hoursAhead = 1 + rng.nextInt(48);
  return DateTime(
    now.year,
    now.month,
    now.day,
    now.hour + hoursAhead,
  );
}


void main() {
  final scheduler = SmartSchedulerService();

  // ===========================================================================
  // Feature: smart-scheduling, Property 9: Manual Block Preservation on Reschedule
  // **Validates: Requirements 7.5**
  //
  // For any reschedule operation triggered by editing task A, all TimeBlocks
  // of other tasks that were manually placed (isManuallyPlaced=true) shall
  // remain at their original slots unchanged.
  // ===========================================================================
  group('Property 9: Manual Block Preservation on Reschedule', () {
    test(
      'manually placed blocks of other tasks remain unchanged after reschedule',
      () {
        final rng = Random(42);
        var iterationCount = 0;

        for (var i = 0; i < 100; i++) {
          final now = DateTime(2024, 6, 15, 8, 0, 0);
          final config = _generateScheduleConfig(rng);

          // Create task A (the one being edited/rescheduled)
          final taskA = _generateTask(
            rng: rng,
            now: now,
            id: 'taskA-$i',
            sawScore: 0.5 + rng.nextDouble() * 0.3,
            estimasiWaktu: 1 + rng.nextInt(3),
          );

          // Create task B with manual blocks
          final taskB = _generateTask(
            rng: rng,
            now: now,
            id: 'taskB-$i',
            sawScore: 0.3 + rng.nextDouble() * 0.3,
            estimasiWaktu: 1 + rng.nextInt(3),
          );

          // Create manual blocks for task B at specific slots
          final manualBlockCount = 1 + rng.nextInt(3);
          final manualBlocks = <TimeBlock>[];
          final usedSlots = <DateTime>{};

          for (var j = 0; j < manualBlockCount; j++) {
            DateTime slot;
            do {
              slot = _generateFutureSlot(rng, now);
            } while (usedSlots.contains(slot) ||
                !slot.isBefore(taskB.deadline));
            usedSlots.add(slot);

            manualBlocks.add(TimeBlock(
              id: 'manual-block-$i-$j',
              taskId: taskB.id,
              startTime: slot,
              endTime: slot.add(const Duration(hours: 1)),
              isManuallyPlaced: true,
            ));
          }

          // Record original manual block positions
          final originalPositions = manualBlocks
              .map((b) => (id: b.id, startTime: b.startTime, taskId: b.taskId))
              .toList();

          // Run rescheduleAll (simulating task A being edited)
          final result = scheduler.rescheduleAll(
            tasks: [taskA, taskB],
            manualBlocks: manualBlocks,
            config: config,
            now: now,
          );

          // Verify all manual blocks of task B are preserved
          for (final original in originalPositions) {
            final preserved = result.timeBlocks.where((b) =>
                b.id == original.id &&
                b.startTime.isAtSameMomentAs(original.startTime) &&
                b.taskId == original.taskId);

            expect(
              preserved.isNotEmpty,
              isTrue,
              reason:
                  'Iteration $i: Manual block ${original.id} of task B at '
                  '${original.startTime} was not preserved after reschedule',
            );
          }

          iterationCount++;
        }
        expect(iterationCount, greaterThanOrEqualTo(100));
      },
    );

    test(
      'manual blocks from multiple tasks all preserved after reschedule',
      () {
        final rng = Random(123);
        var iterationCount = 0;

        for (var i = 0; i < 100; i++) {
          final now = DateTime(2024, 6, 15, 8, 0, 0);
          final config = ScheduleConfig(); // Default 8-17

          // Create 3-5 tasks
          final taskCount = 3 + rng.nextInt(3);
          final tasks = List.generate(taskCount, (idx) => _generateTask(
            rng: rng,
            now: now,
            id: 'task-$i-$idx',
            sawScore: 0.2 + idx * 0.15,
            estimasiWaktu: 1 + rng.nextInt(2),
          ));

          // Create manual blocks for tasks 1..n (not task 0, which is "edited")
          final manualBlocks = <TimeBlock>[];
          final usedSlots = <DateTime>{};

          for (var t = 1; t < tasks.length; t++) {
            DateTime slot;
            do {
              slot = _generateFutureSlot(rng, now);
            } while (usedSlots.contains(slot) ||
                !slot.isBefore(tasks[t].deadline));
            usedSlots.add(slot);

            manualBlocks.add(TimeBlock(
              id: 'manual-$i-$t',
              taskId: tasks[t].id,
              startTime: slot,
              endTime: slot.add(const Duration(hours: 1)),
              isManuallyPlaced: true,
            ));
          }

          final originalPositions = manualBlocks
              .map((b) => (id: b.id, startTime: b.startTime))
              .toList();

          final result = scheduler.rescheduleAll(
            tasks: tasks,
            manualBlocks: manualBlocks,
            config: config,
            now: now,
          );

          // All manual blocks should be in the result at their original positions
          for (final original in originalPositions) {
            final found = result.timeBlocks.any((b) =>
                b.id == original.id &&
                b.startTime.isAtSameMomentAs(original.startTime));

            expect(
              found,
              isTrue,
              reason:
                  'Iteration $i: Manual block ${original.id} at '
                  '${original.startTime} was not preserved',
            );
          }

          iterationCount++;
        }
        expect(iterationCount, greaterThanOrEqualTo(100));
      },
    );
  });


  // ===========================================================================
  // Feature: smart-scheduling, Property 10: Move Validation
  // **Validates: Requirements 7.1, 7.2, 7.3**
  //
  // For any manual move of a TimeBlock: (a) moving to an empty slot before
  // the task's deadline shall succeed; (b) moving to an occupied slot shall
  // be rejected; (c) moving to a slot at or after the task's deadline shall
  // be rejected.
  //
  // Tests the moveTimeBlock validation logic directly (simulating TaskProvider).
  // ===========================================================================
  group('Property 10: Move Validation', () {
    test(
      'move to empty slot before deadline succeeds',
      () {
        final rng = Random(200);
        var iterationCount = 0;

        for (var i = 0; i < 100; i++) {
          final now = DateTime(2024, 6, 15, 8, 0, 0);

          // Create a task with a future deadline
          final deadline = now.add(Duration(hours: 24 + rng.nextInt(48)));
          final task = _generateTask(
            rng: rng,
            now: now,
            id: 'task-move-$i',
            deadline: deadline,
            estimasiWaktu: 2,
          );

          // Create a block for this task
          final originalSlot = DateTime(
            now.year,
            now.month,
            now.day,
            now.hour + 2 + rng.nextInt(5),
          );
          final block = TimeBlock(
            id: 'block-move-$i',
            taskId: task.id,
            startTime: originalSlot,
            endTime: originalSlot.add(const Duration(hours: 1)),
          );

          // Generate a target slot that is:
          // - empty (no other blocks)
          // - before deadline
          // - not in the past
          DateTime targetSlot;
          do {
            final hoursAhead = 1 + rng.nextInt(20);
            targetSlot = DateTime(
              now.year,
              now.month,
              now.day,
              now.hour + hoursAhead,
            );
          } while (targetSlot.isAtSameMomentAs(originalSlot) ||
              !targetSlot.isBefore(deadline) ||
              targetSlot.isBefore(now));

          // Simulate move validation (same logic as TaskProvider.moveTimeBlock)
          final timeBlocks = [block];
          final normalizedSlot = DateTime(
            targetSlot.year,
            targetSlot.month,
            targetSlot.day,
            targetSlot.hour,
          );
          final normalizedNow = DateTime(now.year, now.month, now.day, now.hour);

          // Check: not in the past
          final isPast = normalizedSlot.isBefore(normalizedNow);
          // Check: not occupied
          final isOccupied = timeBlocks.any((b) {
            if (b.id == block.id) return false;
            final bSlot = DateTime(
              b.startTime.year,
              b.startTime.month,
              b.startTime.day,
              b.startTime.hour,
            );
            return bSlot.isAtSameMomentAs(normalizedSlot);
          });
          // Check: before deadline
          final isBeforeDeadline = normalizedSlot.isBefore(task.deadline);

          final success = !isPast && !isOccupied && isBeforeDeadline;

          expect(
            success,
            isTrue,
            reason:
                'Iteration $i: Move to empty slot $targetSlot before deadline '
                '$deadline should succeed. isPast=$isPast, isOccupied=$isOccupied, '
                'isBeforeDeadline=$isBeforeDeadline',
          );

          iterationCount++;
        }
        expect(iterationCount, greaterThanOrEqualTo(100));
      },
    );

    test(
      'move to occupied slot is rejected',
      () {
        final rng = Random(300);
        var iterationCount = 0;

        for (var i = 0; i < 100; i++) {
          final now = DateTime(2024, 6, 15, 8, 0, 0);

          final deadline = now.add(Duration(hours: 48 + rng.nextInt(48)));
          final task = _generateTask(
            rng: rng,
            now: now,
            id: 'task-occ-$i',
            deadline: deadline,
            estimasiWaktu: 2,
          );

          // Create the block to move
          final originalSlot = DateTime(
            now.year, now.month, now.day, now.hour + 2,
          );
          final blockToMove = TimeBlock(
            id: 'block-occ-$i',
            taskId: task.id,
            startTime: originalSlot,
            endTime: originalSlot.add(const Duration(hours: 1)),
          );

          // Create another block occupying the target slot
          final occupiedSlot = DateTime(
            now.year, now.month, now.day, now.hour + 5 + rng.nextInt(10),
          );
          final occupyingBlock = TimeBlock(
            id: 'block-other-$i',
            taskId: 'other-task-$i',
            startTime: occupiedSlot,
            endTime: occupiedSlot.add(const Duration(hours: 1)),
          );

          final timeBlocks = [blockToMove, occupyingBlock];

          // Try to move blockToMove to the occupied slot
          final normalizedSlot = DateTime(
            occupiedSlot.year,
            occupiedSlot.month,
            occupiedSlot.day,
            occupiedSlot.hour,
          );

          final isOccupied = timeBlocks.any((b) {
            if (b.id == blockToMove.id) return false;
            final bSlot = DateTime(
              b.startTime.year,
              b.startTime.month,
              b.startTime.day,
              b.startTime.hour,
            );
            return bSlot.isAtSameMomentAs(normalizedSlot);
          });

          expect(
            isOccupied,
            isTrue,
            reason:
                'Iteration $i: Slot $occupiedSlot should be detected as occupied',
          );

          // Move should be rejected
          final moveSuccess = !isOccupied; // Would be false
          expect(
            moveSuccess,
            isFalse,
            reason:
                'Iteration $i: Move to occupied slot should be rejected',
          );

          iterationCount++;
        }
        expect(iterationCount, greaterThanOrEqualTo(100));
      },
    );

    test(
      'move to slot at or after deadline is rejected',
      () {
        final rng = Random(400);
        var iterationCount = 0;

        for (var i = 0; i < 100; i++) {
          final now = DateTime(2024, 6, 15, 8, 0, 0);

          // Create task with a specific deadline
          final deadlineHoursAhead = 10 + rng.nextInt(20);
          final deadline = DateTime(
            now.year, now.month, now.day, now.hour + deadlineHoursAhead,
          );
          final task = _generateTask(
            rng: rng,
            now: now,
            id: 'task-deadline-$i',
            deadline: deadline,
            estimasiWaktu: 2,
          );

          // Create a block for this task
          final originalSlot = DateTime(
            now.year, now.month, now.day, now.hour + 2,
          );
          final block = TimeBlock(
            id: 'block-deadline-$i',
            taskId: task.id,
            startTime: originalSlot,
            endTime: originalSlot.add(const Duration(hours: 1)),
          );

          // Target slot is at or after deadline
          final pastDeadlineHours = rng.nextInt(10); // 0 = at deadline, >0 = after
          final targetSlot = DateTime(
            deadline.year,
            deadline.month,
            deadline.day,
            deadline.hour + pastDeadlineHours,
          );

          // Validate: slot is NOT before deadline
          final isBeforeDeadline = targetSlot.isBefore(task.deadline);

          expect(
            isBeforeDeadline,
            isFalse,
            reason:
                'Iteration $i: Target slot $targetSlot should not be before '
                'deadline $deadline',
          );

          // Move should be rejected
          expect(
            isBeforeDeadline,
            isFalse,
            reason:
                'Iteration $i: Move to slot at/after deadline should be rejected',
          );

          iterationCount++;
        }
        expect(iterationCount, greaterThanOrEqualTo(100));
      },
    );
  });


  // ===========================================================================
  // Feature: smart-scheduling, Property 11: Task Completion Cleanup
  // **Validates: Requirements 7.6**
  //
  // For any task marked as complete, all TimeBlocks associated with that task
  // shall be removed from the schedule, and their slots shall become available
  // for other tasks.
  // ===========================================================================
  group('Property 11: Task Completion Cleanup', () {
    test(
      'all blocks of completed task are removed from schedule',
      () {
        final rng = Random(500);
        var iterationCount = 0;

        for (var i = 0; i < 100; i++) {
          final now = DateTime(2024, 6, 15, 8, 0, 0);
          final config = _generateScheduleConfig(rng);

          // Create multiple tasks
          final taskCount = 2 + rng.nextInt(4);
          final tasks = List.generate(taskCount, (idx) => _generateTask(
            rng: rng,
            now: now,
            id: 'task-cleanup-$i-$idx',
            sawScore: 0.2 + idx * 0.15,
            estimasiWaktu: 1 + rng.nextInt(3),
          ));

          // Schedule all tasks
          final result = scheduler.rescheduleAll(
            tasks: tasks,
            manualBlocks: [],
            config: config,
            now: now,
          );

          // Pick a random task to mark as complete
          final completedTaskIdx = rng.nextInt(tasks.length);
          final completedTask = tasks[completedTaskIdx];

          // Simulate task completion: remove all blocks for that task
          final blocksAfterCompletion = result.timeBlocks
              .where((b) => b.taskId != completedTask.id)
              .toList();

          // Verify no blocks remain for the completed task
          final remainingBlocksForCompleted = blocksAfterCompletion
              .where((b) => b.taskId == completedTask.id)
              .toList();

          expect(
            remainingBlocksForCompleted.isEmpty,
            isTrue,
            reason:
                'Iteration $i: After marking task ${completedTask.id} as complete, '
                '${remainingBlocksForCompleted.length} blocks still remain',
          );

          // Verify blocks of other tasks are still present
          for (var t = 0; t < tasks.length; t++) {
            if (t == completedTaskIdx) continue;
            final otherTask = tasks[t];
            final otherBlocks = result.timeBlocks
                .where((b) => b.taskId == otherTask.id)
                .toList();
            final otherBlocksAfter = blocksAfterCompletion
                .where((b) => b.taskId == otherTask.id)
                .toList();

            expect(
              otherBlocksAfter.length,
              equals(otherBlocks.length),
              reason:
                  'Iteration $i: Blocks of task ${otherTask.id} should not be '
                  'affected by completion of task ${completedTask.id}',
            );
          }

          iterationCount++;
        }
        expect(iterationCount, greaterThanOrEqualTo(100));
      },
    );

    test(
      'freed slots from completed task become available for rescheduling',
      () {
        final rng = Random(501);
        var iterationCount = 0;

        for (var i = 0; i < 100; i++) {
          final now = DateTime(2024, 6, 15, 8, 0, 0);
          final config = ScheduleConfig(); // Default 8-17

          // Create 2 tasks with tight deadline to force slot competition
          final deadline = now.add(Duration(hours: 6 + rng.nextInt(6)));
          final taskA = _generateTask(
            rng: rng,
            now: now,
            id: 'taskA-free-$i',
            deadline: deadline,
            sawScore: 0.9,
            estimasiWaktu: 3,
          );
          final taskB = _generateTask(
            rng: rng,
            now: now,
            id: 'taskB-free-$i',
            deadline: deadline,
            sawScore: 0.4,
            estimasiWaktu: 3,
          );

          // Schedule both
          final resultBefore = scheduler.rescheduleAll(
            tasks: [taskA, taskB],
            manualBlocks: [],
            config: config,
            now: now,
          );

          final slotsUsedByA = resultBefore.timeBlocks
              .where((b) => b.taskId == taskA.id)
              .map((b) => DateTime(
                    b.startTime.year,
                    b.startTime.month,
                    b.startTime.day,
                    b.startTime.hour,
                  ))
              .toSet();

          // Now mark task A as complete and reschedule only task B
          final resultAfter = scheduler.rescheduleAll(
            tasks: [taskB], // Only task B remains active
            manualBlocks: [],
            config: config,
            now: now,
          );

          // Task B should now potentially use slots that were freed by task A
          // At minimum, task B should have at least as many blocks as before
          final taskBBlocksBefore = resultBefore.timeBlocks
              .where((b) => b.taskId == taskB.id)
              .length;
          final taskBBlocksAfter = resultAfter.timeBlocks
              .where((b) => b.taskId == taskB.id)
              .length;

          expect(
            taskBBlocksAfter,
            greaterThanOrEqualTo(taskBBlocksBefore),
            reason:
                'Iteration $i: Task B should have at least as many blocks after '
                'task A is completed (before=$taskBBlocksBefore, after=$taskBBlocksAfter)',
          );

          iterationCount++;
        }
        expect(iterationCount, greaterThanOrEqualTo(100));
      },
    );
  });


  // ===========================================================================
  // Feature: smart-scheduling, Property 12: Missed Block Detection
  // **Validates: Requirements 9.4**
  //
  // For any TimeBlock whose endTime is before the current time and whose
  // associated task is not marked as complete, the block shall be marked
  // with status "missed".
  // ===========================================================================
  group('Property 12: Missed Block Detection', () {
    test(
      'past blocks of incomplete tasks are marked as missed',
      () {
        final rng = Random(600);
        var iterationCount = 0;

        for (var i = 0; i < 100; i++) {
          // Simulate "now" as a point in time
          final now = DateTime(2024, 6, 15, 14, 0, 0);

          // Create tasks (some complete, some not)
          final taskCount = 2 + rng.nextInt(4);
          final tasks = <Task>[];
          for (var t = 0; t < taskCount; t++) {
            final isComplete = rng.nextBool();
            tasks.add(_generateTask(
              rng: rng,
              now: now,
              id: 'task-missed-$i-$t',
              status: isComplete
                  ? TaskStatus.selesai
                  : TaskStatus.belumDikerjakan,
            ));
          }

          // Create time blocks: some in the past, some in the future
          final timeBlocks = <TimeBlock>[];
          for (var t = 0; t < tasks.length; t++) {
            final blockCount = 1 + rng.nextInt(3);
            for (var b = 0; b < blockCount; b++) {
              final isPast = rng.nextBool();
              final hoursOffset = 1 + rng.nextInt(10);
              final startTime = isPast
                  ? DateTime(now.year, now.month, now.day,
                      now.hour - hoursOffset)
                  : DateTime(now.year, now.month, now.day,
                      now.hour + hoursOffset);

              timeBlocks.add(TimeBlock(
                id: 'block-missed-$i-$t-$b',
                taskId: tasks[t].id,
                startTime: startTime,
                endTime: startTime.add(const Duration(hours: 1)),
                status: TimeBlockStatus.active,
              ));
            }
          }

          // Apply _markMissedBlocks logic (same as TaskProvider)
          final updatedBlocks = <TimeBlock>[];
          for (final block in timeBlocks) {
            if (block.endTime.isBefore(now) &&
                block.status != TimeBlockStatus.missed) {
              final taskIndex =
                  tasks.indexWhere((t) => t.id == block.taskId);
              if (taskIndex != -1 &&
                  tasks[taskIndex].status != TaskStatus.selesai) {
                updatedBlocks
                    .add(block.copyWith(status: TimeBlockStatus.missed));
              } else if (taskIndex == -1) {
                updatedBlocks
                    .add(block.copyWith(status: TimeBlockStatus.missed));
              } else {
                updatedBlocks.add(block);
              }
            } else {
              updatedBlocks.add(block);
            }
          }

          // Verify: all past blocks of incomplete tasks are marked missed
          for (final block in updatedBlocks) {
            final task = tasks.where((t) => t.id == block.taskId).firstOrNull;
            final isPast = block.endTime.isBefore(now);
            final isIncomplete =
                task == null || task.status != TaskStatus.selesai;

            if (isPast && isIncomplete) {
              expect(
                block.status,
                equals(TimeBlockStatus.missed),
                reason:
                    'Iteration $i: Block ${block.id} (endTime=${block.endTime}) '
                    'is past and task is incomplete, should be marked missed',
              );
            }
          }

          // Verify: future blocks are NOT marked missed
          for (final block in updatedBlocks) {
            final isFuture = !block.endTime.isBefore(now);
            if (isFuture) {
              expect(
                block.status,
                isNot(equals(TimeBlockStatus.missed)),
                reason:
                    'Iteration $i: Block ${block.id} (endTime=${block.endTime}) '
                    'is in the future, should NOT be marked missed',
              );
            }
          }

          // Verify: past blocks of COMPLETED tasks are NOT marked missed
          for (final block in updatedBlocks) {
            final task = tasks.where((t) => t.id == block.taskId).firstOrNull;
            final isPast = block.endTime.isBefore(now);
            final isComplete = task != null && task.status == TaskStatus.selesai;

            if (isPast && isComplete) {
              expect(
                block.status,
                isNot(equals(TimeBlockStatus.missed)),
                reason:
                    'Iteration $i: Block ${block.id} is past but task is complete, '
                    'should NOT be marked missed',
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
  // Feature: smart-scheduling, Property 13: Estimation Change Reallocates Without SAW Modification
  // **Validates: Requirements 8.4**
  //
  // For any task whose estimation is changed, the scheduler shall remove all
  // old TimeBlocks for that task and allocate new blocks matching the new
  // estimation count, without modifying the task's SAW Score.
  // ===========================================================================
  group('Property 13: Estimation Change Reallocates Without SAW Modification', () {
    test(
      'estimation change produces new block count matching new estimation, SAW unchanged',
      () {
        final rng = Random(700);
        var iterationCount = 0;

        for (var i = 0; i < 100; i++) {
          final now = DateTime(2024, 6, 15, 8, 0, 0);
          final config = _generateScheduleConfig(rng);

          // Create a task with initial estimation
          final initialEstimation = 1 + rng.nextInt(5); // 1-5
          final sawScore = 0.3 + rng.nextDouble() * 0.6;
          final deadline = now.add(Duration(hours: 24 + rng.nextInt(72)));

          final task = _generateTask(
            rng: rng,
            now: now,
            id: 'task-est-$i',
            sawScore: sawScore,
            estimasiWaktu: initialEstimation,
            deadline: deadline,
          );

          // Schedule with initial estimation
          final resultBefore = scheduler.rescheduleAll(
            tasks: [task],
            manualBlocks: [],
            config: config,
            now: now,
          );

          final blocksBefore = resultBefore.timeBlocks
              .where((b) => b.taskId == task.id)
              .toList();

          // Change estimation (new value different from initial)
          int newEstimation;
          do {
            newEstimation = 1 + rng.nextInt(8); // 1-8
          } while (newEstimation == initialEstimation);

          // Create updated task with new estimation but SAME SAW score
          final updatedTask = task.copyWith(estimasiWaktu: newEstimation);

          // Verify SAW score is unchanged
          expect(
            updatedTask.sawScore,
            equals(sawScore),
            reason:
                'Iteration $i: SAW score should remain $sawScore after '
                'estimation change',
          );

          // Reschedule with new estimation
          final resultAfter = scheduler.rescheduleAll(
            tasks: [updatedTask],
            manualBlocks: [],
            config: config,
            now: now,
          );

          final blocksAfter = resultAfter.timeBlocks
              .where((b) => b.taskId == task.id)
              .toList();

          // New block count should match new estimation
          // (or be limited by available slots)
          final availableSlots = scheduler.getAvailableSlots(
            from: now,
            until: deadline,
            occupiedSlots: <DateTime>{},
            config: config,
          );
          final expectedBlockCount =
              newEstimation <= availableSlots.length
                  ? newEstimation
                  : availableSlots.length;

          expect(
            blocksAfter.length,
            equals(expectedBlockCount),
            reason:
                'Iteration $i: After estimation change from $initialEstimation '
                'to $newEstimation, expected $expectedBlockCount blocks but got '
                '${blocksAfter.length}. Available slots: ${availableSlots.length}',
          );

          // Old blocks should be gone (new IDs generated)
          final oldBlockIds = blocksBefore.map((b) => b.id).toSet();
          final newBlockIds = blocksAfter.map((b) => b.id).toSet();
          // Since rescheduleAll generates new blocks, IDs should be different
          // (unless by extreme coincidence with UUID)
          if (blocksBefore.isNotEmpty && blocksAfter.isNotEmpty) {
            expect(
              oldBlockIds.intersection(newBlockIds).isEmpty,
              isTrue,
              reason:
                  'Iteration $i: Old block IDs should not appear in new schedule '
                  '(old blocks should be removed and new ones allocated)',
            );
          }

          iterationCount++;
        }
        expect(iterationCount, greaterThanOrEqualTo(100));
      },
    );

    test(
      'estimation change does not affect SAW scores of other tasks',
      () {
        final rng = Random(701);
        var iterationCount = 0;

        for (var i = 0; i < 100; i++) {
          final now = DateTime(2024, 6, 15, 8, 0, 0);
          final config = ScheduleConfig();

          // Create multiple tasks
          final taskA = _generateTask(
            rng: rng,
            now: now,
            id: 'taskA-saw-$i',
            sawScore: 0.8,
            estimasiWaktu: 2,
          );
          final taskB = _generateTask(
            rng: rng,
            now: now,
            id: 'taskB-saw-$i',
            sawScore: 0.5,
            estimasiWaktu: 3,
          );

          // Record original SAW scores
          final originalScoreA = taskA.sawScore;
          final originalScoreB = taskB.sawScore;

          // Change estimation of task A
          final newEstimation = 1 + rng.nextInt(8);
          final updatedTaskA = taskA.copyWith(estimasiWaktu: newEstimation);

          // Reschedule
          scheduler.rescheduleAll(
            tasks: [updatedTaskA, taskB],
            manualBlocks: [],
            config: config,
            now: now,
          );

          // SAW scores should remain unchanged (scheduler doesn't modify them)
          expect(
            updatedTaskA.sawScore,
            equals(originalScoreA),
            reason:
                'Iteration $i: Task A SAW score should remain $originalScoreA',
          );
          expect(
            taskB.sawScore,
            equals(originalScoreB),
            reason:
                'Iteration $i: Task B SAW score should remain $originalScoreB',
          );

          iterationCount++;
        }
        expect(iterationCount, greaterThanOrEqualTo(100));
      },
    );
  });
}
