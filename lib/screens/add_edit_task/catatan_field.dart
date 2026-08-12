// lib/screens/add_edit_task/catatan_field.dart

import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

class CatatanField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onExpand;

  const CatatanField({
    super.key,
    required this.controller,
    required this.onExpand,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          minLines: 3,
          maxLines: null,
          decoration: InputDecoration(
            hintText: 'Tambah catatan (opsional)...',
            prefixIcon: const Icon(Icons.notes),
            suffixIcon: IconButton(
              icon:
                  const Icon(Icons.open_in_full_rounded, size: 18),
              tooltip: 'Buka editor penuh',
              color: AppTheme.textSecondary,
              onPressed: onExpand,
            ),
          ),
        ),
      ],
    );
  }
}

Future<void> showFullscreenNoteSheet(
  BuildContext context, {
  required String initialText,
  required ValueChanged<String> onSave,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      final localCtrl = TextEditingController(text: initialText);
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: SizedBox(
          height: MediaQuery.of(ctx).size.height * 0.7,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Row(
                  children: [
                    const Text('Catatan',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary)),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        onSave(localCtrl.text);
                        Navigator.pop(ctx);
                      },
                      child: const Text('Simpan'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: TextField(
                  controller: localCtrl,
                  autofocus: true,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: const InputDecoration(
                    hintText: 'Tulis catatan di sini...',
                    contentPadding: EdgeInsets.all(20),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    fillColor: Colors.transparent,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
