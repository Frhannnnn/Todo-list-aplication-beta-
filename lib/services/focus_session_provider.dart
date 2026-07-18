// lib/services/focus_session_provider.dart

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/focus_session_model.dart';
import '../models/task_model.dart';
import 'focus_timer_service.dart';
import 'focus_session_repository.dart';
import 'task_provider.dart';

/// Orkestrasi sesi fokus: mengendalikan [FocusTimerService], menyimpan snapshot
/// lewat [FocusSessionRepository], dan mengekspos state (via
/// [FocusSessionState]) ke UI. Seluruh business logic sesi fokus ada di sini —
/// widget hanya memanggil method ini.
class FocusSessionProvider with ChangeNotifier {
  final FocusTimerService _timer = FocusTimerService();
  final FocusSessionRepository _repo = FocusSessionRepository();
  final _uuid = const Uuid();

  FocusSession? _active;
  Duration _remaining = Duration.zero;
  FocusSessionState _state = FocusSessionState.idle;

  FocusSession? get active => _active;
  Duration get remaining => _remaining;
  FocusSessionState get state => _state;
  bool get isRunning => _state == FocusSessionState.running;
  bool get isPaused => _state == FocusSessionState.paused;
  bool get isFinished => _state == FocusSessionState.completed;
  bool get hasActiveSession => _active != null;

  FocusSessionProvider() {
    _timer.onTick = (d) {
      _remaining = d;
      notifyListeners();
    };
    _timer.onFinished = () {
      _state = FocusSessionState.completed;
      _remaining = Duration.zero;
      notifyListeners();
    };
  }

  void startSession({
    required Task task,
    required FocusMode mode,
    required FocusPreset preset,
    String? targetText,
    required int recommendedSessions,
  }) {
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
      startedAt: DateTime.now(),
    );
    _state = FocusSessionState.running;
    final total = Duration(minutes: preset.focusMinutes);
    _remaining = total;
    _timer.start(total);
    _persist();
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
    }
    _remaining = _timer.remaining;
    _persist();
    notifyListeners();
  }

  /// Akhiri (batalkan) sesi tanpa disimpan sebagai selesai.
  Future<void> endSession() async {
    _timer.pause();
    _active = null;
    _state = FocusSessionState.idle;
    _remaining = Duration.zero;
    await _repo.clearActive();
    notifyListeners();
  }

  /// Tandai sesi selesai dengan status pencapaian target. Menambahkan menit
  /// fokus ke tugas terkait (pola existing [TaskProvider.addFocusMinutes]).
  /// [status] disimpan ke riwayat pada Fase 4.
  Future<void> completeSession(
    SessionTargetStatus status, {
    TaskProvider? taskProvider,
  }) async {
    final session = _active;
    if (session != null) {
      taskProvider?.addFocusMinutes(session.taskId, session.focusMinutes);
    }
    _timer.pause();
    _active = null;
    _state = FocusSessionState.idle;
    _remaining = Duration.zero;
    await _repo.clearActive();
    notifyListeners();
  }

  void _persist() {
    final session = _active;
    if (session == null) return;
    _repo.saveActive(
      ActiveSessionSnapshot(
        session: session,
        remainingSeconds: _remaining.inSeconds,
      ),
    );
  }

  @override
  void dispose() {
    _timer.dispose();
    super.dispose();
  }
}
