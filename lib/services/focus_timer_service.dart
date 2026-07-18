// lib/services/focus_timer_service.dart

import 'dart:async';

/// Mesin timer sesi fokus berbasis timestamp (bukan decrement manual) agar
/// tetap akurat dan siap dipulihkan. Murni logika waktu — tanpa Flutter UI
/// dan tanpa penyimpanan (itu tanggung jawab repository/provider).
class FocusTimerService {
  Timer? _ticker;
  DateTime? _endAt; // kapan sesi seharusnya selesai
  Duration _pausedRemaining = Duration.zero;
  bool _isRunning = false;

  void Function(Duration remaining)? onTick;
  void Function()? onFinished;

  bool get isRunning => _isRunning;

  Duration get remaining {
    if (_isRunning && _endAt != null) {
      final left = _endAt!.difference(DateTime.now());
      return left.isNegative ? Duration.zero : left;
    }
    return _pausedRemaining;
  }

  bool get isFinished => remaining <= Duration.zero;

  /// Mulai timer baru dengan durasi [total].
  void start(Duration total) {
    _pausedRemaining = total;
    _endAt = DateTime.now().add(total);
    _isRunning = true;
    _startTicker();
  }

  /// Lanjutkan dengan sisa waktu [remaining] (dipakai saat resume/restore).
  void resumeWith(Duration remaining) {
    _pausedRemaining = remaining;
    _endAt = DateTime.now().add(remaining);
    _isRunning = true;
    _startTicker();
  }

  void pause() {
    if (!_isRunning) return;
    _pausedRemaining = remaining;
    _isRunning = false;
    _ticker?.cancel();
  }

  void resume() {
    if (_isRunning) return;
    resumeWith(_pausedRemaining);
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final left = remaining;
      onTick?.call(left);
      if (left <= Duration.zero) {
        _ticker?.cancel();
        _isRunning = false;
        onFinished?.call();
      }
    });
  }

  void dispose() {
    _ticker?.cancel();
    _ticker = null;
  }
}
