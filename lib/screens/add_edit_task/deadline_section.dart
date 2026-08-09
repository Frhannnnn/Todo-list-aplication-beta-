// lib/screens/add_edit_task/deadline_section.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../utils/app_theme.dart';

/// Badge kecil urgensi otomatis berdasarkan deadline.
Widget urgensiBadge(DateTime deadline) {
  final sisa = deadline.difference(DateTime.now()).inHours;
  String label;
  Color color;

  if (sisa <= 0) {
    label = 'Lewat';
    color = AppTheme.danger;
  } else if (sisa <= 3) {
    label = '< 3 jam';
    color = AppTheme.danger;
  } else if (sisa <= 24) {
    label = '< 24 jam';
    color = const Color(0xFFF97316);
  } else if (sisa <= 72) {
    label = '< 3 hari';
    color = AppTheme.warning;
  } else if (sisa <= 168) {
    label = '< 7 hari';
    color = AppTheme.success;
  } else {
    label = 'Santai';
    color = AppTheme.success;
  }

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withValues(alpha: 0.35)),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: color,
      ),
    ),
  );
}

/// Pintasan deadline umum agar tak perlu selalu buka date+time picker.
/// Menyetel tanggal ke pukul 23:59 (akhir hari) sebagai konvensi deadline.
class DeadlinePresets extends StatelessWidget {
  final DateTime deadline;
  final ValueChanged<DateTime> onChanged;

  const DeadlinePresets({
    super.key,
    required this.deadline,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final presets = <(String, DateTime)>[
      ('Hari ini', today),
      ('Besok', today.add(const Duration(days: 1))),
      ('3 hari', today.add(const Duration(days: 3))),
      ('Minggu depan', today.add(const Duration(days: 7))),
    ];
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: presets.map((p) {
          final target = DateTime(p.$2.year, p.$2.month, p.$2.day, 23, 59);
          final selected = deadline.year == target.year &&
              deadline.month == target.month &&
              deadline.day == target.day &&
              deadline.hour == 23 &&
              deadline.minute == 59;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onChanged(target);
                },
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppTheme.primary.withValues(alpha: 0.1)
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: selected ? AppTheme.primary : AppTheme.border,
                        width: selected ? 1.5 : 1),
                  ),
                  child: Text(
                    p.$1,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color:
                          selected ? AppTheme.primary : AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class DeadlinePicker extends StatelessWidget {
  final DateTime deadline;
  final ValueChanged<DateTime> onChanged;

  const DeadlinePicker({
    super.key,
    required this.deadline,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: deadline,
          firstDate: DateTime.now().subtract(const Duration(days: 1)),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (date != null) {
          if (!context.mounted) return;
          final time = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.fromDateTime(deadline),
          );
          if (!context.mounted) return;
          onChanged(DateTime(
            date.year,
            date.month,
            date.day,
            time?.hour ?? 23,
            time?.minute ?? 59,
          ));
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.border),
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey.shade50,
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: AppTheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Deadline',
                      style: TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary)),
                  Text(
                    DateFormat('EEEE, d MMMM yyyy - HH:mm', 'id_ID')
                        .format(deadline),
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            urgensiBadge(deadline),
          ],
        ),
      ),
    );
  }
}
