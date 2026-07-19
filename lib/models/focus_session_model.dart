// lib/models/focus_session_model.dart

/// Mode sesi fokus.
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

/// Status siklus hidup sebuah sesi fokus. `preparing` disiapkan untuk fase
/// berikutnya (belum dipakai). `breakTime` dipakai mulai Fase 2.
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

/// Pilihan durasi fokus (menit) untuk Mode Kustom.
const List<int> kCustomFocusOptions = [15, 25, 30, 45, 50, 60, 90, 120];

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

/// Opsi native sesi fokus (Fase 3). Untuk mode preset non-Kustom dipakai
/// default; untuk Mode Kustom diisi dari toggle.
class FocusOptions {
  final bool keepScreenOn; // wakelock selama sesi
  final bool vibrate; // getaran saat sesi selesai
  final bool alarmOnFinish; // suara saat sesi selesai
  final bool lockNavigation; // paksa kunci navigasi (PopScope)
  final bool strictMode; // keluar app saat sesi → dialog

  const FocusOptions({
    this.keepScreenOn = false,
    this.vibrate = false,
    this.alarmOnFinish = false,
    this.lockNavigation = false,
    this.strictMode = false,
  });
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
  final int totalSessions; // jumlah siklus fokus yang dijalankan
  final int breakMinutes; // durasi istirahat antar-siklus
  final bool autoAdvance; // lanjut sesi berikutnya otomatis
  final bool keepScreenOn;
  final bool vibrate;
  final bool alarmOnFinish;
  final bool lockNavigation;
  final bool strictMode;
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
    this.totalSessions = 1,
    this.breakMinutes = 0,
    this.autoAdvance = false,
    this.keepScreenOn = false,
    this.vibrate = false,
    this.alarmOnFinish = false,
    this.lockNavigation = false,
    this.strictMode = false,
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
      totalSessions: totalSessions,
      breakMinutes: breakMinutes,
      autoAdvance: autoAdvance,
      keepScreenOn: keepScreenOn,
      vibrate: vibrate,
      alarmOnFinish: alarmOnFinish,
      lockNavigation: lockNavigation,
      strictMode: strictMode,
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
        'totalSessions': totalSessions,
        'breakMinutes': breakMinutes,
        'autoAdvance': autoAdvance,
        'keepScreenOn': keepScreenOn,
        'vibrate': vibrate,
        'alarmOnFinish': alarmOnFinish,
        'lockNavigation': lockNavigation,
        'strictMode': strictMode,
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
      totalSessions: json['totalSessions'] as int? ?? 1,
      breakMinutes: json['breakMinutes'] as int? ?? 0,
      autoAdvance: json['autoAdvance'] as bool? ?? false,
      keepScreenOn: json['keepScreenOn'] as bool? ?? false,
      vibrate: json['vibrate'] as bool? ?? false,
      alarmOnFinish: json['alarmOnFinish'] as bool? ?? false,
      lockNavigation: json['lockNavigation'] as bool? ?? false,
      strictMode: json['strictMode'] as bool? ?? false,
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
  final int currentSession;
  final int accumulatedFocusMinutes;
  final FocusSessionState state;
  final int? endAtEpochMs; // waktu selesai absolut saat running/breakTime

  const ActiveSessionSnapshot({
    required this.session,
    required this.remainingSeconds,
    this.currentSession = 1,
    this.accumulatedFocusMinutes = 0,
    this.state = FocusSessionState.idle,
    this.endAtEpochMs,
  });

  Map<String, dynamic> toJson() => {
        'session': session.toJson(),
        'remainingSeconds': remainingSeconds,
        'currentSession': currentSession,
        'accumulatedFocusMinutes': accumulatedFocusMinutes,
        'state': state.index,
        'endAtEpochMs': endAtEpochMs,
      };

  factory ActiveSessionSnapshot.fromJson(Map<String, dynamic> json) {
    final rawState = json['state'];
    final state = (rawState is int &&
            rawState >= 0 &&
            rawState < FocusSessionState.values.length)
        ? FocusSessionState.values[rawState]
        : FocusSessionState.idle;
    return ActiveSessionSnapshot(
      session: FocusSession.fromJson(json['session'] as Map<String, dynamic>),
      remainingSeconds: json['remainingSeconds'] as int? ?? 0,
      currentSession: json['currentSession'] as int? ?? 1,
      accumulatedFocusMinutes: json['accumulatedFocusMinutes'] as int? ?? 0,
      state: state,
      endAtEpochMs: json['endAtEpochMs'] as int?,
    );
  }
}
