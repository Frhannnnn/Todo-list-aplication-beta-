// lib/screens/schedule_screen.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/task_model.dart';
import '../models/time_block_model.dart';
import '../models/schedule_config_model.dart';
import '../services/task_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/conflict_notification_banner.dart';

/// Category color mapping for TimeBlocks.
/// Each task category (String-based) has a distinct color for visual identification.
class ScheduleColors {
  static const Color kuliah = Color(0xFF3B82F6); // Blue
  static const Color praktikum = Color(0xFF10B981); // Green
  static const Color project = Color(0xFF8B5CF6); // Purple
  static const Color lainnya = Color(0xFF6B7280); // Gray

  /// Returns the color for a given category string.
  static Color forCategory(String category) {
    switch (category.toLowerCase()) {
      case 'kuliah':
        return kuliah;
      case 'praktikum':
        return praktikum;
      case 'proyek':
      case 'project':
        return project;
      default:
        return lainnya;
    }
  }
}

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  late PageController _pageController;
  late DateTime _selectedDate;

  // We use a reference date (today) and page index offset to allow swiping
  static const int _initialPage = 500;
  late DateTime _referenceDate;

  // Current time indicator timer
  Timer? _currentTimeTimer;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _referenceDate = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    _selectedDate = _referenceDate;
    _pageController = PageController(initialPage: _initialPage);

    // Start timer to update current time indicator every 60 seconds
    // Bug #2 Fix: Prevent multiple timers and handle mounted check
    _startCurrentTimeTimer();
  }

  void _startCurrentTimeTimer() {
    // Cancel existing timer if any to prevent memory leak
    _currentTimeTimer?.cancel();
    
    _currentTimeTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      // Bug #2 Fix: Check mounted before setState to prevent error after dispose
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    // Bug #2 Fix: Properly cancel and nullify timer
    _currentTimeTimer?.cancel();
    _currentTimeTimer = null;
    _pageController.dispose();
    super.dispose();
  }

  DateTime _dateForPage(int pageIndex) {
    final offset = pageIndex - _initialPage;
    return _referenceDate.add(Duration(days: offset));
  }

  int _pageForDate(DateTime date) {
    final offset = date.difference(_referenceDate).inDays;
    return _initialPage + offset;
  }

  void _goToDate(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
    _pageController.animateToPage(
      _pageForDate(date),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _goToPreviousDay() {
    _goToDate(_selectedDate.subtract(const Duration(days: 1)));
  }

  void _goToNextDay() {
    _goToDate(_selectedDate.add(const Duration(days: 1)));
  }

  /// Checks if the selected date is today (for showing current time indicator).
  bool _isDateToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildDateNavigation(),
            const ConflictNotificationBanner(),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (pageIndex) {
                  setState(() {
                    _selectedDate = _dateForPage(pageIndex);
                  });
                },
                itemBuilder: (context, pageIndex) {
                  final date = _dateForPage(pageIndex);
                  return _buildDayTimeline(date);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Jadwal',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          GestureDetector(
            onTap: () => _goToDate(DateTime(
              DateTime.now().year,
              DateTime.now().month,
              DateTime.now().day,
            )),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.border),
              ),
              child: const Icon(
                Icons.today_rounded,
                color: AppTheme.textSecondary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateNavigation() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: _goToPreviousDay,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.border),
              ),
              child: const Icon(Icons.chevron_left_rounded, size: 20),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                _formatDateLabel(_selectedDate),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: _goToNextDay,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.border),
              ),
              child: const Icon(Icons.chevron_right_rounded, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final yesterday = today.subtract(const Duration(days: 1));

    if (date.isAtSameMomentAs(today)) {
      return 'Hari Ini — ${DateFormat('d MMMM yyyy', 'id_ID').format(date)}';
    } else if (date.isAtSameMomentAs(tomorrow)) {
      return 'Besok — ${DateFormat('d MMMM yyyy', 'id_ID').format(date)}';
    } else if (date.isAtSameMomentAs(yesterday)) {
      return 'Kemarin — ${DateFormat('d MMMM yyyy', 'id_ID').format(date)}';
    }
    return DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(date);
  }

  Widget _buildDayTimeline(DateTime date) {
    return Consumer<TaskProvider>(
      builder: (context, provider, _) {
        final blocks = provider.getTimeBlocksForDate(date);
        final config = provider.scheduleConfig;

        if (blocks.isEmpty) {
          return _buildEmptyState();
        }

        // Bug #4 Fix: Filter blocks dengan valid task dan cleanup invalid blocks
        final validBlocks = blocks.where((block) {
          return provider.tasks.any((t) => t.id == block.taskId);
        }).toList();
        
        // Cleanup invalid blocks (task sudah dihapus)
        final invalidBlocks = blocks.where((b) => !validBlocks.contains(b)).toList();
        for (final invalid in invalidBlocks) {
          provider.deleteTimeBlock(invalid.id);
        }
        
        if (validBlocks.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: 24,
          itemBuilder: (context, hour) {
            final slotBlocks =
                validBlocks.where((b) => b.startTime.hour == hour).toList();
            return _buildHourSlot(hour, date, slotBlocks, provider, config);
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_available_rounded,
              size: 64,
              color: AppTheme.textSecondary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            const Text(
              'Belum ada jadwal untuk hari ini',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tambahkan tugas dengan deadline untuk melihat jadwal otomatis.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHourSlot(
    int hour,
    DateTime date,
    List<TimeBlock> slotBlocks,
    TaskProvider provider,
    ScheduleConfig config,
  ) {
    final timeLabel = '${hour.toString().padLeft(2, '0')}:00';
    final slotDateTime = DateTime(date.year, date.month, date.day, hour);

    // Determine if this slot is within Primary Work Hours
    final isWithinPWH = config.isWithinWorkHours(slotDateTime);

    // Background color: PWH slots are brighter, non-PWH are dimmer
    final slotBackgroundColor = isWithinPWH
        ? Colors.white
        : const Color(0xFFF3F4F6); // Slightly dimmer for non-PWH

    // Check if current time indicator should be shown in this slot
    final showCurrentTimeIndicator =
        _isDateToday(date) && _currentTime.hour == hour;

    return DragTarget<TimeBlock>(
      onWillAcceptWithDetails: (details) {
        // Accept if the block is being dragged to a different slot
        return details.data.startTime != slotDateTime;
      },
      onAcceptWithDetails: (details) {
        _handleBlockDrop(details.data, slotDateTime, provider);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;

        return Stack(
          children: [
            Container(
              constraints: const BoxConstraints(minHeight: 60),
              decoration: BoxDecoration(
                color: isHovered
                    ? AppTheme.primary.withValues(alpha: 0.08)
                    : slotBackgroundColor,
                border: Border(
                  bottom: BorderSide(
                    color: AppTheme.border.withValues(alpha: 0.5),
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hour label with PWH indicator
                  SizedBox(
                    width: 52,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          // PWH indicator dot
                          Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.only(right: 4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isWithinPWH
                                  ? AppTheme.primary.withValues(alpha: 0.7)
                                  : Colors.transparent,
                            ),
                          ),
                          Text(
                            timeLabel,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isWithinPWH
                                  ? AppTheme.textPrimary
                                  : AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Block content
                  Expanded(
                    child: slotBlocks.isEmpty
                        ? _buildEmptySlotContent(isWithinPWH, isHovered)
                        : Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Column(
                              children: slotBlocks
                                  .map((block) =>
                                      _buildDraggableTimeBlockCard(
                                          block, provider))
                                  .toList(),
                            ),
                          ),
                  ),
                ],
              ),
            ),
            // Current time indicator
            if (showCurrentTimeIndicator) _buildCurrentTimeIndicator(),
          ],
        );
      },
    );
  }

  /// Builds content for empty slots.
  /// PWH empty slots show a faint dashed border area for visual distinction.
  /// When hovered during drag, shows "drop here" indicator.
  Widget _buildEmptySlotContent(bool isWithinPWH, bool isHovered) {
    if (isHovered) {
      return SizedBox(
        height: 60,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              border: Border.all(
                color: AppTheme.primary.withValues(alpha: 0.4),
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'Lepaskan di sini',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      );
    }

    // Empty slot with subtle PWH indicator
    return SizedBox(
      height: 60,
      child: isWithinPWH
          ? Center(
              child: Container(
                height: 40,
                margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.08),
                    width: 1,
                  ),
                ),
              ),
            )
          : null,
    );
  }

  /// Builds the current time indicator — a red horizontal line at the
  /// proportional position within the current hour slot.
  /// Updated every 60 seconds via Timer.
  Widget _buildCurrentTimeIndicator() {
    // Calculate vertical position within the 60px slot based on current minute
    final minuteFraction = _currentTime.minute / 60.0;
    final topOffset = minuteFraction * 60.0;

    return Positioned(
      top: topOffset,
      left: 0,
      right: 0,
      child: Row(
        children: [
          // Red circle at the left edge
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFFEF4444),
              shape: BoxShape.circle,
            ),
          ),
          // Red line spanning the width
          Expanded(
            child: Container(
              height: 2,
              color: const Color(0xFFEF4444),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDraggableTimeBlockCard(TimeBlock block, TaskProvider provider) {
    final card = _buildTimeBlockCard(block, provider);

    return LongPressDraggable<TimeBlock>(
      data: block,
      feedback: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: MediaQuery.of(context).size.width - 100,
          child: card,
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: card,
      ),
      child: card,
    );
  }

  Widget _buildTimeBlockCard(TimeBlock block, TaskProvider provider) {
    // Look up task from provider's tasks list
    final matchingTasks = provider.tasks.where((t) => t.id == block.taskId);
    final task = matchingTasks.isNotEmpty ? matchingTasks.first : null;
    final taskName = task?.namaTugas ?? 'Tugas tidak ditemukan';
    final startLabel = DateFormat('HH:mm').format(block.startTime);
    final endLabel = DateFormat('HH:mm').format(block.endTime);

    // Determine category color
    final categoryColor = task != null
        ? ScheduleColors.forCategory(task.category)
        : ScheduleColors.lainnya;

    // Determine if block is missed
    final isMissed = block.status == TimeBlockStatus.missed;

    // Opacity: missed blocks are dimmed
    final blockOpacity = isMissed ? 0.5 : 1.0;

    return GestureDetector(
      onTap: () => _showTimeBlockDetail(block, task, provider),
      child: Opacity(
        opacity: blockOpacity,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          margin: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(
            color: categoryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: categoryColor.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            children: [
              // Category color bar on the left
              Container(
                width: 4,
                height: 36,
                decoration: BoxDecoration(
                  color: categoryColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              // Task info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      taskName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                        // Strikethrough for missed blocks
                        decoration: isMissed
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        decorationColor: AppTheme.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          '$startLabel - $endLabel',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                            decoration: isMissed
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                            decorationColor: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Category label chip
                        if (task != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: categoryColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              task.categoryLabel,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: categoryColor,
                              ),
                            ),
                          ),
                        // Missed indicator badge
                        if (isMissed) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppTheme.danger.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Terlewat',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.danger,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  /// Handles the drop of a TimeBlock onto a new slot.
  /// Calls moveTimeBlock and shows error SnackBar if the move fails.
  Future<void> _handleBlockDrop(
    TimeBlock block,
    DateTime newSlot,
    TaskProvider provider,
  ) async {
    final result = await provider.moveTimeBlock(block.id, newSlot);
    if (!result.success && result.error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error!),
          backgroundColor: AppTheme.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  /// Shows a bottom sheet with TimeBlock detail info:
  /// task name, mata kuliah, deadline, remaining unscheduled hours.
  void _showTimeBlockDetail(
    TimeBlock block,
    Task? task,
    TaskProvider provider,
  ) {
    // Calculate remaining unscheduled hours
    int remainingHours = 0;
    if (task != null) {
      final scheduledBlocks = provider.getTimeBlocksForTask(task.id).length;
      remainingHours = task.estimasiWaktu - scheduledBlocks;
      if (remainingHours < 0) remainingHours = 0;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Task name
              Text(
                task?.namaTugas ?? 'Tugas tidak ditemukan',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              // Mata kuliah / lingkup
              _buildDetailRow(
                Icons.label_rounded,
                'Lingkup Tugas',
                task?.lingkupTugas ?? '-',
              ),
              const SizedBox(height: 12),
              // Deadline
              _buildDetailRow(
                Icons.event_rounded,
                'Deadline',
                task != null
                    ? DateFormat('d MMMM yyyy, HH:mm', 'id_ID')
                        .format(task.deadline)
                    : '-',
              ),
              const SizedBox(height: 12),
              // Remaining unscheduled hours
              _buildDetailRow(
                Icons.hourglass_bottom_rounded,
                'Sisa Jam Belum Terjadwal',
                '$remainingHours jam',
              ),
              const SizedBox(height: 24),
              // Delete button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showDeleteConfirmation(block, task, provider);
                  },
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: const Text('Hapus Time Block'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.danger,
                    side: const BorderSide(color: AppTheme.danger),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.textSecondary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Performs the actual deletion and shows a success SnackBar.
  Future<void> _deleteTimeBlock(TimeBlock block, TaskProvider provider) async {
    await provider.deleteTimeBlock(block.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Time block berhasil dihapus'),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  /// Shows an AlertDialog to confirm TimeBlock deletion.
  void _showDeleteConfirmation(
    TimeBlock block,
    Task? task,
    TaskProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Hapus Time Block',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          content: Text(
            'Apakah Anda yakin ingin menghapus jadwal "${task?.namaTugas ?? 'ini'}" '
            'pada ${DateFormat('HH:mm').format(block.startTime)} - '
            '${DateFormat('HH:mm').format(block.endTime)}?',
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Batal',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteTimeBlock(block, provider);
              },
              child: const Text(
                'Hapus',
                style: TextStyle(
                  color: AppTheme.danger,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
