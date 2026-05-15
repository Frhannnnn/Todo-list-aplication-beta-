// test/property/filter_sort_property_test.dart
//
// Property-Based Tests untuk filter dan sort prioritas di TaskListScreen.
//
// **Property 6: Filter "Semua" Tidak Menyaring Tugas**
// **Validates: Requirements 4.3**

import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:tugasku/models/task_model.dart';
import 'package:tugasku/utils/app_theme.dart';

// ---------------------------------------------------------------------------
// Mirror dari logika _applyFilterAndSort() di TaskListScreen (pure function)
// ---------------------------------------------------------------------------
List<Task> applyFilterAndSort({
  required List<Task> tasks,
  required int totalActive,
  required String filterPrioritas,
  required String sortMode,
  required String searchQuery,
}) {
  var result = List<Task>.from(tasks);

  // 1. Filter pencarian teks
  if (searchQuery.isNotEmpty) {
    final q = searchQuery.toLowerCase();
    result = result
        .where(
          (t) =>
              t.namaTugas.toLowerCase().contains(q) ||
              t.mataKuliah.toLowerCase().contains(q),
        )
        .toList();
  }

  // 2. Filter prioritas
  if (filterPrioritas != 'Semua') {
    result = result.where((t) {
      if (t.ranking == 0 || t.status == TaskStatus.selesai) return false;
      return AppTheme.getPrioritasLabel(t.ranking, totalActive) ==
          filterPrioritas;
    }).toList();
  }

  // 3. Sort
  if (sortMode == 'Prioritas Tertinggi') {
    result.sort((a, b) {
      if (a.ranking == 0 && b.ranking == 0) return 0;
      if (a.ranking == 0) return 1;
      if (b.ranking == 0) return -1;
      return a.ranking.compareTo(b.ranking);
    });
  }

  return result;
}

// ---------------------------------------------------------------------------
// Generator: membuat daftar Task acak
// ---------------------------------------------------------------------------
List<Task> generateRandomTaskList(Random rng, {int? count}) {
  final taskCount = count ?? (rng.nextInt(20) + 1); // 1–20 tugas
  const statuses = TaskStatus.values;

  return List.generate(taskCount, (i) {
    final ranking = rng.nextBool() ? 0 : rng.nextInt(taskCount) + 1;
    final status = statuses[rng.nextInt(statuses.length)];

    return Task(
      id: 'task-$i',
      namaTugas: 'Tugas ${String.fromCharCode(65 + rng.nextInt(26))}${rng.nextInt(100)}',
      mataKuliah: 'MK ${String.fromCharCode(65 + rng.nextInt(26))}${rng.nextInt(10)}',
      deadline: DateTime.now().add(Duration(days: rng.nextInt(30) + 1)),
      tingkatKepentingan: rng.nextInt(5) + 1,
      tingkatUrgensi: rng.nextInt(5) + 1,
      estimasiWaktu: rng.nextInt(10) + 1,
      status: status,
      createdAt: DateTime.now(),
      ranking: ranking,
    );
  });
}

void main() {
  // =========================================================================
  // Property 6: Filter "Semua" Tidak Menyaring Tugas
  // **Validates: Requirements 4.3**
  // =========================================================================
  group('Property 6: Filter "Semua" Tidak Menyaring Tugas', () {
    test(
      'filter "Semua" tanpa pencarian teks tidak mengubah jumlah tugas',
      () {
        final rng = Random(42);
        var iterationCount = 0;

        for (var i = 0; i < 100; i++) {
          final tasks = generateRandomTaskList(rng);
          final totalActive = tasks
              .where((t) => t.status != TaskStatus.selesai)
              .length;

          final result = applyFilterAndSort(
            tasks: tasks,
            totalActive: totalActive,
            filterPrioritas: 'Semua',
            sortMode: 'Default',
            searchQuery: '',
          );

          expect(
            result.length,
            equals(tasks.length),
            reason:
                'Iterasi $i: filter "Semua" tanpa pencarian teks mengubah jumlah tugas '
                'dari ${tasks.length} menjadi ${result.length}',
          );

          iterationCount++;
        }
        expect(iterationCount, greaterThanOrEqualTo(100));
      },
    );

    test(
      'filter "Semua" mempertahankan semua tugas terlepas dari ranking dan status',
      () {
        final rng = Random(123);
        var iterationCount = 0;

        for (var i = 0; i < 100; i++) {
          final tasks = generateRandomTaskList(rng);
          final totalActive = tasks
              .where((t) => t.status != TaskStatus.selesai)
              .length;

          final result = applyFilterAndSort(
            tasks: tasks,
            totalActive: totalActive,
            filterPrioritas: 'Semua',
            sortMode: 'Default',
            searchQuery: '',
          );

          // Verifikasi setiap tugas asli ada di hasil
          for (final task in tasks) {
            expect(
              result.any((t) => t.id == task.id),
              isTrue,
              reason:
                  'Iterasi $i: tugas "${task.namaTugas}" (id=${task.id}, ranking=${task.ranking}, '
                  'status=${task.status}) hilang setelah filter "Semua"',
            );
          }

          iterationCount++;
        }
        expect(iterationCount, greaterThanOrEqualTo(100));
      },
    );

    test(
      'filter "Semua" dengan sort "Prioritas Tertinggi" tidak mengubah jumlah tugas',
      () {
        final rng = Random(456);
        var iterationCount = 0;

        for (var i = 0; i < 100; i++) {
          final tasks = generateRandomTaskList(rng);
          final totalActive = tasks
              .where((t) => t.status != TaskStatus.selesai)
              .length;

          final result = applyFilterAndSort(
            tasks: tasks,
            totalActive: totalActive,
            filterPrioritas: 'Semua',
            sortMode: 'Prioritas Tertinggi',
            searchQuery: '',
          );

          expect(
            result.length,
            equals(tasks.length),
            reason:
                'Iterasi $i: filter "Semua" + sort "Prioritas Tertinggi" mengubah jumlah tugas '
                'dari ${tasks.length} menjadi ${result.length}',
          );

          iterationCount++;
        }
        expect(iterationCount, greaterThanOrEqualTo(100));
      },
    );

    test(
      'filter "Semua" hanya menyaring berdasarkan teks pencarian (bukan prioritas)',
      () {
        // Ketika searchQuery tidak kosong, filter "Semua" tetap tidak menyaring
        // berdasarkan prioritas — hanya filter teks yang berlaku
        final rng = Random(789);
        var iterationCount = 0;

        for (var i = 0; i < 100; i++) {
          final tasks = generateRandomTaskList(rng);
          final totalActive = tasks
              .where((t) => t.status != TaskStatus.selesai)
              .length;

          // Gunakan searchQuery yang cocok dengan beberapa tugas
          final searchQuery = tasks.isNotEmpty
              ? tasks[rng.nextInt(tasks.length)].namaTugas.substring(0, 1)
              : '';

          final resultWithFilter = applyFilterAndSort(
            tasks: tasks,
            totalActive: totalActive,
            filterPrioritas: 'Semua',
            sortMode: 'Default',
            searchQuery: searchQuery,
          );

          // Hitung secara manual berapa tugas yang cocok dengan pencarian teks
          final q = searchQuery.toLowerCase();
          final expectedCount = searchQuery.isEmpty
              ? tasks.length
              : tasks
                  .where(
                    (t) =>
                        t.namaTugas.toLowerCase().contains(q) ||
                        t.mataKuliah.toLowerCase().contains(q),
                  )
                  .length;

          expect(
            resultWithFilter.length,
            equals(expectedCount),
            reason:
                'Iterasi $i: filter "Semua" + searchQuery="$searchQuery" menghasilkan '
                '${resultWithFilter.length} tugas, diharapkan $expectedCount '
                '(hanya filter teks yang berlaku)',
          );

          iterationCount++;
        }
        expect(iterationCount, greaterThanOrEqualTo(100));
      },
    );

    test(
      'filter "Semua" pada daftar kosong menghasilkan daftar kosong',
      () {
        // Edge case: daftar tugas kosong
        var iterationCount = 0;
        for (var i = 0; i < 100; i++) {
          final result = applyFilterAndSort(
            tasks: [],
            totalActive: 0,
            filterPrioritas: 'Semua',
            sortMode: 'Default',
            searchQuery: '',
          );

          expect(
            result.length,
            equals(0),
            reason: 'Iterasi $i: filter "Semua" pada daftar kosong harus menghasilkan 0 tugas',
          );

          iterationCount++;
        }
        expect(iterationCount, greaterThanOrEqualTo(100));
      },
    );
  });
}
