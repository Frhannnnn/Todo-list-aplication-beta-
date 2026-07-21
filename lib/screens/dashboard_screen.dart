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
                        const SizedBox(height: 20),
                        _buildSummaryCard(provider),
                        const SizedBox(height: 24),
                        _buildProgressAndCalendar(provider),
                        const SizedBox(height: 28),
                        _buildSectionTitle('Tugas Mendatang'),
                        const SizedBox(height: 12),
                        _buildUpcomingTasks(provider),
                        const SizedBox(height: 28),
                        _buildSectionTitle('Lingkup Tugas Aktif'),
                        const SizedBox(height: 12),
                        _buildCourseCards(provider),
                        _buildMataKuliahSection(provider),
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

  Widget _buildProgressAndCalendar(TaskProvider provider) {
    final total = provider.totalTugas;
    final selesai = provider.tugasSelesai;
    final pct = total > 0 ? (selesai / total * 100).round() : 0;

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        // Circular progress
        Expanded(
          flex: 4,
          child: Column(
            children: [
              const Text(
                'PROGRES MINGGUAN',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textSecondary,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final size =
                      constraints.maxWidth < 120 ? constraints.maxWidth : 120.0;
                  return SizedBox(
                    width: size,
                    height: size,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: size,
                          height: size,
                          child: CircularProgressIndicator(
                            value: total > 0 ? selesai / total : 0,
                            strokeWidth: 10,
                            backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
                            valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
                            strokeCap: StrokeCap.round,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.assignment_turned_in_outlined,
                                color: AppTheme.primary, size: 22),
                            const SizedBox(height: 4),
                            Text(
                              '$pct%',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const Text(
                              'Selesai',
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
                },
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // Streak motivasi
        Expanded(
          flex: 5,
          child: _buildStreakCard(provider),
        ),
          ],
        ),
        const SizedBox(height: 20),
        _buildTaskCalendar(provider),
      ],
    );
  }

  Widget _buildStreakCard(TaskProvider provider) {
    final streak = provider.currentStreak;
    final selesai = provider.tugasSelesai;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.warning.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.local_fire_department_rounded,
                  color: AppTheme.warning, size: 22),
              SizedBox(width: 6),
              Text(
                'Streak',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$streak',
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.warning,
                ),
              ),
              const SizedBox(width: 4),
              const Padding(
                padding: EdgeInsets.only(bottom: 5),
                child: Text(
                  'hari',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            streak == 0
                ? 'Selesaikan 1 tugas hari ini untuk memulai!'
                : 'Beruntun! Pertahankan ya 🔥',
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Total selesai: $selesai',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Kalender Tugas',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              InkWell(
                onTap: () =>
                    MainNavigation.tabIndex.value = MainNavigation.calendarTab,
                borderRadius: BorderRadius.circular(20),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Buka Kalender',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(Icons.chevron_right,
                          size: 16, color: AppTheme.primary),
                    ],
                  ),
                ),
              ),
            ],
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppTheme.textPrimary,
      ),
    );
  }

  Widget _buildUpcomingTasks(TaskProvider provider) {
    final tasks = List.of(provider.activeTasks)
      ..sort((a, b) => a.deadline.compareTo(b.deadline));

    if (tasks.isEmpty) {
      return _buildEmptyState('Tidak ada tugas mendatang 🎉');
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

  Widget _buildCourseCards(TaskProvider provider) {
    // Group tasks by lingkupTugas
    final scopeMap = <String, List<dynamic>>{};
    for (final task in provider.activeTasks) {
      scopeMap.putIfAbsent(task.lingkupTugas, () => []).add(task);
    }

    if (scopeMap.isEmpty) {
      return _buildEmptyState('Belum ada lingkup tugas aktif');
    }

    final scopes = scopeMap.entries.take(4).toList();

    return SizedBox(
      height: 130,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: scopes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final entry = scopes[index];
          final taskCount = entry.value.length;
          final completedInScope = provider.tasks
              .where((t) =>
                  t.lingkupTugas == entry.key &&
                  t.status == TaskStatus.selesai)
              .length;
          final totalInScope = provider.tasks
              .where((t) => t.lingkupTugas == entry.key)
              .length;
          final progress =
              totalInScope > 0 ? completedInScope / totalInScope : 0.0;

          final colors = [
            AppTheme.primary,
            AppTheme.accent,
            AppTheme.warning,
            AppTheme.danger,
          ];
          final color = colors[index % colors.length];

          return Container(
            width: 140,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.label_rounded, color: color, size: 20),
                ),
                const Spacer(),
                Text(
                  entry.key,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$taskCount Tugas',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: color.withValues(alpha: 0.15),
                          valueColor: AlwaysStoppedAnimation(color),
                          minHeight: 4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${(progress * 100).round()}%',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Ringkasan tugas per mata kuliah (Issue #2). Hanya tugas berlingkup
  /// "Perkuliahan" yang mengisi mata kuliah yang dihitung di sini.
  Widget _buildMataKuliahSection(TaskProvider provider) {
    final matkulMap = <String, List<Task>>{};
    for (final task in provider.tasks) {
      final matkul = task.mataKuliah?.trim();
      if (task.lingkupTugas == 'Perkuliahan' &&
          matkul != null &&
          matkul.isNotEmpty) {
        matkulMap.putIfAbsent(matkul, () => []).add(task);
      }
    }

    if (matkulMap.isEmpty) return const SizedBox.shrink();

    final entries = matkulMap.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));

    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Ringkasan Mata Kuliah'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              children: entries.map((entry) {
                final tasks = entry.value;
                final selesai = tasks
                    .where((t) => t.status == TaskStatus.selesai)
                    .length;
                final totalMenit =
                    tasks.fold<int>(0, (sum, t) => sum + t.totalFocusMinutes);
                final subtitle = totalMenit > 0
                    ? '${tasks.length} tugas • $selesai selesai • ${(totalMenit / 60).toStringAsFixed(1)} jam fokus'
                    : '${tasks.length} tugas • $selesai selesai';

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.menu_book_rounded,
                            color: AppTheme.primary, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.key,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
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
