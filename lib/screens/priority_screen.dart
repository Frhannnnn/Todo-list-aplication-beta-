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
      body: SafeArea(
        child: Consumer<TaskProvider>(
          builder: (context, provider, _) {
            final activeTasks = provider.activeTasks;
            final groupedTasks = _groupTasks(activeTasks);

            if (activeTasks.isEmpty) return _buildEmptyState();

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeader()),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildIntroCard(activeTasks.length, groupedTasks),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.72,
                    ),
                    delegate: SliverChildListDelegate(
                      EisenhowerQuadrant.values
                          .map((quadrant) => _QuadrantCard(
                                config: _configFor(quadrant),
                                tasks: groupedTasks[quadrant] ?? [],
                              ))
                          .toList(),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Text(
        'Prioritas',
        style: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          color: AppTheme.textPrimary,
        ),
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

  Widget _buildIntroCard(int activeCount, Map<EisenhowerQuadrant, List<Task>> grouped) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.grid_view_rounded,
                    color: AppTheme.secondary, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Eisenhower Matrix',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$activeCount tugas aktif dikelompokkan',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: EisenhowerQuadrant.values.map((q) {
              final count = grouped[q]?.length ?? 0;
              final config = _configFor(q);
              return _buildDistribItem(config.title, count, config.color);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDistribItem(String label, int count, Color color) {
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(AppAssets.emptyPriority, width: 160, height: 120),
            const SizedBox(height: 20),
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
              'Tambah tugas untuk melihat matrix prioritas.',
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
          subtitle: 'Penting & mendesak',
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
          subtitle: 'Kurang penting',
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: config.color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: config.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(config.icon, color: config.color, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        config.title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        config.subtitle,
                        style: const TextStyle(
                          fontSize: 10,
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
                borderRadius: BorderRadius.circular(10),
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
          Expanded(
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
        color: config.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: config.color.withValues(alpha: 0.3)),
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
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AddEditTaskScreen(task: task)),
      ),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.15)),
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
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
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
            Row(
              children: [
                Icon(Icons.calendar_today_outlined, size: 10, color: color),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    DateFormat('d MMM, HH:mm', 'id_ID').format(task.deadline),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      color: task.isOverdue ? AppTheme.danger : AppTheme.textSecondary,
                      fontWeight: task.isOverdue ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                _scorePill('P', task.tingkatKepentingan),
                const SizedBox(width: 3),
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
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$label$value',
        style: TextStyle(
          fontSize: 9,
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
