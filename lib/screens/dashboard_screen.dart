// lib/screens/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task_model.dart';
import '../services/task_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/task_card_widget.dart';
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
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.border),
            ),
            child: const Icon(Icons.more_horiz, color: AppTheme.textSecondary, size: 20),
          ),
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

    return Row(
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
              SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 120,
                      height: 120,
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
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // Activity grid (heatmap)
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Kalender Tugas',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Icon(Icons.calendar_today_outlined,
                      size: 16, color: AppTheme.textSecondary),
                ],
              ),
              const SizedBox(height: 10),
              _buildActivityGrid(provider),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityGrid(TaskProvider provider) {
    final now = DateTime.now();
    final days = List.generate(35, (i) {
      return now.subtract(Duration(days: 34 - i));
    });

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 35,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 3,
        crossAxisSpacing: 3,
      ),
      itemBuilder: (context, index) {
        final date = days[index];
        final tasksOnDay = provider.tasks.where((t) =>
            t.deadline.year == date.year &&
            t.deadline.month == date.month &&
            t.deadline.day == date.day).length;

        Color cellColor;
        if (tasksOnDay == 0) {
          cellColor = AppTheme.primary.withValues(alpha: 0.06);
        } else if (tasksOnDay == 1) {
          cellColor = AppTheme.primary.withValues(alpha: 0.2);
        } else if (tasksOnDay == 2) {
          cellColor = AppTheme.primary.withValues(alpha: 0.4);
        } else {
          cellColor = AppTheme.primary.withValues(alpha: 0.7);
        }

        return Container(
          decoration: BoxDecoration(
            color: cellColor,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      },
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
