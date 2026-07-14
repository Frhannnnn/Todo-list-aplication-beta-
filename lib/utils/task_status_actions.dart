// lib/utils/task_status_actions.dart

import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../services/task_provider.dart';
import '../screens/pomodoro_timer_screen.dart';

/// Terapkan perubahan status tugas dari kartu tugas (tombol "Mulai" /
/// "Selesaikan" / "Buka Lagi"). Dipakai bersama oleh task_list_screen.dart
/// dan calendar_screen.dart supaya perilaku "Mulai" konsisten di kedua
/// tempat (Issue #5): begitu tugas ditandai "Sedang Dikerjakan", buka Timer
/// Pomodoro untuk tugas itu. Transisi status lain tetap langsung diterapkan
/// tanpa navigasi tambahan.
void handleStatusChange(
  BuildContext context,
  TaskProvider provider,
  Task task,
  TaskStatus newStatus,
) {
  provider.updateStatus(task.id, newStatus);

  if (newStatus == TaskStatus.sedangDikerjakan) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PomodoroTimerScreen(task: task)),
    );
  }
}
