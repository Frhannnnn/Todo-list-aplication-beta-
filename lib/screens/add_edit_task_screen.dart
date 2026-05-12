// lib/screens/add_edit_task_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/task_provider.dart';
import '../models/task_model.dart';
import '../utils/app_assets.dart';
import '../utils/app_theme.dart';

class AddEditTaskScreen extends StatefulWidget {
  final Task? task;
  const AddEditTaskScreen({super.key, this.task});

  @override
  State<AddEditTaskScreen> createState() => _AddEditTaskScreenState();
}

class _AddEditTaskScreenState extends State<AddEditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaTugasCtrl = TextEditingController();
  final _mataKuliahCtrl = TextEditingController();
  final _catatanCtrl = TextEditingController();

  DateTime _deadline = DateTime.now().add(const Duration(days: 7));
  int _kepentingan = 3;
  int _urgensi = 3;
  int _estimasiWaktu = 3;
  TaskGroup _group = TaskGroup.individu;
  TaskCategory _category = TaskCategory.kuliah;
  TaskStatus _status = TaskStatus.belumDikerjakan;

  bool get isEdit => widget.task != null;

  @override
  void initState() {
    super.initState();
    if (isEdit) {
      final t = widget.task!;
      _namaTugasCtrl.text = t.namaTugas;
      _mataKuliahCtrl.text = t.mataKuliah;
      _catatanCtrl.text = t.catatan ?? '';
      _deadline = t.deadline;
      _kepentingan = t.tingkatKepentingan;
      _urgensi = t.tingkatUrgensi;
      _estimasiWaktu = t.estimasiWaktu;
      _group = t.group;
      _category = t.category;
      _status = t.status;
    }
  }

  @override
  void dispose() {
    _namaTugasCtrl.dispose();
    _mataKuliahCtrl.dispose();
    _catatanCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(isEdit ? '✏️ Edit Tugas' : '➕ Tambah Tugas'),
        backgroundColor: AppTheme.primary,
        actions: [
          if (isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white),
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
              _buildTextField(_namaTugasCtrl, 'Nama Tugas', Icons.assignment,
                  validator: (v) => v!.isEmpty ? 'Wajib diisi' : null),
              const SizedBox(height: 12),
              _buildTextField(_mataKuliahCtrl, 'Mata Kuliah', Icons.school,
                  validator: (v) => v!.isEmpty ? 'Wajib diisi' : null),
            ]),
            const SizedBox(height: 16),
            _buildSection('Deadline', [
              _buildDeadlinePicker(),
            ]),
            const SizedBox(height: 16),
            _buildSection('Kategori & Grup', [
              _buildDropdownRow(),
            ]),
            const SizedBox(height: 16),
            _buildSection('Parameter SAW', [
              _buildSlider('Tingkat Kepentingan', _kepentingan,
                  (v) => setState(() => _kepentingan = v.round()),
                  hint: 'Seberapa penting tugas ini?'),
              const SizedBox(height: 12),
              _buildSlider('Tingkat Urgensi', _urgensi,
                  (v) => setState(() => _urgensi = v.round()),
                  hint: 'Seberapa mendesak tugas ini?'),
              const SizedBox(height: 12),
              _buildSlider('Estimasi Waktu (jam)', _estimasiWaktu,
                  (v) => setState(() => _estimasiWaktu = v.round()),
                  hint: 'Berapa jam yang dibutuhkan?', max: 10),
            ]),
            const SizedBox(height: 16),
            _buildSection('Status', [_buildStatusSelector()]),
            const SizedBox(height: 16),
            _buildSection('Catatan', [
              TextFormField(
                controller: _catatanCtrl,
                decoration: const InputDecoration(
                  hintText: 'Tambah catatan (opsional)...',
                  prefixIcon: Icon(Icons.notes),
                ),
                maxLines: 3,
              ),
            ]),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _save,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(isEdit ? 'Simpan Perubahan' : 'Tambah Tugas',
                    style: const TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          const Divider(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController ctrl, String label, IconData icon,
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
                    style:
                        TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                Text(
                    DateFormat('EEEE, d MMMM yyyy - HH:mm', 'id_ID')
                        .format(_deadline),
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary)),
              ],
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownRow() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Kategori',
                  style:
                      TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              DropdownButton<TaskCategory>(
                value: _category,
                isExpanded: true,
                underline: const SizedBox(),
                onChanged: (v) => setState(() => _category = v!),
                items: TaskCategory.values.map((c) {
                  return DropdownMenuItem(
                    value: c,
                    child: Row(
                      children: [
                        Image.asset(
                          AppAssets.categoryIcon(c),
                          width: 24,
                          height: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(AppAssets.categoryLabel(c)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Grup',
                  style:
                      TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              DropdownButton<TaskGroup>(
                value: _group,
                isExpanded: true,
                underline: const SizedBox(),
                onChanged: (v) => setState(() => _group = v!),
                items: const [
                  DropdownMenuItem(
                      value: TaskGroup.individu, child: Text('Individu')),
                  DropdownMenuItem(
                      value: TaskGroup.kelompok, child: Text('Kelompok')),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSlider(String label, int value, ValueChanged<double> onChanged,
      {String? hint, int max = 5}) {
    final labels = [
      '',
      'Sangat Rendah',
      'Rendah',
      'Sedang',
      'Tinggi',
      'Sangat Tinggi',
      '6 jam',
      '7 jam',
      '8 jam',
      '9 jam',
      '10 jam'
    ];

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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(max == 5 ? labels[value] : '$value jam',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary)),
            ),
          ],
        ),
        if (hint != null)
          Text(hint,
              style:
                  const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
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

  Widget _buildStatusSelector() {
    return Row(
      children: TaskStatus.values.map((s) {
        final labels = ['Belum\nDikerjakan', 'Sedang\nDikerjakan', 'Selesai'];
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
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
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
                      color:
                          isSelected ? colors[s.index] : AppTheme.textSecondary,
                      size: 20),
                  const SizedBox(height: 4),
                  Text(labels[s.index],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.normal,
                        color: isSelected
                            ? colors[s.index]
                            : AppTheme.textSecondary,
                      )),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<TaskProvider>();

    if (isEdit) {
      await provider.editTugas(
        widget.task!.id,
        namaTugas: _namaTugasCtrl.text.trim(),
        mataKuliah: _mataKuliahCtrl.text.trim(),
        deadline: _deadline,
        tingkatKepentingan: _kepentingan,
        tingkatUrgensi: _urgensi,
        estimasiWaktu: _estimasiWaktu,
        status: _status,
        group: _group,
        category: _category,
        catatan: _catatanCtrl.text.trim(),
      );
    } else {
      await provider.tambahTugas(
        namaTugas: _namaTugasCtrl.text.trim(),
        mataKuliah: _mataKuliahCtrl.text.trim(),
        deadline: _deadline,
        tingkatKepentingan: _kepentingan,
        tingkatUrgensi: _urgensi,
        estimasiWaktu: _estimasiWaktu,
        group: _group,
        category: _category,
        catatan: _catatanCtrl.text.trim(),
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
              onPressed: () => Navigator.pop(c), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
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
