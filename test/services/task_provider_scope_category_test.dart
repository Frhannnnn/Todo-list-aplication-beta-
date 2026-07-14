import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tugasku/services/task_provider.dart';

import '../mocks/mock_notification_service.dart';

void main() {
  group('TaskProvider - Scope & Category Management', () {
    late TaskProvider taskProvider;

    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      taskProvider = TaskProvider(notifService: MockNotificationService());
      await taskProvider.init();
    });

    tearDown(() async {
      await taskProvider.clearAllTasks();
    });

    // ─────────────────────────────────────────────
    // 3.1 Test addScope() & removeScope()
    // ─────────────────────────────────────────────

    group('Scope Management', () {
      test('Skenario Add Valid Scope: Tambah scope baru', () async {
        // Arrange
        const newScope = 'Proyek';
        final initialCount = taskProvider.customScopes.length;

        // Act
        await taskProvider.addScope(newScope);

        // Assert
        expect(taskProvider.customScopes.length, initialCount + 1);
        expect(taskProvider.customScopes.contains(newScope), true);
      });

      test('Skenario Add Valid Scope: Trim whitespace', () async {
        // Act
        await taskProvider.addScope('  Proyek  ');

        // Assert
        expect(taskProvider.customScopes.contains('Proyek'), true);
      });

      test('Skenario Add Invalid Scope: Reject duplicate', () async {
        // Arrange
        const scope = 'Perkuliahan';
        final initialCount = taskProvider.customScopes.length;

        // Act
        await taskProvider.addScope(scope); // Should be ignored (duplicate)

        // Assert
        expect(taskProvider.customScopes.length, initialCount);
      });

      test('Skenario Add Invalid Scope: Reject empty string', () async {
        // Arrange
        final initialCount = taskProvider.customScopes.length;

        // Act
        await taskProvider.addScope('');

        // Assert
        expect(taskProvider.customScopes.length, initialCount);
      });

      test('Skenario Remove Scope: Remove existing scope', () async {
        // Arrange
        const newScope = 'Olahraga';
        await taskProvider.addScope(newScope);
        final countAfterAdd = taskProvider.customScopes.length;

        // Act
        await taskProvider.removeScope(newScope);

        // Assert
        expect(taskProvider.customScopes.length, countAfterAdd - 1);
        expect(taskProvider.customScopes.contains(newScope), false);
      });

      test('Skenario Remove Scope: Safe remove non-exist scope', () async {
        // Arrange
        final initialCount = taskProvider.customScopes.length;

        // Act
        await taskProvider.removeScope('Non-Exist Scope');

        // Assert
        expect(taskProvider.customScopes.length, initialCount);
      });

      test('Skenario Multiple Scopes: Add multiple scopes', () async {
        // Act
        await taskProvider.addScope('Scope 1');
        await taskProvider.addScope('Scope 2');
        await taskProvider.addScope('Scope 3');

        // Assert
        expect(taskProvider.customScopes.contains('Scope 1'), true);
        expect(taskProvider.customScopes.contains('Scope 2'), true);
        expect(taskProvider.customScopes.contains('Scope 3'), true);
      });

      test('Skenario Multiple Scopes: Remove some scopes', () async {
        // Arrange
        await taskProvider.addScope('Scope 1');
        await taskProvider.addScope('Scope 2');
        await taskProvider.addScope('Scope 3');

        // Act
        await taskProvider.removeScope('Scope 2');

        // Assert
        expect(taskProvider.customScopes.contains('Scope 1'), true);
        expect(taskProvider.customScopes.contains('Scope 2'), false);
        expect(taskProvider.customScopes.contains('Scope 3'), true);
      });
    });

    // ─────────────────────────────────────────────
    // 3.2 Test addCategoryToScope() & removeCategoryFromScope()
    // Kategori kini per-lingkup (Issue #4) — tidak lagi global.
    // ─────────────────────────────────────────────

    group('Category Management (per-scope)', () {
      const scope = 'Perkuliahan';

      test('Skenario Add Valid Category: Tambah category baru ke lingkup', () async {
        final initialCount = taskProvider.categoriesForScope(scope).length;

        await taskProvider.addCategoryToScope(scope, 'Seminar');

        expect(taskProvider.categoriesForScope(scope).length, initialCount + 1);
        expect(taskProvider.categoriesForScope(scope).contains('Seminar'), true);
      });

      test('Skenario Add Valid Category: Trim whitespace', () async {
        await taskProvider.addCategoryToScope(scope, '  Seminar  ');

        expect(taskProvider.categoriesForScope(scope).contains('Seminar'), true);
      });

      test('Skenario Add Invalid Category: Reject duplicate dalam lingkup sama', () async {
        const category = 'Tugas';
        final initialCount = taskProvider.categoriesForScope(scope).length;

        await taskProvider.addCategoryToScope(scope, category);

        expect(taskProvider.categoriesForScope(scope).length, initialCount);
      });

      test('Skenario Add Invalid Category: Reject empty string', () async {
        final initialCount = taskProvider.categoriesForScope(scope).length;

        await taskProvider.addCategoryToScope(scope, '');

        expect(taskProvider.categoriesForScope(scope).length, initialCount);
      });

      test('Skenario Remove Category: Remove existing category', () async {
        const newCategory = 'Workshop';
        await taskProvider.addCategoryToScope(scope, newCategory);
        final countAfterAdd = taskProvider.categoriesForScope(scope).length;

        await taskProvider.removeCategoryFromScope(scope, newCategory);

        expect(taskProvider.categoriesForScope(scope).length, countAfterAdd - 1);
        expect(taskProvider.categoriesForScope(scope).contains(newCategory), false);
      });

      test('Skenario Remove Category: Safe remove non-exist category', () async {
        final initialCount = taskProvider.categoriesForScope(scope).length;

        await taskProvider.removeCategoryFromScope(scope, 'Non-Exist Category');

        expect(taskProvider.categoriesForScope(scope).length, initialCount);
      });

      test('Skenario Multiple Categories: Add multiple categories', () async {
        await taskProvider.addCategoryToScope(scope, 'Category 1');
        await taskProvider.addCategoryToScope(scope, 'Category 2');
        await taskProvider.addCategoryToScope(scope, 'Category 3');

        final cats = taskProvider.categoriesForScope(scope);
        expect(cats.contains('Category 1'), true);
        expect(cats.contains('Category 2'), true);
        expect(cats.contains('Category 3'), true);
      });

      test('Skenario Multiple Categories: Remove some categories', () async {
        await taskProvider.addCategoryToScope(scope, 'Category 1');
        await taskProvider.addCategoryToScope(scope, 'Category 2');
        await taskProvider.addCategoryToScope(scope, 'Category 3');

        await taskProvider.removeCategoryFromScope(scope, 'Category 2');

        final cats = taskProvider.categoriesForScope(scope);
        expect(cats.contains('Category 1'), true);
        expect(cats.contains('Category 2'), false);
        expect(cats.contains('Category 3'), true);
      });

      test('Skenario Independensi: kategori di satu lingkup tidak memengaruhi lingkup lain', () async {
        await taskProvider.addCategoryToScope('Perkuliahan', 'Ujian Tengah Semester');

        expect(
          taskProvider.categoriesForScope('Perkuliahan').contains('Ujian Tengah Semester'),
          true,
        );
        expect(
          taskProvider.categoriesForScope('Tugas Rumah').contains('Ujian Tengah Semester'),
          false,
        );
      });

      test('Skenario Independensi: dua lingkup boleh punya kategori dengan nama sama', () async {
        await taskProvider.addCategoryToScope('Perkuliahan', 'Mendesak');
        await taskProvider.addCategoryToScope('Tugas Rumah', 'Mendesak');

        expect(taskProvider.categoriesForScope('Perkuliahan').contains('Mendesak'), true);
        expect(taskProvider.categoriesForScope('Tugas Rumah').contains('Mendesak'), true);

        // Hapus dari satu lingkup tidak menghapus dari lingkup lain
        await taskProvider.removeCategoryFromScope('Perkuliahan', 'Mendesak');
        expect(taskProvider.categoriesForScope('Perkuliahan').contains('Mendesak'), false);
        expect(taskProvider.categoriesForScope('Tugas Rumah').contains('Mendesak'), true);
      });
    });

    // ─────────────────────────────────────────────
    // 3.3 Test renameScope() & renameCategoryInScope() (Issue #9)
    // ─────────────────────────────────────────────

    group('Rename (cascade)', () {
      test('Skenario Rename Scope: tugas lama ikut menunjuk nama baru', () async {
        await taskProvider.tambahTugas(
          namaTugas: 'Tugas A',
          lingkupTugas: 'Perkuliahan',
          deadline: DateTime.now().add(const Duration(days: 1)),
          tingkatKepentingan: 3,
          estimasiWaktu: 2,
        );

        final success = await taskProvider.renameScope('Perkuliahan', 'Kuliah S1');

        expect(success, true);
        expect(taskProvider.customScopes.contains('Kuliah S1'), true);
        expect(taskProvider.customScopes.contains('Perkuliahan'), false);
        expect(taskProvider.tasks.first.lingkupTugas, 'Kuliah S1');
      });

      test('Skenario Rename Scope: kategori lingkup ikut pindah', () async {
        await taskProvider.addCategoryToScope('Perkuliahan', 'Praktikum');

        await taskProvider.renameScope('Perkuliahan', 'Kuliah S1');

        expect(taskProvider.categoriesForScope('Kuliah S1').contains('Praktikum'), true);
      });

      test('Skenario Rename Scope: ditolak jika nama baru sudah dipakai', () async {
        final success = await taskProvider.renameScope('Perkuliahan', 'Tugas Rumah');

        expect(success, false);
        expect(taskProvider.customScopes.contains('Perkuliahan'), true);
      });

      test('Skenario Rename Category: tugas lama ikut menunjuk kategori baru', () async {
        await taskProvider.tambahTugas(
          namaTugas: 'Tugas A',
          lingkupTugas: 'Perkuliahan',
          deadline: DateTime.now().add(const Duration(days: 1)),
          tingkatKepentingan: 3,
          estimasiWaktu: 2,
          category: 'Tugas',
        );

        final success = await taskProvider.renameCategoryInScope(
            'Perkuliahan', 'Tugas', 'Tugas Individu');

        expect(success, true);
        expect(taskProvider.tasks.first.category, 'Tugas Individu');
      });

      test('Skenario Rename Category: ditolak jika nama baru sudah dipakai di lingkup sama', () async {
        final success = await taskProvider.renameCategoryInScope(
            'Perkuliahan', 'Tugas', 'Ujian');

        expect(success, false);
      });
    });

    // ─────────────────────────────────────────────
    // 3.4 Test removeScope() dengan tugas terdampak (Issue #4)
    // ─────────────────────────────────────────────

    group('Remove Scope with affected tasks', () {
      test('Skenario Remove Scope Kosong: langsung berhasil tanpa reassign', () async {
        await taskProvider.addScope('Scope Kosong');

        final result = await taskProvider.removeScope('Scope Kosong');

        expect(result.success, true);
        expect(result.affectedTasks, 0);
        expect(taskProvider.customScopes.contains('Scope Kosong'), false);
      });

      test('Skenario Remove Scope Terpakai: ditolak tanpa reassignTasksTo', () async {
        await taskProvider.tambahTugas(
          namaTugas: 'Tugas A',
          lingkupTugas: 'Perkuliahan',
          deadline: DateTime.now().add(const Duration(days: 1)),
          tingkatKepentingan: 3,
          estimasiWaktu: 2,
        );

        final result = await taskProvider.removeScope('Perkuliahan');

        expect(result.success, false);
        expect(result.affectedTasks, 1);
        expect(taskProvider.customScopes.contains('Perkuliahan'), true);
        expect(taskProvider.tasks.first.lingkupTugas, 'Perkuliahan');
      });

      test('Skenario Remove Scope Terpakai: berhasil dengan reassignTasksTo', () async {
        await taskProvider.tambahTugas(
          namaTugas: 'Tugas A',
          lingkupTugas: 'Perkuliahan',
          deadline: DateTime.now().add(const Duration(days: 1)),
          tingkatKepentingan: 3,
          estimasiWaktu: 2,
        );

        final result = await taskProvider.removeScope(
          'Perkuliahan',
          reassignTasksTo: 'Tugas Rumah',
        );

        expect(result.success, true);
        expect(result.affectedTasks, 1);
        expect(taskProvider.customScopes.contains('Perkuliahan'), false);
        expect(taskProvider.tasks.first.lingkupTugas, 'Tugas Rumah');
      });
    });

    // ─────────────────────────────────────────────
    // Persistence Tests
    // ─────────────────────────────────────────────

    group('Persistence Tests', () {
      test('Skenario Scope Persistent: Scope data saved dan loaded', () async {
        // Arrange
        await taskProvider.addScope('Persistent Scope');

        // Act - Create new provider instance and load data
        final newProvider = TaskProvider(notifService: MockNotificationService());
        await newProvider.init();

        // Assert
        expect(
          newProvider.customScopes.contains('Persistent Scope'),
          true,
        );
      });

      test('Skenario Category Persistent: Category data saved dan loaded', () async {
        // Arrange
        await taskProvider.addCategoryToScope('Perkuliahan', 'Persistent Category');

        // Act - Create new provider instance and load data
        final newProvider = TaskProvider(notifService: MockNotificationService());
        await newProvider.init();

        // Assert
        expect(
          newProvider.categoriesForScope('Perkuliahan').contains('Persistent Category'),
          true,
        );
      });
    });
  });
}
