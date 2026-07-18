// lib/screens/focus/focus_mode_sheet.dart

import 'package:flutter/material.dart';
import '../../models/focus_session_model.dart';
import '../../utils/app_theme.dart';

/// Bottom sheet pemilihan mode & preset sebelum memulai sesi fokus.
/// Mengembalikan pilihan mode + preset, atau null bila dibatalkan.
Future<({FocusMode mode, FocusPreset preset})?> showFocusModeSheet(
    BuildContext context) {
  return showModalBottomSheet<({FocusMode mode, FocusPreset preset})>(
    context: context,
    backgroundColor: Colors.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const _FocusModeSheet(),
  );
}

class _FocusModeSheet extends StatefulWidget {
  const _FocusModeSheet();

  @override
  State<_FocusModeSheet> createState() => _FocusModeSheetState();
}

class _FocusModeSheetState extends State<_FocusModeSheet> {
  FocusMode _mode = FocusMode.focus;
  FocusPreset _preset = kFocusPresets.first;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Mulai Sesi Fokus',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 4),
            const Text('Pilih mode & durasi sesi fokusmu.',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
            const SizedBox(height: 18),
            const Text('Mode', style: _sectionLabel),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _modeCard(FocusMode.focus,
                      Icons.center_focus_strong_rounded, 'Navigasi terkunci'),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _modeCard(FocusMode.flexible, Icons.tune_rounded,
                      'Bebas berpindah'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _customModeDisabled(),
            const SizedBox(height: 20),
            const Text('Preset', style: _sectionLabel),
            const SizedBox(height: 8),
            ...kFocusPresets.map(_presetTile),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () =>
                    Navigator.pop(context, (mode: _mode, preset: _preset)),
                child: const Text('Lanjut'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _modeCard(FocusMode mode, IconData icon, String subtitle) {
    final selected = _mode == mode;
    return InkWell(
      onTap: () => setState(() => _mode = mode),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primary.withValues(alpha: 0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: selected
                  ? AppTheme.primary
                  : AppTheme.border,
              width: selected ? 1.5 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon,
                color: selected ? AppTheme.primary : AppTheme.textSecondary,
                size: 24),
            const SizedBox(height: 8),
            Text(mode.label,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: selected ? AppTheme.primary : AppTheme.textPrimary)),
            const SizedBox(height: 2),
            Text(subtitle,
                style: const TextStyle(
                    fontSize: 11, color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _customModeDisabled() {
    return Opacity(
      opacity: 0.55,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.build_circle_outlined,
                color: AppTheme.textSecondary, size: 22),
            const SizedBox(width: 10),
            const Expanded(
              child: Text('Kustom',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary)),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.textSecondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Segera hadir',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _presetTile(FocusPreset preset) {
    final selected = _preset.name == preset.name;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => setState(() => _preset = preset),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? AppTheme.primary.withValues(alpha: 0.08)
                : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: selected ? AppTheme.primary : AppTheme.border,
                width: selected ? 1.5 : 1),
          ),
          child: Row(
            children: [
              Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: selected ? AppTheme.primary : AppTheme.textSecondary,
                  size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(preset.name,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary)),
              ),
              Text('${preset.focusMinutes} / ${preset.breakMinutes} menit',
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}

const TextStyle _sectionLabel = TextStyle(
    fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary);
