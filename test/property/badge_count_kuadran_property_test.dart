// test/property/badge_count_kuadran_property_test.dart
//
// Property-Based Test untuk badge count kuadran di PriorityScreen.
//
// **Property 8: Badge Count Kuadran Konsisten dengan Data Tugas**
// **Validates: Requirements 5.2**

import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:tugasku/models/task_model.dart';
import 'package:tugasku/screens/priority_screen.dart';

// ---------------------------------------------------------------------------
// Mirror dari logika _groupTasks() dan _quadrantFor() di PriorityScreen
// ---------------------------------------------------------------------------

/// Menentukan kuadran Eisenhower untuk sebuah tugas berdasarkan
/// tingkatKepentingan dan tingkatUrgensi.
/// Threshold: nilai >= 4 dianggap "tinggi".
EisenhowerQuadrant quadrantFor(Task task) {
  final isImportant = task.tingkatKepentingan >= 4;
  final isUrgent = task.tingkatUrgensi >= 4;

  if (isImportant && isUrgent) return EisenhowerQuadrant.doNow;
  if (isImportant && !isUrgent) return EisenhowerQuadrant.schedule;
  if (!isImportant && isUrgent) return EisenhowerQuadrant.delegate;
  return EisenhowerQuadrant.eliminate;
}

/// Mengelompokkan daftar tugas ke dalam kuadran Eisenhower.
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
// Generator: membuat daftar Task acak (tugas aktif)
// ---------------------------------------------------------------------------
List<Task> generateRandomActiveTasks(Random rng, {int? count}) {
  final taskCount = count ?? (rng.nextInt(20) + 1); // 1–20 tugas
  // Hanya status aktif (bukan selesai) karena PriorityScreen menggunakan activeTasks
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
  // Property 8: Badge Count Kuadran Konsisten dengan Data Tugas
  // **Validates: Requirements 5.2**
  // =========================================================================
  group('Property 8: Badge Count Kuadran Konsisten dengan Data Tugas', () {
    test(
      'jumlah tugas per kuadran harus sama dengan jumlah tugas yang memenuhi kriteria kuadran tersebut',
      () {
        final rng = Random(42);
        var iterationCount = 0;

        for (var i = 0; i < 100; i++) {
          final tasks = generateRandomActiveTasks(rng);
          final grouped = groupTasks(tasks);

          // Hitung secara manual berapa tugas yang memenuhi kriteria setiap kuadran
          final expectedDoNow = tasks
              .where((t) => t.tingkatKepentingan >= 4 && t.tingkatUrgensi >= 4)
              .length;
          final expectedSchedule = tasks
              .where((t) => t.tingkatKepentingan >= 4 && t.tingkatUrgensi < 4)
              .length;
          final expectedDelegate = tasks
              .where((t) => t.tingkatKepentingan < 4 && t.tingkatUrgensi >= 4)
              .length;
          final expectedEliminate = tasks
              .where((t) => t.tingkatKepentingan < 4 && t.tingkatUrgensi < 4)
              .length;

          // Verifikasi badge count (panjang list) setiap kuadran
          expect(
            grouped[EisenhowerQuadrant.doNow]!.length,
            equals(expectedDoNow),
            reason:
                'Iterasi $i: kuadran "Kerjakan" (doNow) memiliki '
                '${grouped[EisenhowerQuadrant.doNow]!.length} tugas, '
                'diharapkan $expectedDoNow (kepentingan >= 4 AND urgensi >= 4)',
          );

          expect(
            grouped[EisenhowerQuadrant.schedule]!.length,
            equals(expectedSchedule),
            reason:
                'Iterasi $i: kuadran "Jadwalkan" (schedule) memiliki '
                '${grouped[EisenhowerQuadrant.schedule]!.length} tugas, '
                'diharapkan $expectedSchedule (kepentingan >= 4 AND urgensi < 4)',
          );

          expect(
            grouped[EisenhowerQuadrant.delegate]!.length,
            equals(expectedDelegate),
            reason:
                'Iterasi $i: kuadran "Delegasikan" (delegate) memiliki '
                '${grouped[EisenhowerQuadrant.delegate]!.length} tugas, '
                'diharapkan $expectedDelegate (kepentingan < 4 AND urgensi >= 4)',
          );

          expect(
            grouped[EisenhowerQuadrant.eliminate]!.length,
            equals(expectedEliminate),
            reason:
                'Iterasi $i: kuadran "Eliminasi" (eliminate) memiliki '
                '${grouped[EisenhowerQuadrant.eliminate]!.length} tugas, '
                'diharapkan $expectedEliminate (kepentingan < 4 AND urgensi < 4)',
          );

          iterationCount++;
        }
        expect(iterationCount, greaterThanOrEqualTo(100));
      },
    );

    test(
      'total tugas di semua kuadran harus sama dengan total tugas input',
      () {
        final rng = Random(123);
        var iterationCount = 0;

        for (var i = 0; i < 100; i++) {
          final tasks = generateRandomActiveTasks(rng);
          final grouped = groupTasks(tasks);

          final totalInQuadrants = grouped.values
              .fold<int>(0, (sum, list) => sum + list.length);

          expect(
            totalInQuadrants,
            equals(tasks.length),
            reason:
                'Iterasi $i: total tugas di semua kuadran ($totalInQuadrants) '
                'tidak sama dengan total tugas input (${tasks.length})',
          );

          iterationCount++;
        }
        expect(iterationCount, greaterThanOrEqualTo(100));
      },
    );

    test(
      'setiap tugas dalam kuadran memenuhi kriteria kuadran tersebut',
      () {
        final rng = Random(456);
        var iterationCount = 0;

        for (var i = 0; i < 100; i++) {
          final tasks = generateRandomActiveTasks(rng);
          final grouped = groupTasks(tasks);

          // Verifikasi setiap tugas di kuadran doNow memenuhi kriteria
          for (final task in grouped[EisenhowerQuadrant.doNow]!) {
            expect(
              task.tingkatKepentingan >= 4 && task.tingkatUrgensi >= 4,
              isTrue,
              reason:
                  'Iterasi $i: tugas "${task.namaTugas}" di kuadran "Kerjakan" '
                  'memiliki kepentingan=${task.tingkatKepentingan}, urgensi=${task.tingkatUrgensi} '
                  '(harus kepentingan >= 4 AND urgensi >= 4)',
            );
          }

          // Verifikasi setiap tugas di kuadran schedule memenuhi kriteria
          for (final task in grouped[EisenhowerQuadrant.schedule]!) {
            expect(
              task.tingkatKepentingan >= 4 && task.tingkatUrgensi < 4,
              isTrue,
              reason:
                  'Iterasi $i: tugas "${task.namaTugas}" di kuadran "Jadwalkan" '
                  'memiliki kepentingan=${task.tingkatKepentingan}, urgensi=${task.tingkatUrgensi} '
                  '(harus kepentingan >= 4 AND urgensi < 4)',
            );
          }

          // Verifikasi setiap tugas di kuadran delegate memenuhi kriteria
          for (final task in grouped[EisenhowerQuadrant.delegate]!) {
            expect(
              task.tingkatKepentingan < 4 && task.tingkatUrgensi >= 4,
              isTrue,
              reason:
                  'Iterasi $i: tugas "${task.namaTugas}" di kuadran "Delegasikan" '
                  'memiliki kepentingan=${task.tingkatKepentingan}, urgensi=${task.tingkatUrgensi} '
                  '(harus kepentingan < 4 AND urgensi >= 4)',
            );
          }

          // Verifikasi setiap tugas di kuadran eliminate memenuhi kriteria
          for (final task in grouped[EisenhowerQuadrant.eliminate]!) {
            expect(
              task.tingkatKepentingan < 4 && task.tingkatUrgensi < 4,
              isTrue,
              reason:
                  'Iterasi $i: tugas "${task.namaTugas}" di kuadran "Eliminasi" '
                  'memiliki kepentingan=${task.tingkatKepentingan}, urgensi=${task.tingkatUrgensi} '
                  '(harus kepentingan < 4 AND urgensi < 4)',
            );
          }

          iterationCount++;
        }
        expect(iterationCount, greaterThanOrEqualTo(100));
      },
    );

    test(
      'daftar tugas kosong menghasilkan semua kuadran kosong',
      () {
        var iterationCount = 0;

        for (var i = 0; i < 100; i++) {
          final grouped = groupTasks([]);

          for (final quadrant in EisenhowerQuadrant.values) {
            expect(
              grouped[quadrant]!.length,
              equals(0),
              reason:
                  'Iterasi $i: kuadran $quadrant harus kosong untuk daftar tugas kosong',
            );
          }

          iterationCount++;
        }
        expect(iterationCount, greaterThanOrEqualTo(100));
      },
    );

    test(
      'tugas dengan nilai batas (kepentingan=4, urgensi=4) masuk ke kuadran doNow',
      () {
        final rng = Random(789);
        var iterationCount = 0;

        for (var i = 0; i < 100; i++) {
          // Generate tugas dengan nilai batas threshold
          final boundaryTask = Task(
            id: 'boundary-$i',
            namaTugas: 'Boundary Task $i',
            mataKuliah: 'MK Test',
            deadline: DateTime.now().add(Duration(days: rng.nextInt(30) + 1)),
            tingkatKepentingan: 4, // tepat di batas
            tingkatUrgensi: 4, // tepat di batas
            estimasiWaktu: rng.nextInt(10) + 1,
            status: TaskStatus.belumDikerjakan,
            createdAt: DateTime.now(),
            ranking: 1,
          );

          // Tambahkan tugas acak lainnya
          final otherTasks = generateRandomActiveTasks(rng, count: rng.nextInt(10));
          final allTasks = [boundaryTask, ...otherTasks];
          final grouped = groupTasks(allTasks);

          // Tugas dengan kepentingan=4 dan urgensi=4 harus masuk ke doNow
          expect(
            grouped[EisenhowerQuadrant.doNow]!.any((t) => t.id == 'boundary-$i'),
            isTrue,
            reason:
                'Iterasi $i: tugas dengan kepentingan=4, urgensi=4 harus masuk ke kuadran "Kerjakan" (doNow)',
          );

          iterationCount++;
        }
        expect(iterationCount, greaterThanOrEqualTo(100));
      },
    );
  });
}
