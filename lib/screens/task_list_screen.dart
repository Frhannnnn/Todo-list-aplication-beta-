// lib/screens/task_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/task_provider.dart';
import '../models/task_model.dart';
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
  TaskGroup? _filterGroup;

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
        title: const Text('📋 Data Tugas'),
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
        onPressed: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const AddEditTaskScreen())),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Tambah Tugas',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
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
                onPressed: () => setState(() => _searchQuery = ''))
            : null,
        ),
        onChanged: (v) => setState(() => _searchQuery = v),
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

        // Filter tugas yang belum selesai dulu, lalu tambahkan yang selesai
        if (group == null) {
          final active = provider.activeTasks;
          final done = provider.completedTasks;
          tasks = [...active, ...done];
        }

        if (_searchQuery.isNotEmpty) {
          tasks = tasks.where((t) =>
            t.namaTugas.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            t.mataKuliah.toLowerCase().contains(_searchQuery.toLowerCase())
          ).toList();
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
              onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => AddEditTaskScreen(task: task))),
              onDelete: () => _confirmDelete(context, provider, task),
              onStatusChange: (status) => provider.updateStatus(task.id, status),
            );
          },
        );
      },
    );
  }

  void _confirmDelete(BuildContext ctx, TaskProvider provider, Task task) {
    showDialog(
      context: ctx,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Tugas'),
        content: Text('Hapus "${task.namaTugas}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              provider.hapusTugas(task.id);
              Navigator.pop(c);
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(content: Text('Tugas berhasil dihapus'),
                  backgroundColor: AppTheme.danger));
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('Hapus'),
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
          const Text('📭', style: TextStyle(fontSize: 60)),
          const SizedBox(height: 16),
          const Text('Belum ada tugas',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary)),
          const SizedBox(height: 8),
          const Text('Tap tombol + untuk menambah tugas baru',
            style: TextStyle(color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}
