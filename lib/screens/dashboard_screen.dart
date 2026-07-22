// lib/screens/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task_model.dart';
import '../services/task_provider.dart';
import '../utils/app_theme.dart';
import '../utils/recurrence.dart';
import '../widgets/task_card_widget.dart';
import '../main.dart';
import 'add_edit_task_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: AppTheme.background,
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeader(context)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                            const SizedBox(height: 16),
                        _buildSummaryCard(provider),
                        const SizedBox(height: 12),
                        _buildHariIniRow(provider),
                        const SizedBox(height: 16),
                        _buildTaskCalendar(provider),
                        const SizedBox(height: 24),
                        _buildSectionHeader(
                          'Prioritas Teratas',
                          onSeeAll: () => MainNavigation.tabIndex.value =
                              MainNavigation.taskListTab,
                        ),
                        const SizedBox(height: 10),
                        _buildTopPriorityTasks(provider),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(width: 40, height: 40),
          const Text(
            'Tugas',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddEditTaskScreen()),
            ),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.border),
              ),
              child: const Icon(Icons.add, color: AppTheme.textPrimary, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(TaskProvider provider) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));
    final weekTasks = provider.activeTasks.where((t) =>
        t.deadline.isAfter(weekStart) &&
        t.deadline.isBefore(weekEnd.add(const Duration(days: 1)))).length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.assignment_rounded, color: AppTheme.primary, size: 26),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tugas Kuliah',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Ringkasan Minggu Ini',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$weekTasks tugas',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Minggu Ini',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHariIniRow(TaskProvider provider) {
    final total = provider.totalTugas;
    final selesai = provider.tugasSelesai;
    final streak = provider.currentStreak;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline_rounded,
              color: AppTheme.primary, size: 18),
          const SizedBox(width: 6),
          Text(
            '$selesai/$total selesai',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(width: 16),
          Container(width: 1, height: 16, color: AppTheme.border),
          const SizedBox(width: 16),
          const Icon(Icons.local_fire_department_rounded,
              color: AppTheme.warning, size: 18),
          const SizedBox(width: 6),
          Text(
            '$streak hari',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCalendar(TaskProvider provider) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Minggu berjalan: Senin s/d Minggu yang memuat hari ini.
    final weekStart =
        today.subtract(Duration(days: today.weekday - DateTime.monday));
    final weekDays = List.generate(7, (i) => weekStart.add(Duration(days: i)));
    final weekEnd = DateTime(
        weekStart.year, weekStart.month, weekStart.day + 6, 23, 59);

    bool sameDay(DateTime a, DateTime b) =>
        a.year == b.year && a.month == b.month && a.day == b.day;

    // Tanggal dalam minggu ini yang punya occurrence tugas berulang.
    final previewDays = <DateTime>{};
    for (final t in provider.tasks) {
      if (t.recurrence == RecurrenceType.none ||
          t.status == TaskStatus.selesai) {
        continue;
      }
      for (final d in upcomingOccurrences(t, until: weekEnd)) {
        if (!d.isBefore(weekStart)) {
          previewDays.add(DateTime(d.year, d.month, d.day));
        }
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kalender Tugas',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: weekDays.map((date) {
              final isToday = sameDay(date, today);
              final dayTasks = provider.tasks
                  .where((t) => sameDay(t.deadline, date))
                  .toList();
              final hasTask = dayTasks.isNotEmpty;
              final hasOverdue = dayTasks.any((t) => t.isOverdue);
              final hasPreview = previewDays.contains(date);
              const weekdayLabels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    children: [
                      Text(
                        weekdayLabels[date.weekday - 1],
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: isToday
                              ? AppTheme.primary
                              : hasTask
                                  ? AppTheme.primary.withValues(alpha: 0.08)
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${date.day}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isToday || hasTask
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isToday
                                    ? Colors.white
                                    : AppTheme.textPrimary,
                              ),
                            ),
                            if (hasTask) ...[
                              const SizedBox(height: 3),
                              Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isToday
                                      ? Colors.white
                                      : hasOverdue
                                          ? AppTheme.danger
                                          : AppTheme.primary,
                                ),
                              ),
                            ] else if (!isToday && hasPreview) ...[
                              const SizedBox(height: 3),
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: AppTheme.primary, width: 1.2),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Judul section dengan aksi "Lihat Semua" opsional di kanan.
  Widget _buildSectionHeader(String title, {VoidCallback? onSeeAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        if (onSeeAll != null)
          InkWell(
            onTap: onSeeAll,
            borderRadius: BorderRadius.circular(20),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Lihat Semua',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                  ),
                  SizedBox(width: 2),
                  Icon(Icons.chevron_right, size: 16, color: AppTheme.primary),
                ],
              ),
            ),
          ),
      ],
    );
  }

  /// Tiga tugas paling prioritas (peringkat SAW terkecil). Ini inti nilai
  /// aplikasi: pengguna langsung tahu apa yang harus dikerjakan lebih dulu.
  Widget _buildTopPriorityTasks(TaskProvider provider) {
    final tasks = List.of(provider.activeTasks)
      ..sort((a, b) {
        if (a.ranking == 0 && b.ranking == 0) {
          return a.deadline.compareTo(b.deadline);
        }
        if (a.ranking == 0) return 1;
        if (b.ranking == 0) return -1;
        return a.ranking.compareTo(b.ranking);
      });

    if (tasks.isEmpty) {
      return _buildEmptyState('Belum ada tugas aktif 🎉');
    }

    return Builder(
      builder: (context) => Column(
        children: tasks
            .take(3)
            .map((t) => TaskCardWidget(
                  task: t,
                  showRanking: false,
                  totalActiveTasks: provider.activeTasks.length,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => AddEditTaskScreen(task: t)),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          const Text('📭', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 8),
          Text(message,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
        ],
      ),
    );
  }
}
