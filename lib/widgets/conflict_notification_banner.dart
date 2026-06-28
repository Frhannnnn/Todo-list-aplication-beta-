// lib/widgets/conflict_notification_banner.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/schedule_result_model.dart';
import '../services/task_provider.dart';
import '../utils/app_theme.dart';

/// Banner widget yang menampilkan notifikasi konflik jadwal.
///
/// Ditampilkan di bagian atas ScheduleScreen ketika konflik terdeteksi
/// selama proses penjadwalan. Menunjukkan:
/// - Nama tugas yang berkonflik dan waktu slot yang diperebutkan
/// - SAW Score masing-masing tugas
/// - Rekomendasi (pemenang dan tugas yang digeser)
/// - Hasil resolusi (alokasi slot baru)
class ConflictNotificationBanner extends StatelessWidget {
  const ConflictNotificationBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, provider, _) {
        if (!provider.hasConflicts) {
          return const SizedBox.shrink();
        }

        return _ConflictBannerContent(
          conflicts: provider.latestConflicts,
          provider: provider,
        );
      },
    );
  }
}

class _ConflictBannerContent extends StatefulWidget {
  final List<ScheduleConflict> conflicts;
  final TaskProvider provider;

  const _ConflictBannerContent({
    required this.conflicts,
    required this.provider,
  });

  @override
  State<_ConflictBannerContent> createState() => _ConflictBannerContentState();
}

class _ConflictBannerContentState extends State<_ConflictBannerContent> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: AppTheme.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.warning.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: AppTheme.warning,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Konflik Jadwal Terdeteksi (${widget.conflicts.length})',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  Icon(
                    _isExpanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: AppTheme.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => widget.provider.dismissConflicts(),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      child: const Icon(
                        Icons.close_rounded,
                        color: AppTheme.textSecondary,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Expanded conflict details
          if (_isExpanded) ...[
            const Divider(height: 1, indent: 14, endIndent: 14),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widget.conflicts
                    .map((conflict) => _buildConflictItem(conflict))
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConflictItem(ScheduleConflict conflict) {
    final slotTime = DateTime.tryParse(conflict.slotTime);
    final slotLabel = slotTime != null
        ? DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(slotTime)
        : conflict.slotTime;

    // Look up task names from provider
    final taskNames = <String, String>{};
    for (final taskId in conflict.taskIds) {
      final matchingTasks =
          widget.provider.tasks.where((t) => t.id == taskId);
      if (matchingTasks.isNotEmpty) {
        taskNames[taskId] = matchingTasks.first.namaTugas;
      } else {
        taskNames[taskId] = 'Tugas tidak ditemukan';
      }
    }

    // Find where the losers were shifted to (from the final timeBlocks)
    final loserIds = conflict.taskIds.where((id) => id != conflict.winnerId);
    final shiftedAllocations = <String, String>{};
    for (final loserId in loserIds) {
      final loserBlocks = widget.provider.timeBlocks
          .where((b) => b.taskId == loserId)
          .toList();
      if (loserBlocks.isNotEmpty) {
        // Find the block that was shifted (closest to the original conflict slot)
        loserBlocks.sort((a, b) => a.startTime.compareTo(b.startTime));
        final latestBlock = loserBlocks.last;
        shiftedAllocations[loserId] =
            DateFormat('d MMM, HH:mm', 'id_ID').format(latestBlock.startTime);
      } else {
        shiftedAllocations[loserId] = 'Tidak terjadwalkan';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Slot time
          Row(
            children: [
              const Icon(Icons.access_time_rounded,
                  size: 14, color: AppTheme.textSecondary),
              const SizedBox(width: 6),
              Text(
                'Slot: $slotLabel',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Conflicting tasks with SAW scores
          ...conflict.taskIds.map((taskId) {
            final name = taskNames[taskId] ?? taskId;
            final score = conflict.sawScores[taskId];
            final isWinner = taskId == conflict.winnerId;

            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(
                    isWinner
                        ? Icons.emoji_events_rounded
                        : Icons.arrow_forward_rounded,
                    size: 14,
                    color: isWinner ? AppTheme.warning : AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isWinner ? FontWeight.w700 : FontWeight.w500,
                        color: AppTheme.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (score != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isWinner
                            ? AppTheme.primary.withValues(alpha: 0.1)
                            : AppTheme.border.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'SAW: ${score.toStringAsFixed(3)}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isWinner
                              ? AppTheme.primary
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),

          const SizedBox(height: 6),

          // Recommendation / Resolution result
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.success.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.success.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.check_circle_outline_rounded,
                        size: 13, color: AppTheme.success),
                    SizedBox(width: 4),
                    Text(
                      'Hasil Resolusi:',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '• ${taskNames[conflict.winnerId] ?? conflict.winnerId} → tetap di slot ini',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textPrimary,
                  ),
                ),
                ...loserIds.map((loserId) {
                  final loserName = taskNames[loserId] ?? loserId;
                  final newSlot =
                      shiftedAllocations[loserId] ?? 'Tidak terjadwalkan';
                  return Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '• $loserName → dipindahkan ke $newSlot',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
