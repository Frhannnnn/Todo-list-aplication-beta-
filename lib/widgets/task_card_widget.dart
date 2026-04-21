// lib/widgets/task_card_widget.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task_model.dart';
import '../utils/app_theme.dart';

class TaskCardWidget extends StatelessWidget {
  final Task task;
  final bool showRanking;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final Function(TaskStatus)? onStatusChange;

  const TaskCardWidget({
    super.key,
    required this.task,
    this.showRanking = false,
    this.onTap,
    this.onDelete,
    this.onStatusChange,
  });

  @override
  Widget build(BuildContext context) {
    final prioritasColor = task.ranking > 0
      ? AppTheme.getPrioritasColor(task.ranking, 10)
      : AppTheme.textSecondary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: task.isOverdue ? AppTheme.danger.withOpacity(0.5)
              : task.isDueToday ? AppTheme.warning.withOpacity(0.5)
              : AppTheme.border,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          children: [
            // Color indicator bar on left
            IntrinsicHeight(
              child: Row(
                children: [
                  Container(
                    width: 5,
                    decoration: BoxDecoration(
                      color: task.isOverdue ? AppTheme.danger
                        : task.isDueToday ? AppTheme.warning
                        : task.isDueSoon ? AppTheme.warning.withOpacity(0.6)
                        : AppTheme.success,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header row
                          Row(
                            children: [
                              if (showRanking && task.ranking > 0) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: prioritasColor.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text('#${task.ranking}',
                                    style: TextStyle(
                                      fontSize: 11, fontWeight: FontWeight.w800,
                                      color: prioritasColor)),
                                ),
                                const SizedBox(width: 6),
                              ],
                              Expanded(
                                child: Text(task.namaTugas,
                                  style: TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary,
                                    decoration: task.status == TaskStatus.selesai
                                      ? TextDecoration.lineThrough : null,
                                  ),
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                              ),
                              _buildStatusBadge(),
                            ],
                          ),
                          const SizedBox(height: 4),
                          // Mata Kuliah
                          Row(
                            children: [
                              const Icon(Icons.school, size: 12, color: AppTheme.textSecondary),
                              const SizedBox(width: 4),
                              Text(task.mataKuliah,
                                style: const TextStyle(
                                  fontSize: 12, color: AppTheme.textSecondary)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: task.group == TaskGroup.individu
                                    ? AppTheme.accent.withOpacity(0.1)
                                    : AppTheme.secondary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  task.group == TaskGroup.individu ? 'Individu' : 'Kelompok',
                                  style: TextStyle(
                                    fontSize: 10, fontWeight: FontWeight.w600,
                                    color: task.group == TaskGroup.individu
                                      ? AppTheme.accent : AppTheme.secondary)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Deadline & info row
                          Row(
                            children: [
                              Icon(Icons.calendar_today, size: 12,
                                color: task.isOverdue ? AppTheme.danger : AppTheme.textSecondary),
                              const SizedBox(width: 4),
                              Text(
                                DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(task.deadline),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: task.isOverdue ? AppTheme.danger : AppTheme.textSecondary,
                                  fontWeight: task.isOverdue ? FontWeight.w600 : FontWeight.normal,
                                )),
                              const Spacer(),
                              if (task.isOverdue)
                                _buildDeadlineChip('Terlambat!', AppTheme.danger)
                              else if (task.isDueToday)
                                _buildDeadlineChip('Hari ini!', AppTheme.warning)
                              else if (task.isDueSoon)
                                _buildDeadlineChip('${task.sisaHari} hari lagi', AppTheme.warning)
                              else
                                _buildDeadlineChip('${task.sisaHari} hari', AppTheme.success),
                            ],
                          ),
                          if (onDelete != null || onStatusChange != null) ...[
                            const Divider(height: 12),
                            _buildActions(),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color color = AppTheme.getStatusColor(task.status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(task.statusLabel,
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color)),
    );
  }

  Widget _buildDeadlineChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        if (onStatusChange != null) ...[
          if (task.status != TaskStatus.selesai) ...[
            InkWell(
              onTap: () => onStatusChange!(
                task.status == TaskStatus.belumDikerjakan
                  ? TaskStatus.sedangDikerjakan
                  : TaskStatus.selesai),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check, size: 12, color: AppTheme.success),
                    const SizedBox(width: 4),
                    Text(
                      task.status == TaskStatus.belumDikerjakan
                        ? 'Mulai' : 'Selesaikan',
                      style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w600,
                        color: AppTheme.success)),
                  ],
                ),
              ),
            ),
          ] else ...[
            InkWell(
              onTap: () => onStatusChange!(TaskStatus.belumDikerjakan),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.undo, size: 12, color: AppTheme.warning),
                    SizedBox(width: 4),
                    Text('Buka Lagi',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                        color: AppTheme.warning)),
                  ],
                ),
              ),
            ),
          ],
        ],
        const Spacer(),
        if (onDelete != null)
          InkWell(
            onTap: onDelete,
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.all(5),
              child: const Icon(Icons.delete_outline, size: 16, color: AppTheme.danger),
            ),
          ),
      ],
    );
  }
}
