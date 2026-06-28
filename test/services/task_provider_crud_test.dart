import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tugasku/models/task_model.dart';
import 'package:tugasku/services/task_provider.dart';
import 'package:tugasku/services/notification_service.dart';

import '../mocks/mock_notification_service.dart';

void main() {
  group('TaskProvider - CRUD Operations', () {
    late TaskProvider taskProvider;
    late MockNotificationService mockNotifService;

    setUp(() async {
      // Setup mock notification service
      mockNotifService = MockNotificationService();
      
      // Clear all persisted data first
      SharedPreferences.setMockInitialValues({});
      
      // Initialize TaskProvider
      taskProvider = TaskProvider();
      await taskProvider._init();
      
      // Clear tasks before each test
      await taskProvider.clearAllTasks();
    });

    tearDown(() async {
      await taskProvider.clearAllTasks();
    });

    // ─────────────────────────────────────────────
    // 1.1 Test tambahTugas() - Add Task
    // ─────────────────────────────────────────────

    group('tambahTugas() - Add Task', () {
      test('Skenario Valid: Tambah task dengan semua parameter', () async {
        // Arrange
        const namaTugas = 'Tugas UTS Matematika';
        const lingkupTugas = 'Perkuliahan';
        final deadline = DateTime.now().add(const Duration(days: 5));
        const tingkatKepentingan = 4;
        const estimasiWaktu = 3;

        // Act
        await taskProvider.tambahTugas(
          namaTugas: namaTugas,
          lingkupTugas: lingkupTugas,
          deadline: deadline,
          tingkatKepentingan: tingkatKepentingan,
          estimasiWaktu: estimasiWaktu,
        );

        // Assert
        expect(taskProvider.totalTugas, 1);
        expect(taskProvider.tasks.first.namaTugas, namaTugas);
        expect(taskProvider.tasks.first.lingkupTugas, lingkupTugas);
        expect(taskProvider.tasks.first.tingkatKepentingan, tingkatKepentingan);
        expect(taskProvider.tasks.first.estimasiWaktu, estimasiWaktu);
        expect(taskProvider.tasks.first.id, isNotNull);
        expect(taskProvider.tasks.first.createdAt, isNotNull);
      });

      test('Skenario Valid: ID ter-generate unique untuk setiap task', () async {
        // Act
        await taskProvider.tambahTugas(
          namaTugas: 'Task 1',
          lingkupTugas: 'Scope 1',
          deadline: DateTime.now().add(const Duration(days: 1)),
          tingkatKepentingan: 3,
          estimasiWaktu: 2,
        );

        await taskProvider.tambahTugas(
          namaTugas: 'Task 2',
          lingkupTugas: 'Scope 2',
          deadline: DateTime.now().add(const Duration(days: 2)),
          tingkatKepentingan: 2,
          estimasiWaktu: 1,
        );

        // Assert
        expect(taskProvider.totalTugas, 2);
        expect(
          taskProvider.tasks[0].id != taskProvider.tasks[1].id,
          true,
        );
      });

      test('Skenario Multiple Add: Tambah multiple tasks berurutan', () async {
        // Act
        for (int i = 0; i < 5; i++) {
          await taskProvider.tambahTugas(
            namaTugas: 'Task $i',
            lingkupTugas: 'Scope',
            deadline: DateTime.now().add(Duration(days: i + 1)),
            tingkatKepentingan: (i % 5) + 1,
            estimasiWaktu: (i % 4) + 1,
          );
        }

        // Assert
        expect(taskProvider.totalTugas, 5);
        expect(taskProvider.tasks.length, 5);
        
        // Verify order
        for (int i = 0; i < 5; i++) {
          expect(taskProvider.tasks[i].namaTugas, 'Task $i');
        }
      });

      test('Skenario Default Values: Default category dan notification settings', () async {
        // Act
        await taskProvider.tambahTugas(
          namaTugas: 'Test Task',
          lingkupTugas: 'Test Scope',
          deadline: DateTime.now().add(const Duration(days: 1)),
          tingkatKepentingan: 3,
          estimasiWaktu: 2,
        );

        // Assert
        expect(taskProvider.tasks.first.category, 'Tugas');
        expect(taskProvider.tasks.first.notifEnabled, true);
      });

      test('Skenario Validation: Reject empty task name', () async {
        // Act & Assert
        expect(() async {
          await taskProvider.tambahTugas(
            namaTugas: '',
            lingkupTugas: 'Scope',
            deadline: DateTime.now().add(const Duration(days: 1)),
            tingkatKepentingan: 3,
            estimasiWaktu: 2,
          );
        }, throwsA(isA<ArgumentError>()));
      });

      test('Skenario Validation: Reject zero estimasi waktu', () async {
        // Act & Assert
        expect(() async {
          await taskProvider.tambahTugas(
            namaTugas: 'Task',
            lingkupTugas: 'Scope',
            deadline: DateTime.now().add(const Duration(days: 1)),
            tingkatKepentingan: 3,
            estimasiWaktu: 0,
          );
        }, throwsA(isA<ArgumentError>()));
      });

      test('Skenario Validation: Reject negative tingkat kepentingan', () async {
        // Act & Assert
        expect(() async {
          await taskProvider.tambahTugas(
            namaTugas: 'Task',
            lingkupTugas: 'Scope',
            deadline: DateTime.now().add(const Duration(days: 1)),
            tingkatKepentingan: 0,
            estimasiWaktu: 2,
          );
        }, throwsA(isA<ArgumentError>()));
      });

      test('Skenario Validation: Reject tingkat kepentingan > 5', () async {
        // Act & Assert
        expect(() async {
          await taskProvider.tambahTugas(
            namaTugas: 'Task',
            lingkupTugas: 'Scope',
            deadline: DateTime.now().add(const Duration(days: 1)),
            tingkatKepentingan: 6,
            estimasiWaktu: 2,
          );
        }, throwsA(isA<ArgumentError>()));
      });
    });

    // ─────────────────────────────────────────────
    // 1.2 Test editTugas() - Update Task
    // ─────────────────────────────────────────────

    group('editTugas() - Update Task', () {
      late String taskId;

      setUp(() async {
        // Setup: Add a task to edit
        await taskProvider.tambahTugas(
          namaTugas: 'Original Task',
          lingkupTugas: 'Original Scope',
          deadline: DateTime.now().add(const Duration(days: 5)),
          tingkatKepentingan: 3,
          estimasiWaktu: 2,
        );
        taskId = taskProvider.tasks.first.id;
      });

      test('Skenario Update Lengkap: Update semua field sekaligus', () async {
        // Arrange
        const newName = 'Updated Task';
        const newScope = 'Updated Scope';
        final newDeadline = DateTime.now().add(const Duration(days: 10));
        const newPriority = 5;
        const newEstimasi = 4;

        // Act
        await taskProvider.editTugas(
          taskId,
          namaTugas: newName,
          lingkupTugas: newScope,
          deadline: newDeadline,
          tingkatKepentingan: newPriority,
          estimasiWaktu: newEstimasi,
        );

        // Assert
        final updatedTask = taskProvider.tasks.first;
        expect(updatedTask.namaTugas, newName);
        expect(updatedTask.lingkupTugas, newScope);
        expect(updatedTask.tingkatKepentingan, newPriority);
        expect(updatedTask.estimasiWaktu, newEstimasi);
        expect(updatedTask.id, taskId); // ID should not change
      });

      test('Skenario Update Partial: Update hanya nama', () async {
        // Act
        await taskProvider.editTugas(
          taskId,
          namaTugas: 'New Name',
        );

        // Assert
        final updatedTask = taskProvider.tasks.first;
        expect(updatedTask.namaTugas, 'New Name');
        expect(updatedTask.lingkupTugas, 'Original Scope'); // Should remain original
      });

      test('Skenario Status Update: Update status pending to selesai', () async {
        // Act
        await taskProvider.editTugas(
          taskId,
          status: TaskStatus.selesai,
        );

        // Assert
        expect(taskProvider.tasks.first.status, TaskStatus.selesai);
        expect(taskProvider.activeTasks.isEmpty, true);
        expect(taskProvider.completedTasks.length, 1);
      });

      test('Skenario Invalid Edit: Update dengan ID tidak ada', () async {
        // Act & Assert
        await taskProvider.editTugas(
          'invalid-id',
          namaTugas: 'New Name',
        );
        
        // Task should remain unchanged
        expect(taskProvider.tasks.first.namaTugas, 'Original Task');
      });

      test('Skenario Category Change: Update kategori', () async {
        // Act
        await taskProvider.editTugas(
          taskId,
          category: 'Ujian',
        );

        // Assert
        expect(taskProvider.tasks.first.category, 'Ujian');
      });
    });

    // ─────────────────────────────────────────────
    // 1.3 Test hapusTugas() - Delete Task
    // ─────────────────────────────────────────────

    group('hapusTugas() - Delete Task', () {
      test('Skenario Delete Exist: Hapus task yang ada', () async {
        // Arrange
        await taskProvider.tambahTugas(
          namaTugas: 'Task to Delete',
          lingkupTugas: 'Scope',
          deadline: DateTime.now().add(const Duration(days: 1)),
          tingkatKepentingan: 3,
          estimasiWaktu: 2,
        );
        final taskId = taskProvider.tasks.first.id;

        // Act
        await taskProvider.hapusTugas(taskId);

        // Assert
        expect(taskProvider.totalTugas, 0);
        expect(taskProvider.tasks.isEmpty, true);
      });

      test('Skenario Delete Not Exist: Hapus task yang tidak ada', () async {
        // Arrange
        await taskProvider.tambahTugas(
          namaTugas: 'Task',
          lingkupTugas: 'Scope',
          deadline: DateTime.now().add(const Duration(days: 1)),
          tingkatKepentingan: 3,
          estimasiWaktu: 2,
        );
        final initialCount = taskProvider.totalTugas;

        // Act
        await taskProvider.hapusTugas('invalid-id');

        // Assert
        expect(taskProvider.totalTugas, initialCount);
      });

      test('Skenario Delete Multiple: Hapus multiple tasks', () async {
        // Arrange
        final ids = <String>[];
        for (int i = 0; i < 3; i++) {
          await taskProvider.tambahTugas(
            namaTugas: 'Task $i',
            lingkupTugas: 'Scope',
            deadline: DateTime.now().add(const Duration(days: 1)),
            tingkatKepentingan: 3,
            estimasiWaktu: 2,
          );
          ids.add(taskProvider.tasks[i].id);
        }

        // Act
        for (final id in ids) {
          await taskProvider.hapusTugas(id);
        }

        // Assert
        expect(taskProvider.totalTugas, 0);
        expect(taskProvider.tasks.isEmpty, true);
      });

      test('Skenario Delete Completion Impact: Update metrics setelah delete', () async {
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
        final taskId = taskProvider.tasks.first.id;

        // Act
        await taskProvider.hapusTugas(taskId);

        // Assert
        expect(taskProvider.totalTugas, 1);
        expect(taskProvider.tugasAktif, 1);
      });
    });

    // ─────────────────────────────────────────────
    // 1.4 Test updateStatus() - Update Task Status
    // ─────────────────────────────────────────────

    group('updateStatus() - Update Task Status', () {
      late String taskId;

      setUp(() async {
        await taskProvider.tambahTugas(
          namaTugas: 'Status Test Task',
          lingkupTugas: 'Scope',
          deadline: DateTime.now().add(const Duration(days: 3)),
          tingkatKepentingan: 3,
          estimasiWaktu: 2,
        );
        taskId = taskProvider.tasks.first.id;
      });

      test('Skenario Valid Status Transition: pending to selesai', () async {
        // Act
        await taskProvider.updateStatus(taskId, TaskStatus.selesai);

        // Assert
        expect(taskProvider.tasks.first.status, TaskStatus.selesai);
      });

      test('Skenario Selesai Status: Move dari active ke completed', () async {
        // Arrange
        expect(taskProvider.activeTasks.length, 1);
        expect(taskProvider.completedTasks.isEmpty, true);

        // Act
        await taskProvider.updateStatus(taskId, TaskStatus.selesai);

        // Assert
        expect(taskProvider.activeTasks.isEmpty, true);
        expect(taskProvider.completedTasks.length, 1);
      });

      test('Skenario Invalid Task: Update status task tidak ada', () async {
        // Act
        await taskProvider.updateStatus('invalid-id', TaskStatus.selesai);

        // Assert - Should not throw error and task should remain unchanged
        expect(taskProvider.tasks.first.status, TaskStatus.pending);
      });
    });

    // ─────────────────────────────────────────────
    // 2.1 Test Getters & Computed Properties
    // ─────────────────────────────────────────────

    group('Task Provider - Query/Getter Methods', () {
      test('Skenario activeTasks: Get tasks yang belum selesai', () async {
        // Arrange
        await taskProvider.tambahTugas(
          namaTugas: 'Active Task',
          lingkupTugas: 'Scope',
          deadline: DateTime.now().add(const Duration(days: 1)),
          tingkatKepentingan: 3,
          estimasiWaktu: 2,
        );
        await taskProvider.tambahTugas(
          namaTugas: 'Completed Task',
          lingkupTugas: 'Scope',
          deadline: DateTime.now().add(const Duration(days: 2)),
          tingkatKepentingan: 2,
          estimasiWaktu: 1,
        );
        
        // Mark second task as completed
        await taskProvider.updateStatus(
          taskProvider.tasks[1].id,
          TaskStatus.selesai,
        );

        // Assert
        expect(taskProvider.activeTasks.length, 1);
        expect(taskProvider.activeTasks.first.namaTugas, 'Active Task');
      });

      test('Skenario completedTasks: Get tasks yang selesai', () async {
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

        // Mark both as completed
        await taskProvider.updateStatus(
          taskProvider.tasks[0].id,
          TaskStatus.selesai,
        );
        await taskProvider.updateStatus(
          taskProvider.tasks[1].id,
          TaskStatus.selesai,
        );

        // Assert
        expect(taskProvider.completedTasks.length, 2);
      });

      test('Skenario Metrics: totalTugas count correct', () async {
        // Act
        for (int i = 0; i < 3; i++) {
          await taskProvider.tambahTugas(
            namaTugas: 'Task $i',
            lingkupTugas: 'Scope',
            deadline: DateTime.now().add(const Duration(days: i + 1)),
            tingkatKepentingan: 3,
            estimasiWaktu: 2,
          );
        }

        // Assert
        expect(taskProvider.totalTugas, 3);
      });

      test('Skenario Metrics: tugasAktif and tugasSelesai counts', () async {
        // Arrange
        await taskProvider.tambahTugas(
          namaTugas: 'Active',
          lingkupTugas: 'Scope',
          deadline: DateTime.now().add(const Duration(days: 1)),
          tingkatKepentingan: 3,
          estimasiWaktu: 2,
        );
        await taskProvider.tambahTugas(
          namaTugas: 'Completed',
          lingkupTugas: 'Scope',
          deadline: DateTime.now().add(const Duration(days: 2)),
          tingkatKepentingan: 2,
          estimasiWaktu: 1,
        );

        // Act
        await taskProvider.updateStatus(
          taskProvider.tasks[1].id,
          TaskStatus.selesai,
        );

        // Assert
        expect(taskProvider.tugasAktif, 1);
        expect(taskProvider.tugasSelesai, 1);
        expect(taskProvider.totalTugas, 2);
      });

      test('Skenario Metrics: persentaseSelesai calculation', () async {
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

        // Act
        await taskProvider.updateStatus(
          taskProvider.tasks[0].id,
          TaskStatus.selesai,
        );

        // Assert
        expect(taskProvider.persentaseSelesai, 50.0);
      });

      test('Skenario getTasksByScope: Get tasks by scope', () async {
        // Arrange
        await taskProvider.tambahTugas(
          namaTugas: 'Task 1',
          lingkupTugas: 'Perkuliahan',
          deadline: DateTime.now().add(const Duration(days: 1)),
          tingkatKepentingan: 3,
          estimasiWaktu: 2,
        );
        await taskProvider.tambahTugas(
          namaTugas: 'Task 2',
          lingkupTugas: 'Tugas Rumah',
          deadline: DateTime.now().add(const Duration(days: 2)),
          tingkatKepentingan: 2,
          estimasiWaktu: 1,
        );

        // Act
        final perkuliahanTasks = taskProvider.getTasksByScope('Perkuliahan');
        final tugasRumahTasks = taskProvider.getTasksByScope('Tugas Rumah');

        // Assert
        expect(perkuliahanTasks.length, 1);
        expect(tugasRumahTasks.length, 1);
        expect(perkuliahanTasks.first.namaTugas, 'Task 1');
      });

      test('Skenario getTasksByScope: Query scope yang tidak ada', () async {
        // Arrange
        await taskProvider.tambahTugas(
          namaTugas: 'Task',
          lingkupTugas: 'Perkuliahan',
          deadline: DateTime.now().add(const Duration(days: 1)),
          tingkatKepentingan: 3,
          estimasiWaktu: 2,
        );

        // Act
        final result = taskProvider.getTasksByScope('Non-Exist Scope');

        // Assert
        expect(result.isEmpty, true);
      });
    });
  });
}
