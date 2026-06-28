// lib/screens/ai_task_creator_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/ai_task_creator_service.dart';
import '../services/task_provider.dart';
import '../utils/app_theme.dart';

class AITaskCreatorScreen extends StatefulWidget {
  const AITaskCreatorScreen({super.key});

  @override
  State<AITaskCreatorScreen> createState() => _AITaskCreatorScreenState();
}

class _AITaskCreatorScreenState extends State<AITaskCreatorScreen> {
  final _inputController = TextEditingController();
  final _aiService = AITaskCreatorService();

  // State management
  bool _isLoading = false;
  String? _errorMessage;
  List<TaskSuggestion> _suggestions = [];
  bool _isPreviewMode = false;

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  int get _inputLength => _inputController.text.length;
  bool get _isInputValid => _inputLength >= 50 && _inputLength <= 10000;
  int get _selectedCount =>
      _suggestions.where((s) => s.isSelected).length;

  Future<void> _processInput() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await _aiService.extractTasks(_inputController.text);
      setState(() {
        _suggestions = results;
        _isPreviewMode = true;
        _isLoading = false;
      });
    } on AIExtractionException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage =
            'Ekstraksi gagal — coba perjelas input atau buat tugas manual.';
        _isLoading = false;
      });
    }
  }

  Future<void> _confirmTasks() async {
    final provider = context.read<TaskProvider>();
    final selectedSuggestions =
        _suggestions.where((s) => s.isSelected).toList();

    if (selectedSuggestions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih minimal satu tugas untuk disimpan'),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      for (final suggestion in selectedSuggestions) {
        await provider.tambahTugas(
          namaTugas: suggestion.namaTugas,
          mataKuliah: '',
          deadline: suggestion.deadline ??
              DateTime.now().add(const Duration(days: 7)),
          tingkatKepentingan: suggestion.tingkatKepentingan,
          tingkatUrgensi: suggestion.tingkatUrgensi,
          estimasiWaktu: suggestion.estimasiWaktu,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${selectedSuggestions.length} tugas berhasil ditambahkan'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal menyimpan tugas: $e';
        _isLoading = false;
      });
    }
  }

  void _editSuggestion(int index) {
    final suggestion = _suggestions[index];
    final nameController = TextEditingController(text: suggestion.namaTugas);
    int estimasi = suggestion.estimasiWaktu;
    int kepentingan = suggestion.tingkatKepentingan;
    int urgensi = suggestion.tingkatUrgensi;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Edit Tugas'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Tugas',
                    prefixIcon: Icon(Icons.assignment, color: AppTheme.primary),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Estimasi Waktu: $estimasi jam',
                    style: const TextStyle(fontSize: 13)),
                Slider(
                  value: estimasi.toDouble(),
                  min: 1,
                  max: 10,
                  divisions: 9,
                  activeColor: AppTheme.primary,
                  onChanged: (v) =>
                      setDialogState(() => estimasi = v.round()),
                ),
                const SizedBox(height: 8),
                Text('Kepentingan: $kepentingan',
                    style: const TextStyle(fontSize: 13)),
                Slider(
                  value: kepentingan.toDouble(),
                  min: 1,
                  max: 5,
                  divisions: 4,
                  activeColor: AppTheme.primary,
                  onChanged: (v) =>
                      setDialogState(() => kepentingan = v.round()),
                ),
                const SizedBox(height: 8),
                Text('Urgensi: $urgensi',
                    style: const TextStyle(fontSize: 13)),
                Slider(
                  value: urgensi.toDouble(),
                  min: 1,
                  max: 5,
                  divisions: 4,
                  activeColor: AppTheme.primary,
                  onChanged: (v) =>
                      setDialogState(() => urgensi = v.round()),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _suggestions[index] = TaskSuggestion(
                    namaTugas: nameController.text.trim(),
                    deadline: suggestion.deadline,
                    estimasiWaktu: estimasi,
                    tingkatKepentingan: kepentingan,
                    tingkatUrgensi: urgensi,
                    isSelected: suggestion.isSelected,
                  );
                });
                Navigator.pop(ctx);
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteSuggestion(int index) {
    setState(() {
      _suggestions.removeAt(index);
      if (_suggestions.isEmpty) {
        _isPreviewMode = false;
      }
    });
  }

  void _backToInput() {
    setState(() {
      _isPreviewMode = false;
      _suggestions = [];
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Buat Tugas Otomatis'),
        backgroundColor: Colors.transparent,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_isPreviewMode) {
              _backToInput();
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _isPreviewMode
              ? _buildPreviewState()
              : _buildInputState(),
    );
  }

  // ─── Input State ───────────────────────────────────────────────────────────

  Widget _buildInputState() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection(
            'Input Teks',
            [
              const Text(
                'Tempel silabus, brief proyek, atau daftar tugas untuk diekstrak secara otomatis oleh AI.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _inputController,
                maxLines: 10,
                maxLength: 10000,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText:
                      'Contoh:\n- UTS Algoritma, deadline 15 Maret\n- Project Web Development\n- Laporan Praktikum Fisika...',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary.withValues(alpha: 0.6),
                  ),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$_inputLength / 10.000 karakter',
                    style: TextStyle(
                      fontSize: 12,
                      color: _inputLength < 50
                          ? AppTheme.danger
                          : AppTheme.textSecondary,
                    ),
                  ),
                  if (_inputLength > 0 && _inputLength < 50)
                    Text(
                      'Minimum ${50 - _inputLength} karakter lagi',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.danger,
                      ),
                    ),
                ],
              ),
            ],
          ),
          if (_inputLength > 0 && _inputLength < 50) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppTheme.warning.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 16,
                      color: AppTheme.warning.withValues(alpha: 0.8)),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Input terlalu pendek (minimum 50 karakter)',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: AppTheme.danger.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      size: 16, color: AppTheme.danger),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.danger,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isInputValid ? _processInput : null,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Proses dengan AI'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ─── Loading State ─────────────────────────────────────────────────────────

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppTheme.primary),
          const SizedBox(height: 24),
          Text(
            _isPreviewMode
                ? 'Menyimpan tugas...'
                : 'Mengekstrak tugas dari teks...',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Mohon tunggu sebentar',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Preview State ─────────────────────────────────────────────────────────

  Widget _buildPreviewState() {
    return Column(
      children: [
        // Header info
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: AppTheme.primary.withValues(alpha: 0.05),
          child: Row(
            children: [
              const Icon(Icons.checklist, color: AppTheme.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$_selectedCount dari ${_suggestions.length} tugas dipilih',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    final allSelected =
                        _suggestions.every((s) => s.isSelected);
                    for (final s in _suggestions) {
                      s.isSelected = !allSelected;
                    }
                  });
                },
                child: Text(
                  _suggestions.every((s) => s.isSelected)
                      ? 'Batal Semua'
                      : 'Pilih Semua',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        // Task list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _suggestions.length,
            itemBuilder: (context, index) =>
                _buildSuggestionCard(index),
          ),
        ),
        // Bottom action bar
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: AppTheme.border),
            ),
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _selectedCount > 0 ? _confirmTasks : null,
              icon: const Icon(Icons.check_circle_outline),
              label: Text('Konfirmasi $_selectedCount Tugas'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestionCard(int index) {
    final suggestion = _suggestions[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: suggestion.isSelected
              ? AppTheme.primary.withValues(alpha: 0.4)
              : AppTheme.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Checkbox
          Checkbox(
            value: suggestion.isSelected,
            activeColor: AppTheme.primary,
            onChanged: (value) {
              setState(() {
                suggestion.isSelected = value ?? false;
              });
            },
          ),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  suggestion.namaTugas,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _buildChip(
                      Icons.schedule,
                      '${suggestion.estimasiWaktu} jam',
                    ),
                    _buildChip(
                      Icons.priority_high,
                      'K:${suggestion.tingkatKepentingan}',
                    ),
                    _buildChip(
                      Icons.speed,
                      'U:${suggestion.tingkatUrgensi}',
                    ),
                    if (suggestion.deadline != null)
                      _buildChip(
                        Icons.event,
                        DateFormat('d MMM', 'id_ID')
                            .format(suggestion.deadline!),
                      ),
                  ],
                ),
              ],
            ),
          ),
          // Actions
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () => _editSuggestion(index),
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(Icons.edit_outlined,
                      size: 18, color: AppTheme.primary),
                ),
              ),
              const SizedBox(height: 4),
              InkWell(
                onTap: () => _deleteSuggestion(index),
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(Icons.delete_outline,
                      size: 18, color: AppTheme.danger),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppTheme.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppTheme.primary,
            ),
          ),
        ],
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
}
