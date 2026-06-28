// lib/screens/schedule_settings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/schedule_config_model.dart';
import '../services/task_provider.dart';
import '../utils/app_theme.dart';

class ScheduleSettingsScreen extends StatefulWidget {
  const ScheduleSettingsScreen({super.key});

  @override
  State<ScheduleSettingsScreen> createState() => _ScheduleSettingsScreenState();
}

class _ScheduleSettingsScreenState extends State<ScheduleSettingsScreen> {
  late int _startHour;
  late int _startMinute;
  late int _endHour;
  late int _endMinute;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final config = context.read<TaskProvider>().scheduleConfig;
    _startHour = config.workStartHour;
    _startMinute = config.workStartMinute;
    _endHour = config.workEndHour;
    _endMinute = config.workEndMinute;
  }

  /// Calculates the duration in minutes between start and end,
  /// supporting cross-midnight configurations.
  int _calculateDurationMinutes() {
    final startMinutes = _startHour * 60 + _startMinute;
    final endMinutes = _endHour * 60 + _endMinute;

    if (endMinutes > startMinutes) {
      return endMinutes - startMinutes;
    } else if (endMinutes < startMinutes) {
      // Cross-midnight: e.g., 22:00–06:00 = (24*60 - 22*60) + 6*60 = 480 min
      return (24 * 60 - startMinutes) + endMinutes;
    } else {
      // start == end means 0 duration
      return 0;
    }
  }

  void _validate() {
    final duration = _calculateDurationMinutes();
    if (duration < 60) {
      setState(() {
        _errorMessage = 'Rentang jam kerja minimal 1 jam';
      });
    } else {
      setState(() {
        _errorMessage = null;
      });
    }
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _startHour, minute: _startMinute),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppTheme.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _startHour = picked.hour;
        _startMinute = picked.minute;
      });
      _validate();
    }
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _endHour, minute: _endMinute),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppTheme.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _endHour = picked.hour;
        _endMinute = picked.minute;
      });
      _validate();
    }
  }

  Future<void> _save() async {
    _validate();
    if (_errorMessage != null) return;

    final newConfig = ScheduleConfig(
      workStartHour: _startHour,
      workStartMinute: _startMinute,
      workEndHour: _endHour,
      workEndMinute: _endMinute,
    );

    final provider = context.read<TaskProvider>();
    await provider.updateScheduleConfig(newConfig);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Jam kerja berhasil disimpan. Jadwal diperbarui.'),
          backgroundColor: AppTheme.success,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  String _formatTime(int hour, int minute) {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  bool get _isCrossMidnight {
    final startMinutes = _startHour * 60 + _startMinute;
    final endMinutes = _endHour * 60 + _endMinute;
    return startMinutes > endMinutes ||
        (startMinutes == endMinutes && startMinutes > 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Jam Kerja Utama'),
        backgroundColor: Colors.transparent,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildInfoCard(),
          const SizedBox(height: 16),
          _buildTimePickerCard(),
          const SizedBox(height: 16),
          if (_isCrossMidnight) ...[
            _buildCrossMidnightInfo(),
            const SizedBox(height: 16),
          ],
          if (_errorMessage != null) ...[
            _buildErrorCard(),
            const SizedBox(height: 16),
          ],
          _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
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
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.schedule, color: Colors.white, size: 24),
              SizedBox(width: 10),
              Text(
                'Primary Work Hours',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Atur jam kerja utama kamu. Sistem akan memprioritaskan penjadwalan tugas pada rentang waktu ini. Slot di luar jam kerja tetap tersedia.',
            style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildTimePickerCard() {
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
          const Text(
            '⏰ Pengaturan Waktu',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const Divider(height: 16),
          _buildTimeTile(
            label: 'Jam Mulai',
            time: _formatTime(_startHour, _startMinute),
            icon: Icons.play_arrow_rounded,
            iconColor: AppTheme.success,
            onTap: _pickStartTime,
          ),
          const SizedBox(height: 12),
          _buildTimeTile(
            label: 'Jam Selesai',
            time: _formatTime(_endHour, _endMinute),
            icon: Icons.stop_rounded,
            iconColor: AppTheme.danger,
            onTap: _pickEndTime,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    color: AppTheme.textSecondary, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Durasi: ${_calculateDurationMinutes() ~/ 60} jam ${_calculateDurationMinutes() % 60 > 0 ? '${_calculateDurationMinutes() % 60} menit' : ''}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeTile({
    required String label,
    required String time,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: iconColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: iconColor,
                  ),
                ),
              ],
            ),
            const Spacer(),
            const Icon(Icons.edit, color: AppTheme.textSecondary, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildCrossMidnightInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.nightlight_round, color: AppTheme.warning, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Konfigurasi lintas tengah malam: ${_formatTime(_startHour, _startMinute)} → ${_formatTime(_endHour, _endMinute)} (melewati pukul 00:00)',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textPrimary,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.danger.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.danger.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppTheme.danger, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor:
              _errorMessage != null ? AppTheme.textSecondary : AppTheme.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: const Icon(Icons.save_rounded, size: 20),
        label: const Text(
          'Simpan',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        onPressed: _errorMessage != null ? null : _save,
      ),
    );
  }
}
