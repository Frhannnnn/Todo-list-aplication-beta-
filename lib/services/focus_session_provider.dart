// lib/services/focus_session_provider.dart

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/focus_session_model.dart';
import '../models/task_model.dart';
import 'focus_timer_service.dart';
import 'focus_session_repository.dart';
import 'notification_service.dart';
import 'task_provider.dart';

/// Orkestrasi sesi fokus multi-siklus: mengendalikan [FocusTimerService],
/// menyimpan snapshot lewat [FocusSessionRepository], menampilkan foreground
/// notification, dan mengekspos state (via [FocusSessionState]) ke UI. Seluruh
/// business logic sesi fokus ada di sini — widget hanya memanggil method ini.
class FocusSessionProvider with ChangeNotifier {
  final FocusTimerService _timer = FocusTimerService();
  final FocusSessionRepository _repo = FocusSessionRepository();
  final NotificationService _notif = NotificationService();
  final _uuid = const Uuid();

  TaskProvider? _taskRef;

  FocusSession? _active;
  Duration _remaining = Duration.zero;
  FocusSessionState _state = FocusSessionState.idle;
  int _currentSession = 1;
  int _accumulatedFocusMinutes = 0;

  FocusSession? get active => _active;
  Duration get remaining => _remaining;
  FocusSessionState get state => _state;
  int get currentSession => _currentSession;
  bool get isRunning => _state == FocusSessionState.running;
  bool get isPaused => _state == FocusSessionState.paused;
  bool get isFinished => _state == FocusSessionState.completed;
  bool get isBreak => _state == FocusSessionState.breakTime;
  bool get hasActiveSession => _active != null;
  bool get hasNextSession =>
      _active != null && _currentSession < _active!.totalSessions;

  FocusSessionProvider() {
    _timer.onTick = (d) {
      _remaining = d;
      notifyListeners();
    };
    _timer.onFinished = _handleTimerFinished;
    _notif.onFocusAction = _onNotifAction;
  }

  /// Dipasang sekali dari root agar aksi notifikasi & akumulasi menit bisa
  /// mengakses TaskProvider tanpa BuildContext.
  void attachTaskProvider(TaskProvider tp) => _taskRef = tp;

  void _onNotifAction(String actionId) {
    if (actionId == 'focus_pause') {
      pauseResume();
    } else if (actionId == 'focus_end') {
      endSession(taskProvider: _taskRef);
    }
  }

  void _handleTimerFinished() {
    if (_state == FocusSessionState.running) {
      final s = _active;
      if (s != null) _accumulatedFocusMinutes += s.focusMinutes;
      if ((s?.autoAdvance ?? false) && hasNextSession) {
        if ((s?.breakMinutes ?? 0) > 0) {
          startBreak();
        } else {
          startNextSession();
        }
      } else {
        _state = FocusSessionState.completed;
        _remaining = Duration.zero;
        _persist();
        _cancelNotification();
        notifyListeners();
      }
    } else if (_state == FocusSessionState.breakTime) {
      startNextSession();
    }
  }

  void startSession({
    required Task task,
    required FocusMode mode,
    required FocusPreset preset,
    String? targetText,
    required int recommendedSessions,
    required int totalSessions,
    required bool autoAdvance,
  }) {
    // Minta izin notifikasi (Android 13+) agar foreground notification tampil.
    try {
      _notif.requestPermission();
    } catch (_) {}

    _active = FocusSession(
      id: _uuid.v4(),
      taskId: task.id,
      mode: mode,
      presetName: preset.name,
      targetText: (targetText != null && targetText.trim().isNotEmpty)
          ? targetText.trim()
          : null,
      focusMinutes: preset.focusMinutes,
      recommendedSessions: recommendedSessions,
      totalSessions: totalSessions < 1 ? 1 : totalSessions,
      breakMinutes: preset.breakMinutes,
      autoAdvance: autoAdvance,
      startedAt: DateTime.now(),
    );
    _currentSession = 1;
    _accumulatedFocusMinutes = 0;
    _startFocusTimer();
  }

  void _startFocusTimer() {
    final s = _active;
    if (s == null) return;
    _state = FocusSessionState.running;
    final total = Duration(minutes: s.focusMinutes);
    _remaining = total;
    _timer.start(total);
    _persist();
    _updateNotification();
    notifyListeners();
  }

  void pauseResume() {
    if (_active == null) return;
    if (_state == FocusSessionState.running) {
      _timer.pause();
      _state = FocusSessionState.paused;
    } else if (_state == FocusSessionState.paused) {
      _timer.resume();
      _state = FocusSessionState.running;
    } else {
      return;
    }
    _remaining = _timer.remaining;
    _persist();
    _updateNotification();
    notifyListeners();
  }

  /// Mulai istirahat antar-siklus.
  void startBreak() {
    final s = _active;
    if (s == null) return;
    _state = FocusSessionState.breakTime;
    final total = Duration(minutes: s.breakMinutes);
    _remaining = total;
    _timer.start(total);
    _persist();
    _updateNotification();
    notifyListeners();
  }

  /// Lewati istirahat dan langsung ke sesi fokus berikutnya.
  void skipBreak() => startNextSession();

  /// Mulai blok fokus berikutnya (menaikkan nomor sesi).
  void startNextSession() {
    final s = _active;
    if (s == null) return;
    if (_currentSession < s.totalSessions) {
      _currentSession++;
    }
    _startFocusTimer();
  }

  /// Sinkronkan setelah app kembali foreground: waktu dihitung dari timestamp,
  /// jadi tetap akurat walau Dart sempat dijeda OS. Picu penyelesaian bila
  /// blok/istirahat sudah habis saat app di background.
  void syncFromBackground() {
    if (_state != FocusSessionState.running &&
        _state != FocusSessionState.breakTime) {
      return;
    }
    _remaining = _timer.remaining;
    if (_timer.isFinished) {
      _handleTimerFinished();
    } else {
      _updateNotification();
      notifyListeners();
    }
  }

  /// Akhiri (batalkan) sesi. Menit fokus dari blok yang sudah selesai tetap
  /// dihitung ke tugas.
  Future<void> endSession({TaskProvider? taskProvider}) async {
    _addAccumulatedMinutes(taskProvider);
    _timer.pause();
    _cancelNotification();
    _reset();
    await _repo.clearActive();
    notifyListeners();
  }

  /// Tandai seluruh sesi selesai dengan status pencapaian target.
  /// [status] disimpan ke riwayat pada Fase 4.
  Future<void> completeSession(
    SessionTargetStatus status, {
    TaskProvider? taskProvider,
  }) async {
    _addAccumulatedMinutes(taskProvider);
    _timer.pause();
    _cancelNotification();
    _reset();
    await _repo.clearActive();
    notifyListeners();
  }

  void _addAccumulatedMinutes(TaskProvider? taskProvider) {
    final s = _active;
    if (s != null && _accumulatedFocusMinutes > 0) {
      (taskProvider ?? _taskRef)
          ?.addFocusMinutes(s.taskId, _accumulatedFocusMinutes);
    }
  }

  void _reset() {
    _active = null;
    _state = FocusSessionState.idle;
    _remaining = Duration.zero;
    _currentSession = 1;
    _accumulatedFocusMinutes = 0;
  }

  void _persist() {
    final session = _active;
    if (session == null) return;
    final isTiming = _state == FocusSessionState.running ||
        _state == FocusSessionState.breakTime;
    _repo.saveActive(
      ActiveSessionSnapshot(
        session: session,
        remainingSeconds: _remaining.inSeconds,
        currentSession: _currentSession,
        accumulatedFocusMinutes: _accumulatedFocusMinutes,
        state: _state,
        endAtEpochMs: isTiming ? _timer.endAt?.millisecondsSinceEpoch : null,
      ),
    );
  }

  void _updateNotification() {
    final s = _active;
    if (s == null) return;
    try {
      _notif.showFocusNotification(
        taskName: _taskNameFor(s.taskId),
        remaining: _remaining,
        running: _state == FocusSessionState.running ||
            _state == FocusSessionState.breakTime,
        isBreak: _state == FocusSessionState.breakTime,
      );
    } catch (_) {
      // Platform tanpa notifikasi (mis. web) — abaikan.
    }
  }

  void _cancelNotification() {
    try {
      _notif.cancelFocusNotification();
    } catch (_) {}
  }

  String _taskNameFor(String taskId) {
    final list = _taskRef?.tasks ?? const <Task>[];
    for (final t in list) {
      if (t.id == taskId) return t.namaTugas;
    }
    return 'Tugas';
  }

  @override
  void dispose() {
    _timer.dispose();
    super.dispose();
  }
}
