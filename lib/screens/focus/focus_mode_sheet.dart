// lib/screens/focus/focus_mode_sheet.dart

import 'package:flutter/material.dart';
import '../../models/focus_session_model.dart';
import '../../utils/app_theme.dart';
import 'focus_custom_sheet.dart';

/// Hasil pemilihan pada [showFocusModeSheet]. Untuk mode non-Kustom, `cycles`
/// diabaikan (pemanggil memakai rekomendasi SAW) dan `autoAdvance` false.
typedef FocusModeSelection = ({
  FocusMode mode,
  FocusPreset preset,
  int cycles,
  bool autoAdvance,
  FocusOptions options,
});

/// Bottom sheet pemilihan mode & preset (atau konfigurasi Kustom) sebelum
/// memulai sesi fokus. Mengembalikan pilihan, atau null bila dibatalkan.
Future<FocusModeSelection?> showFocusModeSheet(BuildContext context) {
  return showModalBottomSheet<FocusModeSelection>(
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

  bool get _isCustom => _mode == FocusMode.custom;

  Future<void> _openCustom() async {
    final cfg = await showFocusCustomSheet(context);
    if (cfg == null || !mounted) return;
    Navigator.pop(context, (
      mode: FocusMode.custom,
      preset: cfg.preset,
      cycles: cfg.cycles,
      autoAdvance: cfg.autoAdvance,
      options: cfg.options,
    ));
  }

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
            const SizedBox(height: 18),
            const Text('Mode', style: _sectionLabel),
            const SizedBox(height: 8),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  const SizedBox(width: 10),
                  Expanded(
                    child: _modeCard(FocusMode.custom, Icons.build_rounded,
                        'Atur sendiri'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (_isCustom) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _openCustom,
                  child: const Text('Atur Kustom'),
                ),
              ),
            ] else ...[
              const Text('Preset', style: _sectionLabel),
              const SizedBox(height: 8),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: kFocusPresets
                      .map((p) => Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 3),
                              child: _presetChip(p),
                            ),
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, (
                    mode: _mode,
                    preset: _preset,
                    cycles: 0,
                    autoAdvance: false,
                    options: FocusOptions(
                        lockNavigation: _mode == FocusMode.focus),
                  )),
                  child: const Text('Lanjut'),
                ),
              ),
            ],
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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primary.withValues(alpha: 0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: selected ? AppTheme.primary : AppTheme.border,
              width: selected ? 1.5 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon,
                color: selected ? AppTheme.primary : AppTheme.textSecondary,
                size: 22),
            const SizedBox(height: 8),
            Text(mode.label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: selected ? AppTheme.primary : AppTheme.textPrimary)),
            const SizedBox(height: 2),
            Text(subtitle,
                style: const TextStyle(
                    fontSize: 10, color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _presetChip(FocusPreset preset) {
    final selected = _preset.name == preset.name;
    return InkWell(
      onTap: () => setState(() => _preset = preset),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primary.withValues(alpha: 0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected ? AppTheme.primary : AppTheme.border,
              width: selected ? 1.5 : 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(preset.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color:
                        selected ? AppTheme.primary : AppTheme.textPrimary)),
            const SizedBox(height: 3),
            Text('${preset.focusMinutes}/${preset.breakMinutes}m',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 10,
                    color: selected
                        ? AppTheme.primary.withValues(alpha: 0.8)
                        : AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }
}

const TextStyle _sectionLabel = TextStyle(
    fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary);
