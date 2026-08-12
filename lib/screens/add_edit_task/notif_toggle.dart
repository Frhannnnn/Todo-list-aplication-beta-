// lib/screens/add_edit_task/notif_toggle.dart

import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

/// Sakelar notifikasi khusus tugas ini. Ini bawahan dari sakelar global di
/// Profil → Notifikasi: kalau global mati ([globalEnabled] false), notifikasi
/// tugas apa pun tidak dikirim, jadi sakelar per-tugas dinonaktifkan agar
/// tidak berbenturan/menyesatkan. Jadwal pengingat memakai default (H-1,
/// 3 jam sebelum, tepat deadline).
class NotifToggle extends StatelessWidget {
  final bool globalEnabled;
  final bool notifEnabled;
  final ValueChanged<bool> onChanged;

  const NotifToggle({
    super.key,
    required this.globalEnabled,
    required this.notifEnabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (!globalEnabled) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.warning.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.warning.withValues(alpha: 0.3)),
        ),
        child: const Row(
          children: [
            Icon(Icons.notifications_off_rounded,
                color: AppTheme.warning, size: 18),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Notifikasi dimatikan untuk semua tugas di Profil → Notifikasi. '
                'Aktifkan di sana dulu untuk mengatur notifikasi per tugas.',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
            ),
          ],
        ),
      );
    }
    return SwitchListTile(
      value: notifEnabled,
      onChanged: onChanged,
      activeThumbColor: AppTheme.primary,
      contentPadding: EdgeInsets.zero,
      title: const Text('Notifikasi tugas ini',
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary)),
      subtitle: Text(
        notifEnabled
            ? 'Pengingat H-1, 3 jam sebelum, & tepat deadline'
            : 'Notifikasi dimatikan untuk tugas ini saja',
        style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
      ),
    );
  }
}
