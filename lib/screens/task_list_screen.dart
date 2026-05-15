import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/task_model.dart';
import '../services/task_provider.dart';
import '../utils/app_assets.dart';
import '../utils/app_theme.dart';
import '../widgets/task_card_widget.dart';
import 'add_edit_task_screen.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  String _filterPrioritas = 'Semua'; // nilai valid: 'Semua', 'Tinggi', 'Sedang', 'Rendah'
  String _sortMode = 'Default'; // nilai valid: 'Default', 'Prioritas Tertinggi'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Data Tugas'),
        backgroundColor: AppTheme.primary,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Semua'),
            Tab(text: 'Individu'),
            Tab(text: 'Kelompok'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilterSortBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTaskList(null),
                _buildTaskList(TaskGroup.individu),
                _buildTaskList(TaskGroup.kelompok),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddEditTaskScreen()),
        ),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Tambah Tugas',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Cari tugas...',
          prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: AppTheme.textSecondary),
                  onPressed: () => setState(() => _searchQuery = ''),
                )
              : null,
        ),
        onChanged: (value) => setState(() => _searchQuery = value),
      ),
    );
  }

  List<Task> _applyFilterAndSort(List<Task> tasks, int totalActive) {
    // 1. Filter pencarian teks
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      tasks = tasks
          .where(
            (t) =>
                t.namaTugas.toLowerCase().contains(q) ||
                t.mataKuliah.toLowerCase().contains(q),
          )
          .toList();
    }

    // 2. Filter prioritas
    if (_filterPrioritas != 'Semua') {
      tasks = tasks.where((t) {
        if (t.ranking == 0 || t.status == TaskStatus.selesai) return false;
        return AppTheme.getPrioritasLabel(t.ranking, totalActive) ==
            _filterPrioritas;
      }).toList();
    }

    // 3. Sort
    if (_sortMode == 'Prioritas Tertinggi') {
      tasks.sort((a, b) {
        if (a.ranking == 0 && b.ranking == 0) return 0;
        if (a.ranking == 0) return 1; // ranking 0 ke bawah
        if (b.ranking == 0) return -1;
        return a.ranking.compareTo(b.ranking);
      });
    }

    return tasks;
  }

  Widget _buildFilterSortBar() {
    const filterOptions = ['Semua', 'Tinggi', 'Sedang', 'Rendah'];
    const sortOptions = ['Default', 'Prioritas Tertinggi'];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Baris filter prioritas
          Row(
            children: [
              const Text(
                'Filter:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: filterOptions.map((label) {
                      final isSelected = _filterPrioritas == label;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          label: Text(
                            label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : AppTheme.textPrimary,
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (_) =>
                              setState(() => _filterPrioritas = label),
                          selectedColor: AppTheme.primary,
                          backgroundColor: AppTheme.background,
                          checkmarkColor: Colors.white,
                          showCheckmark: false,
                          side: BorderSide(
                            color: isSelected
                                ? AppTheme.primary
                                : AppTheme.border,
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 0),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Baris sort
          Row(
            children: [
              const Text(
                'Urutkan:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: sortOptions.map((label) {
                      final isSelected = _sortMode == label;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          label: Text(
                            label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : AppTheme.textPrimary,
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (_) =>
                              setState(() => _sortMode = label),
                          selectedColor: AppTheme.primary,
                          backgroundColor: AppTheme.background,
                          checkmarkColor: Colors.white,
                          showCheckmark: false,
                          side: BorderSide(
                            color: isSelected
                                ? AppTheme.primary
                                : AppTheme.border,
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 0),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList(TaskGroup? group) {
    return Consumer<TaskProvider>(
      builder: (context, provider, _) {
        List<Task> tasks = group == null
            ? provider.tasks
            : group == TaskGroup.individu
                ? provider.individuTasks
                : provider.kelompokTasks;

        if (group == null) {
          final active = provider.activeTasks;
          final done = provider.completedTasks;
          tasks = [...active, ...done];
        }

        final totalActiveTasks = provider.activeTasks.length;
        tasks = _applyFilterAndSort(tasks, totalActiveTasks);

        if (tasks.isEmpty && _filterPrioritas != 'Semua') {
          return _buildEmptyFilterState(_filterPrioritas);
        }

        if (tasks.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];
            return TaskCardWidget(
              task: task,
              showRanking: true,
              totalActiveTasks: totalActiveTasks,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => AddEditTaskScreen(task: task)),
              ),
              onDelete: () => _confirmDelete(context, provider, task),
              onStatusChange: (status) =>
                  provider.updateStatus(task.id, status),
            );
          },
        );
      },
    );
  }

  void _confirmDelete(BuildContext ctx, TaskProvider provider, Task task) {
    showDialog(
      context: ctx,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Tugas'),
        content: Text('Hapus "${task.namaTugas}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.hapusTugas(task.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(
                  content: Text('Tugas berhasil dihapus'),
                  backgroundColor: AppTheme.danger,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyFilterState(String label) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.filter_list_off, size: 64, color: AppTheme.textSecondary),
          const SizedBox(height: 16),
          Text(
            'Tidak ada tugas dengan prioritas $label saat ini.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(AppAssets.emptyTasks, width: 180, height: 135),
          const SizedBox(height: 16),
          const Text(
            'Belum ada tugas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap tombol + untuk menambah tugas baru',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}
