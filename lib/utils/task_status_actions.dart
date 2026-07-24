// lib/utils/task_status_actions.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/task_model.dart';
import '../models/focus_session_model.dart';
import '../services/task_provider.dart';
import '../screens/focus/focus_mode_sheet.dart';
import '../screens/focus/focus_intent_dialog.dart';
import '../screens/focus/focus_preparation_screen.dart';
import 'app_theme.dart';
import 'celebration.dart';
import 'focus_recommendation.dart';

/// Terapkan perubahan status tugas dari kartu tugas (tombol "Mulai" /
/// "Selesaikan" / "Buka Lagi"). Saat tugas ditandai "Sedang Dikerjakan",
/// jalankan alur Focus Session: pilih mode & preset → tentukan target →
/// halaman persiapan → timer. Transisi status lain diterapkan langsung.
void handleStatusChange(
  BuildContext context,
  TaskProvider provider,
  Task task,
  TaskStatus newStatus,
) {
  provider.updateStatus(task.id, newStatus);

  if (newStatus == TaskStatus.sedangDikerjakan) {
    _startFocusFlow(context, provider, task);
  } else if (newStatus == TaskStatus.selesai) {
    // Rayakan penyelesaian: getar + animasi centang singkat.
    celebrateTaskCompletion(context);
  }
}

Future<void> _startFocusFlow(
  BuildContext context,
  TaskProvider provider,
  Task task,
) async {
  final selection = await showFocusModeSheet(context);
  if (selection == null || !context.mounted) return;

  final target = await showFocusIntentDialog(context);
  if (target == null || !context.mounted) return; // dibatalkan

  // Getar saat sesi fokus benar-benar dimulai.
  HapticFeedback.mediumImpact();

  final totalActive = provider.activeTasks.length;
  final priorityLabel = AppTheme.getPrioritasLabel(task.ranking, totalActive);
  final recommendedSessions = focusRecommendation(priorityLabel).sessions;
  final totalSessions = selection.mode == FocusMode.custom
      ? selection.cycles
      : recommendedSessions;

  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => FocusPreparationScreen(
        task: task,
        mode: selection.mode,
        preset: selection.preset,
        targetText: target.trim().isEmpty ? null : target.trim(),
        recommendedSessions: recommendedSessions,
        totalSessions: totalSessions,
        autoAdvance: selection.autoAdvance,
        options: selection.options,
      ),
    ),
  );
}
