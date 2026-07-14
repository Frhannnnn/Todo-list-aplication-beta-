// lib/widgets/rename_dialog.dart

import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

/// Dialog ganti nama generik (dipakai untuk rename lingkup & kategori).
/// [onSubmit] mengembalikan bool sukses/gagal (bukan exception) — dialog
/// menampilkan pesan error inline dan tidak menutup diri bila gagal
/// (mis. nama baru sudah dipakai).
class RenameDialog extends StatefulWidget {
  final String title;
  final String initialValue;
  final Future<bool> Function(String newName) onSubmit;

  const RenameDialog({
    super.key,
    required this.title,
    required this.initialValue,
    required this.onSubmit,
  });

  @override
  State<RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<RenameDialog> {
  late final TextEditingController _ctrl =
      TextEditingController(text: widget.initialValue);
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    final success = await widget.onSubmit(text);
    if (!mounted) return;

    if (success) {
      Navigator.pop(context, text);
    } else {
      setState(() {
        _isSubmitting = false;
        _error = 'Nama tidak valid atau sudah dipakai';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _ctrl,
            autofocus: true,
            enabled: !_isSubmitting,
            onSubmitted: (_) => _submit(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(color: AppTheme.danger, fontSize: 12),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Simpan'),
        ),
      ],
    );
  }
}
