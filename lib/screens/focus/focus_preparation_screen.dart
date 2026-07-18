// lib/screens/focus/focus_preparation_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/focus_session_model.dart';
import '../../models/task_model.dart';
import '../../services/focus_session_provider.dart';
import '../../services/task_provider.dart';
import '../../utils/app_theme.dart';
import 'focus_timer_screen.dart';

/// Halaman persiapan sebelum timer dimulai: menampilkan ringkasan sesi dan
/// countdown 5 detik (bisa dilewati). Setelah countdown, sesi otomatis dimulai.
class FocusPreparationScreen extends StatefulWidget {
  final Task task;
  final FocusMode mode;
  final FocusPreset preset;
  final String? targetText;
  final int recommendedSessions;

  const FocusPreparationScreen({
    super.key,
    required this.task,
    required this.mode,
    required this.preset,
    required this.targetText,
    required this.recommendedSessions,
  });

  @override
  State<FocusPreparationScreen> createState() => _FocusPreparationScreenState();
}

class _FocusPreparationScreenState extends State<FocusPreparationScreen> {
  int _count = 5;
  bool _started = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _count--);
      if (_count <= 0) _begin();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _begin() {
    if (_started) return;
    _started = true;
    _timer?.cancel();
    context.read<FocusSessionProvider>().startSession(
          task: widget.task,
          mode: widget.mode,
          preset: widget.preset,
          targetText: widget.targetText,
          recommendedSessions: widget.recommendedSessions,
        );
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => FocusTimerScreen(task: widget.task),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalActive = context.read<TaskProvider>().activeTasks.length;
    final priorityLabel =
        AppTheme.getPrioritasLabel(widget.task.ranking, totalActive);
    final estimasi = DateFormat('HH:mm').format(
        DateTime.now().add(Duration(minutes: widget.preset.focusMinutes)));

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              const Text('Siapkan Fokus',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary)),
              const SizedBox(height: 20),
              _infoCard(priorityLabel, estimasi),
              const Spacer(),
              Text('$_count',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 72,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primary)),
              const SizedBox(height: 4),
              const Text('Sesi dimulai otomatis…',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 13, color: AppTheme.textSecondary)),
              const Spacer(),
              ElevatedButton(
                onPressed: _begin,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child:
                      Text('Mulai Sekarang', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoCard(String priorityLabel, String estimasi) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          _row('Tugas', widget.task.namaTugas),
          const SizedBox(height: 10),
          _row('Kategori', widget.task.categoryLabel),
          const SizedBox(height: 10),
          _row('Prioritas', priorityLabel),
          const SizedBox(height: 10),
          _row('Durasi sesi', '${widget.preset.focusMinutes} menit'),
          const SizedBox(height: 10),
          _row('Rekomendasi sesi', '${widget.recommendedSessions} sesi'),
          const SizedBox(height: 10),
          _row('Estimasi selesai', estimasi),
          if (widget.targetText != null) ...[
            const SizedBox(height: 10),
            _row('Target', widget.targetText!),
          ],
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(label,
              style: const TextStyle(
                  fontSize: 13, color: AppTheme.textSecondary)),
        ),
        Expanded(
          child: Text(value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary)),
        ),
      ],
    );
  }
}
