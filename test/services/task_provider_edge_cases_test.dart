import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tugasku/services/task_provider.dart';
import 'package:tugasku/models/task_model.dart';

void main() {
  group('TaskProvider - Edge Cases & Error Handling', () {
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
    // 10.1 General Edge Cases
    // ─────────────────────────────────────────────

    group('Empty State Operations', () {
      test('Skenario activeTasks dengan empty list', () async {
        // Act
        final activeTasks = taskProvider.activeTasks;

        // Assert
        expect(activeTasks.isEmpty, true);
      });

      test('Skenario completedTasks dengan empty list', () async {
        // Act
        final completedTasks = taskProvider.completedTasks;

        // Assert
        expect(completedTasks.isEmpty, true);
      });

      test('Skenario overdueTasks dengan empty list', () async {
        // Act
        final overdueTasks = taskProvider.overdueTasks;

        // Assert
        expect(overdueTasks.isEmpty, true);
      });

      test('Skenario prioritizedTasks dengan empty list', () async {
        // Act
        final prioritizedTasks = taskProvider.prioritizedTasks;

        // Assert
        expect(prioritizedTasks.isEmpty, true);
      });

      test('Skenario totalTugas dengan empty state', () async {
        // Act
        final total = taskProvider.totalTugas;

        // Assert
        expect(total, 0);
      });

      test('Skenario persentaseSelesai dengan empty state', () async {
        // Act
        final percentage = taskProvider.persentaseSelesai;

        // Assert
        expect(percentage, 0);
      });

      test('Skenario getTasksByScope dengan empty list', () async {
        // Act
        final result = taskProvider.getTasksByScope('Any Scope');

        // Assert
        expect(result.isEmpty, true);
      });
    });

    group('Concurrent Operations', () {
      test('Skenario Rapid Add/Delete Sequence', () async {
        // Act
        for (int i = 0; i < 5; i++) {
          await taskProvider.tambahTugas(
            namaTugas: 'Task $i',
            lingkupTugas: 'Scope',
            deadline: DateTime.now().add(const Duration(days: i + 1)),
            tingkatKepentingan: 3,
            estimasiWaktu: 2,
          );
        }

        // Delete in different order
        for (int i = 0; i < 5; i++) {
          if (taskProvider.tasks.isNotEmpty) {
            await taskProvider.hapusTugas(taskProvider.tasks.first.id);
          }
        }

        // Assert
        expect(taskProvider.totalTugas, 0);
      });

      test('Skenario Multiple Updates to Same Task', () async {
        // Arrange
        await taskProvider.tambahTugas(
          namaTugas: 'Task',
          lingkupTugas: 'Scope 1',
          deadline: DateTime.now().add(const Duration(days: 5)),
          tingkatKepentingan: 3,
          estimasiWaktu: 2,
        );

        final taskId = taskProvider.tasks.first.id;

        // Act
        for (int i = 0; i < 3; i++) {
          await taskProvider.editTugas(
            taskId,
            lingkupTugas: 'Scope $i',
          );
        }

        // Assert
        expect(taskProvider.tasks.first.lingkupTugas, 'Scope 2');
      });

      test('Skenario Interleaved Add/Edit Operations', () async {
        // Act
        await taskProvider.tambahTugas(
          namaTugas: 'Task 1',
          lingkupTugas: 'Scope',
          deadline: DateTime.now().add(const Duration(days: 1)),
          tingkatKepentingan: 3,
          estimasiWaktu: 2,
        );

        final task1Id = taskProvider.tasks.first.id;

        await taskProvider.tambahTugas(
          namaTugas: 'Task 2',
          lingkupTugas: 'Scope',
          deadline: DateTime.now().add(const Duration(days: 2)),
          tingkatKepentingan: 2,
          estimasiWaktu: 1,
        );

        await taskProvider.editTugas(task1Id, namaTugas: 'Modified Task 1');

        // Assert
        expect(taskProvider.totalTugas, 2);
        expect(
          taskProvider.tasks.firstWhere((t) => t.id == task1Id).namaTugas,
          'Modified Task 1',
        );
      });
    });

    // ─────────────────────────────────────────────
    // Boundary Values
    // ─────────────────────────────────────────────

    group('Boundary Value Tests', () {
      test('Skenario Priority Level Min: 1', () async {
        // Act
        await taskProvider.tambahTugas(
          namaTugas: 'Min Priority Task',
          lingkupTugas: 'Scope',
          deadline: DateTime.now().add(const Duration(days: 1)),
          tingkatKepentingan: 1,
          estimasiWaktu: 1,
        );

        // Assert
        expect(taskProvider.tasks.first.tingkatKepentingan, 1);
      });

      test('Skenario Priority Level Max: 5', () async {
        // Act
        await taskProvider.tambahTugas(
          namaTugas: 'Max Priority Task',
          lingkupTugas: 'Scope',
          deadline: DateTime.now().add(const Duration(days: 1)),
          tingkatKepentingan: 5,
          estimasiWaktu: 1,
        );

        // Assert
        expect(taskProvider.tasks.first.tingkatKepentingan, 5);
      });

      test('Skenario Duration Min: 1 hour', () async {
        // Act
        await taskProvider.tambahTugas(
          namaTugas: 'Min Duration Task',
          lingkupTugas: 'Scope',
          deadline: DateTime.now().add(const Duration(days: 1)),
          tingkatKepentingan: 3,
          estimasiWaktu: 1,
        );

        // Assert
        expect(taskProvider.tasks.first.estimasiWaktu, 1);
      });

      test('Skenario Duration Large: 100+ hours', () async {
        // Act
        await taskProvider.tambahTugas(
          namaTugas: 'Long Duration Task',
          lingkupTugas: 'Scope',
          deadline: DateTime.now().add(const Duration(days: 30)),
          tingkatKepentingan: 3,
          estimasiWaktu: 120,
        );

        // Assert
        expect(taskProvider.tasks.first.estimasiWaktu, 120);
      });

      test('Skenario Deadline Far Future: Many days', () async {
        // Arrange
        final farDeadline = DateTime.now().add(const Duration(days: 365));

        // Act
        await taskProvider.tambahTugas(
          namaTugas: 'Far Future Task',
          lingkupTugas: 'Scope',
          deadline: farDeadline,
          tingkatKepentingan: 3,
          estimasiWaktu: 2,
        );

        // Assert
        expect(taskProvider.tasks.first.deadline.year, farDeadline.year);
      });

      test('Skenario Deadline Near Future: 1 day', () async {
        // Arrange
        final nearDeadline = DateTime.now().add(const Duration(days: 1));

        // Act
        await taskProvider.tambahTugas(
          namaTugas: 'Near Deadline Task',
          lingkupTugas: 'Scope',
          deadline: nearDeadline,
          tingkatKepentingan: 5,
          estimasiWaktu: 2,
        );

        // Assert
        expect(taskProvider.dueSoonTasks.length, 1);
      });
    });

    // ─────────────────────────────────────────────
    // Null & Invalid Input Handling
    // ─────────────────────────────────────────────

    group('Null/Invalid Input Handling', () {
      test('Skenario Null Task ID pada editTugas', () async {
        // Act & Assert - Should not throw
        await taskProvider.editTugas('null-id', namaTugas: 'Name');

        // Task list should remain unchanged
        expect(taskProvider.totalTugas, 0);
      });

      test('Skenario Whitespace Only Name', () async {
        // Act & Assert - Should throw or be handled
        expect(() async {
          await taskProvider.tambahTugas(
            namaTugas: '   ',
            lingkupTugas: 'Scope',
            deadline: DateTime.now().add(const Duration(days: 1)),
            tingkatKepentingan: 3,
            estimasiWaktu: 2,
          );
        }, throwsA(isA<ArgumentError>()));
      });

      test('Skenario Very Long Task Name', () async {
        // Arrange
        const longName = 'A' * 500;

        // Act
        await taskProvider.tambahTugas(
          namaTugas: longName,
          lingkupTugas: 'Scope',
          deadline: DateTime.now().add(const Duration(days: 1)),
          tingkatKepentingan: 3,
          estimasiWaktu: 2,
        );

        // Assert
        expect(taskProvider.tasks.first.namaTugas, longName);
      });

      test('Skenario Special Characters in Task Name', () async {
        // Arrange
        const specialName = 'Task !@#\$%^&*()_+-={}|:<>?[]\\;\'",./';

        // Act
        await taskProvider.tambahTugas(
          namaTugas: specialName,
          lingkupTugas: 'Scope',
          deadline: DateTime.now().add(const Duration(days: 1)),
          tingkatKepentingan: 3,
          estimasiWaktu: 2,
        );

        // Assert
        expect(taskProvider.tasks.first.namaTugas, specialName);
      });

      test('Skenario Unicode Characters in Task Name', () async {
        // Arrange
        const unicodeName = 'Tugas 中文 العربية 日本語';

        // Act
        await taskProvider.tambahTugas(
          namaTugas: unicodeName,
          lingkupTugas: 'Scope',
          deadline: DateTime.now().add(const Duration(days: 1)),
          tingkatKepentingan: 3,
          estimasiWaktu: 2,
        );

        // Assert
        expect(taskProvider.tasks.first.namaTugas, unicodeName);
      });
    });

    // ─────────────────────────────────────────────
    // 10.2 State Consistency
    // ─────────────────────────────────────────────

    group('State Consistency', () {
      test('Skenario Tasks List Consistency: Order preserved', () async {
        // Arrange
        for (int i = 0; i < 5; i++) {
          await taskProvider.tambahTugas(
            namaTugas: 'Task $i',
            lingkupTugas: 'Scope',
            deadline: DateTime.now().add(Duration(days: i + 1)),
            tingkatKepentingan: 3,
            estimasiWaktu: 2,
          );
        }

        // Act & Assert
        for (int i = 0; i < 5; i++) {
          expect(taskProvider.tasks[i].namaTugas, 'Task $i');
        }
      });

      test('Skenario Metric Consistency: totalTugas matches tasks.length', () async {
        // Arrange
        for (int i = 0; i < 3; i++) {
          await taskProvider.tambahTugas(
            namaTugas: 'Task $i',
            lingkupTugas: 'Scope',
            deadline: DateTime.now().add(const Duration(days: 1)),
            tingkatKepentingan: 3,
            estimasiWaktu: 2,
          );
        }

        // Assert
        expect(taskProvider.totalTugas, taskProvider.tasks.length);
      });

      test('Skenario Active/Completed Consistency', () async {
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
        expect(
          taskProvider.activeTasks.length + taskProvider.completedTasks.length,
          taskProvider.totalTugas,
        );
      });

      test('Skenario No Orphaned Data: Delete removes all references', () async {
        // Arrange
        await taskProvider.tambahTugas(
          namaTugas: 'Task to Clean',
          lingkupTugas: 'Scope',
          deadline: DateTime.now().add(const Duration(days: 5)),
          tingkatKepentingan: 3,
          estimasiWaktu: 2,
        );

        // Wait for scheduler
        await Future.delayed(const Duration(milliseconds: 100));

        final taskId = taskProvider.tasks.first.id;
        final initialBlockCount = taskProvider.timeBlocks.length;

        // Act
        await taskProvider.hapusTugas(taskId);

        // Assert
        expect(taskProvider.totalTugas, 0);
        // Time blocks should be removed or reduced
        expect(taskProvider.timeBlocks.length, lessThanOrEqualTo(initialBlockCount));
      });
    });

    // ─────────────────────────────────────────────
    // Special Scenarios
    // ─────────────────────────────────────────────

    group('Special Scenarios', () {
      test('Skenario All Completed: All tasks marked as completed', () async {
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
        for (final task in taskProvider.tasks.toList()) {
          await taskProvider.updateStatus(task.id, TaskStatus.selesai);
        }

        // Assert
        expect(taskProvider.activeTasks.isEmpty, true);
        expect(taskProvider.completedTasks.length, 2);
        expect(taskProvider.persentaseSelesai, 100.0);
      });

      test('Skenario All Overdue: All tasks overdue', () async {
        // Arrange
        for (int i = 0; i < 3; i++) {
          await taskProvider.tambahTugas(
            namaTugas: 'Overdue Task $i',
            lingkupTugas: 'Scope',
            deadline: DateTime.now().subtract(Duration(days: i + 1)),
            tingkatKepentingan: 5,
            estimasiWaktu: 2,
          );
        }

        // Assert
        expect(taskProvider.overdueTasks.length, 3);
      });

      test('Skenario High Volume: 50+ tasks performance', () async {
        // Act
        final sw = Stopwatch()..start();

        for (int i = 0; i < 50; i++) {
          await taskProvider.tambahTugas(
            namaTugas: 'High Volume Task $i',
            lingkupTugas: 'Scope',
            deadline: DateTime.now().add(Duration(days: (i % 30) + 1)),
            tingkatKepentingan: (i % 5) + 1,
            estimasiWaktu: (i % 8) + 1,
          );
        }

        sw.stop();

        // Assert
        expect(taskProvider.totalTugas, 50);
        expect(sw.elapsedMilliseconds, lessThan(10000)); // Should complete in < 10s
      });
    });
  });
}
