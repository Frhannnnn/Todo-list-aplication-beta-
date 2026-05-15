// test/property/sort_prioritas_property_test.dart
//
// Property-Based Tests untuk sort "Prioritas Tertinggi".
//
// **Property 7: Sort "Prioritas Tertinggi" Menghasilkan Urutan Monoton**
// **Validates: Requirements 4.5**

import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:tugasku/models/task_model.dart';

// ---------------------------------------------------------------------------
// Sort logic yang di-mirror dari TaskListScreen._applyFilterAndSort() (pure)
// ---------------------------------------------------------------------------
List<Task> sortPrioritasTertinggi(List<Task> tasks) {
  final sorted = List<Task>.from(tasks);
  sorted.sort((a, b) {
    if (a.ranking == 0 && b.ranking == 0) return 0;
    if (a.ranking == 0) return 1; // ranking 0 ke bawah
    if (b.ranking == 0) return -1;
    return a.ranking.compareTo(b.ranking);
  });
  return sorted;
}

// ---------------------------------------------------------------------------
// Helper: membuat Task minimal dengan ranking tertentu
// ---------------------------------------------------------------------------
Task _makeTask({required int ranking}) {
  return Task(
    id: 'task-$ranking-${DateTime.now().microsecondsSinceEpoch}',
    namaTugas: 'Task ranking $ranking',
    mataKuliah: 'MK Test',
    deadline: DateTime.now().add(const Duration(days: 7)),
    tingkatKepentingan: 3,
    tingkatUrgensi: 3,
    estimasiWaktu: 2,
    status: TaskStatus.belumDikerjakan,
    createdAt: DateTime.now(),
    ranking: ranking,
  );
}

// ---------------------------------------------------------------------------
// Generator: daftar tugas acak dengan ranking campuran (0 dan > 0)
// ---------------------------------------------------------------------------
List<Task> generateRandomTaskList({required Random rng, int maxLength = 20}) {
  final length = rng.nextInt(maxLength) + 1; // 1–maxLength tugas
  return List.generate(length, (_) {
    // ranking: 0 (30% chance) atau 1–50
    final ranking = rng.nextDouble() < 0.3 ? 0 : rng.nextInt(50) + 1;
    return _makeTask(ranking: ranking);
  });
}

void main() {
  // =========================================================================
  // Property 7: Sort "Prioritas Tertinggi" Menghasilkan Urutan Monoton
  // **Validates: Requirements 4.5**
  // =========================================================================
  group('Property 7: Sort "Prioritas Tertinggi" Menghasilkan Urutan Monoton', () {
    test(
      'setelah sort, untuk setiap pasangan berurutan dengan ranking > 0, berlaku tasks[i].ranking <= tasks[i+1].ranking',
      () {
        final rng = Random(42);
        var iterationCount = 0;

        for (var i = 0; i < 100; i++) {
          final tasks = generateRandomTaskList(rng: rng);
          final sorted = sortPrioritasTertinggi(tasks);

          // Verifikasi urutan monoton ascending untuk tugas dengan ranking > 0
          for (var j = 0; j < sorted.length - 1; j++) {
            if (sorted[j].ranking > 0 && sorted[j + 1].ranking > 0) {
              expect(
                sorted[j].ranking <= sorted[j + 1].ranking,
                isTrue,
                reason:
                    'Iterasi $i: tasks[$j].ranking=${sorted[j].ranking} > tasks[${j + 1}].ranking=${sorted[j + 1].ranking} — urutan tidak monoton ascending',
              );
            }
          }

          iterationCount++;
        }
        expect(iterationCount, greaterThanOrEqualTo(100));
      },
    );

    test(
      'tugas dengan ranking == 0 selalu berada di bawah (setelah semua tugas dengan ranking > 0)',
      () {
        final rng = Random(123);
        var iterationCount = 0;

        for (var i = 0; i < 100; i++) {
          final tasks = generateRandomTaskList(rng: rng);
          final sorted = sortPrioritasTertinggi(tasks);

          // Cari indeks pertama tugas dengan ranking == 0
          final firstZeroIndex = sorted.indexWhere((t) => t.ranking == 0);

          if (firstZeroIndex != -1) {
            // Semua tugas sebelum firstZeroIndex harus memiliki ranking > 0
            for (var j = 0; j < firstZeroIndex; j++) {
              expect(
                sorted[j].ranking > 0,
                isTrue,
                reason:
                    'Iterasi $i: tasks[$j].ranking=${sorted[j].ranking} seharusnya > 0 (sebelum zona ranking 0)',
              );
            }

            // Semua tugas dari firstZeroIndex ke bawah harus memiliki ranking == 0
            for (var j = firstZeroIndex; j < sorted.length; j++) {
              expect(
                sorted[j].ranking == 0,
                isTrue,
                reason:
                    'Iterasi $i: tasks[$j].ranking=${sorted[j].ranking} seharusnya == 0 (dalam zona ranking 0)',
              );
            }
          }

          iterationCount++;
        }
        expect(iterationCount, greaterThanOrEqualTo(100));
      },
    );

    test(
      'sort tidak mengubah jumlah elemen (tidak ada tugas yang hilang atau bertambah)',
      () {
        final rng = Random(456);
        var iterationCount = 0;

        for (var i = 0; i < 100; i++) {
          final tasks = generateRandomTaskList(rng: rng);
          final originalLength = tasks.length;
          final sorted = sortPrioritasTertinggi(tasks);

          expect(
            sorted.length,
            equals(originalLength),
            reason:
                'Iterasi $i: jumlah tugas berubah setelah sort — sebelum=$originalLength, sesudah=${sorted.length}',
          );

          iterationCount++;
        }
        expect(iterationCount, greaterThanOrEqualTo(100));
      },
    );

    test(
      'sort mempertahankan semua elemen (permutasi, bukan modifikasi)',
      () {
        final rng = Random(789);
        var iterationCount = 0;

        for (var i = 0; i < 100; i++) {
          final tasks = generateRandomTaskList(rng: rng);
          final originalIds = tasks.map((t) => t.id).toSet();
          final sorted = sortPrioritasTertinggi(tasks);
          final sortedIds = sorted.map((t) => t.id).toSet();

          expect(
            sortedIds,
            equals(originalIds),
            reason:
                'Iterasi $i: elemen berubah setelah sort — ada tugas yang hilang atau bertambah',
          );

          iterationCount++;
        }
        expect(iterationCount, greaterThanOrEqualTo(100));
      },
    );

    test(
      'daftar kosong tetap kosong setelah sort',
      () {
        final sorted = sortPrioritasTertinggi([]);
        expect(sorted, isEmpty);
      },
    );

    test(
      'daftar dengan semua ranking == 0 tetap stabil (semua di bawah)',
      () {
        final rng = Random(101);
        var iterationCount = 0;

        for (var i = 0; i < 100; i++) {
          final length = rng.nextInt(10) + 1;
          final tasks = List.generate(length, (_) => _makeTask(ranking: 0));
          final sorted = sortPrioritasTertinggi(tasks);

          // Semua harus tetap ranking 0
          for (final task in sorted) {
            expect(
              task.ranking,
              equals(0),
              reason: 'Iterasi $i: tugas dengan ranking 0 berubah setelah sort',
            );
          }

          iterationCount++;
        }
        expect(iterationCount, greaterThanOrEqualTo(100));
      },
    );

    test(
      'daftar dengan semua ranking > 0 menghasilkan urutan ascending sempurna',
      () {
        final rng = Random(202);
        var iterationCount = 0;

        for (var i = 0; i < 100; i++) {
          final length = rng.nextInt(15) + 2; // minimal 2 tugas
          final tasks = List.generate(
            length,
            (_) => _makeTask(ranking: rng.nextInt(50) + 1),
          );
          final sorted = sortPrioritasTertinggi(tasks);

          for (var j = 0; j < sorted.length - 1; j++) {
            expect(
              sorted[j].ranking <= sorted[j + 1].ranking,
              isTrue,
              reason:
                  'Iterasi $i: tasks[$j].ranking=${sorted[j].ranking} > tasks[${j + 1}].ranking=${sorted[j + 1].ranking}',
            );
          }

          iterationCount++;
        }
        expect(iterationCount, greaterThanOrEqualTo(100));
      },
    );
  });
}
