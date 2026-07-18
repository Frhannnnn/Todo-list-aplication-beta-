// lib/screens/focus/focus_timer_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/focus_session_model.dart';
import '../../models/task_model.dart';
import '../../services/focus_session_provider.dart';
import '../../services/task_provider.dart';
import '../../utils/app_theme.dart';
import 'focus_complete_screen.dart';
import 'widgets/focus_info_row.dart';

/// Layar timer sesi fokus. Mode Fokus mengunci navigasi (PopScope); Mode
/// Fleksibel membiarkan pengguna keluar. Seluruh logika timer ada di
/// [FocusSessionProvider] — layar ini hanya menampilkan & memanggil.
class FocusTimerScreen extends StatefulWidget {
  final Task task;

  const FocusTimerScreen({super.key, required this.task});

  @override
  State<FocusTimerScreen> createState() => _FocusTimerScreenState();
}

class _FocusTimerScreenState extends State<FocusTimerScreen> {
  bool _navigatedToComplete = false;

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<bool> _confirmEnd() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Akhiri sesi fokus?'),
        content: const Text('Progres sesi fokus akan dihentikan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, Akhiri'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _handleEnd(FocusSessionProvider provider) async {
    final ok = await _confirmEnd();
    if (!ok || !mounted) return;
    await provider.endSession();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final totalActive = context.read<TaskProvider>().activeTasks.length;
    final priorityLabel =
        AppTheme.getPrioritasLabel(widget.task.ranking, totalActive);

    return Consumer<FocusSessionProvider>(
      builder: (context, provider, _) {
        final session = provider.active;
        if (session == null) {
          return const Scaffold(
            backgroundColor: AppTheme.background,
            body: SizedBox.shrink(),
          );
        }

        // Saat sesi selesai, pindah ke halaman selesai (sekali saja).
        if (provider.isFinished && !_navigatedToComplete) {
          _navigatedToComplete = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => FocusCompleteScreen(
                    task: widget.task, session: session),
              ),
            );
          });
        }

        final isFocusMode = session.mode == FocusMode.focus;
        final total = Duration(minutes: session.focusMinutes);
        final remaining = provider.remaining;
        final progress = total.inSeconds == 0
            ? 0.0
            : remaining.inSeconds / total.inSeconds;
        final estimasi = DateFormat('HH:mm')
            .format(DateTime.now().add(remaining));

        return PopScope(
          canPop: !isFocusMode,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop || !isFocusMode) return;
            await _handleEnd(provider);
          },
          child: Scaffold(
            backgroundColor: AppTheme.background,
            body: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minHeight: constraints.maxHeight),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _modeBadge(session),
                          const SizedBox(height: 20),
                          _buildRing(progress, remaining),
                          const SizedBox(height: 20),
                          _taskInfo(session, priorityLabel, estimasi),
                          const SizedBox(height: 28),
                          _controls(provider),
                          const SizedBox(height: 12),
                          _streakPlaceholder(),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _modeBadge(FocusSession session) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.center_focus_strong_rounded,
              size: 16, color: AppTheme.primary),
          const SizedBox(width: 6),
          Text('Mode ${session.mode.label} • ${session.presetName}',
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary)),
        ],
      ),
    );
  }

  Widget _buildRing(double progress, Duration remaining) {
    return SizedBox(
      width: 240,
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 240,
            height: 240,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 10,
              backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
              valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
              strokeCap: StrokeCap.round,
            ),
          ),
          Text(
            _fmt(remaining),
            style: const TextStyle(
                fontSize: 52,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _taskInfo(
      FocusSession session, String priorityLabel, String estimasi) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          FocusInfoRow(label: 'Tugas', value: widget.task.namaTugas),
          const SizedBox(height: 8),
          FocusInfoRow(label: 'Kategori', value: widget.task.categoryLabel),
          const SizedBox(height: 8),
          FocusInfoRow(label: 'Prioritas', value: priorityLabel),
          if (session.targetText != null) ...[
            const SizedBox(height: 8),
            FocusInfoRow(label: 'Target', value: session.targetText!),
          ],
          const SizedBox(height: 8),
          FocusInfoRow(
              label: 'Sesi',
              value: 'Sesi 1 dari ${session.recommendedSessions}'),
          const SizedBox(height: 8),
          FocusInfoRow(label: 'Estimasi selesai', value: estimasi),
        ],
      ),
    );
  }

  Widget _controls(FocusSessionProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _circleButton(
          icon: provider.isRunning
              ? Icons.pause_rounded
              : Icons.play_arrow_rounded,
          label: provider.isRunning ? 'Jeda' : 'Lanjut',
          background: AppTheme.primary,
          foreground: Colors.white,
          onTap: provider.pauseResume,
        ),
        const SizedBox(width: 20),
        _circleButton(
          icon: Icons.stop_rounded,
          label: 'Akhiri',
          background: Colors.white,
          foreground: AppTheme.danger,
          border: true,
          onTap: () => _handleEnd(provider),
        ),
      ],
    );
  }

  Widget _circleButton({
    required IconData icon,
    required String label,
    required Color background,
    required Color foreground,
    required VoidCallback onTap,
    bool border = false,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: background,
              border: border ? Border.all(color: AppTheme.border) : null,
            ),
            child: Icon(icon, color: foreground, size: 30),
          ),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary)),
      ],
    );
  }

  /// Placeholder Focus Streak (nilai nyata diisi pada Fase 4).
  Widget _streakPlaceholder() {
    return const Text('🔥 Fokus hari ini',
        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary));
  }
}
