// lib/screens/add_edit_task/priority_picker.dart

import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

/// Pemilih prioritas ringkas (Rendah/Sedang/Tinggi) menggantikan slider
/// Kepentingan + Estimasi + ringkasan Eisenhower. Nilainya dipetakan ke
/// tingkat kepentingan SAW; estimasi memakai nilai default. SAW tetap
/// mengurutkan tugas dari urgensi (deadline) + kepentingan ini.
class PriorityPicker extends StatelessWidget {
  final int kepentingan;
  final ValueChanged<int> onChanged;

  const PriorityPicker({
    super.key,
    required this.kepentingan,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const options = [
      ('Rendah', 2),
      ('Sedang', 3),
      ('Tinggi', 5),
    ];
    final selectedLevel =
        kepentingan <= 2 ? 2 : (kepentingan >= 4 ? 5 : 3);
    return Row(
      children: options.map((opt) {
        final selected = selectedLevel == opt.$2;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () => onChanged(opt.$2),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? AppTheme.primary.withValues(alpha: 0.1)
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected ? AppTheme.primary : AppTheme.border,
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  opt.$1,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color:
                        selected ? AppTheme.primary : AppTheme.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
