// lib/screens/focus/focus_intent_dialog.dart

import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

/// Dialog kecil untuk menetapkan target sesi (opsional).
/// Mengembalikan teks target (bisa kosong), atau null bila dibatalkan.
Future<String?> showFocusIntentDialog(BuildContext context) {
  return showDialog<String>(
    context: context,
    builder: (_) => const _FocusIntentDialog(),
  );
}

class _FocusIntentDialog extends StatefulWidget {
  const _FocusIntentDialog();

  @override
  State<_FocusIntentDialog> createState() => _FocusIntentDialogState();
}

class _FocusIntentDialogState extends State<_FocusIntentDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Apa target sesi ini?',
          style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Boleh dikosongkan.',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              hintText: 'Menyelesaikan Bab II',
            ),
            onSubmitted: (v) => Navigator.pop(context, v),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Lanjut'),
        ),
      ],
    );
  }
}
