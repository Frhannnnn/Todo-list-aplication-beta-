// lib/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/task_provider.dart';
import '../utils/app_theme.dart';
import 'notification_settings_screen.dart';
import 'schedule_settings_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          children: [
            const Text(
              'Pengaturan',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            _buildProfileCard(),
            const SizedBox(height: 16),
            _buildInfoCard(context),
            const SizedBox(height: 16),
            _buildNotifCard(context),
            const SizedBox(height: 16),
            _buildScheduleSettingsCard(context),
            const SizedBox(height: 16),
            _buildSAWInfoCard(),
            const SizedBox(height: 16),
            _buildDangerZone(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppTheme.primary,
            AppTheme.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text('👨‍🎓', style: TextStyle(fontSize: 28)),
            ),
          ),
          const SizedBox(width: 16),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('TugasKu',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
              SizedBox(height: 2),
              Text('Manajemen Tugas Mahasiswa',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
              SizedBox(height: 4),
              Text('Versi 1.0.0',
                  style: TextStyle(color: Colors.white60, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, provider, _) {
        return _buildCard('Statistik', Icons.bar_chart_rounded, [
          _buildStatRow('Total Tugas', '${provider.totalTugas}', AppTheme.primary),
          _buildStatRow('Tugas Aktif', '${provider.tugasAktif}', AppTheme.warning),
          _buildStatRow('Tugas Selesai', '${provider.tugasSelesai}', AppTheme.success),
          _buildStatRow('Terlambat', '${provider.overdueTasks.length}', AppTheme.danger),
          _buildStatRow('Persentase',
              '${provider.persentaseSelesai.toStringAsFixed(1)}%', AppTheme.primary),
        ]);
      },
    );
  }

  Widget _buildNotifCard(BuildContext context) {
    return Consumer<TaskProvider>(builder: (ctx, provider, _) {
      return _buildCard('Notifikasi', Icons.notifications_rounded, [
        GestureDetector(
          onTap: () => Navigator.push(
            ctx,
            MaterialPageRoute(builder: (_) => const NotificationSettingsScreen()),
          ),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.notifications_active_rounded,
                      color: AppTheme.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Pengaturan Notifikasi',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600)),
                      Text(
                        provider.notifEnabled
                            ? 'Notifikasi aktif'
                            : 'Notifikasi dimatikan',
                        style: TextStyle(
                          fontSize: 12,
                          color: provider.notifEnabled
                              ? AppTheme.success
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: AppTheme.textSecondary),
              ],
            ),
          ),
        ),
      ]);
    });
  }

  Widget _buildScheduleSettingsCard(BuildContext context) {
    return Consumer<TaskProvider>(builder: (ctx, provider, _) {
      final config = provider.scheduleConfig;
      final startStr =
          '${config.workStartHour.toString().padLeft(2, '0')}:${config.workStartMinute.toString().padLeft(2, '0')}';
      final endStr =
          '${config.workEndHour.toString().padLeft(2, '0')}:${config.workEndMinute.toString().padLeft(2, '0')}';

      return _buildCard('Penjadwalan', Icons.schedule_rounded, [
        GestureDetector(
          onTap: () => Navigator.push(
            ctx,
            MaterialPageRoute(builder: (_) => const ScheduleSettingsScreen()),
          ),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.access_time_rounded,
                      color: AppTheme.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Primary Work Hours',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600)),
                      Text(
                        'Jam kerja: $startStr – $endStr',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: AppTheme.textSecondary),
              ],
            ),
          ),
        ),
      ]);
    });
  }

  Widget _buildSAWInfoCard() {
    return _buildCard('Metode SAW', Icons.psychology_rounded, [
      const Text(
        'Simple Additive Weighting (SAW) menghitung nilai bobot untuk setiap kriteria, lalu menjumlahkan semua nilai terbobot untuk mendapatkan nilai preferensi akhir.',
        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.5),
      ),
      const SizedBox(height: 14),
      const Text('Bobot Kriteria:',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
      const SizedBox(height: 8),
      _buildKriteriaRow('Tingkat Urgensi', '40%', AppTheme.danger),
      _buildKriteriaRow('Tingkat Kepentingan', '40%', AppTheme.warning),
      _buildKriteriaRow('Estimasi Waktu', '20%', AppTheme.success),
    ]);
  }

  Widget _buildDangerZone(BuildContext context) {
    return _buildCard('Zona Bahaya', Icons.warning_rounded, [
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.danger,
            side: const BorderSide(color: AppTheme.danger),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          icon: const Icon(Icons.delete_forever_rounded),
          label: const Text('Hapus Semua Tugas'),
          onPressed: () => _confirmClearAll(context),
        ),
      ),
    ]);
  }

  Widget _buildCard(String title, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppTheme.primary),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary)),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(value,
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: color)),
          ),
        ],
      ),
    );
  }

  Widget _buildKriteriaRow(String label, String bobot, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          ),
          Text(bobot,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  void _confirmClearAll(BuildContext context) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Semua Tugas'),
        content: const Text('Semua data tugas akan dihapus permanen. Lanjutkan?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () {
              context.read<TaskProvider>().clearAllTasks();
              Navigator.pop(c);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Semua tugas telah dihapus'),
                  backgroundColor: AppTheme.danger));
            },
            child: const Text('Hapus Semua'),
          ),
        ],
      ),
    );
  }
}
