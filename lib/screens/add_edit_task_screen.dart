// lib/screens/add_edit_task_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/task_provider.dart';
import '../models/task_model.dart';
import '../utils/app_theme.dart';
import '../main.dart';
import '../widgets/rename_dialog.dart';
import 'ai_task_creator_screen.dart';

class AddEditTaskScreen extends StatefulWidget {
  final Task? task;
  const AddEditTaskScreen({super.key, this.task});

  @override
  State<AddEditTaskScreen> createState() => _AddEditTaskScreenState();
}

class _AddEditTaskScreenState extends State<AddEditTaskScreen> {
  // Lingkup yang memunculkan kolom Mata Kuliah. Pencocokan literal by design
  // (lihat issue.md #2) — kalau nanti dibutuhkan penanda "lingkup akademik"
  // per-lingkup yang custom-renameable, ganti pengecekan ini.
  static const String _kAkademikScope = 'Perkuliahan';

  final _formKey = GlobalKey<FormState>();
  final _namaTugasCtrl = TextEditingController();
  final _catatanCtrl = TextEditingController();
  final _mataKuliahCtrl = TextEditingController();

  DateTime _deadline = DateTime.now().add(const Duration(days: 7));
  int _kepentingan = 3;
  int _estimasiWaktu = 3;
  String _lingkupTugas = '';
  String _category = 'Tugas';
  TaskStatus _status = TaskStatus.belumDikerjakan;
  bool _notifEnabled = true;
  List<String> _notifSchedule = ['h-1', '3jam', 'deadline'];

  bool get isEdit => widget.task != null;
  bool get _isAkademik => _lingkupTugas == _kAkademikScope;

  @override
  void initState() {
    super.initState();
    if (isEdit) {
      final t = widget.task!;
      _namaTugasCtrl.text = t.namaTugas;
      _catatanCtrl.text = t.catatan ?? '';
      _mataKuliahCtrl.text = t.mataKuliah ?? '';
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
    _mataKuliahCtrl.dispose();
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
                  if (_isAkademik) ...[
                    const SizedBox(height: 12),
                    _buildTextField(
                        _mataKuliahCtrl, 'Mata Kuliah', Icons.menu_book),
                  ],
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
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Lingkup Tugas',
              prefixIcon: Icon(Icons.label_outline, color: AppTheme.primary),
            ),
            items: scopes
                .map((s) => DropdownMenuItem(
                    value: s,
                    child: Text(s, overflow: TextOverflow.ellipsis)))
                .toList(),
            onChanged: (v) {
              if (v == null) return;
              setState(() {
                _lingkupTugas = v;
                // Kategori independen per lingkup (Issue #4) — reset ke
                // kategori pertama milik lingkup baru saat lingkup diganti.
                final catsForNewScope = provider.categoriesForScope(v);
                _category = catsForNewScope.isNotEmpty
                    ? catsForNewScope.first
                    : '';
              });
            },
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

  // Bug #3 Fix: dialog dipisah jadi StatefulWidget sendiri (lihat _AddNameDialog)
  // supaya siklus hidupnya tidak bersilangan dengan setState() layar induk —
  // itulah akar penyebab "Assertion failed: _dependents.isEmpty" / "Tried to
  // build dirty widget in the wrong build scope" yang muncul sebelumnya.
  Future<void> _showAddScopeDialog(TaskProvider provider) async {
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AddNameDialog(
        title: 'Tambah Lingkup Tugas',
        hint: 'Nama lingkup...',
        onSubmit: (text) => provider.addScope(text),
      ),
    );
    if (result != null && mounted) {
      setState(() => _lingkupTugas = result);
    }
  }

  Widget _buildKategoriDropdown(TaskProvider provider) {
    // Kategori independen per lingkup (Issue #4) — hanya kategori milik
    // _lingkupTugas yang sedang aktif yang ditampilkan.
    final categories = provider.categoriesForScope(_lingkupTugas);

    String validCategory = _category;
    if (categories.isNotEmpty && !categories.contains(_category)) {
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
            onPressed: () => _showAddCategoryDialog(provider),
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
            onChanged: (v) => setState(() => _category = v!),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.add_circle_outline, color: AppTheme.primary),
          tooltip: 'Tambah kategori baru',
          onPressed: () => _showAddCategoryDialog(provider),
        ),
        IconButton(
          icon: const Icon(Icons.tune_rounded, color: AppTheme.textSecondary),
          tooltip: 'Kelola kategori lingkup ini',
          onPressed: () => _showCategoryManagerSheet(provider),
        ),
      ],
    );
  }

  Future<void> _showAddCategoryDialog(TaskProvider provider) async {
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AddNameDialog(
        title: 'Tambah Kategori',
        hint: 'Nama kategori...',
        onSubmit: (text) => provider.addCategoryToScope(_lingkupTugas, text),
      ),
    );
    if (result != null && mounted) {
      setState(() => _category = result);
    }
  }

  void _showCategoryManagerSheet(TaskProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _CategoryManagerSheet(
        provider: provider,
        scope: _lingkupTugas,
        currentCategory: _category,
        onCategoriesChanged: (validCategory) {
          if (mounted) setState(() => _category = validCategory);
        },
      ),
    );
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
    final mataKuliah =
        _isAkademik && _mataKuliahCtrl.text.trim().isNotEmpty
            ? _mataKuliahCtrl.text.trim()
            : null;
    bool saved;

    if (isEdit) {
      saved = await provider.editTugas(
        widget.task!.id,
        namaTugas: _namaTugasCtrl.text.trim(),
        lingkupTugas: _lingkupTugas,
        mataKuliah: mataKuliah,
        clearMataKuliah: mataKuliah == null,
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
      saved = await provider.tambahTugas(
        namaTugas: _namaTugasCtrl.text.trim(),
        lingkupTugas: _lingkupTugas,
        mataKuliah: mataKuliah,
        deadline: _deadline,
        tingkatKepentingan: _kepentingan,
        estimasiWaktu: _estimasiWaktu,
        category: _category,
        catatan: _catatanCtrl.text.trim(),
        notifEnabled: _notifEnabled,
        notifSchedule: _notifSchedule,
      );
    }

    if (!saved || !mounted) return;

    // Selalu kembali ke tab "Data Tugas" apa pun layar asal form ini dibuka
    // (FAB di TaskListScreen/CalendarScreen, atau tap-to-edit di manapun).
    MainNavigation.tabIndex.value = MainNavigation.taskListTab;
    Navigator.popUntil(context, (route) => route.isFirst);
    rootScaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(isEdit
            ? 'Tugas berhasil diperbarui'
            : 'Tugas berhasil ditambahkan'),
        backgroundColor: AppTheme.success,
      ),
    );
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
            onPressed: () async {
              final provider = context.read<TaskProvider>();
              final deleted = await provider.hapusTugas(widget.task!.id);
              if (c.mounted) Navigator.pop(c);
              if (!deleted || !mounted) return;
              MainNavigation.tabIndex.value = MainNavigation.taskListTab;
              Navigator.popUntil(context, (route) => route.isFirst);
              rootScaffoldMessengerKey.currentState?.showSnackBar(
                const SnackBar(
                  content: Text('Tugas berhasil dihapus'),
                  backgroundColor: AppTheme.danger,
                ),
              );
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}

/// Dialog "Tambah Lingkup/Kategori" — sengaja jadi StatefulWidget sendiri
/// (bukan StatefulBuilder di dalam method layar induk) supaya state loading
/// murni lokal terhadap dialog. Layar pemanggil hanya menerima hasilnya lewat
/// Navigator.pop(context, text) SETELAH dialog selesai — tidak pernah
/// memanggil setState() layar induk sementara dialog masih terbuka.
class _AddNameDialog extends StatefulWidget {
  final String title;
  final String hint;
  final Future<void> Function(String text) onSubmit;

  const _AddNameDialog({
    required this.title,
    required this.hint,
    required this.onSubmit,
  });

  @override
  State<_AddNameDialog> createState() => _AddNameDialogState();
}

class _AddNameDialogState extends State<_AddNameDialog> {
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

/// Bottom sheet "Kelola Kategori" — kategori di sini selalu milik satu
/// [scope] tertentu (Issue #4: kategori independen per lingkup, tidak
/// dibagi-pakai). Mendukung tambah, ganti nama (cascade ke semua tugas di
/// lingkup ini), dan hapus.
class _CategoryManagerSheet extends StatefulWidget {
  final TaskProvider provider;
  final String scope;
  final String currentCategory;
  final ValueChanged<String> onCategoriesChanged;

  const _CategoryManagerSheet({
    required this.provider,
    required this.scope,
    required this.currentCategory,
    required this.onCategoriesChanged,
  });

  @override
  State<_CategoryManagerSheet> createState() => _CategoryManagerSheetState();
}

class _CategoryManagerSheetState extends State<_CategoryManagerSheet> {
  final _ctrl = TextEditingController();
  late String _trackedCategory = widget.currentCategory;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = widget.provider.categoriesForScope(widget.scope);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
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
            const Text(
              'Kelola Kategori',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Kategori khusus untuk lingkup "${widget.scope}" — tidak dibagi dengan lingkup lain.',
              style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            if (categories.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Belum ada kategori. Tambahkan di bawah.',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              )
            else
              ...categories.map((cat) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.category_outlined,
                          color: AppTheme.primary, size: 18),
                    ),
                    title: Text(cat,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined,
                              color: AppTheme.textSecondary, size: 20),
                          tooltip: 'Ganti nama',
                          onPressed: () => _renameCategory(cat),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded,
                              color: AppTheme.danger, size: 20),
                          tooltip: 'Hapus',
                          onPressed: () => _deleteCategory(cat),
                        ),
                      ],
                    ),
                  )),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    decoration: InputDecoration(
                      hintText: 'Nama kategori baru...',
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
                    onSubmitted: (_) => _addCategory(),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _addCategory,
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

  void _addCategory() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    widget.provider.addCategoryToScope(widget.scope, text);
    _ctrl.clear();
    setState(() {});
    _syncSelection();
  }

  Future<void> _deleteCategory(String cat) async {
    await widget.provider.removeCategoryFromScope(widget.scope, cat);
    if (!mounted) return;
    setState(() {});
    _syncSelection();
  }

  Future<void> _renameCategory(String oldCat) async {
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => RenameDialog(
        title: 'Ganti Nama Kategori',
        initialValue: oldCat,
        onSubmit: (newName) => widget.provider
            .renameCategoryInScope(widget.scope, oldCat, newName),
      ),
    );
    if (result != null && mounted) {
      // Kalau yang di-rename adalah kategori yang sedang dipilih di form,
      // ikutkan supaya form tetap menunjuk kategori yang sama (nama baru).
      if (_trackedCategory == oldCat) _trackedCategory = result;
      setState(() {});
      _syncSelection();
    }
  }

  /// Pastikan kategori yang sedang "dipegang" tetap valid (masih ada di
  /// daftar kategori lingkup ini); kalau sudah dihapus, jatuh ke kategori
  /// pertama yang tersisa. Kategori lain yang tidak terkait tidak
  /// memengaruhi pilihan form sama sekali.
  void _syncSelection() {
    final categories = widget.provider.categoriesForScope(widget.scope);
    if (!categories.contains(_trackedCategory)) {
      _trackedCategory = categories.isNotEmpty ? categories.first : '';
    }
    widget.onCategoriesChanged(_trackedCategory);
  }
}
