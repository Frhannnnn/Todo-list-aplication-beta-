import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/task_model.dart';
import '../services/task_provider.dart';
import '../utils/app_assets.dart';
import '../utils/app_theme.dart';
import '../widgets/task_card_widget.dart';
import '../widgets/rename_dialog.dart';
import '../utils/task_status_actions.dart';
import 'add_edit_task_screen.dart';

const TextStyle _sheetLabel = TextStyle(
    fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary);

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  String _searchQuery = '';
  String _filterPrioritas = 'Semua';
  String _sortMode = 'Default';

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, provider, _) {
        final scopes = provider.customScopes;

        // Dynamically build tabs based on scopes
        final tabs = <Widget>[
          const Tab(text: 'Semua', height: 36),
          ...scopes.map((s) => Tab(text: s, height: 36)),
        ];

        final tabViews = <Widget>[
          _buildTaskList(null, provider),
          ...scopes.map((scope) => _buildTaskList(scope, provider)),
        ];

        return DefaultTabController(
          length: tabs.length,
          child: Scaffold(
            backgroundColor: AppTheme.background,
            body: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, provider),
                  _buildTabBar(tabs),
                  _buildSearchFilterRow(context),
                  Expanded(
                    child: TabBarView(
                      children: tabViews,
                    ),
                  ),
                ],
              ),
            ),
            floatingActionButton: FloatingActionButton(
              heroTag: 'task_list_add_task_fab',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddEditTaskScreen()),
              ),
              backgroundColor: AppTheme.primary,
              elevation: 0,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, TaskProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Data Tugas',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          GestureDetector(
            onTap: () => _showScopeManager(context, provider),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.border),
              ),
              child: const Icon(Icons.tune_rounded,
                  color: AppTheme.textSecondary, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(List<Widget> tabs) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(4),
      child: TabBar(
        labelColor: Colors.white,
        unselectedLabelColor: AppTheme.textSecondary,
        labelStyle:
            const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle:
            const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        indicator: BoxDecoration(
          color: AppTheme.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        isScrollable: tabs.length > 2,
        tabAlignment:
            tabs.length > 2 ? TabAlignment.start : TabAlignment.fill,
        tabs: tabs,
      ),
    );
  }

  /// Baris tunggal: kolom pencarian + satu tombol filter. Filter prioritas &
  /// urutan dipindah ke bottom sheet supaya daftar tugas tidak tertutup tiga
  /// baris kontrol.
  Widget _buildSearchFilterRow(BuildContext context) {
    final filterActive = _filterPrioritas != 'Semua' || _sortMode != 'Default';
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Cari tugas...',
                hintStyle: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: AppTheme.textSecondary),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded,
                            color: AppTheme.textSecondary),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppTheme.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppTheme.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: AppTheme.primary, width: 1.5),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => _showFilterSheet(context),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: filterActive ? AppTheme.primary : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: filterActive ? AppTheme.primary : AppTheme.border),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(Icons.filter_list_rounded,
                      color: filterActive
                          ? Colors.white
                          : AppTheme.textSecondary,
                      size: 22),
                  if (filterActive)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Bottom sheet filter prioritas + urutan. Perubahan langsung diterapkan
  /// (setState induk) sehingga daftar ikut ter-update.
  void _showFilterSheet(BuildContext context) {
    const filterOptions = ['Semua', 'Tinggi', 'Sedang', 'Rendah'];
    const sortOptions = ['Default', 'Prioritas Tertinggi'];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Filter & Urutan',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary)),
                    if (_filterPrioritas != 'Semua' || _sortMode != 'Default')
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _filterPrioritas = 'Semua';
                            _sortMode = 'Default';
                          });
                          setSheet(() {});
                        },
                        child: const Text('Reset'),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('Prioritas', style: _sheetLabel),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: filterOptions.map((label) {
                    final selected = _filterPrioritas == label;
                    return _sheetChip(label, selected, AppTheme.primary, () {
                      setState(() => _filterPrioritas = label);
                      setSheet(() {});
                    });
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Text('Urutkan', style: _sheetLabel),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: sortOptions.map((label) {
                    final selected = _sortMode == label;
                    return _sheetChip(label, selected, AppTheme.secondary, () {
                      setState(() => _sortMode = label);
                      setSheet(() {});
                    });
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sheetChip(
      String label, bool selected, Color accent, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? accent : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? accent : AppTheme.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  List<Task> _applyFilterAndSort(List<Task> tasks, int totalActive) {
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      tasks = tasks
          .where((t) =>
              t.namaTugas.toLowerCase().contains(q) ||
              t.lingkupTugas.toLowerCase().contains(q))
          .toList();
    }

    if (_filterPrioritas != 'Semua') {
      tasks = tasks.where((t) {
        if (t.ranking == 0 || t.status == TaskStatus.selesai) return false;
        return AppTheme.getPrioritasLabel(t.ranking, totalActive) ==
            _filterPrioritas;
      }).toList();
    }

    if (_sortMode == 'Prioritas Tertinggi') {
      tasks.sort((a, b) {
        if (a.ranking == 0 && b.ranking == 0) return 0;
        if (a.ranking == 0) return 1;
        if (b.ranking == 0) return -1;
        return a.ranking.compareTo(b.ranking);
      });
    }

    return tasks;
  }

  Widget _buildTaskList(String? scope, TaskProvider provider) {
    List<Task> tasks;
    if (scope == null) {
      // "Semua" tab
      final active = provider.activeTasks;
      final done = provider.completedTasks;
      tasks = [...active, ...done];
    } else {
      tasks = provider.getTasksByScope(scope);
    }

    final totalActiveTasks = provider.activeTasks.length;
    tasks = _applyFilterAndSort(tasks, totalActiveTasks);

    Widget child;
    if (tasks.isEmpty && _searchQuery.trim().isNotEmpty) {
      child = _scrollableCenter(
          _buildNoResultsState('Tidak ada tugas yang cocok dengan pencarianmu.'));
    } else if (tasks.isEmpty && _filterPrioritas != 'Semua') {
      child = _scrollableCenter(_buildEmptyFilterState(_filterPrioritas));
    } else if (tasks.isEmpty && provider.tasks.isEmpty) {
      // Benar-benar belum ada tugas → onboarding.
      child = _scrollableCenter(_buildEmptyState(context));
    } else if (tasks.isEmpty) {
      // Ada tugas lain, tapi lingkup/tab ini kosong.
      child =
          _scrollableCenter(_buildNoResultsState('Belum ada tugas di sini.'));
    } else {
      child = ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];
          return Dismissible(
            key: ValueKey(task.id),
            background: _swipeBackground(
              alignment: Alignment.centerLeft,
              color: AppTheme.success,
              icon: Icons.check_rounded,
              label: 'Selesai',
            ),
            secondaryBackground: _swipeBackground(
              alignment: Alignment.centerRight,
              color: AppTheme.danger,
              icon: Icons.delete_outline_rounded,
              label: 'Hapus',
            ),
            confirmDismiss: (direction) async {
              if (direction == DismissDirection.startToEnd) {
                // Geser kanan → tandai selesai (tidak menghapus dari daftar).
                if (task.status != TaskStatus.selesai) {
                  handleStatusChange(
                      context, provider, task, TaskStatus.selesai);
                }
                return false;
              }
              // Geser kiri → konfirmasi hapus.
              return _confirmDeleteDialog(context, task);
            },
            onDismissed: (_) => _deleteWithUndo(context, provider, task),
            child: TaskCardWidget(
              task: task,
              // Rank numerik (#N) redundan dengan label prioritas (Tinggi/
              // Sedang/Rendah) di kartu — biarkan #N khusus di layar Prioritas.
              showRanking: false,
              totalActiveTasks: totalActiveTasks,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => AddEditTaskScreen(task: task)),
              ),
              onDelete: () => _confirmDelete(context, provider, task),
              onStatusChange: (status) =>
                  handleStatusChange(context, provider, task, status),
            ),
          );
        },
      );
    }

    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: () => provider.refresh(),
      child: child,
    );
  }

  /// Bungkus konten kosong agar tetap bisa di-pull-to-refresh.
  Widget _scrollableCenter(Widget child) {
    return LayoutBuilder(
      builder: (context, constraints) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: constraints.maxHeight,
            child: Center(child: child),
          ),
        ],
      ),
    );
  }

  Widget _swipeBackground({
    required Alignment alignment,
    required Color color,
    required IconData icon,
    required String label,
  }) {
    final left = alignment == Alignment.centerLeft;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      alignment: alignment,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (left) Icon(icon, color: color, size: 22),
          if (left) const SizedBox(width: 8),
          Text(label,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w700, fontSize: 14)),
          if (!left) const SizedBox(width: 8),
          if (!left) Icon(icon, color: color, size: 22),
        ],
      ),
    );
  }

  Future<bool> _confirmDeleteDialog(BuildContext ctx, Task task) async {
    final result = await showDialog<bool>(
      context: ctx,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Tugas'),
        content: Text('Hapus "${task.namaTugas}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _deleteWithUndo(
      BuildContext ctx, TaskProvider provider, Task task) async {
    final deleted = await provider.hapusTugas(task.id);
    if (!ctx.mounted) return;
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text(deleted
            ? 'Tugas berhasil dihapus'
            : 'Gagal menghapus — coba lagi'),
        backgroundColor: AppTheme.danger,
        action: deleted
            ? SnackBarAction(
                label: 'Urungkan',
                textColor: Colors.white,
                onPressed: () => provider.restoreTugas(task),
              )
            : null,
      ),
    );
  }

  void _confirmDelete(BuildContext ctx, TaskProvider provider, Task task) {
    showDialog(
      context: ctx,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Tugas'),
        content: Text('Hapus "${task.namaTugas}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final deleted = await provider.hapusTugas(task.id);
              if (context.mounted) Navigator.pop(context);
              if (!ctx.mounted) return;
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(
                  content: Text(deleted
                      ? 'Tugas berhasil dihapus'
                      : 'Gagal menghapus — coba lagi'),
                  backgroundColor: AppTheme.danger,
                  action: deleted
                      ? SnackBarAction(
                          label: 'Urungkan',
                          textColor: Colors.white,
                          onPressed: () => provider.restoreTugas(task),
                        )
                      : null,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.danger),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  // ─── Scope Manager ────────────────────────────────────────────────────────

  void _showScopeManager(BuildContext context, TaskProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _ScopeManagerSheet(provider: provider),
    );
  }

  // ─── Empty States ─────────────────────────────────────────────────────────

  Widget _buildEmptyFilterState(String label) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.filter_list_off_rounded,
                size: 32, color: AppTheme.primary),
          ),
          const SizedBox(height: 16),
          Text(
            'Tidak ada tugas dengan prioritas $label',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.search_off_rounded,
                  size: 32, color: AppTheme.primary),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(AppAssets.emptyTasks, width: 160, height: 120),
            const SizedBox(height: 20),
            const Text(
              'Selamat datang di Priora 👋',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tambahkan tugas pertamamu, lalu Priora akan mengurutkan mana yang harus dikerjakan lebih dulu.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const AddEditTaskScreen()),
              ),
              icon: const Icon(Icons.add, size: 20),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 22, vertical: 14),
              ),
              label: const Text('Buat Tugas Pertama',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Scope Manager Bottom Sheet ───────────────────────────────────────────────

class _ScopeManagerSheet extends StatefulWidget {
  final TaskProvider provider;
  const _ScopeManagerSheet({required this.provider});

  @override
  State<_ScopeManagerSheet> createState() => _ScopeManagerSheetState();
}

class _ScopeManagerSheetState extends State<_ScopeManagerSheet> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scopes = widget.provider.customScopes;

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
              'Kelola Lingkup Tugas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Tab pada daftar tugas diambil dari lingkup ini.',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            // List scopes
            if (scopes.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Belum ada lingkup. Tambahkan di bawah.',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              )
            else
              ...scopes.map((scope) => ListTile(
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
                    title: Text(scope,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined,
                              color: AppTheme.textSecondary, size: 20),
                          tooltip: 'Ganti nama',
                          onPressed: () => _renameScope(context, scope),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded,
                              color: AppTheme.danger, size: 20),
                          tooltip: 'Hapus',
                          onPressed: () => _confirmRemoveScope(context, scope),
                        ),
                      ],
                    ),
                  )),
            const Divider(height: 24),
            // Add new scope
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    decoration: InputDecoration(
                      hintText: 'Nama lingkup baru...',
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppTheme.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppTheme.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: AppTheme.primary, width: 1.5),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onSubmitted: (_) => _addScope(),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _addScope,
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

  void _addScope() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    widget.provider.addScope(text);
    _ctrl.clear();
    setState(() {});
  }

  Future<void> _renameScope(BuildContext context, String oldName) async {
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => RenameDialog(
        title: 'Ganti Nama Lingkup',
        initialValue: oldName,
        onSubmit: (newName) => widget.provider.renameScope(oldName, newName),
      ),
    );
    if (result != null && mounted) setState(() {});
  }

  /// Hapus lingkup [scope]. Kalau masih ada tugas yang memakainya, user
  /// wajib memindahkannya ke lingkup lain dulu (Issue #4) — tidak pernah
  /// diam-diam meninggalkan tugas yatim.
  Future<void> _confirmRemoveScope(BuildContext context, String scope) async {
    final tasksInScope = widget.provider.getTasksByScope(scope);

    if (tasksInScope.isEmpty) {
      await widget.provider.removeScope(scope);
      if (mounted) setState(() {});
      return;
    }

    final otherScopes =
        widget.provider.customScopes.where((s) => s != scope).toList();

    if (otherScopes.isEmpty) {
      if (!context.mounted) return;
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Tidak Bisa Dihapus'),
          content: Text(
              'Lingkup "$scope" masih dipakai ${tasksInScope.length} tugas, dan tidak ada lingkup lain untuk memindahkannya. Buat lingkup baru dulu, atau hapus tugas-tugasnya terlebih dahulu.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Mengerti')),
          ],
        ),
      );
      return;
    }

    if (!context.mounted) return;
    final target = await showDialog<String>(
      context: context,
      builder: (ctx) => _ReassignScopeDialog(
        scope: scope,
        affectedCount: tasksInScope.length,
        otherScopes: otherScopes,
      ),
    );

    if (target != null) {
      await widget.provider.removeScope(scope, reassignTasksTo: target);
      if (mounted) setState(() {});
    }
  }
}

/// Dialog konfirmasi hapus lingkup yang masih dipakai tugas — user wajib
/// memilih lingkup pengganti sebelum tugas-tugas dipindahkan & lingkup lama
/// dihapus.
class _ReassignScopeDialog extends StatefulWidget {
  final String scope;
  final int affectedCount;
  final List<String> otherScopes;

  const _ReassignScopeDialog({
    required this.scope,
    required this.affectedCount,
    required this.otherScopes,
  });

  @override
  State<_ReassignScopeDialog> createState() => _ReassignScopeDialogState();
}

class _ReassignScopeDialogState extends State<_ReassignScopeDialog> {
  late String _target = widget.otherScopes.first;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Hapus Lingkup Tugas'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
              'Lingkup "${widget.scope}" masih dipakai ${widget.affectedCount} tugas. Pindahkan tugas-tugas itu ke lingkup lain sebelum menghapus:'),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _target,
            isExpanded: true,
            items: widget.otherScopes
                .map((s) => DropdownMenuItem(
                    value: s, child: Text(s, overflow: TextOverflow.ellipsis)))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _target = v);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
          onPressed: () => Navigator.pop(context, _target),
          child: const Text('Pindahkan & Hapus'),
        ),
      ],
    );
  }
}