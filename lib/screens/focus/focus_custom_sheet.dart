// lib/screens/focus/focus_custom_sheet.dart

import 'package:flutter/material.dart';
import '../../models/focus_session_model.dart';
import '../../utils/app_theme.dart';

/// Bottom sheet konfigurasi Mode Kustom. Mengembalikan preset kustom + jumlah
/// siklus + autoAdvance, atau null bila dibatalkan.
Future<({FocusPreset preset, int cycles, bool autoAdvance, FocusOptions options})?>
    showFocusCustomSheet(BuildContext context) {
  return showModalBottomSheet<
      ({FocusPreset preset, int cycles, bool autoAdvance, FocusOptions options})>(
    context: context,
    backgroundColor: Colors.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const _FocusCustomSheet(),
  );
}

class _FocusCustomSheet extends StatefulWidget {
  const _FocusCustomSheet();

  @override
  State<_FocusCustomSheet> createState() => _FocusCustomSheetState();
}

class _FocusCustomSheetState extends State<_FocusCustomSheet> {
  int _focus = 25;
  int _break = 5;
  int _cycles = 4;
  bool _auto = false;
  bool _keepScreenOn = false;
  bool _lockNavigation = false;
  bool _strictMode = false;
  bool _alarm = false;
  bool _vibrate = false;
  bool _showAdvanced = false;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pengaturan Kustom',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 16),
            const Text('Durasi Fokus', style: _label),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: kCustomFocusOptions.map((m) {
                final selected = _focus == m;
                return InkWell(
                  onTap: () => setState(() => _focus = m),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppTheme.primary.withValues(alpha: 0.1)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color:
                              selected ? AppTheme.primary : AppTheme.border,
                          width: selected ? 1.5 : 1),
                    ),
                    child: Text('$m mnt',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? AppTheme.primary
                                : AppTheme.textSecondary)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            _stepperRow('Durasi Istirahat', '$_break menit',
                onMinus: () => setState(() {
                      if (_break > 0) _break--;
                    }),
                onPlus: () => setState(() {
                      if (_break < 30) _break++;
                    })),
            const SizedBox(height: 8),
            _stepperRow('Jumlah Siklus', '$_cycles',
                onMinus: () => setState(() {
                      if (_cycles > 1) _cycles--;
                    }),
                onPlus: () => setState(() {
                      if (_cycles < 8) _cycles++;
                    })),
            const SizedBox(height: 8),
            _toggle('Mulai sesi berikutnya otomatis', _auto,
                (v) => _auto = v),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => setState(() => _showAdvanced = !_showAdvanced),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    const Expanded(child: Text('Opsi lanjutan', style: _label)),
                    Icon(
                        _showAdvanced
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        color: AppTheme.textSecondary),
                  ],
                ),
              ),
            ),
            if (_showAdvanced) ...[
              _toggle('Pertahankan layar tetap menyala', _keepScreenOn,
                  (v) => _keepScreenOn = v),
              _toggle('Kunci navigasi', _lockNavigation,
                  (v) => _lockNavigation = v),
              _toggle('Strict Mode', _strictMode, (v) => _strictMode = v),
              _toggle('Alarm selesai', _alarm, (v) => _alarm = v),
              _toggle('Getaran', _vibrate, (v) => _vibrate = v),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(
                  context,
                  (
                    preset: FocusPreset(
                        name: 'Kustom',
                        focusMinutes: _focus,
                        breakMinutes: _break),
                    cycles: _cycles,
                    autoAdvance: _auto,
                    options: FocusOptions(
                      keepScreenOn: _keepScreenOn,
                      lockNavigation: _lockNavigation,
                      strictMode: _strictMode,
                      alarmOnFinish: _alarm,
                      vibrate: _vibrate,
                    ),
                  ),
                ),
                child: const Text('Simpan'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepperRow(String label, String value,
      {required VoidCallback onMinus, required VoidCallback onPlus}) {
    return Row(
      children: [
        Expanded(
          child: Text(label,
              style: const TextStyle(
                  fontSize: 14, color: AppTheme.textPrimary)),
        ),
        IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          color: AppTheme.primary,
          onPressed: onMinus,
        ),
        SizedBox(
          width: 64,
          child: Text(value,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary)),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          color: AppTheme.primary,
          onPressed: onPlus,
        ),
      ],
    );
  }

  Widget _toggle(String label, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      value: value,
      onChanged: (v) => setState(() => onChanged(v)),
      title: Text(label,
          style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary)),
    );
  }
}

const TextStyle _label = TextStyle(
    fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary);
