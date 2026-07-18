// lib/screens/focus/focus_break_screen.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/task_model.dart';
import '../../services/focus_session_provider.dart';
import '../../utils/app_theme.dart';
import 'focus_timer_screen.dart';

/// Layar istirahat antar-siklus. Timer istirahat dikelola oleh
/// [FocusSessionProvider]; layar ini hanya menampilkan & memanggil.
class FocusBreakScreen extends StatefulWidget {
  final Task task;

  const FocusBreakScreen({super.key, required this.task});

  @override
  State<FocusBreakScreen> createState() => _FocusBreakScreenState();
}

class _FocusBreakScreenState extends State<FocusBreakScreen> {
  static const _tips = [
    'Minum air putih',
    'Berdiri sebentar',
    'Istirahatkan mata',
    'Peregangan ringan',
  ];
  late final String _tip = _tips[Random().nextInt(_tips.length)];
  bool _navigated = false;

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FocusSessionProvider>(
      builder: (context, provider, _) {
        final session = provider.active;
        if (session == null) {
          return const Scaffold(
            backgroundColor: AppTheme.background,
            body: SizedBox.shrink(),
          );
        }

        // Saat istirahat selesai, provider berpindah ke sesi fokus berikutnya.
        if (provider.isRunning && !_navigated) {
          _navigated = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => FocusTimerScreen(task: widget.task),
              ),
            );
          });
        }

        final total = Duration(minutes: session.breakMinutes);
        final remaining = provider.remaining;
        final progress =
            total.inSeconds == 0 ? 0.0 : remaining.inSeconds / total.inSeconds;
        final nextSession = provider.currentSession + 1;

        return PopScope(
          canPop: false,
          child: Scaffold(
            backgroundColor: AppTheme.background,
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Waktunya Istirahat',
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary)),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: 200,
                      height: 200,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 200,
                            height: 200,
                            child: CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 10,
                              backgroundColor:
                                  AppTheme.success.withValues(alpha: 0.12),
                              valueColor: const AlwaysStoppedAnimation(
                                  AppTheme.success),
                              strokeCap: StrokeCap.round,
                            ),
                          ),
                          Text(_fmt(remaining),
                              style: const TextStyle(
                                  fontSize: 44,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textPrimary)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.success.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: AppTheme.success.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.tips_and_updates_rounded,
                              color: AppTheme.success, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(_tip,
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                        'Berikutnya: Sesi $nextSession dari ${session.totalSessions}',
                        style: const TextStyle(
                            fontSize: 13, color: AppTheme.textSecondary)),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: provider.skipBreak,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.border),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Lewati Istirahat',
                            style: TextStyle(color: AppTheme.textPrimary)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
