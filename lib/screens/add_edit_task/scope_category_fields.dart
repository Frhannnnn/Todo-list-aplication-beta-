// lib/screens/add_edit_task/scope_category_fields.dart

import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

/// Dropdown lingkup tugas. Saling terkait dengan [CategoryDropdownField]:
/// memilih lingkup baru mereset kategori — logika reset itu tetap tinggal
/// di parent (lewat [onScopeSelected]), widget ini murni tampilan.
class ScopeDropdownField extends StatelessWidget {
  final List<String> scopes;
  final String value;
  final ValueChanged<String> onScopeSelected;
  final VoidCallback onAddPressed;
  final VoidCallback onManagePressed;

  const ScopeDropdownField({
    super.key,
    required this.scopes,
    required this.value,
    required this.onScopeSelected,
    required this.onAddPressed,
    required this.onManagePressed,
  });

  @override
  Widget build(BuildContext context) {
    if (scopes.isEmpty) {
      return Row(
        children: [
          const Icon(Icons.label_outline, color: AppTheme.primary, size: 20),
          const SizedBox(width: 10),
          const Expanded(
            child: Text('Belum ada lingkup tugas.',
                style: TextStyle(
                    fontSize: 13, color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: onAddPressed,
            child: const Text('Tambah'),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: value,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Lingkup Tugas',
              prefixIcon:
                  Icon(Icons.label_outline, color: AppTheme.primary),
            ),
            items: scopes
                .map((s) => DropdownMenuItem(
                    value: s,
                    child: Text(s, overflow: TextOverflow.ellipsis)))
                .toList(),
            onChanged: (v) {
              if (v != null) onScopeSelected(v);
            },
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline, color: AppTheme.primary),
          tooltip: 'Tambah lingkup baru',
          onPressed: onAddPressed,
        ),
        IconButton(
          icon: const Icon(Icons.tune_rounded, color: AppTheme.textSecondary),
          tooltip: 'Kelola lingkup',
          onPressed: onManagePressed,
        ),
      ],
    );
  }
}

/// Dropdown kategori — hanya kategori milik lingkup yang sedang aktif yang
/// ditampilkan (Issue #4: kategori independen per lingkup).
class CategoryDropdownField extends StatelessWidget {
  final List<String> categories;
  final String value;
  final ValueChanged<String> onChanged;
  final VoidCallback onAddPressed;
  final VoidCallback onManagePressed;

  const CategoryDropdownField({
    super.key,
    required this.categories,
    required this.value,
    required this.onChanged,
    required this.onAddPressed,
    required this.onManagePressed,
  });

  @override
  Widget build(BuildContext context) {
    String validCategory = value;
    if (categories.isNotEmpty && !categories.contains(value)) {
      validCategory = categories.first;
    }

    if (categories.isEmpty) {
      return Row(
        children: [
          const Icon(Icons.category_outlined,
              color: AppTheme.primary, size: 20),
          const SizedBox(width: 10),
          const Expanded(
            child: Text('Belum ada kategori untuk lingkup ini.',
                style:
                    TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: onAddPressed,
            child: const Text('Tambah'),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: validCategory,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Kategori',
              prefixIcon:
                  Icon(Icons.category_outlined, color: AppTheme.primary),
            ),
            items: categories
                .map((c) => DropdownMenuItem(
                    value: c,
                    child: Text(c, overflow: TextOverflow.ellipsis)))
                .toList(),
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline, color: AppTheme.primary),
          tooltip: 'Tambah kategori baru',
          onPressed: onAddPressed,
        ),
        IconButton(
          icon: const Icon(Icons.tune_rounded, color: AppTheme.textSecondary),
          tooltip: 'Kelola kategori',
          onPressed: onManagePressed,
        ),
      ],
    );
  }
}
