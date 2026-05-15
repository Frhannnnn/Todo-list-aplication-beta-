// test/property/filter_prioritas_property_test.dart
//
// Property-Based Tests untuk filter prioritas di TaskListScreen.
//
// **Property 5: Filter Prioritas Hanya Menampilkan Tugas yang Sesuai**
// **Validates: Requirements 4.2**

import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:tugasku/models/task_model.dart';
import 'package:tugasku/utils/app_theme.dart';

// ---------------------------------------------------------------------------
// Pure function yang mereplikasi logika filter prioritas dari
// _TaskListScreenState._applyFilterAndSort() — hanya bagian filter prioritas.
// ---------------------------------------------------------------------------
List<Task> applyFilterPrioritas(
  List<Task> tasks,
  String filterPrioritas,
  int totalActive,
) {
  if (filterPrioritas == 'Semua') return tasks;

  return tasks.where((t) {
    if (t.ranking == 0 || t.status == TaskStatus.selesai) return false;
    return AppTheme.getPrioritasLabel(t.ranking, totalActive) == filterPrioritas;
  }).toList();
}

// ---------------------------------------------------------------------------
// Helper: membuat Task minimal untuk keperluan test
// ---------------------------------------------------------------------------
Task _makeTask({
  required String id,
  required int ranking,
  required TaskStatus status,
}) {
  return Task(
    id: id,
    namaTugas: 'Task $id',
    mataKuliah: 'MK $id',
    deadline: DateTime.now().add(const Duration(days: 7)),
    tingkatKepentingan: 3,
    tingkatUrgensi: 3,
    estimasiWaktu: 2,
    status: status,
    createdAt: DateTime.now(),
    ranking: ranking,
  );
}

void main() {
  // =========================================================================
  // Property 5: Filter Prioritas Hanya Menampilkan Tugas yang Sesuai
  // **Validates: Requirements 4.2**
  // =========================================================================
  group('Property 5: Filter Prioritas Hanya Menampilkan Tugas yang Sesuai', () {
    // Generator: daftar tugas acak dengan berbagai ranking dan status
    List<Task> generateRandomTasks(Random rng, {int maxCount = 30}) {
      final count = rng.nextInt(maxCount) + 1; // 1–maxCount tugas
      const statuses = TaskStatus.values;
      final tasks = <Task>[];
      for (var i = 0; i < count; i++) {
        // ranking: 0 (belum dihitung) atau 1–count (valid ranking)
        final ranking = rng.nextBool() ? 0 : rng.nextInt(count) + 1;
        final status = statuses[rng.nextInt(statuses.length)];
        tasks.add(_makeTask(id: 'task-$i', ranking: ranking, status: status));
      }
      return tasks;
    }

    // Generator: pilihan filter acak (selain "Semua")
    String generateRandomFilter(Random rng) {
      const filters = ['Tinggi', 'Sedang', 'Rendah'];
      return filters[rng.nextInt(filters.length)];
    }

    test(
      'semua tugas hasil filter memiliki label prioritas yang sesuai dengan pilihan filter',
      () {
        final rng = Random(42);
        var iterationCount = 0;

        for (var i = 0; i < 100; i++) {
          final tasks = generateRandomTasks(rng);
          final filter = generateRandomFilter(rng);
          // totalActive: jumlah tugas dengan ranking > 0 dan status != selesai
          final totalActive = tasks
              .where((t) => t.ranking > 0 && t.status != TaskStatus.selesai)
              .length;

          final result = applyFilterPrioritas(tasks, filter, totalActive);

          for (final task in result) {
            final label = AppTheme.getPrioritasLabel(task.ranking, totalActive);
            expect(
              label,
              equals(filter),
              reason:
                  'Iterasi $i: task ranking=${task.ranking}, totalActive=$totalActive '
                  'memiliki label "$label" tapi filter="$filter"',
            );
          }

          iterationCount++;
        }
        expect(iterationCount, greaterThanOrEqualTo(100));
      },
    );

    test(
      'tugas dengan ranking == 0 tidak pernah lolos filter prioritas',
      () {
        final rng = Random(123);
        var iterationCount = 0;

        for (var i = 0; i < 100; i++) {
          final tasks = generateRandomTasks(rng);
          final filter = generateRandomFilter(rng);
          final totalActive = tasks
              .where((t) => t.ranking > 0 && t.status != TaskStatus.selesai)
              .length;

          final result = applyFilterPrioritas(tasks, filter, totalActive);

          for (final task in result) {
            expect(
              task.ranking,
              greaterThan(0),
              reason:
                  'Iterasi $i: tugas dengan ranking=0 lolos filter "$filter"',
            );
          }

          iterationCount++;
        }
        expect(iterationCount, greaterThanOrEqualTo(100));
      },
    );

    test(
      'tugas dengan status selesai tidak pernah lolos filter prioritas',
      () {
        final rng = Random(456);
        var iterationCount = 0;

        for (var i = 0; i < 100; i++) {
          final tasks = generateRandomTasks(rng);
          final filter = generateRandomFilter(rng);
          final totalActive = tasks
              .where((t) => t.ranking > 0 && t.status != TaskStatus.selesai)
              .length;

          final result = applyFilterPrioritas(tasks, filter, totalActive);

          for (final task in result) {
            expect(
              task.status,
              isNot(equals(TaskStatus.selesai)),
              reason:
                  'Iterasi $i: tugas dengan status selesai lolos filter "$filter"',
            );
          }

          iterationCount++;
        }
        expect(iterationCount, greaterThanOrEqualTo(100));
      },
    );

    test(
      'hasil filter adalah subset dari daftar tugas asli',
      () {
        final rng = Random(789);
        var iterationCount = 0;

        for (var i = 0; i < 100; i++) {
          final tasks = generateRandomTasks(rng);
          final filter = generateRandomFilter(rng);
          final totalActive = tasks
              .where((t) => t.ranking > 0 && t.status != TaskStatus.selesai)
              .length;

          final result = applyFilterPrioritas(tasks, filter, totalActive);

          // Setiap tugas di result harus ada di tasks asli
          for (final task in result) {
            expect(
              tasks.contains(task),
              isTrue,
              reason:
                  'Iterasi $i: tugas "${task.id}" di hasil filter tidak ada di daftar asli',
            );
          }

          // Jumlah hasil tidak boleh melebihi jumlah asli
          expect(
            result.length,
            lessThanOrEqualTo(tasks.length),
            reason:
                'Iterasi $i: hasil filter (${result.length}) melebihi daftar asli (${tasks.length})',
          );

          iterationCount++;
        }
        expect(iterationCount, greaterThanOrEqualTo(100));
      },
    );

    test(
      'tidak ada tugas yang seharusnya lolos filter tapi tidak ada di hasil',
      () {
        // Completeness: semua tugas yang memenuhi kriteria filter harus ada di hasil
        final rng = Random(321);
        var iterationCount = 0;

        for (var i = 0; i < 100; i++) {
          final tasks = generateRandomTasks(rng);
          final filter = generateRandomFilter(rng);
          final totalActive = tasks
              .where((t) => t.ranking > 0 && t.status != TaskStatus.selesai)
              .length;

          final result = applyFilterPrioritas(tasks, filter, totalActive);

          // Hitung secara manual berapa tugas yang seharusnya lolos
          final expectedCount = tasks.where((t) {
            if (t.ranking == 0 || t.status == TaskStatus.selesai) return false;
            return AppTheme.getPrioritasLabel(t.ranking, totalActive) == filter;
          }).length;

          expect(
            result.length,
            equals(expectedCount),
            reason:
                'Iterasi $i: filter="$filter", totalActive=$totalActive, '
                'expected $expectedCount tugas tapi dapat ${result.length}',
          );

          iterationCount++;
        }
        expect(iterationCount, greaterThanOrEqualTo(100));
      },
    );
  });
}
