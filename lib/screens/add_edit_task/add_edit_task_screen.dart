// lib/screens/add_edit_task/add_edit_task_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/task_provider.dart';
import '../../models/task_model.dart';
import '../../utils/app_theme.dart';
import '../../main.dart';
import '../../widgets/add_name_dialog.dart';
import '../ai_task_creator_screen.dart';
import 'catatan_field.dart';
import 'deadline_section.dart';
import 'manage_values_sheet.dart';
import 'notif_toggle.dart';
import 'priority_picker.dart';
import 'recurrence_picker_tile.dart';
import 'recurrence_type_sheet.dart';
import 'scope_category_fields.dart';
import 'status_selector.dart';

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
                  DeadlinePresets(
                    deadline: _deadline,
                    onChanged: (d) => setState(() => _deadline = d),
                  ),
                  const SizedBox(height: 12),
                  DeadlinePicker(
                    deadline: _deadline,
                    onChanged: (d) => setState(() => _deadline = d),
                  ),
                ]),
                const SizedBox(height: 16),
                _buildSection('Prioritas', [
                  PriorityPicker(
                    kepentingan: _kepentingan,
                    onChanged: (v) => setState(() => _kepentingan = v),
                  ),
                ]),
                const SizedBox(height: 16),
                _buildAdvancedToggle(),
                if (_showAdvanced) ...[
                  const SizedBox(height: 16),
                  _buildSection('Pengulangan', [
                    RecurrencePickerTile(
                      recurrence: _recurrence,
                      deadline: _deadline,
                      recurrenceInterval: _recurrenceInterval,
                      recurrenceUnit: _recurrenceUnit,
                      onTap: _pickRecurrence,
                    ),
                  ]),
                  if (isEdit) ...[
                    const SizedBox(height: 16),
                    _buildSection('Status', [
                      StatusSelector(
                        status: _status,
                        onChanged: (v) => setState(() => _status = v),
                      ),
                    ]),
                  ],
                  const SizedBox(height: 16),
                  _buildSection('Notifikasi', [
                    NotifToggle(
                      globalEnabled: provider.notifEnabled,
                      notifEnabled: _notifEnabled,
                      onChanged: (v) => setState(() => _notifEnabled = v),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  _buildSection('Catatan', [
                    CatatanField(
                      controller: _catatanCtrl,
                      onExpand: () => showFullscreenNoteSheet(
                        context,
                        initialText: _catatanCtrl.text,
                        onSave: (t) => setState(() => _catatanCtrl.text = t),
                      ),
                    ),
                  ]),
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
    // Ensure _lingkupTugas is in the list
    if (scopes.isNotEmpty && !scopes.contains(_lingkupTugas)) {
      _lingkupTugas = scopes.first;
    }
    return ScopeDropdownField(
      scopes: scopes,
      value: _lingkupTugas,
      onScopeSelected: (v) => setState(() {
        _lingkupTugas = v;
        // Kategori independen per lingkup (Issue #4) — reset ke
        // kategori pertama milik lingkup baru saat lingkup diganti.
        final catsForNewScope = provider.categoriesForScope(v);
        _category = catsForNewScope.isNotEmpty ? catsForNewScope.first : '';
      }),
      onAddPressed: () => _showAddScopeDialog(provider),
      onManagePressed: () => _showManageScopes(provider),
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
      builder: (_) => ManageValuesSheet(
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
      builder: (_) => AddNameDialog(
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
    return CategoryDropdownField(
      categories: categories,
      value: _category,
      onChanged: (v) => setState(() => _category = v),
      onAddPressed: () => _showAddCategoryDialog(provider),
      onManagePressed: () => _showManageCategories(provider),
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
      builder: (_) => ManageValuesSheet(
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
      builder: (_) => AddNameDialog(
        title: 'Tambah Kategori',
        hint: 'Nama kategori...',
        onSubmit: (text) => provider.addCategoryToScope(_lingkupTugas, text),
      ),
    );
    if (result != null && mounted) {
      setState(() => _category = result);
    }
  }

  Future<void> _pickRecurrence() async {
    final result = await showRecurrenceTypeSheet(
      context,
      current: (
        type: _recurrence,
        interval: _recurrenceInterval,
        unit: _recurrenceUnit,
        endDate: _recurrenceEndDate,
        count: _recurrenceCount,
      ),
      deadline: _deadline,
    );
    if (result == null || !mounted) return;
    setState(() {
      _recurrence = result.type;
      _recurrenceInterval = result.interval;
      _recurrenceUnit = result.unit;
      _recurrenceEndDate = result.endDate;
      _recurrenceCount = result.count;
    });
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
