// lib/services/smart_scheduler_service.dart

import 'package:uuid/uuid.dart';

import '../models/time_block_model.dart';
import '../models/schedule_config_model.dart';
import '../models/schedule_result_model.dart';
import '../models/task_model.dart';

/// Service inti untuk penjadwalan cerdas.
///
/// Mengelola backward scheduling dari deadline, conflict detection & resolution,
/// dan slot management. Menggunakan SAW Score sebagai penentu prioritas
/// saat terjadi konflik.
class SmartSchedulerService {
  /// Mendapatkan slot tersedia (hour-aligned) antara [from] dan [until],
  /// mengecualikan slot yang sudah terisi ([occupiedSlots]),
  /// dan memprioritaskan slot dalam Primary Work Hours terlebih dahulu.
  ///
  /// Mengembalikan list DateTime yang mewakili awal setiap slot 1 jam.
  /// Slot dalam PWH diurutkan lebih dulu, diikuti slot di luar PWH.
  /// Dalam masing-masing grup, slot diurutkan dari yang paling dekat ke [until]
  /// (mundur dari deadline).
  ///
  /// [from] dan [until] akan di-normalize ke jam bulat:
  /// - [from] dibulatkan ke atas ke jam berikutnya jika tidak tepat di jam
  /// - [until] dibulatkan ke bawah ke jam sebelumnya (slot terakhir sebelum until)
  List<DateTime> getAvailableSlots({
    required DateTime from,
    required DateTime until,
    required Set<DateTime> occupiedSlots,
    required ScheduleConfig config,
  }) {
    // Normalize 'from' ke jam bulat berikutnya jika tidak tepat di jam
    DateTime normalizedFrom;
    if (from.minute == 0 && from.second == 0 && from.millisecond == 0) {
      normalizedFrom = from;
    } else {
      normalizedFrom = DateTime(
        from.year,
        from.month,
        from.day,
        from.hour + 1,
      );
    }

    // Jika from >= until, tidak ada slot tersedia
    if (!normalizedFrom.isBefore(until)) {
      return [];
    }

    // Kumpulkan semua slot hour-aligned dari normalizedFrom sampai sebelum until
    final pwhSlots = <DateTime>[];
    final nonPwhSlots = <DateTime>[];

    DateTime cursor = normalizedFrom;
    while (cursor.isBefore(until)) {
      // Normalize cursor untuk memastikan hour-aligned
      final normalizedCursor = DateTime(
        cursor.year,
        cursor.month,
        cursor.day,
        cursor.hour,
      );

      // Cek apakah slot sudah terisi
      if (!occupiedSlots.contains(normalizedCursor)) {
        if (config.isWithinWorkHours(normalizedCursor)) {
          pwhSlots.add(normalizedCursor);
        } else {
          nonPwhSlots.add(normalizedCursor);
        }
      }

      // Maju 1 jam
      cursor = cursor.add(const Duration(hours: 1));
    }

    // Gabungkan: PWH slots dulu, lalu non-PWH slots
    // Masing-masing tetap dalam urutan kronologis (dari from menuju until)
    return [...pwhSlots, ...nonPwhSlots];
  }

  /// Memvalidasi bahwa tidak ada dua TimeBlock yang menempati slot yang sama.
  ///
  /// Mengembalikan `true` jika tidak ada overlap (valid),
  /// `false` jika ditemukan overlap.
  bool validateNoOverlaps(List<TimeBlock> blocks) {
    if (blocks.length <= 1) return true;

    final seenSlots = <DateTime>{};
    for (final block in blocks) {
      // Normalize startTime untuk perbandingan
      final slotKey = DateTime(
        block.startTime.year,
        block.startTime.month,
        block.startTime.day,
        block.startTime.hour,
      );

      if (seenSlots.contains(slotKey)) {
        return false;
      }
      seenSlots.add(slotKey);
    }
    return true;
  }

  // ---------------------------------------------------------------------------
  // Placeholder methods untuk task berikutnya (2.3 - 2.5)
  // ---------------------------------------------------------------------------

  /// Backward schedule satu tugas dari deadline.
  ///
  /// Algoritma:
  /// 1. Jika deadline sudah lewat (sebelum [now]), return list kosong.
  /// 2. Dapatkan slot tersedia dari [now] sampai deadline menggunakan
  ///    [getAvailableSlots] (sudah memprioritaskan PWH).
  /// 3. Ambil hingga [task.estimasiWaktu] slot dari daftar tersedia.
  /// 4. Buat TimeBlock untuk setiap slot yang dipilih.
  /// 5. Jika slot tidak cukup, alokasikan sebanyak mungkin
  ///    (min(estimasi, available)).
  ///
  /// Catatan: Peringatan (warning) untuk insufficient slots dan past deadline
  /// ditangani oleh caller (rescheduleAll).
  List<TimeBlock> backwardSchedule({
    required Task task,
    required Set<DateTime> occupiedSlots,
    required ScheduleConfig config,
    required DateTime now,
  }) {
    // Reject if deadline is in the past
    if (task.deadline.isBefore(now) || task.deadline.isAtSameMomentAs(now)) {
      return [];
    }

    // Get available slots from now to deadline (PWH-prioritized)
    final availableSlots = getAvailableSlots(
      from: now,
      until: task.deadline,
      occupiedSlots: occupiedSlots,
      config: config,
    );

    if (availableSlots.isEmpty) {
      return [];
    }

    // Take up to estimasiWaktu slots (min of estimation and available)
    final slotsToAllocate = availableSlots.length < task.estimasiWaktu
        ? availableSlots.length
        : task.estimasiWaktu;

    final selectedSlots = availableSlots.sublist(0, slotsToAllocate);

    // Create TimeBlocks for each selected slot
    const uuid = Uuid();
    final timeBlocks = <TimeBlock>[];

    for (final slot in selectedSlots) {
      timeBlocks.add(TimeBlock(
        id: uuid.v4(),
        taskId: task.id,
        startTime: slot,
        endTime: slot.add(const Duration(hours: 1)),
      ));
    }

    return timeBlocks;
  }

  /// Deteksi konflik dalam set time blocks.
  ///
  /// Mengidentifikasi semua slot di mana lebih dari satu TimeBlock overlap.
  /// Mengembalikan list [ScheduleConflict] dengan informasi task yang berkonflik,
  /// SAW scores, dan pemenang berdasarkan prioritas.
  ///
  /// Winner ditentukan oleh:
  /// 1. SAW Score tertinggi
  /// 2. Tiebreaker: deadline paling awal
  /// 3. Tiebreaker: createdAt paling awal
  List<ScheduleConflict> detectConflicts(
    List<TimeBlock> allBlocks, {
    required List<Task> tasks,
  }) {
    if (allBlocks.isEmpty) return [];

    // Group blocks by their slot (hour-aligned startTime)
    final slotMap = <DateTime, List<TimeBlock>>{};
    for (final block in allBlocks) {
      final slotKey = DateTime(
        block.startTime.year,
        block.startTime.month,
        block.startTime.day,
        block.startTime.hour,
      );
      slotMap.putIfAbsent(slotKey, () => []).add(block);
    }

    // Build task lookup map
    final taskMap = <String, Task>{};
    for (final task in tasks) {
      taskMap[task.id] = task;
    }

    // Find slots with more than one block (conflicts)
    final conflicts = <ScheduleConflict>[];
    for (final entry in slotMap.entries) {
      if (entry.value.length <= 1) continue;

      final slotTime = entry.key;
      final conflictingBlocks = entry.value;

      // Collect task IDs and SAW scores
      final taskIds = <String>[];
      final sawScores = <String, double>{};
      for (final block in conflictingBlocks) {
        if (!taskIds.contains(block.taskId)) {
          taskIds.add(block.taskId);
          final task = taskMap[block.taskId];
          if (task != null) {
            sawScores[block.taskId] = task.sawScore;
          }
        }
      }

      // Determine winner using priority ordering
      final winnerId = _determineWinner(taskIds, taskMap);

      conflicts.add(ScheduleConflict(
        slotTime: slotTime.toIso8601String(),
        taskIds: taskIds,
        winnerId: winnerId,
        sawScores: sawScores,
      ));
    }

    return conflicts;
  }

  /// Menentukan pemenang dari sekumpulan task yang berkonflik.
  ///
  /// Prioritas:
  /// 1. SAW Score tertinggi
  /// 2. Deadline paling awal (tiebreaker)
  /// 3. CreatedAt paling awal (tiebreaker)
  String _determineWinner(List<String> taskIds, Map<String, Task> taskMap) {
    String winnerId = taskIds.first;
    Task? winnerTask = taskMap[winnerId];

    for (int i = 1; i < taskIds.length; i++) {
      final candidateId = taskIds[i];
      final candidateTask = taskMap[candidateId];

      if (winnerTask == null) {
        winnerId = candidateId;
        winnerTask = candidateTask;
        continue;
      }
      if (candidateTask == null) continue;

      // Compare SAW scores
      if (candidateTask.sawScore > winnerTask.sawScore) {
        winnerId = candidateId;
        winnerTask = candidateTask;
      } else if (candidateTask.sawScore == winnerTask.sawScore) {
        // Tiebreaker 1: earliest deadline
        if (candidateTask.deadline.isBefore(winnerTask.deadline)) {
          winnerId = candidateId;
          winnerTask = candidateTask;
        } else if (candidateTask.deadline.isAtSameMomentAs(winnerTask.deadline)) {
          // Tiebreaker 2: earliest createdAt
          if (candidateTask.createdAt.isBefore(winnerTask.createdAt)) {
            winnerId = candidateId;
            winnerTask = candidateTask;
          }
        }
      }
    }

    return winnerId;
  }

  /// Resolve konflik menggunakan SAW scores dengan recursive shift.
  ///
  /// Algoritma:
  /// 1. Deteksi konflik (slot dengan >1 block)
  /// 2. Untuk setiap konflik:
  ///    - Pemenang (SAW Score tertinggi) mempertahankan slot
  ///    - Pecundang digeser mundur ke slot tersedia sebelumnya
  ///    - Jika tidak ada slot tersedia, tandai sebagai unschedulable
  /// 3. Ulangi sampai tidak ada konflik (atau batas iterasi tercapai)
  ///
  /// Mengembalikan record berisi resolved blocks dan warnings.
  ({List<TimeBlock> blocks, List<ScheduleWarning> warnings}) resolveConflicts({
    required List<TimeBlock> blocks,
    required List<ScheduleConflict> conflicts,
    required List<Task> tasks,
    required Set<DateTime> occupiedSlots,
    required ScheduleConfig config,
    required DateTime now,
  }) {
    final warnings = <ScheduleWarning>[];
    final resolvedBlocks = List<TimeBlock>.from(blocks);
    final taskMap = <String, Task>{};
    for (final task in tasks) {
      taskMap[task.id] = task;
    }

    // Track currently occupied slots (from resolved blocks)
    final currentOccupied = Set<DateTime>.from(occupiedSlots);
    for (final block in resolvedBlocks) {
      currentOccupied.add(DateTime(
        block.startTime.year,
        block.startTime.month,
        block.startTime.day,
        block.startTime.hour,
      ));
    }

    // Safety limit to prevent infinite loops
    const maxIterations = 1000;
    int iteration = 0;

    var currentConflicts = detectConflicts(resolvedBlocks, tasks: tasks);

    while (currentConflicts.isNotEmpty && iteration < maxIterations) {
      iteration++;

      for (final conflict in currentConflicts) {
        final slotTime = DateTime.parse(conflict.slotTime);

        // Get all blocks at this conflicting slot
        final blocksAtSlot = resolvedBlocks.where((b) {
          final blockSlot = DateTime(
            b.startTime.year,
            b.startTime.month,
            b.startTime.day,
            b.startTime.hour,
          );
          return blockSlot.isAtSameMomentAs(slotTime);
        }).toList();

        if (blocksAtSlot.length <= 1) continue;

        // Determine winner among competing tasks
        final competingTaskIds = blocksAtSlot
            .map((b) => b.taskId)
            .toSet()
            .toList();
        final winnerId = _determineWinner(competingTaskIds, taskMap);

        // Process losers: shift them backward
        for (final block in blocksAtSlot) {
          if (block.taskId == winnerId) continue; // Winner keeps the slot

          // Remove loser's block from resolved list and occupied set
          resolvedBlocks.remove(block);
          currentOccupied.remove(DateTime(
            block.startTime.year,
            block.startTime.month,
            block.startTime.day,
            block.startTime.hour,
          ));

          // Find next available slot backward (from now to the contested slot)
          final availableSlots = getAvailableSlots(
            from: now,
            until: slotTime,
            occupiedSlots: currentOccupied,
            config: config,
          );

          if (availableSlots.isNotEmpty) {
            // Pick the slot closest to the contested slot
            // (last in the list since getAvailableSlots returns chronologically
            // within PWH/non-PWH groups)
            final shiftedSlot = availableSlots.last;

            // Create new block at the shifted slot
            final newBlock = block.copyWith(
              startTime: shiftedSlot,
              endTime: shiftedSlot.add(const Duration(hours: 1)),
            );
            resolvedBlocks.add(newBlock);
            currentOccupied.add(shiftedSlot);
          } else {
            // No slot available — mark as unschedulable
            final task = taskMap[block.taskId];
            final taskName = task?.namaTugas ?? block.taskId;
            warnings.add(ScheduleWarning(
              taskId: block.taskId,
              message:
                  '$taskName tidak dapat dijadwalkan — tidak ada slot tersedia',
              type: WarningType.unschedulable,
            ));
          }
        }
      }

      // Re-check for conflicts after resolution
      currentConflicts = detectConflicts(resolvedBlocks, tasks: tasks);
    }

    return (blocks: resolvedBlocks, warnings: warnings);
  }

  /// Main entry point: reschedule semua tugas aktif.
  ///
  /// Algoritma:
  /// 1. Filter tugas: exclude completed (selesai=true) dan tanpa deadline valid
  /// 2. Sort tasks by SAW Score descending (higher priority first)
  /// 3. Collect occupied slots from manualBlocks
  /// 4. For each task (in SAW Score order):
  ///    - Skip tasks with past deadlines (add pastDeadline warning)
  ///    - Run backwardSchedule() to get TimeBlocks
  ///    - Add resulting blocks to the collection
  ///    - Update occupied slots
  ///    - If blocks.length < task.estimasiWaktu, add insufficientSlots warning
  /// 5. Combine all blocks (manual + scheduled)
  /// 6. Detect conflicts using detectConflicts()
  /// 7. If conflicts exist, resolve them using resolveConflicts()
  /// 8. Validate no overlaps in final result (safety check)
  /// 9. Return ScheduleResult with all blocks, detected conflicts, and accumulated warnings
  ScheduleResult rescheduleAll({
    required List<Task> tasks,
    required List<TimeBlock> manualBlocks,
    required ScheduleConfig config,
    required DateTime now,
  }) {
    final warnings = <ScheduleWarning>[];

    // 1. Filter tasks: exclude completed and those without valid deadlines
    final activeTasks = tasks.where((task) {
      // Exclude completed tasks
      if (task.status == TaskStatus.selesai) return false;
      return true;
    }).toList();

    // 2. Sort by SAW Score descending (higher priority first)
    activeTasks.sort((a, b) => b.sawScore.compareTo(a.sawScore));

    // 3. Collect occupied slots from manual blocks
    final occupiedSlots = <DateTime>{};
    for (final block in manualBlocks) {
      occupiedSlots.add(DateTime(
        block.startTime.year,
        block.startTime.month,
        block.startTime.day,
        block.startTime.hour,
      ));
    }

    // 4. Schedule each task in SAW Score order
    final scheduledBlocks = <TimeBlock>[];

    for (final task in activeTasks) {
      // Skip tasks with past deadlines
      if (task.deadline.isBefore(now) || task.deadline.isAtSameMomentAs(now)) {
        warnings.add(ScheduleWarning(
          taskId: task.id,
          message:
              '${task.namaTugas} memiliki deadline yang sudah lewat',
          type: WarningType.pastDeadline,
        ));
        continue;
      }

      // Run backward scheduling
      final blocks = backwardSchedule(
        task: task,
        occupiedSlots: occupiedSlots,
        config: config,
        now: now,
      );

      // Add resulting blocks and update occupied slots
      for (final block in blocks) {
        scheduledBlocks.add(block);
        occupiedSlots.add(DateTime(
          block.startTime.year,
          block.startTime.month,
          block.startTime.day,
          block.startTime.hour,
        ));
      }

      // Check if insufficient slots were allocated
      if (blocks.length < task.estimasiWaktu) {
        final shortfall = task.estimasiWaktu - blocks.length;
        warnings.add(ScheduleWarning(
          taskId: task.id,
          message:
              '${task.namaTugas} membutuhkan $shortfall jam lagi sebelum deadline',
          type: WarningType.insufficientSlots,
        ));
      }
    }

    // 5. Combine all blocks (manual + scheduled)
    final allBlocks = [...manualBlocks, ...scheduledBlocks];

    // 6. Detect conflicts
    final conflicts = detectConflicts(allBlocks, tasks: tasks);

    // 7. If conflicts exist, resolve them
    List<TimeBlock> finalBlocks;
    if (conflicts.isNotEmpty) {
      final resolution = resolveConflicts(
        blocks: allBlocks,
        conflicts: conflicts,
        tasks: tasks,
        occupiedSlots: <DateTime>{}, // resolveConflicts manages its own occupied tracking
        config: config,
        now: now,
      );
      finalBlocks = resolution.blocks;
      warnings.addAll(resolution.warnings);
    } else {
      finalBlocks = allBlocks;
    }

    // 8. Validate no overlaps in final result (safety check)
    if (!validateNoOverlaps(finalBlocks)) {
      // If overlaps still exist after resolution, this is unexpected.
      // As a safety measure, run conflict resolution again.
      final safetyConflicts = detectConflicts(finalBlocks, tasks: tasks);
      if (safetyConflicts.isNotEmpty) {
        final safetyResolution = resolveConflicts(
          blocks: finalBlocks,
          conflicts: safetyConflicts,
          tasks: tasks,
          occupiedSlots: <DateTime>{},
          config: config,
          now: now,
        );
        finalBlocks = safetyResolution.blocks;
        warnings.addAll(safetyResolution.warnings);
      }
    }

    // 9. Return ScheduleResult
    return ScheduleResult(
      timeBlocks: finalBlocks,
      conflicts: conflicts,
      warnings: warnings,
    );
  }
}
