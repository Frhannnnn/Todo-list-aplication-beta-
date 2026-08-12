// lib/screens/add_edit_task/recurrence_custom_sheet.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/task_model.dart';
import '../../utils/app_theme.dart';
import 'recurrence_type_sheet.dart';

Future<RecurrenceSelection?> showCustomRecurrenceSheet(
  BuildContext context, {
  required RecurrenceSelection current,
  required DateTime deadline,
}) {
  var interval = current.interval < 1 ? 1 : current.interval;
  var unit = current.unit;
  // endMode: 0 = tidak pernah, 1 = pada tanggal, 2 = setelah N kali
  var endMode = current.endDate != null ? 1 : (current.count != null ? 2 : 0);
  var endDate = current.endDate;
  var count = current.count ?? 10;

  return showModalBottomSheet<RecurrenceSelection>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheet) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pengulangan Custom',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Ulangi setiap',
                    style: TextStyle(color: AppTheme.textPrimary)),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  color: AppTheme.primary,
                  onPressed: () => setSheet(() {
                    if (interval > 1) interval--;
                  }),
                ),
                Text('$interval',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  color: AppTheme.primary,
                  onPressed: () => setSheet(() => interval++),
                ),
                const SizedBox(width: 8),
                DropdownButton<RecurrenceUnit>(
                  value: unit,
                  items: const [
                    DropdownMenuItem(
                        value: RecurrenceUnit.day, child: Text('hari')),
                    DropdownMenuItem(
                        value: RecurrenceUnit.week, child: Text('minggu')),
                    DropdownMenuItem(
                        value: RecurrenceUnit.month, child: Text('bulan')),
                    DropdownMenuItem(
                        value: RecurrenceUnit.year, child: Text('tahun')),
                  ],
                  onChanged: (v) =>
                      setSheet(() => unit = v ?? RecurrenceUnit.day),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('Berakhir',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 4),
            _customEndRow(
              selected: endMode == 0,
              onTap: () => setSheet(() => endMode = 0),
              child: const Text('Tidak pernah'),
            ),
            _customEndRow(
              selected: endMode == 1,
              onTap: () => setSheet(() => endMode = 1),
              child: Row(
                children: [
                  const Text('Pada tanggal'),
                  const SizedBox(width: 8),
                  if (endMode == 1)
                    TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate:
                              endDate ?? deadline.add(const Duration(days: 30)),
                          firstDate: deadline,
                          lastDate: deadline.add(const Duration(days: 365 * 5)),
                        );
                        if (picked != null) setSheet(() => endDate = picked);
                      },
                      child: Text(endDate == null
                          ? 'Pilih…'
                          : DateFormat('d MMM yyyy', 'id_ID').format(endDate!)),
                    ),
                ],
              ),
            ),
            _customEndRow(
              selected: endMode == 2,
              onTap: () => setSheet(() => endMode = 2),
              child: Row(
                children: [
                  const Text('Setelah'),
                  const SizedBox(width: 8),
                  if (endMode == 2) ...[
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, size: 20),
                      color: AppTheme.primary,
                      onPressed: () =>
                          setSheet(() => count = count > 1 ? count - 1 : 1),
                    ),
                    Text('$count'),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, size: 20),
                      color: AppTheme.primary,
                      onPressed: () => setSheet(() => count++),
                    ),
                    const Text('kali'),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx, (
                    type: RecurrenceType.custom,
                    interval: interval,
                    unit: unit,
                    endDate: endMode == 1 ? endDate : null,
                    count: endMode == 2 ? count : null,
                  ));
                },
                child: const Text('Simpan'),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    ),
  );
}

Widget _customEndRow({
  required bool selected,
  required VoidCallback onTap,
  required Widget child,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            selected
                ? Icons.radio_button_checked
                : Icons.radio_button_unchecked,
            color: selected ? AppTheme.primary : AppTheme.textSecondary,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(child: child),
        ],
      ),
    ),
  );
}
