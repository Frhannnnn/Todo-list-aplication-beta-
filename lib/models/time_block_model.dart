// lib/models/time_block_model.dart

enum TimeBlockStatus { active, missed, manuallyMoved }

class TimeBlock {
  final String id;
  final String taskId;
  final DateTime startTime; // Selalu pada jam bulat (e.g., 08:00, 09:00)
  final DateTime endTime; // startTime + 1 hour
  final TimeBlockStatus status;
  final bool isManuallyPlaced; // True jika user drag-and-drop

  TimeBlock({
    required this.id,
    required this.taskId,
    required this.startTime,
    required this.endTime,
    this.status = TimeBlockStatus.active,
    this.isManuallyPlaced = false,
  })  : assert(
          startTime.minute == 0 && startTime.second == 0 && startTime.millisecond == 0,
          'startTime must be on hour boundary (minute=0, second=0, millisecond=0)',
        ),
        assert(
          endTime.isAtSameMomentAs(startTime.add(const Duration(hours: 1))),
          'endTime must be exactly startTime + 1 hour',
        );

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'taskId': taskId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'status': status.index,
      'isManuallyPlaced': isManuallyPlaced,
    };
  }

  factory TimeBlock.fromJson(Map<String, dynamic> json) {
    return TimeBlock(
      id: json['id'],
      taskId: json['taskId'],
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      status: TimeBlockStatus.values[json['status']],
      isManuallyPlaced: json['isManuallyPlaced'] ?? false,
    );
  }

  TimeBlock copyWith({
    String? id,
    String? taskId,
    DateTime? startTime,
    DateTime? endTime,
    TimeBlockStatus? status,
    bool? isManuallyPlaced,
  }) {
    final newStartTime = startTime ?? this.startTime;
    return TimeBlock(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      startTime: newStartTime,
      endTime: endTime ?? (startTime != null ? newStartTime.add(const Duration(hours: 1)) : this.endTime),
      status: status ?? this.status,
      isManuallyPlaced: isManuallyPlaced ?? this.isManuallyPlaced,
    );
  }
}
