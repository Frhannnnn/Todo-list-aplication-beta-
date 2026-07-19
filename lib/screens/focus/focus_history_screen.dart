// lib/screens/focus/focus_history_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/focus_session_model.dart';
import '../../services/focus_session_provider.dart';
import '../../utils/app_theme.dart';

/// Halaman riwayat Focus Session.
class FocusHistoryScreen extends StatelessWidget {
  const FocusHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Riwayat Focus Session'),
        backgroundColor: Colors.transparent,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: FutureBuilder<List<FocusHistoryEntry>>(
        future: context.read<FocusSessionProvider>().loadHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data ?? const <FocusHistoryEntry>[];
          if (items.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Belum ada riwayat sesi fokus.',
                    style: TextStyle(color: AppTheme.textSecondary)),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: items.length,
            itemBuilder: (context, i) => _card(items[i]),
          );
        },
      ),
    );
  }

  Widget _card(FocusHistoryEntry e) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(e.taskName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary)),
              ),
              const SizedBox(width: 8),
              _statusBadge(e.targetStatus),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            DateFormat('d MMM yyyy • HH:mm', 'id_ID').format(e.date),
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _chip('${e.focusMinutes} menit'),
              _chip('${e.sessionsCompleted} sesi'),
              _chip('Mode ${e.mode.label}'),
            ],
          ),
          if (e.targetText != null) ...[
            const SizedBox(height: 8),
            Text('Target: ${e.targetText}',
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textSecondary)),
          ],
        ],
      ),
    );
  }

  Widget _chip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.primary)),
    );
  }

  Widget _statusBadge(SessionTargetStatus? status) {
    final (label, color) = switch (status) {
      SessionTargetStatus.achieved => ('Tercapai', AppTheme.success),
      SessionTargetStatus.partial => ('Sebagian', AppTheme.warning),
      SessionTargetStatus.notAchieved => ('Belum', AppTheme.danger),
      null => ('—', AppTheme.textSecondary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }
}
