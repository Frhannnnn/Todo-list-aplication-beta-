// lib/screens/add_edit_task_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/task_provider.dart';
import '../models/task_model.dart';
import '../utils/app_theme.dart';
import '../main.dart';
import '../widgets/rename_dialog.dart';
import 'ai_task_creator_screen.dart';
import '../utils/recurrence.dart';

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
  RecurrenceType _recurrence = RecurrenceType.none;
  int _recurrenceInterval = 1;
  RecurrenceUnit _recurrenceUnit = RecurrenceUnit.day;
  DateTime? _recurrenceEndDate;
  int? _recurrenceCount;

  bool _isSaving = false;
  bool _showAdvanced = false;
  // Tanda tangan nilai form saat pertama dibuka, untuk mendeteksi perubahan
  // yang belum disimpan (guard "Buang perubahan?").
  String? _initialSignature;

  bool get isEdit => widget.task != null;
  bool get _isAkademik => _lingkupTugas == _kAkademikScope;

  @override
  void initState() {
    super.initState();
    if (isEdit) {
      // Saat mengedit, tampilkan seluruh opsi agar tidak ada yang tersembunyi.
      _showAdvanced = true;
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
      _recurrence = t.recurrence;
      _recurrenceInterval = t.recurrenceInterval;
      _recurrenceUnit = t.recurrenceUnit ?? RecurrenceUnit.day;
      _recurrenceEndDate = t.recurrenceEndDate;
      _recurrenceCount = t.recurrenceCount;
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

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, provider, _) {
        if (!isEdit && _lingkupTugas.isEmpty && provider.customScopes.isNotEmpty) {
          _lingkupTugas = provider.customScopes.first;
        }
        // Rekam kondisi awal form sekali (setelah default lingkup terset).
        _initialSignature ??= _formSignature();
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop || !mounted) return;
            final nav = Navigator.of(context);
            if (_formSignature() == _initialSignature) {
              nav.pop();
              return;
            }
            final discard = await _confirmDiscard();
            if (!mounted || discard != true) return;
            nav.pop();
          },
          child: Scaffold(
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
                      // Fokus otomatis saat menambah tugas baru agar keyboard
                      // langsung siap; jangan saat mengedit.
                      autofocus: !isEdit,
                      validator: (v) =>
                          v!.isEmpty ? 'Wajib diisi' : null),
                  const SizedBox(height: 12),
                  _buildLingkupDropdown(provider),
                  const SizedBox(height: 12),
                  _buildKategoriDropdown(provider),
                  if (_isAkademik) ...[
                    const SizedBox(height: 12),
                    _buildTextField(
                        _mataKuliahCtrl, 'Mata Kuliah', Icons.menu_book),
                  ],
                ]),
                const SizedBox(height: 16),
                _buildSection('Deadline', [
                  _buildDeadlinePresets(),
                  const SizedBox(height: 12),
                  _buildDeadlinePicker(),
                ]),
                const SizedBox(height: 16),
                _buildSection('Prioritas', [
                  _buildPrioritasPicker(),
                ]),
                const SizedBox(height: 16),
                _buildAdvancedToggle(),
                if (_showAdvanced) ...[
                  const SizedBox(height: 16),
                  _buildSection('Pengulangan', [
                    _buildRecurrencePicker(),
                  ]),
                  if (isEdit) ...[
                    const SizedBox(height: 16),
                    _buildSection('Status', [_buildStatusSelector()]),
                  ],
                  const SizedBox(height: 16),
                  _buildSection('Notifikasi', [
                    _buildNotifToggle(provider.notifEnabled),
                  ]),
                  const SizedBox(height: 16),
                  _buildSection('Catatan', [_buildCatatanField()]),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            isEdit ? 'Simpan Perubahan' : 'Tambah Tugas',
                            style: const TextStyle(fontSize: 16),
                          ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
          ),
        );
      },
    );
  }

  /// Tombol lipat opsi lanjutan. Untuk tugas baru, bagian teknis (pengulangan,
  /// parameter SAW, status, notifikasi, catatan) disembunyikan agar pengguna
  /// cukup mengisi nama, deadline, dan kategori. Nilai default sudah memadai.
  Widget _buildAdvancedToggle() {
    return InkWell(
      onTap: () => setState(() => _showAdvanced = !_showAdvanced),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.tune_rounded, color: AppTheme.primary, size: 20),
            const SizedBox(width: 10),
            const Expanded(
              child: Text('Opsi lanjutan',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary)),
            ),
            Icon(
                _showAdvanced
                    ? Icons.expand_less_rounded
                    : Icons.expand_more_rounded,
                color: AppTheme.textSecondary),
          ],
        ),
      ),
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
      {String? Function(String?)? validator, bool autofocus = false}) {
    return TextFormField(
      controller: ctrl,
      validator: validator,
      autofocus: autofocus,
      textCapitalization: TextCapitalization.sentences,
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
              prefixIcon:
                  Icon(Icons.label_outline, color: AppTheme.primary),
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
                _category =
                    catsForNewScope.isNotEmpty ? catsForNewScope.first : '';
              });
            },
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline, color: AppTheme.primary),
          tooltip: 'Tambah lingkup baru',
          onPressed: () => _showAddScopeDialog(provider),
        ),
        IconButton(
          icon: const Icon(Icons.tune_rounded, color: AppTheme.textSecondary),
          tooltip: 'Kelola lingkup',
          onPressed: () => _showManageScopes(provider),
        ),
      ],
    );
  }

  void _showManageScopes(TaskProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ManageValuesSheet(
        title: 'Kelola Lingkup Tugas',
        subtitle: 'Tambah, ganti nama, atau hapus lingkup.',
        addHint: 'Nama lingkup baru...',
        getItems: () => provider.customScopes,
        onAdd: (t) => provider.addScope(t),
        onRename: (o, n) => provider.renameScope(o, n),
        onDelete: (s) => provider.removeScope(s),
        deleteGuard: (s) {
          final n = provider.getTasksByScope(s).length;
          if (n > 0) {
            return 'Lingkup "$s" masih dipakai $n tugas. Pindahkan tugasnya dulu.';
          }
          if (provider.customScopes.length <= 1) {
            return 'Minimal harus ada satu lingkup.';
          }
          return null;
        },
        onChanged: () {
          if (!mounted) return;
          setState(() {
            final scopes = provider.customScopes;
            if (scopes.isNotEmpty && !scopes.contains(_lingkupTugas)) {
              _lingkupTugas = scopes.first;
            }
            final cats = provider.categoriesForScope(_lingkupTugas);
            if (cats.isNotEmpty && !cats.contains(_category)) {
              _category = cats.first;
            }
          });
        },
      ),
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
        IconButton(
          icon: const Icon(Icons.add_circle_outline, color: AppTheme.primary),
          tooltip: 'Tambah kategori baru',
          onPressed: () => _showAddCategoryDialog(provider),
        ),
        IconButton(
          icon: const Icon(Icons.tune_rounded, color: AppTheme.textSecondary),
          tooltip: 'Kelola kategori',
          onPressed: () => _showManageCategories(provider),
        ),
      ],
    );
  }

  void _showManageCategories(TaskProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ManageValuesSheet(
        title: 'Kelola Kategori',
        subtitle: 'Kategori untuk lingkup "$_lingkupTugas".',
        addHint: 'Nama kategori baru...',
        getItems: () => provider.categoriesForScope(_lingkupTugas),
        onAdd: (t) => provider.addCategoryToScope(_lingkupTugas, t),
        onRename: (o, n) =>
            provider.renameCategoryInScope(_lingkupTugas, o, n),
        onDelete: (c) => provider.removeCategoryFromScope(_lingkupTugas, c),
        deleteGuard: (c) =>
            provider.categoriesForScope(_lingkupTugas).length <= 1
                ? 'Minimal harus ada satu kategori.'
                : null,
        onChanged: () {
          if (!mounted) return;
          setState(() {
            final cats = provider.categoriesForScope(_lingkupTugas);
            if (cats.isNotEmpty && !cats.contains(_category)) {
              _category = cats.first;
            }
          });
        },
      ),
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

  /// Pintasan deadline umum agar tak perlu selalu buka date+time picker.
  /// Menyetel tanggal ke pukul 23:59 (akhir hari) sebagai konvensi deadline.
  Widget _buildDeadlinePresets() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final presets = <(String, DateTime)>[
      ('Hari ini', today),
      ('Besok', today.add(const Duration(days: 1))),
      ('3 hari', today.add(const Duration(days: 3))),
      ('Minggu depan', today.add(const Duration(days: 7))),
    ];
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: presets.map((p) {
          final target = DateTime(p.$2.year, p.$2.month, p.$2.day, 23, 59);
          final selected = _deadline.year == target.year &&
              _deadline.month == target.month &&
              _deadline.day == target.day &&
              _deadline.hour == 23 &&
              _deadline.minute == 59;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _deadline = target);
                },
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppTheme.primary.withValues(alpha: 0.1)
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: selected ? AppTheme.primary : AppTheme.border,
                        width: selected ? 1.5 : 1),
                  ),
                  child: Text(
                    p.$1,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color:
                          selected ? AppTheme.primary : AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
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
            Expanded(
              child: Column(
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
            ),
            const SizedBox(width: 8),
            _buildUrgensiBadge(),
          ],
        ),
      ),
    );
  }

  /// Badge kecil urgensi otomatis berdasarkan deadline.
  Widget _buildUrgensiBadge() {
    final sisa = _deadline.difference(DateTime.now()).inHours;
    String label;
    Color color;

    if (sisa <= 0) {
      label = 'Lewat';
      color = AppTheme.danger;
    } else if (sisa <= 3) {
      label = '< 3 jam';
      color = AppTheme.danger;
    } else if (sisa <= 24) {
      label = '< 24 jam';
      color = const Color(0xFFF97316);
    } else if (sisa <= 72) {
      label = '< 3 hari';
      color = AppTheme.warning;
    } else if (sisa <= 168) {
      label = '< 7 hari';
      color = AppTheme.success;
    } else {
      label = 'Santai';
      color = AppTheme.success;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  /// Pemilih prioritas ringkas (Rendah/Sedang/Tinggi) menggantikan slider
  /// Kepentingan + Estimasi + ringkasan Eisenhower. Nilainya dipetakan ke
  /// tingkat kepentingan SAW; estimasi memakai nilai default. SAW tetap
  /// mengurutkan tugas dari urgensi (deadline) + kepentingan ini.
  Widget _buildPrioritasPicker() {
    const options = [
      ('Rendah', 2),
      ('Sedang', 3),
      ('Tinggi', 5),
    ];
    final selectedLevel =
        _kepentingan <= 2 ? 2 : (_kepentingan >= 4 ? 5 : 3);
    return Row(
      children: options.map((opt) {
        final selected = selectedLevel == opt.$2;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () => setState(() => _kepentingan = opt.$2),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? AppTheme.primary.withValues(alpha: 0.1)
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected ? AppTheme.primary : AppTheme.border,
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  opt.$1,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color:
                        selected ? AppTheme.primary : AppTheme.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatusSelector() {
    const labels = ['Belum\nDikerjakan', 'Sedang\nDikerjakan', 'Selesai'];
    const icons = [
      Icons.radio_button_unchecked,
      Icons.access_time,
      Icons.check_circle
    ];
    const colors = [AppTheme.textSecondary, AppTheme.warning, AppTheme.success];
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: TaskStatus.values.map((s) {
          final isSelected = _status == s;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: GestureDetector(
                onTap: () => setState(() => _status = s),
                child: Container(
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
                    mainAxisAlignment: MainAxisAlignment.center,
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
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Sakelar notifikasi khusus tugas ini. Ini bawahan dari sakelar global di
  /// Profil → Notifikasi: kalau global mati ([globalEnabled] false), notifikasi
  /// tugas apa pun tidak dikirim, jadi sakelar per-tugas dinonaktifkan agar
  /// tidak berbenturan/menyesatkan. Jadwal pengingat memakai default (H-1,
  /// 3 jam sebelum, tepat deadline).
  Widget _buildNotifToggle(bool globalEnabled) {
    if (!globalEnabled) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.warning.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.warning.withValues(alpha: 0.3)),
        ),
        child: const Row(
          children: [
            Icon(Icons.notifications_off_rounded,
                color: AppTheme.warning, size: 18),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Notifikasi dimatikan untuk semua tugas di Profil → Notifikasi. '
                'Aktifkan di sana dulu untuk mengatur notifikasi per tugas.',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
            ),
          ],
        ),
      );
    }
    return SwitchListTile(
      value: _notifEnabled,
      onChanged: (v) => setState(() => _notifEnabled = v),
      activeThumbColor: AppTheme.primary,
      contentPadding: EdgeInsets.zero,
      title: const Text('Notifikasi tugas ini',
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary)),
      subtitle: Text(
        _notifEnabled
            ? 'Pengingat H-1, 3 jam sebelum, & tepat deadline'
            : 'Notifikasi dimatikan untuk tugas ini saja',
        style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
      ),
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

  Widget _buildRecurrencePicker() {
    return InkWell(
      onTap: _showRecurrenceSheet,
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
            const Icon(Icons.repeat_rounded, color: AppTheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pengulangan',
                      style: TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary)),
                  Text(
                    recurrenceLabel(_recurrence, _deadline,
                        interval: _recurrenceInterval, unit: _recurrenceUnit),
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }

  void _showRecurrenceSheet() {
    const options = [
      RecurrenceType.none,
      RecurrenceType.daily,
      RecurrenceType.weekly,
      RecurrenceType.monthly,
      RecurrenceType.yearly,
      RecurrenceType.weekday,
      RecurrenceType.custom,
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text('Pengulangan',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary)),
            ),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...options.map((opt) {
              final selected = _recurrence == opt;
              final label = opt == RecurrenceType.custom
                  ? 'Custom…'
                  : recurrenceLabel(opt, _deadline);
              return ListTile(
                title: Text(label,
                    style: TextStyle(
                        color: selected
                            ? AppTheme.primary
                            : AppTheme.textPrimary,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500)),
                trailing: selected
                    ? const Icon(Icons.check_rounded, color: AppTheme.primary)
                    : null,
                onTap: () {
                  Navigator.pop(ctx);
                  if (opt == RecurrenceType.custom) {
                    _showCustomRecurrenceSheet();
                  } else {
                    setState(() => _recurrence = opt);
                  }
                },
              );
            }),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomRecurrenceSheet() {
    var interval = _recurrenceInterval < 1 ? 1 : _recurrenceInterval;
    var unit = _recurrenceUnit;
    // endMode: 0 = tidak pernah, 1 = pada tanggal, 2 = setelah N kali
    var endMode = _recurrenceEndDate != null
        ? 1
        : (_recurrenceCount != null ? 2 : 0);
    var endDate = _recurrenceEndDate;
    var count = _recurrenceCount ?? 10;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Pengulangan Custom',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary)),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Ulangi setiap',
                      style: TextStyle(color: AppTheme.textPrimary)),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    color: AppTheme.primary,
                    onPressed: () => setSheet(() {
                      if (interval > 1) interval--;
                    }),
                  ),
                  Text('$interval',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    color: AppTheme.primary,
                    onPressed: () => setSheet(() => interval++),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<RecurrenceUnit>(
                    value: unit,
                    items: const [
                      DropdownMenuItem(
                          value: RecurrenceUnit.day, child: Text('hari')),
                      DropdownMenuItem(
                          value: RecurrenceUnit.week, child: Text('minggu')),
                      DropdownMenuItem(
                          value: RecurrenceUnit.month, child: Text('bulan')),
                      DropdownMenuItem(
                          value: RecurrenceUnit.year, child: Text('tahun')),
                    ],
                    onChanged: (v) =>
                        setSheet(() => unit = v ?? RecurrenceUnit.day),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text('Berakhir',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary)),
              const SizedBox(height: 4),
              _customEndRow(
                selected: endMode == 0,
                onTap: () => setSheet(() => endMode = 0),
                child: const Text('Tidak pernah'),
              ),
              _customEndRow(
                selected: endMode == 1,
                onTap: () => setSheet(() => endMode = 1),
                child: Row(
                  children: [
                    const Text('Pada tanggal'),
                    const SizedBox(width: 8),
                    if (endMode == 1)
                      TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: endDate ??
                                _deadline.add(const Duration(days: 30)),
                            firstDate: _deadline,
                            lastDate:
                                _deadline.add(const Duration(days: 365 * 5)),
                          );
                          if (picked != null) setSheet(() => endDate = picked);
                        },
                        child: Text(endDate == null
                            ? 'Pilih…'
                            : DateFormat('d MMM yyyy', 'id_ID')
                                .format(endDate!)),
                      ),
                  ],
                ),
              ),
              _customEndRow(
                selected: endMode == 2,
                onTap: () => setSheet(() => endMode = 2),
                child: Row(
                  children: [
                    const Text('Setelah'),
                    const SizedBox(width: 8),
                    if (endMode == 2) ...[
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, size: 20),
                        color: AppTheme.primary,
                        onPressed: () =>
                            setSheet(() => count = count > 1 ? count - 1 : 1),
                      ),
                      Text('$count'),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, size: 20),
                        color: AppTheme.primary,
                        onPressed: () => setSheet(() => count++),
                      ),
                      const Text('kali'),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _recurrence = RecurrenceType.custom;
                      _recurrenceInterval = interval;
                      _recurrenceUnit = unit;
                      _recurrenceEndDate = endMode == 1 ? endDate : null;
                      _recurrenceCount = endMode == 2 ? count : null;
                    });
                  },
                  child: const Text('Simpan'),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _customEndRow({
    required bool selected,
    required VoidCallback onTap,
    required Widget child,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected ? AppTheme.primary : AppTheme.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }

  /// Ringkasan seluruh nilai form untuk mendeteksi perubahan belum tersimpan.
  String _formSignature() => [
        _namaTugasCtrl.text,
        _catatanCtrl.text,
        _mataKuliahCtrl.text,
        _deadline.toIso8601String(),
        _kepentingan,
        _estimasiWaktu,
        _lingkupTugas,
        _category,
        _status.index,
        _notifEnabled,
        _notifSchedule.join(','),
        _recurrence.index,
        _recurrenceInterval,
        _recurrenceUnit.index,
        _recurrenceEndDate?.toIso8601String() ?? '',
        _recurrenceCount ?? '',
      ].join('|');

  Future<bool?> _confirmDiscard() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Buang perubahan?'),
        content: const Text('Perubahan yang belum disimpan akan hilang.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Buang'),
          ),
        ],
      ),
    );
  }

  void _save() async {
    // Cegah tugas terdaftar dua kali akibat tap ganda pada tombol simpan
    // saat proses async (scheduler/penyimpanan) masih berjalan.
    if (_isSaving) return;
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

    setState(() => _isSaving = true);

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
        recurrence: _recurrence,
        recurrenceInterval: _recurrenceInterval,
        recurrenceUnit:
            _recurrence == RecurrenceType.custom ? _recurrenceUnit : null,
        clearRecurrenceUnit: _recurrence != RecurrenceType.custom,
        recurrenceEndDate: _recurrenceEndDate,
        clearRecurrenceEndDate: _recurrenceEndDate == null,
        recurrenceCount: _recurrenceCount,
        clearRecurrenceCount: _recurrenceCount == null,
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
        recurrence: _recurrence,
        recurrenceInterval: _recurrenceInterval,
        recurrenceUnit:
            _recurrence == RecurrenceType.custom ? _recurrenceUnit : null,
        recurrenceEndDate: _recurrenceEndDate,
        recurrenceCount: _recurrenceCount,
      );
    }

    if (!mounted) return;

    if (!saved) {
      // Gagal simpan tidak boleh diam-diam (Issue #7) — tetap di form
      // supaya input user tidak hilang, dan beri tahu jelas bahwa harus
      // dicoba lagi. Buka kunci tombol agar user bisa mencoba ulang.
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal menyimpan — coba lagi'),
          backgroundColor: AppTheme.danger,
        ),
      );
      return;
    }

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
              final deletedTask = widget.task!;
              final deleted = await provider.hapusTugas(deletedTask.id);
              if (c.mounted) Navigator.pop(c);
              if (!mounted) return;

              if (!deleted) {
                // Gagal hapus tidak boleh diam-diam (Issue #7).
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Gagal menghapus — coba lagi'),
                    backgroundColor: AppTheme.danger,
                  ),
                );
                return;
              }

              MainNavigation.tabIndex.value = MainNavigation.taskListTab;
              Navigator.popUntil(context, (route) => route.isFirst);
              rootScaffoldMessengerKey.currentState?.showSnackBar(
                SnackBar(
                  content: const Text('Tugas berhasil dihapus'),
                  backgroundColor: AppTheme.danger,
                  action: SnackBarAction(
                    label: 'Urungkan',
                    textColor: Colors.white,
                    onPressed: () => provider.restoreTugas(deletedTask),
                  ),
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

/// Bottom sheet generik untuk mengelola daftar nilai (lingkup/kategori):
/// tambah, ganti nama, dan hapus — dengan penjaga hapus opsional. Sengaja
/// sederhana & dapat dipakai ulang lewat callback.
class _ManageValuesSheet extends StatefulWidget {
  final String title;
  final String subtitle;
  final String addHint;
  final List<String> Function() getItems;
  final Future<void> Function(String) onAdd;
  final Future<bool> Function(String oldName, String newName) onRename;
  final Future<void> Function(String) onDelete;
  final String? Function(String)? deleteGuard;
  final VoidCallback onChanged;

  const _ManageValuesSheet({
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
  State<_ManageValuesSheet> createState() => _ManageValuesSheetState();
}

class _ManageValuesSheetState extends State<_ManageValuesSheet> {
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

