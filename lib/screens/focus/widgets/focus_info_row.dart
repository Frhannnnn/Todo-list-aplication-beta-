// lib/screens/focus/widgets/focus_info_row.dart

import 'package:flutter/material.dart';
import '../../../utils/app_theme.dart';

/// Baris label–nilai untuk kartu informasi sesi fokus. Dipakai bersama oleh
/// halaman persiapan, timer, dan selesai (menghindari duplikasi).
class FocusInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final double labelWidth;

  const FocusInfoRow({
    super.key,
    required this.label,
    required this.value,
    this.labelWidth = 110,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: labelWidth,
          child: Text(label,
              style: const TextStyle(
                  fontSize: 13, color: AppTheme.textSecondary)),
        ),
        Expanded(
          child: Text(value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary)),
        ),
      ],
    );
  }
}
