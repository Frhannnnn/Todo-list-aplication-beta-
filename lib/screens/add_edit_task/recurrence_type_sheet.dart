// lib/screens/add_edit_task/recurrence_type_sheet.dart

import 'package:flutter/material.dart';
import '../../models/task_model.dart';
import '../../utils/app_theme.dart';
import '../../utils/recurrence.dart';
import 'recurrence_custom_sheet.dart';

/// Hasil pemilihan pengulangan — selalu lengkap (interval/unit/endDate/count)
/// meski pengguna hanya memilih tipe non-custom, supaya pemanggil punya satu
/// bentuk `setState` untuk kedua jalur (lihat [showRecurrenceTypeSheet]).
typedef RecurrenceSelection = ({
  RecurrenceType type,
  int interval,
  RecurrenceUnit unit,
  DateTime? endDate,
  int? count,
});

/// Menampilkan daftar pilihan tipe pengulangan. Jika pengguna memilih tipe
/// non-custom, [current]'s interval/unit/endDate/count di-echo balik tanpa
/// berubah (field-field itu inert sampai tipe custom dipilih — lihat
/// clearing logic di `_save`). Jika pengguna memilih "Custom…", sheet ini
/// menutup diri lalu meneruskan ke [showCustomRecurrenceSheet] dan
/// mengembalikan hasilnya — sehingga pemanggil hanya punya SATU call site
/// apa pun jalur yang ditempuh pengguna.
Future<RecurrenceSelection?> showRecurrenceTypeSheet(
  BuildContext context, {
  required RecurrenceSelection current,
  required DateTime deadline,
}) async {
  const options = [
    RecurrenceType.none,
    RecurrenceType.daily,
    RecurrenceType.weekly,
    RecurrenceType.monthly,
    RecurrenceType.yearly,
    RecurrenceType.weekday,
    RecurrenceType.custom,
  ];

  final picked = await showModalBottomSheet<RecurrenceType>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text('Pengulangan',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary)),
          ),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...options.map((opt) {
                    final selected = current.type == opt;
                    final label = opt == RecurrenceType.custom
                        ? 'Custom…'
                        : recurrenceLabel(opt, deadline);
                    return ListTile(
                      title: Text(label,
                          style: TextStyle(
                              color: selected
                                  ? AppTheme.primary
                                  : AppTheme.textPrimary,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500)),
                      trailing: selected
                          ? const Icon(Icons.check_rounded,
                              color: AppTheme.primary)
                          : null,
                      onTap: () => Navigator.pop(ctx, opt),
                    );
                  }),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );

  if (picked == null) return null;
  if (picked == RecurrenceType.custom) {
    if (!context.mounted) return null;
    return showCustomRecurrenceSheet(
      context,
      current: current,
      deadline: deadline,
    );
  }
  return (
    type: picked,
    interval: current.interval,
    unit: current.unit,
    endDate: current.endDate,
    count: current.count,
  );
}
