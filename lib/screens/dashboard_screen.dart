// lib/screens/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/task_model.dart';
import '../services/task_provider.dart';
import '../utils/app_theme.dart';
import '../utils/recurrence.dart';
import '../widgets/task_card_widget.dart';
import '../utils/task_status_actions.dart';
import '../utils/app_assets.dart';
import '../main.dart';
import 'add_edit_task/add_edit_task_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: AppTheme.background,
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeader(context)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                            const SizedBox(height: 16),
                        _buildSummaryCard(provider),
                        const SizedBox(height: 12),
                        _buildHariIniRow(provider),
                        const SizedBox(height: 12),
                        _buildFocusNowButton(context, provider),
                        _buildTaskCalendar(provider),
                        const SizedBox(height: 24),
                        _buildSectionHeader(
                          'Prioritas Teratas',
                          onSeeAll: provider.tasks.isEmpty
                              ? null
                              : () => MainNavigation.tabIndex.value =
                                  MainNavigation.taskListTab,
                        ),
                        const SizedBox(height: 10),
                        _buildTopPriorityTasks(context, provider),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Image.asset(
                    AppAssets.logo,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                        Icons.check_circle_rounded,
                        color: AppTheme.primary,
                        size: 24),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Priora',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: 1),
                  Text(
                    'Ringkasan hari ini',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddEditTaskScreen()),
            ),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.border),
              ),
              child: const Icon(Icons.add, color: AppTheme.textPrimary, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(TaskProvider provider) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));
    final weekTasks = provider.activeTasks.where((t) =>
        t.deadline.isAfter(weekStart) &&
        t.deadline.isBefore(weekEnd.add(const Duration(days: 1)))).length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.assignment_rounded, color: AppTheme.primary, size: 26),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tugas Kuliah',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Ringkasan Minggu Ini',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$weekTasks tugas',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Minggu Ini',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHariIniRow(TaskProvider provider) {
    final total = provider.totalTugas;
    final selesai = provider.tugasSelesai;
    final streak = provider.currentStreak;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline_rounded,
              color: AppTheme.primary, size: 18),
          const SizedBox(width: 6),
          Text(
            '$selesai/$total selesai',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(width: 16),
          Container(width: 1, height: 16, color: AppTheme.border),
          const SizedBox(width: 16),
          const Icon(Icons.local_fire_department_rounded,
              color: AppTheme.warning, size: 18),
          const SizedBox(width: 6),
          Text(
            '$streak hari',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCalendar(TaskProvider provider) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Minggu berjalan: Senin s/d Minggu yang memuat hari ini.
    final weekStart =
        today.subtract(Duration(days: today.weekday - DateTime.monday));
    final weekDays = List.generate(7, (i) => weekStart.add(Duration(days: i)));
    final weekEnd = DateTime(
        weekStart.year, weekStart.month, weekStart.day + 6, 23, 59);

    bool sameDay(DateTime a, DateTime b) =>
        a.year == b.year && a.month == b.month && a.day == b.day;

    // Tanggal dalam minggu ini yang punya occurrence tugas berulang.
    final previewDays = <DateTime>{};
    for (final t in provider.tasks) {
      if (t.recurrence == RecurrenceType.none ||
          t.status == TaskStatus.selesai) {
        continue;
      }
      for (final d in upcomingOccurrences(t, until: weekEnd)) {
        if (!d.isBefore(weekStart)) {
          previewDays.add(DateTime(d.year, d.month, d.day));
        }
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Kalender Tugas',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              InkWell(
                onTap: () =>
                    MainNavigation.tabIndex.value = MainNavigation.calendarTab,
                borderRadius: BorderRadius.circular(20),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Buka Kalender',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(Icons.chevron_right,
                          size: 16, color: AppTheme.primary),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: weekDays.map((date) {
              final isToday = sameDay(date, today);
              final dayTasks = provider.tasks
                  .where((t) => sameDay(t.deadline, date))
                  .toList();
              final hasTask = dayTasks.isNotEmpty;
              final hasOverdue = dayTasks.any((t) => t.isOverdue);
              final hasPreview = previewDays.contains(date);
              const weekdayLabels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    children: [
                      Text(
                        weekdayLabels[date.weekday - 1],
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Lingkaran simetris untuk tanggal.
                      Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isToday
                              ? AppTheme.primary
                              : hasTask
                                  ? AppTheme.primary.withValues(alpha: 0.08)
                                  : Colors.transparent,
                        ),
                        child: Text(
                          '${date.day}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isToday || hasTask
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isToday
                                ? Colors.white
                                : AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      // Penanda tugas/occurrence di bawah lingkaran; slot tetap
                      // agar semua tanggal sejajar.
                      SizedBox(
                        height: 6,
                        child: hasTask
                            ? Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: hasOverdue
                                      ? AppTheme.danger
                                      : AppTheme.primary,
                                ),
                              )
                            : (hasPreview
                                ? Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: AppTheme.primary, width: 1.2),
                                    ),
                                  )
                                : null),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Judul section dengan aksi "Lihat Semua" opsional di kanan.
  Widget _buildSectionHeader(String title, {VoidCallback? onSeeAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        if (onSeeAll != null)
          InkWell(
            onTap: onSeeAll,
            borderRadius: BorderRadius.circular(20),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Lihat Semua',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                  ),
                  SizedBox(width: 2),
                  Icon(Icons.chevron_right, size: 16, color: AppTheme.primary),
                ],
              ),
            ),
          ),
      ],
    );
  }

  /// Tugas aktif terurut prioritas SAW (peringkat terkecil dulu; tugas tanpa
  /// peringkat memakai deadline terdekat). Dipakai bersama oleh tombol
  /// "Fokus Sekarang" dan daftar "Prioritas Teratas".
  List<Task> _activeByPriority(TaskProvider provider) {
    return List.of(provider.activeTasks)
      ..sort((a, b) {
        if (a.ranking == 0 && b.ranking == 0) {
          return a.deadline.compareTo(b.deadline);
        }
        if (a.ranking == 0) return 1;
        if (b.ranking == 0) return -1;
        return a.ranking.compareTo(b.ranking);
      });
  }

  /// Aksi satu-ketuk: ambil tugas prioritas tertinggi lalu langsung buka alur
  /// Focus Session untuknya — menyatukan prioritas SAW + fokus jadi satu aksi
  /// tanpa pengguna perlu memilih tugas sendiri.
  Widget _buildFocusNowButton(BuildContext context, TaskProvider provider) {
    final tasks = _activeByPriority(provider);
    if (tasks.isEmpty) return const SizedBox.shrink();
    final top = tasks.first;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          handleStatusChange(
              context, provider, top, TaskStatus.sedangDikerjakan);
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primary, AppTheme.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.bolt_rounded,
                    color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Fokus Sekarang',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                    const SizedBox(height: 2),
                    Text('Mulai: ${top.namaTugas}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.white70)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.play_arrow_rounded,
                  color: Colors.white, size: 28),
            ],
          ),
        ),
      ),
    );
  }

  /// Tiga tugas paling prioritas (peringkat SAW terkecil). Ini inti nilai
  /// aplikasi: pengguna langsung tahu apa yang harus dikerjakan lebih dulu.
  Widget _buildTopPriorityTasks(BuildContext context, TaskProvider provider) {
    final tasks = _activeByPriority(provider);

    if (tasks.isEmpty) {
      // First-run (belum pernah ada tugas): tuntun buat tugas pertama langsung
      // dari Dashboard, karena inilah layar yang pertama dilihat pengguna.
      if (provider.tasks.isEmpty) {
        return _buildOnboardingCard(context);
      }
      // Ada tugas tapi semua selesai — beri apresiasi.
      return _buildEmptyState('Semua tugas selesai');
    }

    return Column(
      children: tasks
          .take(3)
          .map((t) => TaskCardWidget(
                task: t,
                showRanking: false,
                totalActiveTasks: provider.activeTasks.length,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => AddEditTaskScreen(task: t)),
                ),
              ))
          .toList(),
    );
  }

  /// Kartu penuntun untuk pengguna baru di Dashboard: jelas apa yang harus
  /// dilakukan pertama kali (buat tugas), tanpa harus menebak-nebak tab mana.
  Widget _buildOnboardingCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Image.asset(
            AppAssets.emptyTasks,
            width: 140,
            height: 105,
            errorBuilder: (_, __, ___) => const Icon(Icons.assignment_outlined,
                size: 44, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 14),
          const Text(
            'Mulai dari sini',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tambahkan tugas pertamamu, lalu Priora otomatis menyusun mana yang harus dikerjakan lebih dulu.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddEditTaskScreen()),
              ),
              icon: const Icon(Icons.add, size: 20),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              label: const Text('Buat Tugas Pertama',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Image.asset(
            AppAssets.emptyTasks,
            width: 120,
            height: 90,
            errorBuilder: (_, __, ___) => const Icon(Icons.inbox_outlined,
                size: 40, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 10),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
        ],
      ),
    );
  }
}
