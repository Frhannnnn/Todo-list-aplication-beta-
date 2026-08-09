// lib/screens/add_edit_task/manage_values_sheet.dart

import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import '../../widgets/rename_dialog.dart';

/// Bottom sheet generik untuk mengelola daftar nilai (lingkup/kategori):
/// tambah, ganti nama, dan hapus — dengan penjaga hapus opsional. Sengaja
/// sederhana & dapat dipakai ulang lewat callback.
class ManageValuesSheet extends StatefulWidget {
  final String title;
  final String subtitle;
  final String addHint;
  final List<String> Function() getItems;
  final Future<void> Function(String) onAdd;
  final Future<bool> Function(String oldName, String newName) onRename;
  final Future<void> Function(String) onDelete;
  final String? Function(String)? deleteGuard;
  final VoidCallback onChanged;

  const ManageValuesSheet({
    super.key,
    required this.title,
    required this.subtitle,
    required this.addHint,
    required this.getItems,
    required this.onAdd,
    required this.onRename,
    required this.onDelete,
    required this.onChanged,
    this.deleteGuard,
  });

  @override
  State<ManageValuesSheet> createState() => _ManageValuesSheetState();
}

class _ManageValuesSheetState extends State<ManageValuesSheet> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    await widget.onAdd(text);
    _ctrl.clear();
    if (mounted) setState(() {});
    widget.onChanged();
  }

  Future<void> _rename(String old) async {
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => RenameDialog(
        title: 'Ganti Nama',
        initialValue: old,
        onSubmit: (newName) => widget.onRename(old, newName),
      ),
    );
    if (result != null && mounted) {
      setState(() {});
      widget.onChanged();
    }
  }

  Future<void> _delete(String item) async {
    final blocked = widget.deleteGuard?.call(item);
    if (blocked != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(blocked), backgroundColor: AppTheme.warning));
      return;
    }
    await widget.onDelete(item);
    if (mounted) setState(() {});
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.getItems();
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const SizedBox(height: 16),
            Text(widget.title,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 4),
            Text(widget.subtitle,
                style: const TextStyle(
                    fontSize: 13, color: AppTheme.textSecondary)),
            const SizedBox(height: 16),
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Belum ada. Tambahkan di bawah.',
                    style: TextStyle(color: AppTheme.textSecondary)),
              )
            else
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: items
                        .map((it) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.label_outline_rounded,
                                    color: AppTheme.primary, size: 18),
                              ),
                              title: Text(it,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined,
                                        color: AppTheme.textSecondary, size: 20),
                                    tooltip: 'Ganti nama',
                                    onPressed: () => _rename(it),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        color: AppTheme.danger,
                                        size: 20),
                                    tooltip: 'Hapus',
                                    onPressed: () => _delete(it),
                                  ),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    decoration: InputDecoration(
                      hintText: widget.addHint,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: AppTheme.primary, width: 1.5),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onSubmitted: (_) => _add(),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _add,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                  child: const Text('Tambah'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
