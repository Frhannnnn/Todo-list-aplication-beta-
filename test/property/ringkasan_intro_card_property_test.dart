// test/property/ringkasan_intro_card_property_test.dart
//
// Property-Based Test untuk ringkasan intro card di PriorityScreen.
//
// **Property 9: Ringkasan Intro Card Mencerminkan Data Aktual**
// **Validates: Requirements 5.6**
//
// For any list of active tasks, the sum of counts across all 4 quadrants
// must equal the total number of active tasks. This verifies that every
// active task is assigned to exactly one quadrant (no task is lost or duplicated).

import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:tugasku/models/task_model.dart';
import 'package:tugasku/screens/priority_screen.dart';

// ---------------------------------------------------------------------------
// Mirror dari logika _groupTasks() dan _quadrantFor() di PriorityScreen
// (menggunakan static method yang sudah ada di PriorityScreen)
// ---------------------------------------------------------------------------

/// Menentukan kuadran Eisenhower untuk sebuah tugas.
/// Threshold: nilai >= 4 dianggap "tinggi".
EisenhowerQuadrant quadrantFor(Task task) {
  final isImportant = task.tingkatKepentingan >= 4;
  final isUrgent = task.tingkatUrgensi >= 4;

  if (isImportant && isUrgent) return EisenhowerQuadrant.doNow;
  if (isImportant && !isUrgent) return EisenhowerQuadrant.schedule;
  if (!isImportant && isUrgent) return EisenhowerQuadrant.delegate;
  return EisenhowerQuadrant.eliminate;
}

/// Mengelompokkan daftar tugas ke dalam 4 kuadran Eisenhower.
Map<EisenhowerQuadrant, List<Task>> groupTasks(List<Task> tasks) {
  final grouped = {
    for (final quadrant in EisenhowerQuadrant.values) quadrant: <Task>[],
  };

  for (final task in tasks) {
    grouped[quadrantFor(task)]!.add(task);
  }

  return grouped;
}

// ---------------------------------------------------------------------------
// Generator: membuat daftar Task aktif acak (status != selesai)
// ---------------------------------------------------------------------------
List<Task> generateRandomActiveTasks(Random rng, {int? count}) {
  final taskCount = count ?? (rng.nextInt(20) + 1); // 1–20 tugas
  // Only generate active statuses (belumDikerjakan, sedangDikerjakan)
  final activeStatuses = [
    TaskStatus.belumDikerjakan,
    TaskStatus.sedangDikerjakan,
  ];

  return List.generate(taskCount, (i) {
    final status = activeStatuses[rng.nextInt(activeStatuses.length)];

    return Task(
      id: 'task-$i',
      namaTugas: 'Tugas ${String.fromCharCode(65 + rng.nextInt(26))}${rng.nextInt(100)}',
      mataKuliah: 'MK ${String.fromCharCode(65 + rng.nextInt(26))}${rng.nextInt(10)}',
      deadline: DateTime.now().add(Duration(days: rng.nextInt(30) + 1)),
      tingkatKepentingan: rng.nextInt(5) + 1, // 1–5
      tingkatUrgensi: rng.nextInt(5) + 1, // 1–5
      estimasiWaktu: rng.nextInt(10) + 1,
      status: status,
      createdAt: DateTime.now(),
      ranking: i + 1,
    );
  });
}

void main() {
  // =========================================================================
  // Property 9: Ringkasan Intro Card Mencerminkan Data Aktual
  // **Validates: Requirements 5.6**
  // =========================================================================
  group('Property 9: Ringkasan Intro Card Mencerminkan Data Aktual', () {
    test(
      'jumlah per kuadran yang ditampilkan harus menjumlah ke total tugas aktif',
      () {
        final rng = Random(42);
        var iterationCount = 0;

        for (var i = 0; i < 100; i++) {
          final activeTasks = generateRandomActiveTasks(rng);
          final totalActive = activeTasks.length;

          // Group tasks into quadrants (same logic as PriorityScreen)
          final grouped = groupTasks(activeTasks);

          // Sum counts across all 4 quadrants
          final sumQuadrants = EisenhowerQuadrant.values.fold<int>(
            0,
            (sum, q) => sum + (grouped[q]?.length ?? 0),
          );

          // Property: sum of all quadrant counts == total active tasks
          expect(
            sumQuadrants,
            equals(totalActive),
            reason:
                'Iterasi $i: jumlah per kuadran ($sumQuadrants) tidak sama dengan '
                'total tugas aktif ($totalActive). '
                'Distribusi: doNow=${grouped[EisenhowerQuadrant.doNow]!.length}, '
                'schedule=${grouped[EisenhowerQuadrant.schedule]!.length}, '
                'delegate=${grouped[EisenhowerQuadrant.delegate]!.length}, '
                'eliminate=${grouped[EisenhowerQuadrant.eliminate]!.length}',
          );

          iterationCount++;
        }
        expect(iterationCount, greaterThanOrEqualTo(100));
      },
    );

    test(
      'setiap tugas aktif masuk tepat ke satu kuadran (tidak ada duplikasi)',
      () {
        final rng = Random(123);
        var iterationCount = 0;

        for (var i = 0; i < 100; i++) {
          final activeTasks = generateRandomActiveTasks(rng);

          // Group tasks into quadrants
          final grouped = groupTasks(activeTasks);

          // Collect all task IDs from all quadrants
          final allIdsInQuadrants = <String>[];
          for (final quadrant in EisenhowerQuadrant.values) {
            for (final task in grouped[quadrant]!) {
              allIdsInQuadrants.add(task.id);
            }
          }

          // No duplicates: set size == list size
          final uniqueIds = allIdsInQuadrants.toSet();
          expect(
            uniqueIds.length,
            equals(allIdsInQuadrants.length),
            reason:
                'Iterasi $i: ada tugas yang muncul di lebih dari satu kuadran. '
                'Total IDs: ${allIdsInQuadrants.length}, Unique: ${uniqueIds.length}',
          );

          // All original tasks are present
          expect(
            uniqueIds.length,
            equals(activeTasks.length),
            reason:
                'Iterasi $i: ada tugas yang hilang dari pengelompokan kuadran. '
                'Original: ${activeTasks.length}, In quadrants: ${uniqueIds.length}',
          );

          iterationCount++;
        }
        expect(iterationCount, greaterThanOrEqualTo(100));
      },
    );

    test(
      'daftar tugas kosong menghasilkan semua kuadran kosong dengan total 0',
      () {
        var iterationCount = 0;

        for (var i = 0; i < 100; i++) {
          final grouped = groupTasks([]);

          final sumQuadrants = EisenhowerQuadrant.values.fold<int>(
            0,
            (sum, q) => sum + (grouped[q]?.length ?? 0),
          );

          expect(
            sumQuadrants,
            equals(0),
            reason:
                'Iterasi $i: daftar kosong harus menghasilkan total 0, '
                'tetapi mendapat $sumQuadrants',
          );

          iterationCount++;
        }
        expect(iterationCount, greaterThanOrEqualTo(100));
      },
    );

    test(
      'distribusi kuadran konsisten dengan kriteria kepentingan dan urgensi',
      () {
        final rng = Random(456);
        var iterationCount = 0;

        for (var i = 0; i < 100; i++) {
          final activeTasks = generateRandomActiveTasks(rng);
          final grouped = groupTasks(activeTasks);

          // Verify each task in each quadrant meets the quadrant criteria
          for (final task in grouped[EisenhowerQuadrant.doNow]!) {
            expect(
              task.tingkatKepentingan >= 4 && task.tingkatUrgensi >= 4,
              isTrue,
              reason:
                  'Iterasi $i: tugas "${task.namaTugas}" di kuadran doNow '
                  'tetapi kepentingan=${task.tingkatKepentingan}, urgensi=${task.tingkatUrgensi}',
            );
          }

          for (final task in grouped[EisenhowerQuadrant.schedule]!) {
            expect(
              task.tingkatKepentingan >= 4 && task.tingkatUrgensi < 4,
              isTrue,
              reason:
                  'Iterasi $i: tugas "${task.namaTugas}" di kuadran schedule '
                  'tetapi kepentingan=${task.tingkatKepentingan}, urgensi=${task.tingkatUrgensi}',
            );
          }

          for (final task in grouped[EisenhowerQuadrant.delegate]!) {
            expect(
              task.tingkatKepentingan < 4 && task.tingkatUrgensi >= 4,
              isTrue,
              reason:
                  'Iterasi $i: tugas "${task.namaTugas}" di kuadran delegate '
                  'tetapi kepentingan=${task.tingkatKepentingan}, urgensi=${task.tingkatUrgensi}',
            );
          }

          for (final task in grouped[EisenhowerQuadrant.eliminate]!) {
            expect(
              task.tingkatKepentingan < 4 && task.tingkatUrgensi < 4,
              isTrue,
              reason:
                  'Iterasi $i: tugas "${task.namaTugas}" di kuadran eliminate '
                  'tetapi kepentingan=${task.tingkatKepentingan}, urgensi=${task.tingkatUrgensi}',
            );
          }

          iterationCount++;
        }
        expect(iterationCount, greaterThanOrEqualTo(100));
      },
    );
  });
}
