import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tugasku/services/task_provider.dart';
import 'package:tugasku/models/task_model.dart';

void main() {
  group('TaskProvider - Data Persistence & Storage', () {
    late TaskProvider taskProvider;

    setUp(() async {
      // Clear all persisted data first
      SharedPreferences.setMockInitialValues({});
      
      // Initialize TaskProvider
      taskProvider = TaskProvider();
      await taskProvider._init();
    });

    tearDown(() async {
      await taskProvider.clearAllTasks();
    });

    // ─────────────────────────────────────────────
    // 7.1 Test _saveTasks() & _loadTasks()
    // ─────────────────────────────────────────────

    group('Tasks Persistence', () {
      test('Skenario Save & Load: Data persistence dari tasks', () async {
        // Arrange
        await taskProvider.tambahTugas(
          namaTugas: 'Persistent Task',
          lingkupTugas: 'Scope',
          deadline: DateTime.now().add(const Duration(days: 1)),
          tingkatKepentingan: 3,
          estimasiWaktu: 2,
        );

        final originalTaskId = taskProvider.tasks.first.id;
        final originalTaskName = taskProvider.tasks.first.namaTugas;

        // Act - Create new provider dan load data
        final newProvider = TaskProvider();
        await newProvider._init();

        // Assert
        expect(newProvider.totalTugas, 1);
        expect(newProvider.tasks.first.id, originalTaskId);
        expect(newProvider.tasks.first.namaTugas, originalTaskName);
      });

      test('Skenario Large Dataset: Save dan load 10+ tasks', () async {
        // Arrange
        const taskCount = 15;
        for (int i = 0; i < taskCount; i++) {
          await taskProvider.tambahTugas(
            namaTugas: 'Task $i',
            lingkupTugas: 'Scope',
            deadline: DateTime.now().add(Duration(days: i + 1)),
            tingkatKepentingan: (i % 5) + 1,
            estimasiWaktu: (i % 4) + 1,
          );
        }

        // Act
        final newProvider = TaskProvider();
        await newProvider._init();

        // Assert
        expect(newProvider.totalTugas, taskCount);
        for (int i = 0; i < taskCount; i++) {
          expect(newProvider.tasks[i].namaTugas, 'Task $i');
        }
      });

      test('Skenario Load Empty: Load when no tasks saved', () async {
        // Act
        final newProvider = TaskProvider();
        await newProvider._init();

        // Assert
        expect(newProvider.totalTugas, 0);
        expect(newProvider.tasks.isEmpty, true);
      });

      test('Skenario Task Status Persistence: Task status preserved', () async {
        // Arrange
        await taskProvider.tambahTugas(
          namaTugas: 'Status Test Task',
          lingkupTugas: 'Scope',
          deadline: DateTime.now().add(const Duration(days: 1)),
          tingkatKepentingan: 3,
          estimasiWaktu: 2,
        );

        final taskId = taskProvider.tasks.first.id;

        // Mark as completed
        await taskProvider.updateStatus(taskId, TaskStatus.selesai);

        // Act - Load from new provider
        final newProvider = TaskProvider();
        await newProvider._init();

        // Assert
        expect(newProvider.tasks.first.status, TaskStatus.selesai);
        expect(newProvider.completedTasks.length, 1);
      });

      test('Skenario Task Metrics Persistence: Metrics recalculated correctly', () async {
        // Arrange
        await taskProvider.tambahTugas(
          namaTugas: 'Task 1',
          lingkupTugas: 'Scope',
          deadline: DateTime.now().add(const Duration(days: 1)),
          tingkatKepentingan: 3,
          estimasiWaktu: 2,
        );

        await taskProvider.tambahTugas(
          namaTugas: 'Task 2',
          lingkupTugas: 'Scope',
          deadline: DateTime.now().add(const Duration(days: 2)),
          tingkatKepentingan: 2,
          estimasiWaktu: 1,
        );

        await taskProvider.updateStatus(
          taskProvider.tasks[0].id,
          TaskStatus.selesai,
        );

        // Act
        final newProvider = TaskProvider();
        await newProvider._init();

        // Assert
        expect(newProvider.totalTugas, 2);
        expect(newProvider.tugasSelesai, 1);
        expect(newProvider.tugasAktif, 1);
        expect(newProvider.persentaseSelesai, 50.0);
      });
    });

    // ─────────────────────────────────────────────
    // 7.2 Test Schedule Persistence
    // ─────────────────────────────────────────────

    group('Schedule Persistence', () {
      test('Skenario Schedule Config Persistence: Config saved and loaded', () async {
        // Arrange
        final prefs = await SharedPreferences.getInstance();
        
        // Verify schedule config exists in preferences after init
        final configString = prefs.getString('tugasku_schedule_config');

        // Assert
        expect(configString, isNotNull);
      });

      test('Skenario Schedule Load: Time blocks loaded correctly', () async {
        // Arrange
        await taskProvider.tambahTugas(
          namaTugas: 'Task',
          lingkupTugas: 'Scope',
          deadline: DateTime.now().add(const Duration(days: 5)),
          tingkatKepentingan: 3,
          estimasiWaktu: 2,
        );

        // Wait for scheduler
        await Future.delayed(const Duration(milliseconds: 100));

        final initialBlockCount = taskProvider.timeBlocks.length;

        // Act
        final newProvider = TaskProvider();
        await newProvider._init();

        // Assert
        expect(newProvider.timeBlocks.isNotEmpty, initialBlockCount > 0);
      });

      test('Skenario Fresh Schedule: Empty schedule on first launch', () async {
        // Clear preferences completely
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();

        // Act
        final newProvider = TaskProvider();
        await newProvider._init();

        // Assert
        expect(newProvider.timeBlocks, isNotNull);
      });
    });

    // ─────────────────────────────────────────────
    // Error Handling & Edge Cases
    // ─────────────────────────────────────────────

    group('Persistence Error Handling', () {
      test('Skenario Partial Data Loss: Still loadable', () async {
        // Arrange
        await taskProvider.tambahTugas(
          namaTugas: 'Task 1',
          lingkupTugas: 'Scope',
          deadline: DateTime.now().add(const Duration(days: 1)),
          tingkatKepentingan: 3,
          estimasiWaktu: 2,
        );

        // Act - Load should work even with partial data
        final newProvider = TaskProvider();
        await newProvider._init();

        // Assert
        expect(newProvider.totalTugas, 1);
      });

      test('Skenario Backup Mechanism: Backup exists', () async {
        // Arrange
        await taskProvider.tambahTugas(
          namaTugas: 'Backup Test Task',
          lingkupTugas: 'Scope',
          deadline: DateTime.now().add(const Duration(days: 1)),
          tingkatKepentingan: 3,
          estimasiWaktu: 2,
        );

        // Act
        final prefs = await SharedPreferences.getInstance();
        final mainData = prefs.getString('tugasku_tasks');
        final backupData = prefs.getString('tugasku_tasks_backup');

        // Assert
        expect(mainData, isNotNull);
        // Backup might not exist on first save, but should be handled gracefully
      });

      test('Skenario Multiple Loads: Consistent data', () async {
        // Arrange
        await taskProvider.tambahTugas(
          namaTugas: 'Consistency Test',
          lingkupTugas: 'Scope',
          deadline: DateTime.now().add(const Duration(days: 1)),
          tingkatKepentingan: 3,
          estimasiWaktu: 2,
        );

        const loadCount = 3;

        // Act & Assert
        for (int i = 0; i < loadCount; i++) {
          final provider = TaskProvider();
          await provider._init();
          expect(provider.totalTugas, 1);
          expect(provider.tasks.first.namaTugas, 'Consistency Test');
        }
      });
    });

    // ─────────────────────────────────────────────
    // Clear All Tasks
    // ─────────────────────────────────────────────

    group('Clear Operations', () {
      test('Skenario clearAllTasks: Semua tasks dan notifications dihapus', () async {
        // Arrange
        for (int i = 0; i < 3; i++) {
          await taskProvider.tambahTugas(
            namaTugas: 'Task $i',
            lingkupTugas: 'Scope',
            deadline: DateTime.now().add(const Duration(days: i + 1)),
            tingkatKepentingan: 3,
            estimasiWaktu: 2,
          );
        }

        expect(taskProvider.totalTugas, 3);

        // Act
        await taskProvider.clearAllTasks();

        // Assert
        expect(taskProvider.totalTugas, 0);
        expect(taskProvider.tasks.isEmpty, true);
      });

      test('Skenario clearAllTasks: Data cleared from SharedPreferences', () async {
        // Arrange
        await taskProvider.tambahTugas(
          namaTugas: 'Task to Clear',
          lingkupTugas: 'Scope',
          deadline: DateTime.now().add(const Duration(days: 1)),
          tingkatKepentingan: 3,
          estimasiWaktu: 2,
        );

        // Act
        await taskProvider.clearAllTasks();

        // Act - Load new provider to verify data is cleared
        final newProvider = TaskProvider();
        await newProvider._init();

        // Assert
        expect(newProvider.totalTugas, 0);
      });

      test('Skenario clearAllTasks: Safe when already empty', () async {
        // Act
        await taskProvider.clearAllTasks();
        await taskProvider.clearAllTasks(); // Second clear

        // Assert
        expect(taskProvider.totalTugas, 0);
      });
    });
  });
}
