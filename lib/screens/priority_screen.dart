import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/task_model.dart';
import '../services/task_provider.dart';
import '../utils/app_assets.dart';
import '../utils/app_theme.dart';
import 'add_edit_task_screen.dart';

enum EisenhowerQuadrant { doNow, schedule, delegate, eliminate }

class PriorityScreen extends StatelessWidget {
  const PriorityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Eisenhower Matrix'),
        backgroundColor: AppTheme.secondary,
      ),
      body: Consumer<TaskProvider>(
        builder: (context, provider, _) {
          final activeTasks = provider.activeTasks;
          final groupedTasks = _groupTasks(activeTasks);

          if (activeTasks.isEmpty) return _buildEmptyState();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              _buildIntroCard(activeTasks.length),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 680;
                  final cards = EisenhowerQuadrant.values
                      .map(
                        (quadrant) => _QuadrantCard(
                          config: _configFor(quadrant),
                          tasks: groupedTasks[quadrant] ?? [],
                        ),
                      )
                      .toList();

                  if (!isWide) {
                    return Column(
                      children: cards
                          .map(
                            (card) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: card,
                            ),
                          )
                          .toList(),
                    );
                  }

                  return GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 0.95,
                    children: cards,
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  static Map<EisenhowerQuadrant, List<Task>> _groupTasks(List<Task> tasks) {
    final grouped = {
      for (final quadrant in EisenhowerQuadrant.values) quadrant: <Task>[],
    };

    for (final task in tasks) {
      grouped[_quadrantFor(task)]!.add(task);
    }

    for (final quadrantTasks in grouped.values) {
      quadrantTasks.sort((a, b) {
        final rankCompare = a.ranking.compareTo(b.ranking);
        if (rankCompare != 0) return rankCompare;
        return a.deadline.compareTo(b.deadline);
      });
    }

    return grouped;
  }

  static EisenhowerQuadrant _quadrantFor(Task task) {
    final isImportant = task.tingkatKepentingan >= 4;
    final isUrgent = task.tingkatUrgensi >= 4;

    if (isImportant && isUrgent) return EisenhowerQuadrant.doNow;
    if (isImportant && !isUrgent) return EisenhowerQuadrant.schedule;
    if (!isImportant && isUrgent) return EisenhowerQuadrant.delegate;
    return EisenhowerQuadrant.eliminate;
  }

  Widget _buildIntroCard(int activeCount) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppTheme.secondary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.grid_view_rounded,
              color: AppTheme.secondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pembagian prioritas 4 kuadran',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$activeCount tugas aktif dikelompokkan dari tingkat kepentingan dan urgensi.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(AppAssets.emptyPriority, width: 180, height: 135),
            const SizedBox(height: 16),
            const Text(
              'Belum ada tugas aktif',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tambah tugas dengan nilai kepentingan dan urgensi untuk melihat matrix.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  _QuadrantConfig _configFor(EisenhowerQuadrant quadrant) {
    switch (quadrant) {
      case EisenhowerQuadrant.doNow:
        return const _QuadrantConfig(
          title: 'Kerjakan',
          subtitle: 'Penting dan mendesak',
          action: 'Prioritas utama',
          icon: Icons.priority_high_rounded,
          color: AppTheme.danger,
        );
      case EisenhowerQuadrant.schedule:
        return const _QuadrantConfig(
          title: 'Jadwalkan',
          subtitle: 'Penting, tidak mendesak',
          action: 'Rencanakan waktu',
          icon: Icons.event_note_rounded,
          color: AppTheme.primary,
        );
      case EisenhowerQuadrant.delegate:
        return const _QuadrantConfig(
          title: 'Delegasikan',
          subtitle: 'Mendesak, kurang penting',
          action: 'Kurangi beban',
          icon: Icons.groups_2_outlined,
          color: AppTheme.warning,
        );
      case EisenhowerQuadrant.eliminate:
        return const _QuadrantConfig(
          title: 'Eliminasi',
          subtitle: 'Kurang penting dan tidak mendesak',
          action: 'Tinjau ulang',
          icon: Icons.low_priority_rounded,
          color: AppTheme.success,
        );
    }
  }
}

class _QuadrantConfig {
  final String title;
  final String subtitle;
  final String action;
  final IconData icon;
  final Color color;

  const _QuadrantConfig({
    required this.title,
    required this.subtitle,
    required this.action,
    required this.icon,
    required this.color,
  });
}

class _QuadrantCard extends StatelessWidget {
  final _QuadrantConfig config;
  final List<Task> tasks;

  const _QuadrantCard({required this.config, required this.tasks});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: config.color.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: config.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(config.icon, color: config.color, size: 21),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        config.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        config.subtitle,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                _countBadge(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: config.color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                config.action,
                style: TextStyle(
                  color: config.color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 210,
            child: tasks.isEmpty
                ? _emptyQuadrant()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                    itemCount: tasks.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) => _MatrixTaskTile(
                      task: tasks[index],
                      color: config.color,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _countBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: config.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: config.color.withValues(alpha: 0.35)),
      ),
      child: Text(
        '${tasks.length}',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: config.color,
        ),
      ),
    );
  }

  Widget _emptyQuadrant() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Text(
          'Tidak ada tugas',
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary.withValues(alpha: 0.8),
          ),
        ),
      ),
    );
  }
}

class _MatrixTaskTile extends StatelessWidget {
  final Task task;
  final Color color;

  const _MatrixTaskTile({required this.task, required this.color});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AddEditTaskScreen(task: task)),
      ),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    task.namaTugas,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '#${task.ranking}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              task.mataKuliah,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today_outlined, size: 12, color: color),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    DateFormat('d MMM, HH:mm', 'id_ID').format(task.deadline),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: task.isOverdue
                          ? AppTheme.danger
                          : AppTheme.textSecondary,
                      fontWeight:
                          task.isOverdue ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                _scorePill('P', task.tingkatKepentingan),
                const SizedBox(width: 4),
                _scorePill('U', task.tingkatUrgensi),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _scorePill(String label, int value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$label$value',
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
