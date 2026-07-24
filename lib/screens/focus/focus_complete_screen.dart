// lib/screens/focus/focus_complete_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/focus_session_model.dart';
import '../../models/task_model.dart';
import '../../services/focus_session_provider.dart';
import '../../services/task_provider.dart';
import '../../utils/app_theme.dart';
import 'focus_break_screen.dart';
import 'focus_timer_screen.dart';

/// Halaman setelah sebuah blok fokus selesai: ringkasan, pertanyaan pencapaian
/// target, dan aksi lanjutan (istirahat / sesi berikutnya / selesai).
class FocusCompleteScreen extends StatefulWidget {
  final Task task;
  final FocusSession session;

  const FocusCompleteScreen({
    super.key,
    required this.task,
    required this.session,
  });

  @override
  State<FocusCompleteScreen> createState() => _FocusCompleteScreenState();
}

class _FocusCompleteScreenState extends State<FocusCompleteScreen> {
  SessionTargetStatus? _status;

  void _startBreak() {
    context.read<FocusSessionProvider>().startBreak();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => FocusBreakScreen(task: widget.task)),
    );
  }

  void _startNext() {
    context.read<FocusSessionProvider>().startNextSession();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => FocusTimerScreen(task: widget.task)),
    );
  }

  Future<void> _finish() async {
    final status = _status ?? SessionTargetStatus.notAchieved;
    await context.read<FocusSessionProvider>().completeSession(
          status,
          taskProvider: context.read<TaskProvider>(),
        );
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final hasNext = context.read<FocusSessionProvider>().hasNextSession;
    final hasBreak = session.breakMinutes > 0;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Center(
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: AppTheme.success.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_rounded,
                      color: AppTheme.success, size: 52),
                ),
              ),
              const SizedBox(height: 20),
              Text(hasNext ? 'Sesi Fokus Selesai' : 'Semua Sesi Selesai',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary)),
              const SizedBox(height: 8),
              Text(
                'Fokus ${session.focusMinutes} menit • ${widget.task.namaTugas}',
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 14, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 24),
              const Text('Apakah target sesi tercapai?',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary)),
              const SizedBox(height: 12),
              Row(
                children: SessionTargetStatus.values
                    .map((s) => Expanded(child: _statusChip(s)))
                    .toList(),
              ),
              const Spacer(),
              if (hasNext && hasBreak) ...[
                ElevatedButton(
                  onPressed: _startBreak,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Text('Mulai Istirahat',
                        style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              if (hasNext) ...[
                OutlinedButton(
                  onPressed: _startNext,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.border),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Mulai Sesi Berikutnya',
                      style: TextStyle(color: AppTheme.textPrimary)),
                ),
                const SizedBox(height: 10),
              ],
              TextButton(
                onPressed: _finish,
                child: const Text('Selesai',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusChip(SessionTargetStatus status) {
    final selected = _status == status;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: () => setState(() => _status = status),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? AppTheme.primary.withValues(alpha: 0.1)
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: selected ? AppTheme.primary : AppTheme.border,
                width: selected ? 1.5 : 1),
          ),
          child: Text(status.label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? AppTheme.primary : AppTheme.textSecondary)),
        ),
      ),
    );
  }
}
