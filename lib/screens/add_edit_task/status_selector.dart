// lib/screens/add_edit_task/status_selector.dart

import 'package:flutter/material.dart';
import '../../models/task_model.dart';
import '../../utils/app_theme.dart';

class StatusSelector extends StatelessWidget {
  final TaskStatus status;
  final ValueChanged<TaskStatus> onChanged;

  const StatusSelector({
    super.key,
    required this.status,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const labels = ['Belum\nDikerjakan', 'Sedang\nDikerjakan', 'Selesai'];
    const icons = [
      Icons.radio_button_unchecked,
      Icons.access_time,
      Icons.check_circle
    ];
    const colors = [AppTheme.textSecondary, AppTheme.warning, AppTheme.success];
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: TaskStatus.values.map((s) {
          final isSelected = status == s;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: GestureDetector(
                onTap: () => onChanged(s),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colors[s.index].withValues(alpha: 0.1)
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? colors[s.index] : AppTheme.border,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icons[s.index],
                          color: isSelected
                              ? colors[s.index]
                              : AppTheme.textSecondary,
                          size: 20),
                      const SizedBox(height: 4),
                      Text(labels[s.index],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.normal,
                              color: isSelected
                                  ? colors[s.index]
                                  : AppTheme.textSecondary)),
                    ],
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
