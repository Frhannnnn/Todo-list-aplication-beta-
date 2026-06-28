// lib/screens/add_edit_task_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/task_provider.dart';
import '../models/task_model.dart';
import '../utils/app_theme.dart';
import 'ai_task_creator_screen.dart';

class AddEditTaskScreen extends StatefulWidget {
  final Task? task;
  const AddEditTaskScreen({super.key, this.task});

  @override
  State<AddEditTaskScreen> createState() => _AddEditTaskScreenState();
}

class _AddEditTaskScreenState extends State<AddEditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaTugasCtrl = TextEditingController();
  final _catatanCtrl = TextEditingController();

  DateTime _deadline = DateTime.now().add(const Duration(days: 7));
  int _kepentingan = 3;
  int _estimasiWaktu = 3;
  String _lingkupTugas = '';
  String _category = 'Tugas';
  TaskStatus _status = TaskStatus.belumDikerjakan;
  bool _notifEnabled = true;
  List<String> _notifSchedule = ['h-1', '3jam', 'deadline'];

  bool get isEdit => widget.task != null;

  @override
  void initState() {
    super.initState();
    if (isEdit) {
      final t = widget.task!;
      _namaTugasCtrl.text = t.namaTugas;
      _catatanCtrl.text = t.catatan ?? '';
      _deadline = t.deadline;
      _kepentingan = t.tingkatKepentingan;
      _estimasiWaktu = t.estimasiWaktu;
      _lingkupTugas = t.lingkupTugas;
      _category = t.category;
      _status = t.status;
      _notifEnabled = t.notifEnabled;
      _notifSchedule = List.from(t.notifSchedule);
    } else {
      // Set default lingkupTugas from provider after build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final scopes = context.read<TaskProvider>().customScopes;
        if (scopes.isNotEmpty && _lingkupTugas.isEmpty) {
          setState(() => _lingkupTugas = scopes.first);
        }
      });
    }
  }

  @override
  void dispose() {
    _namaTugasCtrl.dispose();
    _catatanCtrl.dispose();
    super.dispose();
  }

  /// Urgensi dihitung otomatis dari deadline
  int get _urgensiOtomatis => Task.hitungUrgensiDariDeadline(_deadline);

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, provider, _) {
        if (!isEdit && _lingkupTugas.isEmpty && provider.customScopes.isNotEmpty) {
          _lingkupTugas = provider.customScopes.first;
        }
        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            title: Text(isEdit ? 'Edit Tugas' : 'Tambah Tugas'),
            backgroundColor: Colors.transparent,
            foregroundColor: AppTheme.textPrimary,
            elevation: 0,
            scrolledUnderElevation: 0,
            actions: [
              if (!isEdit)
                IconButton(
                  icon: const Icon(Icons.auto_awesome_rounded,
                      color: AppTheme.primary),
                  tooltip: 'Buat Tugas Otomatis (AI)',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AITaskCreatorScreen()),
                  ),
                ),
              if (isEdit)
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: AppTheme.danger),
                  onPressed: _confirmDelete,
                ),
            ],
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSection('Informasi Tugas', [
                  _buildTextField(_namaTugasCtrl, 'Nama Tugas',
                      Icons.assignment,
                      validator: (v) =>
                          v!.isEmpty ? 'Wajib diisi' : null),
                  const SizedBox(height: 12),
                  _buildLingkupDropdown(provider),
                ]),
                const SizedBox(height: 16),
                _buildSection('Deadline', [
                  _buildDeadlinePicker(),
                  const SizedBox(height: 10),
                  _buildUrgensiIndicator(),
                ]),
                const SizedBox(height: 16),
                _buildSection('Kategori', [
                  _buildKategoriDropdown(provider),
                ]),
                const SizedBox(height: 16),
                _buildSection('Parameter SAW', [
                  _buildKepentinganSlider(),
                  const SizedBox(height: 12),
                  _buildEisenhowerSummary(),
                  const SizedBox(height: 12),
                  _buildSlider(
                    'Estimasi Waktu (jam)',
                    _estimasiWaktu,
                    (v) => setState(() => _estimasiWaktu = v.round()),
                    hint: 'Berapa jam yang dibutuhkan?',
                    max: 10,
                  ),
                ]),
                const SizedBox(height: 16),
                _buildSection('Status', [_buildStatusSelector()]),
                const SizedBox(height: 16),
                _buildSection('Notifikasi', [_buildNotifSection()]),
                const SizedBox(height: 16),
                _buildSection('Catatan', [_buildCatatanField()]),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _save,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      isEdit ? 'Simpan Perubahan' : 'Tambah Tugas',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String label,
      IconData icon,
      {String? Function(String?)? validator}) {
    return TextFormField(
      controller: ctrl,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.primary),
      ),
    );
  }

  Widget _buildLingkupDropdown(TaskProvider provider) {
    final scopes = provider.customScopes;
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
            onPressed: () => _showAddScopeDialog(provider),
            child: const Text('Tambah'),
          ),
        ],
      );
    }

    // Ensure _lingkupTugas is in the list
    if (!scopes.contains(_lingkupTugas)) {
      _lingkupTugas = scopes.first;
    }

    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: _lingkupTugas,
            decoration: const InputDecoration(
              labelText: 'Lingkup Tugas',
              prefixIcon: Icon(Icons.label_outline, color: AppTheme.primary),
            ),
            items: scopes
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (v) => setState(() => _lingkupTugas = v!),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.add_circle_outline, color: AppTheme.primary),
          tooltip: 'Tambah lingkup baru',
          onPressed: () => _showAddScopeDialog(provider),
        ),
      ],
    );
  }

  // Bug #3 Fix: Add state variables for loading and error handling
bool _isAddingScope = false;

  Future<void> _showAddScopeDialog(TaskProvider provider) async {
    final ctrl = TextEditingController();
    final dialogContext = context;
    
    await showDialog(
      context: dialogContext,
      builder: (c) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Tambah Lingkup Tugas'),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            enabled: !_isAddingScope,
            decoration: const InputDecoration(hintText: 'Nama lingkup...'),
          ),
          actions: [
            TextButton(
              onPressed: _isAddingScope ? null : () => Navigator.pop(c), 
              child: const Text('Batal')
            ),
            ElevatedButton(
              onPressed: _isAddingScope
                  ? null
                  : () async {
                      if (ctrl.text.trim().isEmpty) return;
                      
                      setDialogState(() => _isAddingScope = true);
                      
                      try {
                        await provider.addScope(ctrl.text.trim());
                        
                        if (mounted) {
                          setState(() => _lingkupTugas = ctrl.text.trim());
                        }
                        
                        if (c.mounted) Navigator.pop(c);
                      } catch (e) {
                        if (c.mounted) {
                          ScaffoldMessenger.of(c).showSnackBar(
                            SnackBar(content: Text('Error: $e')),
                          );
                        }
                      } finally {
                        if (dialogContext.mounted) {
                          // Reset loading state via setState
                          Future.microtask(() {
                            if (mounted) {
                              setState(() => _isAddingScope = false);
                            }
                          });
                        }
                      }
                    },
              child: _isAddingScope
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Tambah'),
            ),
          ],
        ),
      ),
    );
    ctrl.dispose();
    _isAddingScope = false;
  }

  Widget _buildKategoriDropdown(TaskProvider provider) {
    final categories = provider.customCategories;

    // Bug #9 Fix: Ensure _category is always valid by forcing valid category
    String validCategory = _category;
    if (categories.isNotEmpty && !categories.contains(_category)) {
      validCategory = categories.first;
    }

    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            value: validCategory,
            decoration: const InputDecoration(
              labelText: 'Kategori',
              prefixIcon:
                  Icon(Icons.category_outlined, color: AppTheme.primary),
            ),
            items: categories
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) => setState(() => _category = v!),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.add_circle_outline, color: AppTheme.primary),
          tooltip: 'Tambah kategori baru',
          onPressed: () => _showAddCategoryDialog(provider),
        ),
      ],
    );
  }

  // Bug #3 Fix: Add state variable for loading and error handling
bool _isAddingCategory = false;

  Future<void> _showAddCategoryDialog(TaskProvider provider) async {
    final ctrl = TextEditingController();
    final dialogContext = context;
    
    await showDialog(
      context: dialogContext,
      builder: (c) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Tambah Kategori'),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            enabled: !_isAddingCategory,
            decoration: const InputDecoration(hintText: 'Nama kategori...'),
          ),
          actions: [
            TextButton(
              onPressed: _isAddingCategory ? null : () => Navigator.pop(c), 
              child: const Text('Batal')
            ),
            ElevatedButton(
              onPressed: _isAddingCategory
                  ? null
                  : () async {
                      if (ctrl.text.trim().isEmpty) return;
                      
                      setDialogState(() => _isAddingCategory = true);
                      
                      try {
                        await provider.addCategory(ctrl.text.trim());
                        
                        if (mounted) {
                          setState(() => _category = ctrl.text.trim());
                        }
                        
                        if (c.mounted) Navigator.pop(c);
                      } catch (e) {
                        if (c.mounted) {
                          ScaffoldMessenger.of(c).showSnackBar(
                            SnackBar(content: Text('Error: $e')),
                          );
                        }
                      } finally {
                        if (dialogContext.mounted) {
                          Future.microtask(() {
                            if (mounted) {
                              setState(() => _isAddingCategory = false);
                            }
                          });
                        }
                      }
                    },
              child: _isAddingCategory
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Tambah'),
            ),
          ],
        ),
      ),
    );
    ctrl.dispose();
    _isAddingCategory = false;
  }

  Widget _buildDeadlinePicker() {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _deadline,
          firstDate: DateTime.now().subtract(const Duration(days: 1)),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (date != null) {
          if (!mounted) return;
          final time = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.fromDateTime(_deadline),
          );
          if (!mounted) return;
          setState(() {
            _deadline = DateTime(
              date.year,
              date.month,
              date.day,
              time?.hour ?? 23,
              time?.minute ?? 59,
            );
          });
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.border),
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey.shade50,
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: AppTheme.primary),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Deadline',
                    style: TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary)),
                Text(
                  DateFormat('EEEE, d MMMM yyyy - HH:mm', 'id_ID')
                      .format(_deadline),
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary),
                ),
              ],
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }

  /// Badge urgensi otomatis berdasarkan deadline
  Widget _buildUrgensiIndicator() {
    final sisa = _deadline.difference(DateTime.now()).inHours;
    String label;
    Color color;
    IconData icon;

    if (sisa <= 0) {
      label = 'Sudah Lewat Deadline';
      color = AppTheme.danger;
      icon = Icons.error_rounded;
    } else if (sisa <= 3) {
      label = '🔴 Sangat Mendesak (< 3 jam)';
      color = AppTheme.danger;
      icon = Icons.warning_rounded;
    } else if (sisa <= 24) {
      label = '🟠 Mendesak (< 24 jam)';
      color = const Color(0xFFF97316);
      icon = Icons.access_time_rounded;
    } else if (sisa <= 72) {
      label = '🟡 Perlu Perhatian (< 3 hari)';
      color = AppTheme.warning;
      icon = Icons.schedule_rounded;
    } else if (sisa <= 168) {
      label = '🟢 Masih Aman (< 7 hari)';
      color = AppTheme.success;
      icon = Icons.check_circle_outline_rounded;
    } else {
      label = '✅ Santai (> 7 hari)';
      color = AppTheme.success;
      icon = Icons.sentiment_satisfied_rounded;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlider(String label, int value, ValueChanged<double> onChanged,
      {String? hint, int max = 5}) {
    final labels = {
      1: 'Sangat Rendah',
      2: 'Rendah',
      3: 'Sedang',
      4: 'Tinggi',
      5: 'Sangat Tinggi',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary)),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                max == 5
                    ? (labels[value] ?? '-')
                    : '$value jam',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary),
              ),
            ),
          ],
        ),
        if (hint != null)
          Text(hint,
              style: const TextStyle(
                  fontSize: 11, color: AppTheme.textSecondary)),
        Slider(
          value: value.toDouble(),
          min: 1,
          max: max.toDouble(),
          divisions: max - 1,
          activeColor: AppTheme.primary,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildKepentinganSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Tingkat Kepentingan',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () => showDialog(
                context: context,
                builder: (c) => AlertDialog(
                  title: const Text('Tingkat Kepentingan'),
                  content: const Text(
                    'Kepentingan = seberapa besar dampak tugas ini terhadap nilai atau tujuan akademikmu. '
                    'Contoh: tugas UAS lebih penting dari tugas mingguan biasa.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(c),
                      child: const Text('Mengerti'),
                    ),
                  ],
                ),
              ),
              child: const Icon(Icons.info_outline,
                  size: 16, color: AppTheme.textSecondary),
            ),
            const Spacer(),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                AppTheme.getLabelSlider(_kepentingan),
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Dampak jangka panjang terhadap tujuan akademik',
          style:
              TextStyle(fontSize: 11, color: AppTheme.textSecondary),
        ),
        Slider(
          value: _kepentingan.toDouble(),
          min: 1,
          max: 5,
          divisions: 4,
          activeColor: AppTheme.primary,
          onChanged: (v) => setState(() => _kepentingan = v.round()),
        ),
        const Text(
          '💡 Penting ≠ Mendesak: penting = berdampak besar pada nilai/tujuan; mendesak = deadline dekat',
          style:
              TextStyle(fontSize: 11, color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  Color _getEisenhowerColor(String label) {
    if (label.contains('Kerjakan Sekarang')) return const Color(0xFFEF4444);
    if (label.contains('Jadwalkan')) return const Color(0xFF2563EB);
    if (label.contains('Delegasikan')) return const Color(0xFFF59E0B);
    return const Color(0xFF94A3B8);
  }

  Widget _buildEisenhowerSummary() {
    final label =
        AppTheme.getEisenhowerLabel(_kepentingan, _urgensiOtomatis);
    final color = _getEisenhowerColor(label);

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '📊 $label',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color.withValues(alpha: 0.9)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSelector() {
    return Row(
      children: TaskStatus.values.map((s) {
        final labels = [
          'Belum\nDikerjakan',
          'Sedang\nDikerjakan',
          'Selesai'
        ];
        final icons = [
          Icons.radio_button_unchecked,
          Icons.access_time,
          Icons.check_circle
        ];
        final colors = [
          AppTheme.textSecondary,
          AppTheme.warning,
          AppTheme.success
        ];
        final isSelected = _status == s;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _status = s),
            child: Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? colors[s.index].withValues(alpha: 0.1)
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? colors[s.index] : AppTheme.border,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(icons[s.index],
                      color: isSelected
                          ? colors[s.index]
                          : AppTheme.textSecondary,
                      size: 20),
                  const SizedBox(height: 4),
                  Text(labels[s.index],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.normal,
                          color: isSelected
                              ? colors[s.index]
                              : AppTheme.textSecondary)),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNotifSection() {
    const scheduleOptions = [
      ('h-3', 'H-3 hari'),
      ('h-1', 'H-1 hari'),
      ('3jam', '3 jam sebelum'),
      ('deadline', 'Tepat deadline'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          value: _notifEnabled,
          onChanged: (v) => setState(() => _notifEnabled = v),
          activeThumbColor: AppTheme.primary,
          contentPadding: EdgeInsets.zero,
          title: const Text('Aktifkan Notifikasi',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary)),
          subtitle: Text(
            _notifEnabled
                ? 'Notifikasi aktif untuk tugas ini'
                : 'Notifikasi dimatikan untuk tugas ini',
            style: const TextStyle(
                fontSize: 11, color: AppTheme.textSecondary),
          ),
        ),
        if (_notifEnabled) ...[
          const SizedBox(height: 8),
          const Text('Kirim pengingat pada:',
              style: TextStyle(
                  fontSize: 12, color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: scheduleOptions.map(((String key, String label) opt) {
              final isSelected = _notifSchedule.contains(opt.$1);
              return FilterChip(
                label: Text(opt.$2,
                    style: TextStyle(
                        fontSize: 12,
                        color: isSelected
                            ? AppTheme.primary
                            : AppTheme.textSecondary)),
                selected: isSelected,
                onSelected: (v) {
                  setState(() {
                    if (v) {
                      _notifSchedule.add(opt.$1);
                    } else {
                      _notifSchedule.remove(opt.$1);
                    }
                  });
                },
                selectedColor: AppTheme.primary.withValues(alpha: 0.1),
                checkmarkColor: AppTheme.primary,
                side: BorderSide(
                    color: isSelected
                        ? AppTheme.primary
                        : AppTheme.border),
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildCatatanField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _catatanCtrl,
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
              onPressed: _openFullscreenNote,
            ),
          ),
        ),
      ],
    );
  }

  void _openFullscreenNote() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final localCtrl =
            TextEditingController(text: _catatanCtrl.text);
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
                          setState(() =>
                              _catatanCtrl.text = localCtrl.text);
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

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate lingkupTugas
    if (_lingkupTugas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Pilih lingkup tugas terlebih dahulu'),
            backgroundColor: AppTheme.warning),
      );
      return;
    }

    final provider = context.read<TaskProvider>();

    if (isEdit) {
      await provider.editTugas(
        widget.task!.id,
        namaTugas: _namaTugasCtrl.text.trim(),
        lingkupTugas: _lingkupTugas,
        deadline: _deadline,
        tingkatKepentingan: _kepentingan,
        estimasiWaktu: _estimasiWaktu,
        status: _status,
        category: _category,
        catatan: _catatanCtrl.text.trim(),
        notifEnabled: _notifEnabled,
        notifSchedule: _notifSchedule,
      );
    } else {
      await provider.tambahTugas(
        namaTugas: _namaTugasCtrl.text.trim(),
        lingkupTugas: _lingkupTugas,
        deadline: _deadline,
        tingkatKepentingan: _kepentingan,
        estimasiWaktu: _estimasiWaktu,
        category: _category,
        catatan: _catatanCtrl.text.trim(),
        notifEnabled: _notifEnabled,
        notifSchedule: _notifSchedule,
      );
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEdit
              ? 'Tugas berhasil diperbarui'
              : 'Tugas berhasil ditambahkan'),
          backgroundColor: AppTheme.success,
        ),
      );
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Hapus Tugas'),
        content: const Text('Yakin ingin menghapus tugas ini?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c),
              child: const Text('Batal')),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () {
              context.read<TaskProvider>().hapusTugas(widget.task!.id);
              Navigator.pop(c);
              Navigator.pop(context);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
