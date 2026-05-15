import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/task_model.dart';
import '../services/task_provider.dart';
import '../utils/app_assets.dart';
import '../utils/app_theme.dart';
import '../widgets/task_card_widget.dart';
import 'add_edit_task_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _visibleMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Kalender Tugas'),
        backgroundColor: AppTheme.accent,
      ),
      body: Consumer<TaskProvider>(
        builder: (context, provider, _) {
          final selectedTasks = _tasksForDate(provider.tasks, _selectedDate);

          return Column(
            children: [
              _buildMonthHeader(),
              _buildCalendar(provider.tasks),
              Expanded(
                child: selectedTasks.isEmpty
                    ? _buildEmptyDay()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                        itemCount: selectedTasks.length,
                        itemBuilder: (context, index) {
                          final task = selectedTasks[index];
                          return TaskCardWidget(
                            task: task,
                            showRanking: true,
                            totalActiveTasks: provider.activeTasks.length,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AddEditTaskScreen(task: task),
                              ),
                            ),
                            onStatusChange: (status) =>
                                provider.updateStatus(task.id, status),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddEditTaskScreen()),
        ),
        backgroundColor: AppTheme.accent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildMonthHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Bulan sebelumnya',
            onPressed: () => setState(() {
              _visibleMonth = DateTime(
                _visibleMonth.year,
                _visibleMonth.month - 1,
              );
            }),
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  DateFormat('MMMM yyyy', 'id_ID').format(_visibleMonth),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  DateFormat(
                    'EEEE, d MMMM yyyy',
                    'id_ID',
                  ).format(_selectedDate),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Bulan berikutnya',
            onPressed: () => setState(() {
              _visibleMonth = DateTime(
                _visibleMonth.year,
                _visibleMonth.month + 1,
              );
            }),
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar(List<Task> tasks) {
    final days = _calendarDays(_visibleMonth);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      child: Column(
        children: [
          Row(
            children: const ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min']
                .map(
                  (day) => Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: days.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
            ),
            itemBuilder: (context, index) {
              final date = days[index];
              final isCurrentMonth = date.month == _visibleMonth.month;
              final isSelected = _isSameDay(date, _selectedDate);
              final isToday = _isSameDay(date, DateTime.now());
              final dayTasks = _tasksForDate(tasks, date);
              final hasOverdue = dayTasks.any((task) => task.isOverdue);

              return InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => setState(() => _selectedDate = date),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.accent
                        : isToday
                            ? AppTheme.accent.withValues(alpha: 0.1)
                            : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.accent
                          : isToday
                              ? AppTheme.accent.withValues(alpha: 0.5)
                              : AppTheme.border,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${date.day}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected || isToday
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : isCurrentMonth
                                  ? AppTheme.textPrimary
                                  : AppTheme.textSecondary
                                      .withValues(alpha: 0.45),
                        ),
                      ),
                      const SizedBox(height: 4),
                      _buildDayMarker(dayTasks.length, hasOverdue, isSelected),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDayMarker(int count, bool hasOverdue, bool isSelected) {
    if (count == 0) return const SizedBox(height: 16);

    final color = isSelected
        ? Colors.white
        : hasOverdue
            ? AppTheme.danger
            : AppTheme.warning;

    return Container(
      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isSelected ? 0.24 : 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Center(
        child: Text(
          '$count',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyDay() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(AppAssets.emptyCalendar, width: 180, height: 135),
            const SizedBox(height: 14),
            Text(
              'Tidak ada deadline pada ${DateFormat('d MMMM yyyy', 'id_ID').format(_selectedDate)}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Pilih tanggal lain atau tambah tugas baru.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  List<DateTime> _calendarDays(DateTime month) {
    final firstDay = DateTime(month.year, month.month);
    final startOffset = firstDay.weekday - DateTime.monday;
    final firstGridDay = firstDay.subtract(Duration(days: startOffset));

    return List.generate(42, (index) {
      return DateTime(
        firstGridDay.year,
        firstGridDay.month,
        firstGridDay.day + index,
      );
    });
  }

  List<Task> _tasksForDate(List<Task> tasks, DateTime date) {
    final result =
        tasks.where((task) => _isSameDay(task.deadline, date)).toList();
    result.sort((a, b) => a.deadline.compareTo(b.deadline));
    return result;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
