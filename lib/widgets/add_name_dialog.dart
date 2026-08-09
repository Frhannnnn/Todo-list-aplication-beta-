// lib/widgets/add_name_dialog.dart

import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

/// Dialog "Tambah Lingkup/Kategori" generik — sengaja jadi StatefulWidget
/// sendiri (bukan StatefulBuilder di dalam method layar induk) supaya state
/// loading murni lokal terhadap dialog. Layar pemanggil hanya menerima
/// hasilnya lewat Navigator.pop(context, text) SETELAH dialog selesai —
/// tidak pernah memanggil setState() layar induk sementara dialog masih
/// terbuka (akar penyebab "Assertion failed: _dependents.isEmpty" / "Tried
/// to build dirty widget in the wrong build scope" yang muncul sebelumnya).
class AddNameDialog extends StatefulWidget {
  final String title;
  final String hint;
  final Future<void> Function(String text) onSubmit;

  const AddNameDialog({
    super.key,
    required this.title,
    required this.hint,
    required this.onSubmit,
  });

  @override
  State<AddNameDialog> createState() => _AddNameDialogState();
}

class _AddNameDialogState extends State<AddNameDialog> {
  final _ctrl = TextEditingController();
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

    try {
      await widget.onSubmit(text);
      if (mounted) Navigator.pop(context, text);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _error = 'Gagal menambahkan: $e';
        });
      }
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
            decoration: InputDecoration(hintText: widget.hint),
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
              : const Text('Tambah'),
        ),
      ],
    );
  }
}
