// lib/services/focus_session_provider.dart

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/focus_session_model.dart';
import '../models/task_model.dart';
import 'focus_timer_service.dart';
import 'focus_session_repository.dart';
import 'task_provider.dart';

/// Orkestrasi sesi fokus: menghubungkan [FocusTimerService] dengan
/// [FocusSessionRepository] dan mengekspos state ke UI. Seluruh business logic
/// sesi fokus berada di sini — widget hanya memanggil method ini.
class FocusSessionProvider with ChangeNotifier {
  final FocusTimerService _timer = FocusTimerService();
  final FocusSessionRepository _repo = FocusSessionRepository();
  final _uuid = const Uuid();

  FocusSession? _active;
  Duration _remaining = Duration.zero;
  bool _finished = false;

  FocusSession? get active => _active;
  Duration get remaining => _remaining;
  bool get isRunning => _timer.isRunning;
  bool get isFinished => _finished;
  bool get hasActiveSession => _active != null;

  FocusSessionProvider() {
    _timer.onTick = (d) {
      _remaining = d;
      notifyListeners();
    };
    _timer.onFinished = () {
      _finished = true;
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
    final session = FocusSession(
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
    _active = session;
    _finished = false;
    final total = Duration(minutes: preset.focusMinutes);
    _remaining = total;
    _timer.start(total);
    _persist();
    notifyListeners();
  }

  void pauseResume() {
    if (_active == null) return;
    if (_timer.isRunning) {
      _timer.pause();
    } else {
      _timer.resume();
    }
    _remaining = _timer.remaining;
    _persist();
    notifyListeners();
  }

  /// Akhiri (batalkan) sesi tanpa disimpan sebagai selesai.
  Future<void> endSession() async {
    _timer.pause();
    _active = null;
    _finished = false;
    _remaining = Duration.zero;
    await _repo.clearActive();
    notifyListeners();
  }

  /// Tandai sesi selesai dengan status pencapaian target. Menambahkan menit
  /// fokus ke tugas terkait (pola existing [TaskProvider.addFocusMinutes]).
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
    _finished = false;
    _remaining = Duration.zero;
    await _repo.clearActive();
    notifyListeners();
  }

  void _persist() {
    final session = _active;
    if (session == null) return;
    _repo.saveActive(session, _remaining.inSeconds);
  }

  @override
  void dispose() {
    _timer.dispose();
    super.dispose();
  }
}
