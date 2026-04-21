// lib/screens/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/task_provider.dart';
import '../models/task_model.dart';
import '../utils/app_theme.dart';
import '../widgets/task_card_widget.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: AppTheme.background,
          body: CustomScrollView(
            slivers: [
              _buildHeader(context, provider),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatCards(provider),
                      const SizedBox(height: 20),
                      if (provider.overdueTasks.isNotEmpty) ...[
                        _buildSectionTitle('⚠️ Tugas Terlambat', AppTheme.danger),
                        const SizedBox(height: 8),
                        ...provider.overdueTasks.take(2).map(
                          (t) => TaskCardWidget(task: t, showRanking: false)),
                        const SizedBox(height: 20),
                      ],
                      _buildSectionTitle('📅 Deadline Terdekat', AppTheme.primary),
                      const SizedBox(height: 8),
                      _buildDeadlineTasks(provider),
                      const SizedBox(height: 20),
                      _buildSectionTitle('🏆 Prioritas Tertinggi', AppTheme.secondary),
                      const SizedBox(height: 8),
                      _buildPriorityTasks(provider),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, TaskProvider provider) {
    final now = DateTime.now();
    final greeting = now.hour < 12 ? 'Selamat Pagi' :
                     now.hour < 17 ? 'Selamat Siang' : 'Selamat Malam';
    return SliverAppBar(
      expandedHeight: 150,
      floating: false,
      pinned: true,
      backgroundColor: AppTheme.primary,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primary, AppTheme.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('👋 $greeting!',
                    style: const TextStyle(
                      color: Colors.white70, fontSize: 14)),
                  const Text('TugasKu',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    )),
                  Text(DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(now),
                    style: const TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCards(TaskProvider provider) {
    return Row(
      children: [
        _statCard('Total\nTugas', provider.totalTugas.toString(),
            AppTheme.primary, Icons.assignment_outlined),
        const SizedBox(width: 10),
        _statCard('Belum\nSelesai', provider.tugasAktif.toString(),
            AppTheme.warning, Icons.pending_actions_outlined),
        const SizedBox(width: 10),
        _statCard('Selesai', provider.tugasSelesai.toString(),
            AppTheme.success, Icons.check_circle_outline),
        const SizedBox(width: 10),
        _statCard('Terlambat', provider.overdueTasks.length.toString(),
            AppTheme.danger, Icons.warning_amber_outlined),
      ],
    );
  }

  Widget _statCard(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: color,
              )),
            Text(label,
              style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
              maxLines: 2),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Row(
      children: [
        Container(width: 4, height: 20,
          decoration: BoxDecoration(
            color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          )),
      ],
    );
  }

  Widget _buildDeadlineTasks(TaskProvider provider) {
    final tasks = provider.activeTasks
      ..sort((a, b) => a.deadline.compareTo(b.deadline));

    if (tasks.isEmpty) {
      return _buildEmptyState('Tidak ada tugas mendatang 🎉');
    }

    return Column(
      children: tasks.take(3).map(
        (t) => TaskCardWidget(task: t, showRanking: false)).toList(),
    );
  }

  Widget _buildPriorityTasks(TaskProvider provider) {
    final tasks = provider.prioritizedTasks;
    if (tasks.isEmpty) {
      return _buildEmptyState('Tidak ada tugas aktif 🎉');
    }
    return Column(
      children: tasks.take(3).map(
        (t) => TaskCardWidget(task: t, showRanking: true)).toList(),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          const Text('📭', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 8),
          Text(message,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
        ],
      ),
    );
  }
}
