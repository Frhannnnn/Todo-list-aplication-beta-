// lib/screens/focus/focus_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../models/task_model.dart';
import '../../services/focus_session_provider.dart';
import '../../services/task_provider.dart';

/// Layar Fokus (OLED-friendly): latar hitam penuh, UI minimalis, wakelock aktif
/// agar layar tetap menyala. Menggantikan Always-On-Display (tak ada API publik).
class FocusScreen extends StatefulWidget {
  final Task task;

  const FocusScreen({super.key, required this.task});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  FocusSessionProvider? _provider;

  @override
  void initState() {
    super.initState();
    _provider = context.read<FocusSessionProvider>();
    try {
      WakelockPlus.enable();
    } catch (_) {}
  }

  @override
  void dispose() {
    // Kembalikan wakelock ke keadaan sesi (keepScreenOn).
    _provider?.refreshWakelock();
    super.dispose();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _handleEnd(FocusSessionProvider provider) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Akhiri sesi fokus?'),
        content: const Text('Progres sesi fokus akan dihentikan.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Ya, Akhiri')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await provider.endSession(taskProvider: context.read<TaskProvider>());
    if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FocusSessionProvider>(
      builder: (context, provider, _) {
        final session = provider.active;
        // Kembali ke timer bila blok fokus tak lagi berjalan (selesai/istirahat).
        if (session == null || (!provider.isRunning && !provider.isPaused)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) Navigator.of(context).maybePop();
          });
          return const Scaffold(backgroundColor: Colors.black);
        }

        return PopScope(
          canPop: true,
          child: Scaffold(
            backgroundColor: Colors.black,
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_fmt(provider.remaining),
                        style: const TextStyle(
                            fontSize: 72,
                            fontWeight: FontWeight.w300,
                            color: Colors.white,
                            letterSpacing: 2)),
                    const SizedBox(height: 16),
                    Text(widget.task.namaTugas,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 16, color: Colors.white70)),
                    if (session.targetText != null) ...[
                      const SizedBox(height: 4),
                      Text(session.targetText!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 13, color: Colors.white38)),
                    ],
                    const SizedBox(height: 4),
                    Text(
                        'Sesi ${provider.currentSession} dari ${session.totalSessions}',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.white38)),
                    const SizedBox(height: 48),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _btn(
                          icon: provider.isRunning
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          onTap: provider.pauseResume,
                        ),
                        const SizedBox(width: 32),
                        _btn(
                          icon: Icons.stop_rounded,
                          onTap: () => _handleEnd(provider),
                        ),
                      ],
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

  Widget _btn({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24),
        ),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }
}
