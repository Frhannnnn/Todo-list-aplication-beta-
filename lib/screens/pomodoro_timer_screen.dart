// lib/screens/pomodoro_timer_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task_model.dart';
import '../services/task_provider.dart';
import '../utils/app_theme.dart';

enum PomodoroPhase { focus, shortBreak, longBreak }

/// Timer Pomodoro untuk satu tugas (Issue #5). Alat bantu fokus murni —
/// TIDAK PERNAH mengubah status tugas secara otomatis; status tetap
/// dikendalikan manual oleh user lewat kartu tugas. Tiap sesi fokus yang
/// selesai penuh diakumulasikan ke Task.totalFocusMinutes lewat
/// TaskProvider.addFocusMinutes.
class PomodoroTimerScreen extends StatefulWidget {
  final Task task;
  const PomodoroTimerScreen({super.key, required this.task});

  @override
  State<PomodoroTimerScreen> createState() => _PomodoroTimerScreenState();
}

class _PomodoroTimerScreenState extends State<PomodoroTimerScreen> {
  static const int _focusMinutes = 25;
  static const int _shortBreakMinutes = 5;
  static const int _longBreakMinutes = 15;
  static const int _sessionsBeforeLongBreak = 4;

  PomodoroPhase _phase = PomodoroPhase.focus;
  int _remainingSeconds = _focusMinutes * 60;
  bool _isRunning = false;
  int _completedFocusSessions = 0;
  Timer? _timer;

  int _minutesForPhase(PomodoroPhase phase) {
    switch (phase) {
      case PomodoroPhase.focus:
        return _focusMinutes;
      case PomodoroPhase.shortBreak:
        return _shortBreakMinutes;
      case PomodoroPhase.longBreak:
        return _longBreakMinutes;
    }
  }

  String get _phaseLabel {
    switch (_phase) {
      case PomodoroPhase.focus:
        return 'Fokus';
      case PomodoroPhase.shortBreak:
        return 'Istirahat Pendek';
      case PomodoroPhase.longBreak:
        return 'Istirahat Panjang';
    }
  }

  Color get _phaseColor {
    switch (_phase) {
      case PomodoroPhase.focus:
        return AppTheme.primary;
      case PomodoroPhase.shortBreak:
        return AppTheme.success;
      case PomodoroPhase.longBreak:
        return AppTheme.accent;
    }
  }

  IconData get _phaseIcon {
    switch (_phase) {
      case PomodoroPhase.focus:
        return Icons.psychology_rounded;
      case PomodoroPhase.shortBreak:
        return Icons.coffee_rounded;
      case PomodoroPhase.longBreak:
        return Icons.self_improvement_rounded;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleRunning() {
    if (_isRunning) {
      _pause();
    } else {
      _start();
    }
  }

  void _start() {
    _timer?.cancel();
    setState(() => _isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _pause() {
    _timer?.cancel();
    if (mounted) setState(() => _isRunning = false);
  }

  void _tick() {
    if (!mounted) return;
    if (_remainingSeconds > 1) {
      setState(() => _remainingSeconds--);
      return;
    }
    _completePhase();
  }

  void _completePhase() {
    _timer?.cancel();

    if (_phase == PomodoroPhase.focus) {
      _completedFocusSessions++;
      context.read<TaskProvider>().addFocusMinutes(widget.task.id, _focusMinutes);
    }

    final nextPhase = _phase == PomodoroPhase.focus
        ? (_completedFocusSessions % _sessionsBeforeLongBreak == 0
            ? PomodoroPhase.longBreak
            : PomodoroPhase.shortBreak)
        : PomodoroPhase.focus;

    setState(() {
      _phase = nextPhase;
      _remainingSeconds = _minutesForPhase(nextPhase) * 60;
    });

    // Lanjut otomatis ke fase berikutnya (pola Pomodoro standar) — user
    // tetap bisa menjeda kapan saja.
    _start();
  }

  Future<void> _reset() async {
    if (_isRunning) {
      final confirmed = await _confirmDiscard('Reset timer ke awal?');
      if (!confirmed) return;
    }
    _timer?.cancel();
    setState(() {
      _phase = PomodoroPhase.focus;
      _remainingSeconds = _focusMinutes * 60;
      _isRunning = false;
      _completedFocusSessions = 0;
    });
  }

  Future<bool> _confirmDiscard(String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Timer Sedang Berjalan'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  String get _formattedTime {
    final minutes = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isRunning,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || !_isRunning) return;
        final confirmed =
            await _confirmDiscard('Timer masih berjalan. Keluar sekarang?');
        if (confirmed && context.mounted) Navigator.pop(context);
      },
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: Text(
            widget.task.namaTugas,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          backgroundColor: Colors.transparent,
          foregroundColor: AppTheme.textPrimary,
          elevation: 0,
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildPhaseBadge(),
                        const SizedBox(height: 32),
                        _buildCountdown(),
                        const SizedBox(height: 24),
                        _buildSessionDots(),
                        const SizedBox(height: 48),
                        _buildControls(),
                        const SizedBox(height: 16),
                        Text(
                          'Sesi fokus selesai: $_completedFocusSessions',
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPhaseBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: _phaseColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _phaseColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_phaseIcon, color: _phaseColor, size: 18),
          const SizedBox(width: 8),
          Text(
            _phaseLabel,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _phaseColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdown() {
    return SizedBox(
      width: 260,
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 260,
            height: 260,
            child: CircularProgressIndicator(
              value: _remainingSeconds / (_minutesForPhase(_phase) * 60),
              strokeWidth: 10,
              backgroundColor: _phaseColor.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation(_phaseColor),
              strokeCap: StrokeCap.round,
            ),
          ),
          Text(
            _formattedTime,
            style: const TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_sessionsBeforeLongBreak, (i) {
        final sessionIndexInCycle =
            _completedFocusSessions % _sessionsBeforeLongBreak;
        final filled = i < sessionIndexInCycle ||
            (sessionIndexInCycle == 0 &&
                _completedFocusSessions > 0 &&
                _completedFocusSessions % _sessionsBeforeLongBreak == 0);
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled
                ? AppTheme.primary
                : AppTheme.primary.withValues(alpha: 0.15),
          ),
        );
      }),
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _circleButton(
          icon: Icons.refresh_rounded,
          onTap: _reset,
          color: AppTheme.textSecondary,
          size: 52,
        ),
        const SizedBox(width: 24),
        _circleButton(
          icon: _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
          onTap: _toggleRunning,
          color: Colors.white,
          background: _phaseColor,
          size: 72,
        ),
      ],
    );
  }

  Widget _circleButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
    Color? background,
    required double size,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: background ?? Colors.white,
          border: background == null
              ? Border.all(color: AppTheme.border)
              : null,
          boxShadow: background != null
              ? [
                  BoxShadow(
                    color: background.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Icon(icon, color: color, size: size * 0.45),
      ),
    );
  }
}
