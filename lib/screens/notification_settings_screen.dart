// lib/screens/notification_settings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/task_provider.dart';
import '../utils/app_theme.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  int _pendingCount = 0;

  @override
  void initState() {
    super.initState();
    _loadPendingCount();
  }

  Future<void> _loadPendingCount() async {
    final provider = context.read<TaskProvider>();
    final list = await provider.getPendingNotifications();
    if (mounted) setState(() => _pendingCount = list.length);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('🔔 Pengaturan Notifikasi'),
        backgroundColor: AppTheme.primary,
      ),
      body: Consumer<TaskProvider>(
        builder: (context, provider, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildPermissionCard(provider),
              const SizedBox(height: 16),
              _buildMainToggleCard(provider),
              const SizedBox(height: 16),
              if (provider.notifEnabled) ...[
                _buildDeadlineNotifCard(),
                const SizedBox(height: 16),
                _buildDailyReminderCard(provider),
                const SizedBox(height: 16),
                _buildStatusCard(),
                const SizedBox(height: 16),
              ],
              _buildLegendCard(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPermissionCard(TaskProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.notifications_active, color: Colors.white, size: 24),
              SizedBox(width: 10),
              Text('Izin Notifikasi',
                style: TextStyle(color: Colors.white,
                  fontSize: 16, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Izinkan TugasKu mengirim notifikasi agar kamu tidak pernah melewatkan deadline!',
            style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.check_circle_outline, size: 18),
              label: const Text('Berikan Izin Notifikasi',
                style: TextStyle(fontWeight: FontWeight.w700)),
              onPressed: () async {
                final granted = await provider.requestNotificationPermission();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(granted
                      ? '✅ Izin diberikan!'
                      : '❌ Izin ditolak. Aktifkan di Pengaturan HP.'),
                    backgroundColor: granted ? AppTheme.success : AppTheme.danger,
                  ));
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainToggleCard(TaskProvider provider) {
    return _buildCard(
      '🔔 Notifikasi Tugas',
      [
        SwitchListTile(
          value: provider.notifEnabled,
          onChanged: (v) async {
            await provider.setNotifEnabled(v);
            await _loadPendingCount();
          },
          activeColor: AppTheme.primary,
          title: const Text('Aktifkan Notifikasi',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          subtitle: Text(provider.notifEnabled
            ? 'Notifikasi deadline aktif'
            : 'Semua notifikasi dimatikan',
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildDeadlineNotifCard() {
    return _buildCard('📅 Notifikasi Deadline', [
      _buildNotifRow(
        icon: Icons.notifications,
        iconColor: AppTheme.success,
        title: 'H-3 Hari',
        subtitle: 'Pengingat 3 hari sebelum deadline',
      ),
      const Divider(height: 16),
      _buildNotifRow(
        icon: Icons.notifications,
        iconColor: AppTheme.warning,
        title: 'H-1 Hari',
        subtitle: 'Pengingat 1 hari (24 jam) sebelum deadline',
      ),
      const Divider(height: 16),
      _buildNotifRow(
        icon: Icons.notifications_active,
        iconColor: AppTheme.danger,
        title: 'H-3 Jam',
        subtitle: 'Notifikasi darurat 3 jam sebelum deadline',
      ),
      const Divider(height: 16),
      _buildNotifRow(
        icon: Icons.alarm,
        iconColor: Colors.red.shade900,
        title: 'Tepat Deadline',
        subtitle: 'Notifikasi saat waktu deadline tiba',
      ),
    ]);
  }

  Widget _buildDailyReminderCard(TaskProvider provider) {
    return _buildCard('⏰ Pengingat Harian', [
      SwitchListTile(
        value: provider.dailyReminderEnabled,
        onChanged: (v) async {
          await provider.setDailyReminder(
            enabled: v,
            hour: provider.dailyReminderHour,
            minute: provider.dailyReminderMinute,
          );
          await _loadPendingCount();
        },
        activeColor: AppTheme.primary,
        title: const Text('Pengingat Pagi',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(
          provider.dailyReminderEnabled
            ? 'Aktif setiap hari pukul ${provider.dailyReminderHour.toString().padLeft(2, '0')}:${provider.dailyReminderMinute.toString().padLeft(2, '0')}'
            : 'Pengingat harian dimatikan',
          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        contentPadding: EdgeInsets.zero,
      ),
      if (provider.dailyReminderEnabled) ...[
        const Divider(height: 12),
        InkWell(
          onTap: () => _pickReminderTime(provider),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time, color: AppTheme.primary, size: 20),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Waktu Pengingat',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    Text(
                      '${provider.dailyReminderHour.toString().padLeft(2, '0')}:${provider.dailyReminderMinute.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w800,
                        color: AppTheme.primary)),
                  ],
                ),
                const Spacer(),
                const Icon(Icons.edit, color: AppTheme.textSecondary, size: 16),
              ],
            ),
          ),
        ),
      ],
    ]);
  }

  Future<void> _pickReminderTime(TaskProvider provider) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: provider.dailyReminderHour,
        minute: provider.dailyReminderMinute,
      ),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppTheme.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      await provider.setDailyReminder(
        enabled: true,
        hour: picked.hour,
        minute: picked.minute,
      );
      await _loadPendingCount();
    }
  }

  Widget _buildStatusCard() {
    return _buildCard('📊 Status Notifikasi', [
      Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.schedule, color: AppTheme.primary, size: 24),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$_pendingCount notifikasi terjadwal',
                style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary)),
              const Text('menunggu untuk dikirim',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.primary),
            onPressed: _loadPendingCount,
          ),
        ],
      ),
    ]);
  }

  Widget _buildLegendCard() {
    return _buildCard('ℹ️ Cara Kerja Notifikasi', [
      const Text(
        'Notifikasi dijadwalkan secara otomatis saat kamu menambah atau mengedit tugas. Notifikasi akan dikirim berdasarkan deadline yang kamu set.',
        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.5),
      ),
      const SizedBox(height: 10),
      _buildTip('💡', 'Notifikasi tetap berfungsi saat aplikasi ditutup'),
      _buildTip('📱', 'Pastikan mode hemat baterai tidak memblokir notifikasi'),
      _buildTip('🔕', 'Notifikasi tugas yang selesai akan otomatis dibatalkan'),
    ]);
  }

  Widget _buildTip(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary))),
        ],
      ),
    );
  }

  Widget _buildCard(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          const Divider(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildNotifRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            Text(subtitle, style: const TextStyle(
              fontSize: 11, color: AppTheme.textSecondary)),
          ],
        ),
        const Spacer(),
        const Icon(Icons.check_circle, color: AppTheme.success, size: 16),
      ],
    );
  }
}
