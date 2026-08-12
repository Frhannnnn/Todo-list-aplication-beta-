// lib/screens/add_edit_task/recurrence_picker_tile.dart

import 'package:flutter/material.dart';
import '../../models/task_model.dart';
import '../../utils/app_theme.dart';
import '../../utils/recurrence.dart';

class RecurrencePickerTile extends StatelessWidget {
  final RecurrenceType recurrence;
  final DateTime deadline;
  final int recurrenceInterval;
  final RecurrenceUnit recurrenceUnit;
  final VoidCallback onTap;

  const RecurrencePickerTile({
    super.key,
    required this.recurrence,
    required this.deadline,
    required this.recurrenceInterval,
    required this.recurrenceUnit,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
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
            const Icon(Icons.repeat_rounded, color: AppTheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pengulangan',
                      style: TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary)),
                  Text(
                    recurrenceLabel(recurrence, deadline,
                        interval: recurrenceInterval, unit: recurrenceUnit),
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }
}
