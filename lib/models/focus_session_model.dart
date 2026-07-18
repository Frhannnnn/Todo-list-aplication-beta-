// lib/models/focus_session_model.dart

/// Mode sesi fokus. `custom` disiapkan untuk Fase 2 (belum aktif di Fase 1).
enum FocusMode { focus, flexible, custom }

extension FocusModeLabel on FocusMode {
  String get label {
    switch (this) {
      case FocusMode.focus:
        return 'Fokus';
      case FocusMode.flexible:
        return 'Fleksibel';
      case FocusMode.custom:
        return 'Kustom';
    }
  }
}

/// Status siklus hidup sebuah sesi fokus. `preparing` & `breakTime`
/// dideklarasikan untuk fase berikutnya (belum dipakai di Fase 1).
enum FocusSessionState {
  idle,
  preparing,
  running,
  paused,
  completed,
  cancelled,
  breakTime,
}

/// Lama hitung mundur di halaman persiapan (detik).
const int kPreparationSeconds = 5;

/// Hasil pencapaian target sebuah sesi fokus.
enum SessionTargetStatus { achieved, partial, notAchieved }

extension SessionTargetStatusLabel on SessionTargetStatus {
  String get label {
    switch (this) {
      case SessionTargetStatus.achieved:
        return 'Ya';
      case SessionTargetStatus.partial:
        return 'Sebagian';
      case SessionTargetStatus.notAchieved:
        return 'Belum';
    }
  }
}

/// Preset durasi fokus/istirahat siap pakai.
class FocusPreset {
  final String name;
  final int focusMinutes;
  final int breakMinutes;

  const FocusPreset({
    required this.name,
    required this.focusMinutes,
    required this.breakMinutes,
  });
}

const List<FocusPreset> kFocusPresets = [
  FocusPreset(name: 'Pomodoro', focusMinutes: 25, breakMinutes: 5),
  FocusPreset(name: 'Belajar', focusMinutes: 45, breakMinutes: 15),
  FocusPreset(name: 'Flow', focusMinutes: 50, breakMinutes: 10),
  FocusPreset(name: 'Deep Work', focusMinutes: 90, breakMinutes: 20),
];

/// Satu sesi fokus yang terikat ke sebuah tugas.
class FocusSession {
  final String id;
  final String taskId;
  final FocusMode mode;
  final String presetName;
  final String? targetText; // target bebas, mis. "Menyelesaikan Bab II"
  final int focusMinutes;
  final int recommendedSessions; // rekomendasi dari SAW (informasi)
  final DateTime startedAt;
  final DateTime? endedAt;
  final SessionTargetStatus? targetStatus;

  const FocusSession({
    required this.id,
    required this.taskId,
    required this.mode,
    required this.presetName,
    this.targetText,
    required this.focusMinutes,
    required this.recommendedSessions,
    required this.startedAt,
    this.endedAt,
    this.targetStatus,
  });

  FocusSession copyWith({
    DateTime? endedAt,
    SessionTargetStatus? targetStatus,
  }) {
    return FocusSession(
      id: id,
      taskId: taskId,
      mode: mode,
      presetName: presetName,
      targetText: targetText,
      focusMinutes: focusMinutes,
      recommendedSessions: recommendedSessions,
      startedAt: startedAt,
      endedAt: endedAt ?? this.endedAt,
      targetStatus: targetStatus ?? this.targetStatus,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'taskId': taskId,
        'mode': mode.index,
        'presetName': presetName,
        'targetText': targetText,
        'focusMinutes': focusMinutes,
        'recommendedSessions': recommendedSessions,
        'startedAt': startedAt.toIso8601String(),
        'endedAt': endedAt?.toIso8601String(),
        'targetStatus': targetStatus?.index,
      };

  factory FocusSession.fromJson(Map<String, dynamic> json) {
    final rawMode = json['mode'];
    final mode = (rawMode is int &&
            rawMode >= 0 &&
            rawMode < FocusMode.values.length)
        ? FocusMode.values[rawMode]
        : FocusMode.focus;

    final rawStatus = json['targetStatus'];
    final targetStatus = (rawStatus is int &&
            rawStatus >= 0 &&
            rawStatus < SessionTargetStatus.values.length)
        ? SessionTargetStatus.values[rawStatus]
        : null;

    return FocusSession(
      id: json['id'] as String,
      taskId: json['taskId'] as String,
      mode: mode,
      presetName: json['presetName'] as String? ?? 'Pomodoro',
      targetText: json['targetText'] as String?,
      focusMinutes: json['focusMinutes'] as int,
      recommendedSessions: json['recommendedSessions'] as int? ?? 1,
      startedAt: DateTime.parse(json['startedAt'] as String),
      endedAt: json['endedAt'] != null
          ? DateTime.parse(json['endedAt'] as String)
          : null,
      targetStatus: targetStatus,
    );
  }
}

/// Snapshot sesi aktif untuk disimpan/dipulihkan (fase restore di masa depan).
class ActiveSessionSnapshot {
  final FocusSession session;
  final int remainingSeconds;

  const ActiveSessionSnapshot({
    required this.session,
    required this.remainingSeconds,
  });

  Map<String, dynamic> toJson() => {
        'session': session.toJson(),
        'remainingSeconds': remainingSeconds,
      };

  factory ActiveSessionSnapshot.fromJson(Map<String, dynamic> json) {
    return ActiveSessionSnapshot(
      session: FocusSession.fromJson(json['session'] as Map<String, dynamic>),
      remainingSeconds: json['remainingSeconds'] as int? ?? 0,
    );
  }
}
