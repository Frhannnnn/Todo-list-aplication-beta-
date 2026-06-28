import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tugasku/services/task_provider.dart';

void main() {
  group('TaskProvider - Scope & Category Management', () {
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
        const scope = 'Tugas Rumah';
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
    // 3.2 Test addCategory() & removeCategory()
    // ─────────────────────────────────────────────

    group('Category Management', () {
      test('Skenario Add Valid Category: Tambah category baru', () async {
        // Arrange
        const newCategory = 'Seminar';
        final initialCount = taskProvider.customCategories.length;

        // Act
        await taskProvider.addCategory(newCategory);

        // Assert
        expect(taskProvider.customCategories.length, initialCount + 1);
        expect(taskProvider.customCategories.contains(newCategory), true);
      });

      test('Skenario Add Valid Category: Trim whitespace', () async {
        // Act
        await taskProvider.addCategory('  Seminar  ');

        // Assert
        expect(taskProvider.customCategories.contains('Seminar'), true);
      });

      test('Skenario Add Invalid Category: Reject duplicate', () async {
        // Arrange
        const category = 'Tugas';
        final initialCount = taskProvider.customCategories.length;

        // Act
        await taskProvider.addCategory(category); // Should be ignored (duplicate)

        // Assert
        expect(taskProvider.customCategories.length, initialCount);
      });

      test('Skenario Add Invalid Category: Reject empty string', () async {
        // Arrange
        final initialCount = taskProvider.customCategories.length;

        // Act
        await taskProvider.addCategory('');

        // Assert
        expect(taskProvider.customCategories.length, initialCount);
      });

      test('Skenario Remove Category: Remove existing category', () async {
        // Arrange
        const newCategory = 'Workshop';
        await taskProvider.addCategory(newCategory);
        final countAfterAdd = taskProvider.customCategories.length;

        // Act
        await taskProvider.removeCategory(newCategory);

        // Assert
        expect(taskProvider.customCategories.length, countAfterAdd - 1);
        expect(taskProvider.customCategories.contains(newCategory), false);
      });

      test('Skenario Remove Category: Safe remove non-exist category', () async {
        // Arrange
        final initialCount = taskProvider.customCategories.length;

        // Act
        await taskProvider.removeCategory('Non-Exist Category');

        // Assert
        expect(taskProvider.customCategories.length, initialCount);
      });

      test('Skenario Multiple Categories: Add multiple categories', () async {
        // Act
        await taskProvider.addCategory('Category 1');
        await taskProvider.addCategory('Category 2');
        await taskProvider.addCategory('Category 3');

        // Assert
        expect(taskProvider.customCategories.contains('Category 1'), true);
        expect(taskProvider.customCategories.contains('Category 2'), true);
        expect(taskProvider.customCategories.contains('Category 3'), true);
      });

      test('Skenario Multiple Categories: Remove some categories', () async {
        // Arrange
        await taskProvider.addCategory('Category 1');
        await taskProvider.addCategory('Category 2');
        await taskProvider.addCategory('Category 3');

        // Act
        await taskProvider.removeCategory('Category 2');

        // Assert
        expect(taskProvider.customCategories.contains('Category 1'), true);
        expect(taskProvider.customCategories.contains('Category 2'), false);
        expect(taskProvider.customCategories.contains('Category 3'), true);
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
        final newProvider = TaskProvider();
        await newProvider._init();

        // Assert
        expect(
          newProvider.customScopes.contains('Persistent Scope'),
          true,
        );
      });

      test('Skenario Category Persistent: Category data saved dan loaded', () async {
        // Arrange
        await taskProvider.addCategory('Persistent Category');

        // Act - Create new provider instance and load data
        final newProvider = TaskProvider();
        await newProvider._init();

        // Assert
        expect(
          newProvider.customCategories.contains('Persistent Category'),
          true,
        );
      });
    });
  });
}
