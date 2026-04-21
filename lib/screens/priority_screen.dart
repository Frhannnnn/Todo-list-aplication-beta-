// lib/screens/priority_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/task_provider.dart';
import '../models/task_model.dart';
import '../utils/app_theme.dart';

class PriorityScreen extends StatelessWidget {
  const PriorityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('🧠 Prioritas Tugas (SAW)'),
        backgroundColor: AppTheme.secondary,
      ),
      body: Consumer<TaskProvider>(
        builder: (context, provider, _) {
          final tasks = provider.prioritizedTasks;

          return Column(
            children: [
              _buildSAWInfo(),
              _buildBobotsCard(),
              Expanded(
                child: tasks.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                      itemCount: tasks.length,
                      itemBuilder: (context, i) =>
                        _buildRankingCard(tasks[i], tasks.length),
                    ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSAWInfo() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.secondary, Color(0xFF6D28D9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: Colors.white, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Metode SAW menghitung prioritas berdasarkan bobot kepentingan, urgensi, deadline, dan estimasi waktu.',
              style: TextStyle(color: Colors.white, fontSize: 12, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBobotsCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Bobot Kriteria SAW',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary)),
          const SizedBox(height: 10),
          Row(
            children: [
              _bobotChip('Urgensi', '35%', AppTheme.danger),
              const SizedBox(width: 6),
              _bobotChip('Kepentingan', '30%', AppTheme.warning),
              const SizedBox(width: 6),
              _bobotChip('Deadline', '25%', AppTheme.primary),
              const SizedBox(width: 6),
              _bobotChip('Waktu', '10%', AppTheme.success),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bobotChip(String label, String bobot, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(bobot, style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w800, color: color)),
            Text(label, style: TextStyle(
              fontSize: 9, color: color.withOpacity(0.8))),
          ],
        ),
      ),
    );
  }

  Widget _buildRankingCard(Task task, int total) {
    final isTop = task.ranking == 1;
    final prioritasColor = AppTheme.getPrioritasColor(task.ranking, total);
    final prioritasLabel = AppTheme.getPrioritasLabel(task.ranking, total);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isTop ? AppTheme.danger : AppTheme.border,
          width: isTop ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Ranking Badge
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: prioritasColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: prioritasColor.withOpacity(0.4)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (task.ranking == 1)
                    const Text('🏆', style: TextStyle(fontSize: 16))
                  else if (task.ranking == 2)
                    const Text('🥈', style: TextStyle(fontSize: 16))
                  else if (task.ranking == 3)
                    const Text('🥉', style: TextStyle(fontSize: 16))
                  else
                    Text('#${task.ranking}',
                      style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w800,
                        color: prioritasColor)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Task Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(task.namaTugas,
                    style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(task.mataKuliah,
                    style: const TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary)),
                  const SizedBox(height: 6),
                  // SAW Score bar
                  Row(
                    children: [
                      const Text('Skor: ',
                        style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: task.sawScore.clamp(0, 1),
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation(prioritasColor),
                          borderRadius: BorderRadius.circular(4),
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(task.sawScore.toStringAsFixed(3),
                        style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w700,
                          color: prioritasColor)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Priority badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: prioritasColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: prioritasColor.withOpacity(0.4)),
              ),
              child: Text(prioritasLabel,
                style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w700,
                  color: prioritasColor)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('🧠', style: TextStyle(fontSize: 60)),
          SizedBox(height: 16),
          Text('Belum ada tugas untuk diprioritaskan',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary)),
          SizedBox(height: 8),
          Text('Tambahkan tugas terlebih dahulu',
            style: TextStyle(color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}
