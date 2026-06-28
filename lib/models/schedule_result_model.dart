// lib/models/schedule_result_model.dart

import 'time_block_model.dart';

/// Tipe peringatan yang dihasilkan oleh Smart Scheduler
enum WarningType { insufficientSlots, pastDeadline, unschedulable }

/// Hasil keseluruhan dari proses penjadwalan
class ScheduleResult {
  final List<TimeBlock> timeBlocks;
  final List<ScheduleConflict> conflicts;
  final List<ScheduleWarning> warnings;

  ScheduleResult({
    required this.timeBlocks,
    required this.conflicts,
    required this.warnings,
  });
}

/// Representasi konflik ketika dua atau lebih tugas memperebutkan slot yang sama
class ScheduleConflict {
  final String slotTime; // ISO 8601 string of conflicting slot DateTime
  final List<String> taskIds; // Tasks competing for this slot
  final String winnerId; // Task that won the slot
  final Map<String, double> sawScores; // Maps taskId to its SAW score

  ScheduleConflict({
    required this.slotTime,
    required this.taskIds,
    required this.winnerId,
    required this.sawScores,
  });
}

/// Peringatan yang dihasilkan selama proses penjadwalan
class ScheduleWarning {
  final String taskId;
  final String message;
  final WarningType type;

  ScheduleWarning({
    required this.taskId,
    required this.message,
    required this.type,
  });
}
