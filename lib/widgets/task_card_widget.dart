// lib/widgets/task_card_widget.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task_model.dart';
import '../utils/app_assets.dart';
import '../utils/app_theme.dart';

class TaskCardWidget extends StatelessWidget {
  final Task task;
  final bool showRanking;
  final int totalActiveTasks;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final Function(TaskStatus)? onStatusChange;

  const TaskCardWidget({
    super.key,
    required this.task,
    this.showRanking = false,
    this.totalActiveTasks = 0,
    this.onTap,
    this.onDelete,
    this.onStatusChange,
  });

  bool get _shouldShowPriorityBadge =>
      task.ranking > 0 &&
      task.status != TaskStatus.selesai &&
      totalActiveTasks > 0;

  Color get _cardBorderColor {
    if (task.isOverdue) return AppTheme.danger.withValues(alpha: 0.4);
    if (task.isDueToday) return AppTheme.warning.withValues(alpha: 0.4);
    if (task.isDueSoon) return AppTheme.warning.withValues(alpha: 0.25);
    return AppTheme.primary.withValues(alpha: 0.2);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _cardBorderColor, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: icon + title + deadline badge
            Row(
              children: [
                _buildCategoryIcon(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.namaTugas,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                          decoration: task.status == TaskStatus.selesai
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        task.mataKuliah,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _buildDeadlineBadge(),
              ],
            ),
            // Tags row
            const SizedBox(height: 10),
            Row(
              children: [
                _buildCategoryTag(),
                if (_shouldShowPriorityBadge) ...[
                  const SizedBox(width: 6),
                  _buildPriorityBadge(),
                ],
                if (showRanking && task.ranking > 0) ...[
                  const SizedBox(width: 6),
                  _buildRankingBadge(),
                ],
                const Spacer(),
                _buildStatusBadge(),
              ],
            ),
            // Actions
            if (onDelete != null || onStatusChange != null) ...[
              const SizedBox(height: 10),
              Container(
                height: 1,
                color: AppTheme.border.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 10),
              _buildActions(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryIcon() {
    final color = task.isOverdue
        ? AppTheme.danger
        : task.isDueToday
            ? AppTheme.warning
            : AppTheme.primary;

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Center(
        child: Image.asset(
          AppAssets.categoryIcon(task.category),
          width: 22,
          height: 22,
          errorBuilder: (_, __, ___) => Icon(
            _getCategoryIconData(),
            color: color,
            size: 20,
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIconData() {
    switch (task.category) {
      case TaskCategory.kuliah:
        return Icons.school_rounded;
      case TaskCategory.praktikum:
        return Icons.science_rounded;
      case TaskCategory.project:
        return Icons.code_rounded;
      case TaskCategory.lainnya:
        return Icons.folder_rounded;
    }
  }

  Widget _buildDeadlineBadge() {
    String label;
    Color color;

    if (task.isOverdue) {
      label = 'Terlambat';
      color = AppTheme.danger;
    } else if (task.isDueToday) {
      label = 'Hari Ini';
      color = AppTheme.warning;
    } else if (task.sisaHari <= 2) {
      label = '${task.sisaHari} Hari Lagi';
      color = AppTheme.warning;
    } else {
      label = '${task.sisaHari} Hari Lagi';
      color = AppTheme.success;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          DateFormat('d MMM yyyy', 'id_ID').format(task.deadline),
          style: const TextStyle(
            fontSize: 10,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryTag() {
    final color = task.category == TaskCategory.kuliah
        ? AppTheme.primary
        : task.category == TaskCategory.praktikum
            ? AppTheme.accent
            : task.category == TaskCategory.project
                ? AppTheme.warning
                : AppTheme.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        task.categoryLabel,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildPriorityBadge() {
    final label = AppTheme.getPrioritasLabel(task.ranking, totalActiveTasks);
    final color = AppTheme.getPrioritasColor(task.ranking, totalActiveTasks);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildRankingBadge() {
    final color = AppTheme.getPrioritasColor(task.ranking, totalActiveTasks);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '#${task.ranking}',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color color = AppTheme.getStatusColor(task.status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        task.statusLabel,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        if (onStatusChange != null) ...[
          if (task.status != TaskStatus.selesai) ...[
            _actionButton(
              icon: Icons.check_rounded,
              label: task.status == TaskStatus.belumDikerjakan ? 'Mulai' : 'Selesaikan',
              color: AppTheme.success,
              onTap: () => onStatusChange!(
                task.status == TaskStatus.belumDikerjakan
                    ? TaskStatus.sedangDikerjakan
                    : TaskStatus.selesai,
              ),
            ),
          ] else ...[
            _actionButton(
              icon: Icons.undo_rounded,
              label: 'Buka Lagi',
              color: AppTheme.warning,
              onTap: () => onStatusChange!(TaskStatus.belumDikerjakan),
            ),
          ],
        ],
        const Spacer(),
        if (onDelete != null)
          GestureDetector(
            onTap: onDelete,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.danger.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.delete_outline_rounded,
                  size: 18, color: AppTheme.danger),
            ),
          ),
      ],
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
