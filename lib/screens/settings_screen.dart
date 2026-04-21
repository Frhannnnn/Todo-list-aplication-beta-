// lib/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/task_provider.dart';
import '../utils/app_theme.dart';
import 'notification_settings_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('⚙️ Pengaturan'),
        backgroundColor: AppTheme.primary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildProfileCard(),
          const SizedBox(height: 16),
          _buildInfoCard(context),
          const SizedBox(height: 16),
          _buildNotifCard(context),
          const SizedBox(height: 16),
          _buildSAWInfoCard(),
          const SizedBox(height: 16),
          _buildDangerZone(context),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, AppTheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white24,
            child: Text('👨‍🎓', style: TextStyle(fontSize: 28)),
          ),
          SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('TugasKu', style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
              Text('Aplikasi Manajemen Tugas Mahasiswa',
                style: TextStyle(color: Colors.white70, fontSize: 12)),
              SizedBox(height: 4),
              Text('Versi 1.0.0', style: TextStyle(
                color: Colors.white60, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, provider, _) {
        return _buildCard('📊 Statistik', [
          _buildStatRow('Total Tugas', '${provider.totalTugas}'),
          _buildStatRow('Tugas Aktif', '${provider.tugasAktif}'),
          _buildStatRow('Tugas Selesai', '${provider.tugasSelesai}'),
          _buildStatRow('Tugas Terlambat', '${provider.overdueTasks.length}'),
          _buildStatRow('Persentase Selesai',
            '${provider.persentaseSelesai.toStringAsFixed(1)}%'),
        ]);
      },
    );
  }

  Widget _buildNotifCard(BuildContext context) {
    return Consumer<TaskProvider>(builder: (ctx, provider, _) {
      return _buildCard('🔔 Notifikasi', [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.notifications_active, color: AppTheme.primary, size: 22),
          ),
          title: const Text('Pengaturan Notifikasi',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          subtitle: Text(
            provider.notifEnabled ? '✅ Notifikasi aktif' : '🔕 Notifikasi dimatikan',
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
          onTap: () => Navigator.push(ctx,
            MaterialPageRoute(builder: (_) => const NotificationSettingsScreen())),
        ),
      ]);
    });
  }

  Widget _buildSAWInfoCard() {
    return _buildCard('🧠 Tentang Metode SAW', [
      const Text(
        'Simple Additive Weighting (SAW) adalah metode pengambilan keputusan multi-kriteria yang menghitung nilai bobot untuk setiap kriteria, lalu menjumlahkan semua nilai terbobot untuk mendapatkan nilai preferensi akhir.',
        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.5),
      ),
      const SizedBox(height: 12),
      const Text('Bobot yang digunakan:', style: TextStyle(
        fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
      const SizedBox(height: 6),
      _buildKriteriaRow('Tingkat Urgensi', '35%', AppTheme.danger),
      _buildKriteriaRow('Tingkat Kepentingan', '30%', AppTheme.warning),
      _buildKriteriaRow('Kedekatan Deadline', '25%', AppTheme.primary),
      _buildKriteriaRow('Estimasi Waktu', '10%', AppTheme.success),
    ]);
  }

  Widget _buildDangerZone(BuildContext context) {
    return _buildCard('⚠️ Zona Bahaya', [
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.danger,
            side: const BorderSide(color: AppTheme.danger),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          ),
          icon: const Icon(Icons.delete_forever),
          label: const Text('Hapus Semua Tugas'),
          onPressed: () => _confirmClearAll(context),
        ),
      ),
    ]);
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

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(
            fontSize: 13, color: AppTheme.textSecondary)),
          Text(value, style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildKriteriaRow(String label, String bobot, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(width: 10, height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary))),
          Text(bobot, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  void _confirmClearAll(BuildContext context) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Hapus Semua Tugas'),
        content: const Text('Semua data tugas akan dihapus permanen. Lanjutkan?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () {
              context.read<TaskProvider>().clearAllTasks();
              Navigator.pop(c);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Semua tugas telah dihapus'),
                  backgroundColor: AppTheme.danger));
            },
            child: const Text('Hapus Semua'),
          ),
        ],
      ),
    );
  }
}
