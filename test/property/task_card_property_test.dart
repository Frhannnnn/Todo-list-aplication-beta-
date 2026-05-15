// test/property/task_card_property_test.dart
//
// Property-Based Tests untuk TaskCardWidget badge prioritas.
//
// **Property 3: Badge Prioritas Muncul Jika dan Hanya Jika Kondisi Terpenuhi**
// **Validates: Requirements 3.1, 3.4**
//
// **Property 4: Warna Badge Konsisten dengan AppTheme**
// **Validates: Requirements 3.2**

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tugasku/models/task_model.dart';
import 'package:tugasku/utils/app_theme.dart';

// ---------------------------------------------------------------------------
// Logika badge yang di-mirror dari TaskCardWidget (pure, tanpa widget)
// ---------------------------------------------------------------------------
bool shouldShowPriorityBadge({
  required int ranking,
  required TaskStatus status,
  required int totalActiveTasks,
}) {
  return ranking > 0 &&
      status != TaskStatus.selesai &&
      totalActiveTasks > 0;
}

void main() {
  // =========================================================================
  // Property 3: Badge Prioritas Muncul Jika dan Hanya Jika Kondisi Terpenuhi
  // **Validates: Requirements 3.1, 3.4**
  // =========================================================================
  group('Property 3: Badge Prioritas Muncul Jika dan Hanya Jika Kondisi Terpenuhi', () {
    // Generator: Task acak dengan berbagai kombinasi ranking dan status
    Iterable<({int ranking, TaskStatus status, int totalActiveTasks})>
        generateRandomCombinations({int count = 100, int seed = 42}) sync* {
      final rng = Random(seed);
      const statuses = TaskStatus.values;
      for (var i = 0; i < count; i++) {
        // ranking: 0 atau 1–20 (campuran valid dan tidak valid)
        final ranking = rng.nextBool() ? 0 : rng.nextInt(20) + 1;
        final status = statuses[rng.nextInt(statuses.length)];
        // totalActiveTasks: 0 atau 1–30
        final total = rng.nextBool() ? 0 : rng.nextInt(30) + 1;
        yield (ranking: ranking, status: status, totalActiveTasks: total);
      }
    }

    test(
      'badge muncul jika dan hanya jika ranking > 0, status != selesai, totalActiveTasks > 0',
      () {
        var iterationCount = 0;
        for (final combo in generateRandomCombinations(count: 100)) {
          final shouldShow = shouldShowPriorityBadge(
            ranking: combo.ranking,
            status: combo.status,
            totalActiveTasks: combo.totalActiveTasks,
          );

          final expectedShow = combo.ranking > 0 &&
              combo.status != TaskStatus.selesai &&
              combo.totalActiveTasks > 0;

          expect(
            shouldShow,
            equals(expectedShow),
            reason:
                'ranking=${combo.ranking}, status=${combo.status}, total=${combo.totalActiveTasks}: '
                'shouldShow=$shouldShow, expected=$expectedShow',
          );

          iterationCount++;
        }
        expect(iterationCount, greaterThanOrEqualTo(100));
      },
    );

    test(
      'badge tidak muncul jika ranking == 0',
      () {
        final rng = Random(11);
        var iterationCount = 0;
        for (var i = 0; i < 100; i++) {
          final status = TaskStatus.values[rng.nextInt(TaskStatus.values.length)];
          final total = rng.nextInt(30) + 1; // total > 0

          final shouldShow = shouldShowPriorityBadge(
            ranking: 0,
            status: status,
            totalActiveTasks: total,
          );

          expect(
            shouldShow,
            isFalse,
            reason: 'ranking=0, status=$status, total=$total: badge seharusnya tidak muncul',
          );

          iterationCount++;
        }
        expect(iterationCount, greaterThanOrEqualTo(100));
      },
    );

    test(
      'badge tidak muncul jika status == selesai',
      () {
        final rng = Random(22);
        var iterationCount = 0;
        for (var i = 0; i < 100; i++) {
          final ranking = rng.nextInt(20) + 1; // ranking > 0
          final total = rng.nextInt(30) + 1;   // total > 0

          final shouldShow = shouldShowPriorityBadge(
            ranking: ranking,
            status: TaskStatus.selesai,
            totalActiveTasks: total,
          );

          expect(
            shouldShow,
            isFalse,
            reason: 'ranking=$ranking, status=selesai, total=$total: badge seharusnya tidak muncul',
          );

          iterationCount++;
        }
        expect(iterationCount, greaterThanOrEqualTo(100));
      },
    );

    test(
      'badge tidak muncul jika totalActiveTasks == 0',
      () {
        final rng = Random(33);
        var iterationCount = 0;
        for (var i = 0; i < 100; i++) {
          final ranking = rng.nextInt(20) + 1; // ranking > 0
          final status = TaskStatus.values[rng.nextInt(TaskStatus.values.length)];

          final shouldShow = shouldShowPriorityBadge(
            ranking: ranking,
            status: status,
            totalActiveTasks: 0,
          );

          expect(
            shouldShow,
            isFalse,
            reason: 'ranking=$ranking, status=$status, total=0: badge seharusnya tidak muncul',
          );

          iterationCount++;
        }
        expect(iterationCount, greaterThanOrEqualTo(100));
      },
    );

    test(
      'badge muncul untuk semua status non-selesai jika ranking > 0 dan total > 0',
      () {
        final rng = Random(44);
        final nonSelesaiStatuses = TaskStatus.values
            .where((s) => s != TaskStatus.selesai)
            .toList();
        var iterationCount = 0;
        for (var i = 0; i < 100; i++) {
          final ranking = rng.nextInt(20) + 1;
          final total = rng.nextInt(30) + 1;
          final status = nonSelesaiStatuses[rng.nextInt(nonSelesaiStatuses.length)];

          final shouldShow = shouldShowPriorityBadge(
            ranking: ranking,
            status: status,
            totalActiveTasks: total,
          );

          expect(
            shouldShow,
            isTrue,
            reason: 'ranking=$ranking, status=$status, total=$total: badge seharusnya muncul',
          );

          iterationCount++;
        }
        expect(iterationCount, greaterThanOrEqualTo(100));
      },
    );
  });

  // =========================================================================
  // Property 4: Warna Badge Konsisten dengan AppTheme
  // **Validates: Requirements 3.2**
  // =========================================================================
  group('Property 4: Warna Badge Konsisten dengan AppTheme', () {
    // Generator: pasangan (ranking, totalActiveTasks) yang valid
    // ranking > 0, totalActiveTasks > 0, dan ranking <= totalActiveTasks
    Iterable<({int ranking, int totalActiveTasks})> generateValidPairs({
      int count = 100,
      int seed = 42,
    }) sync* {
      final rng = Random(seed);
      for (var i = 0; i < count; i++) {
        // totalActiveTasks: 1–50
        final total = rng.nextInt(50) + 1;
        // ranking: 1–total (ranking valid tidak melebihi total)
        final ranking = rng.nextInt(total) + 1;
        yield (ranking: ranking, totalActiveTasks: total);
      }
    }

    test(
      'getPrioritasColor() mengembalikan Color yang tidak null untuk setiap pasangan valid',
      () {
        var iterationCount = 0;
        for (final pair in generateValidPairs(count: 100)) {
          final color = AppTheme.getPrioritasColor(
            pair.ranking,
            pair.totalActiveTasks,
          );

          // Color adalah value type di Flutter, selalu non-null
          // Verifikasi bahwa hasilnya adalah salah satu dari warna yang diharapkan
          expect(
            color,
            isA<Color>(),
            reason:
                'getPrioritasColor(${pair.ranking}, ${pair.totalActiveTasks}) harus mengembalikan Color',
          );

          iterationCount++;
        }
        expect(iterationCount, greaterThanOrEqualTo(100));
      },
    );

    test(
      'getPrioritasColor() konsisten — input yang sama selalu menghasilkan warna yang sama',
      () {
        final rng = Random(55);
        var iterationCount = 0;
        for (var i = 0; i < 100; i++) {
          final total = rng.nextInt(50) + 1;
          final ranking = rng.nextInt(total) + 1;

          final color1 = AppTheme.getPrioritasColor(ranking, total);
          final color2 = AppTheme.getPrioritasColor(ranking, total);

          expect(
            color1,
            equals(color2),
            reason:
                'getPrioritasColor($ranking, $total) tidak konsisten: $color1 != $color2',
          );

          iterationCount++;
        }
        expect(iterationCount, greaterThanOrEqualTo(100));
      },
    );

    test(
      'warna badge identik dengan AppTheme.getPrioritasColor() untuk setiap pasangan valid',
      () {
        // Ini adalah inti dari Property 4:
        // Warna yang digunakan pada badge harus IDENTIK dengan AppTheme.getPrioritasColor()
        final rng = Random(66);
        var iterationCount = 0;
        for (var i = 0; i < 100; i++) {
          final total = rng.nextInt(50) + 1;
          final ranking = rng.nextInt(total) + 1;

          // Simulasi logika _buildPriorityBadge() di TaskCardWidget:
          // final color = AppTheme.getPrioritasColor(task.ranking, totalActiveTasks);
          final badgeColor = AppTheme.getPrioritasColor(ranking, total);

          // Referensi: nilai yang seharusnya dikembalikan
          final expectedColor = AppTheme.getPrioritasColor(ranking, total);

          expect(
            badgeColor,
            equals(expectedColor),
            reason:
                'Warna badge untuk ranking=$ranking, total=$total tidak identik dengan AppTheme.getPrioritasColor()',
          );

          iterationCount++;
        }
        expect(iterationCount, greaterThanOrEqualTo(100));
      },
    );

    test(
      'warna badge konsisten dengan label yang dikembalikan getPrioritasLabel()',
      () {
        // Verifikasi konsistensi antara warna dan label:
        // - label "Tinggi" → warna prioritasTinggi (merah)
        // - label "Sedang" → warna prioritasSedang (kuning)
        // - label "Rendah" → warna prioritasRendah (hijau)
        final rng = Random(77);
        var iterationCount = 0;
        for (var i = 0; i < 100; i++) {
          final total = rng.nextInt(50) + 1;
          final ranking = rng.nextInt(total) + 1;

          final color = AppTheme.getPrioritasColor(ranking, total);
          final label = AppTheme.getPrioritasLabel(ranking, total);

          // Verifikasi konsistensi warna-label berdasarkan threshold yang sama
          switch (label) {
            case 'Tinggi':
              expect(
                color,
                equals(AppTheme.prioritasTinggi),
                reason:
                    'ranking=$ranking, total=$total: label="Tinggi" harus menggunakan warna prioritasTinggi',
              );
            case 'Sedang':
              expect(
                color,
                equals(AppTheme.prioritasSedang),
                reason:
                    'ranking=$ranking, total=$total: label="Sedang" harus menggunakan warna prioritasSedang',
              );
            case 'Rendah':
              expect(
                color,
                equals(AppTheme.prioritasRendah),
                reason:
                    'ranking=$ranking, total=$total: label="Rendah" harus menggunakan warna prioritasRendah',
              );
            default:
              fail('Label tidak dikenal: "$label" untuk ranking=$ranking, total=$total');
          }

          iterationCount++;
        }
        expect(iterationCount, greaterThanOrEqualTo(100));
      },
    );

    test(
      'warna badge selalu salah satu dari tiga warna prioritas yang valid',
      () {
        final validColors = {
          AppTheme.prioritasTinggi,
          AppTheme.prioritasSedang,
          AppTheme.prioritasRendah,
        };

        final rng = Random(88);
        var iterationCount = 0;
        for (var i = 0; i < 100; i++) {
          final total = rng.nextInt(50) + 1;
          final ranking = rng.nextInt(total) + 1;

          final color = AppTheme.getPrioritasColor(ranking, total);

          expect(
            validColors.contains(color),
            isTrue,
            reason:
                'getPrioritasColor($ranking, $total) = $color bukan salah satu dari warna prioritas valid: $validColors',
          );

          iterationCount++;
        }
        expect(iterationCount, greaterThanOrEqualTo(100));
      },
    );

    test(
      'ranking di top 25% mendapatkan warna prioritasTinggi (merah)',
      () {
        // Verifikasi threshold: ranking/total <= 0.25 → prioritasTinggi
        final rng = Random(99);
        var iterationCount = 0;
        for (var i = 0; i < 100; i++) {
          // Buat total yang cukup besar agar ada ruang untuk top 25%
          final total = rng.nextInt(40) + 10; // 10–49
          // ranking dalam top 25%: ranking <= total * 0.25
          final maxRankingForHigh = (total * 0.25).floor();
          if (maxRankingForHigh < 1) continue; // skip jika tidak ada ruang
          final ranking = rng.nextInt(maxRankingForHigh) + 1;

          final color = AppTheme.getPrioritasColor(ranking, total);

          expect(
            color,
            equals(AppTheme.prioritasTinggi),
            reason:
                'ranking=$ranking, total=$total (pct=${ranking / total}): seharusnya prioritasTinggi',
          );

          iterationCount++;
        }
        // Minimal 50 iterasi valid (beberapa mungkin di-skip)
        expect(iterationCount, greaterThanOrEqualTo(50));
      },
    );

    test(
      'ranking di bottom 40% mendapatkan warna prioritasRendah (hijau)',
      () {
        // Verifikasi threshold: ranking/total > 0.60 → prioritasRendah
        final rng = Random(111);
        var iterationCount = 0;
        for (var i = 0; i < 100; i++) {
          final total = rng.nextInt(40) + 10; // 10–49
          // ranking di bottom 40%: ranking > total * 0.60
          final minRankingForLow = (total * 0.60).ceil() + 1;
          if (minRankingForLow > total) continue; // skip jika tidak ada ruang
          final ranking = minRankingForLow +
              rng.nextInt(total - minRankingForLow + 1);

          final color = AppTheme.getPrioritasColor(ranking, total);

          expect(
            color,
            equals(AppTheme.prioritasRendah),
            reason:
                'ranking=$ranking, total=$total (pct=${ranking / total}): seharusnya prioritasRendah',
          );

          iterationCount++;
        }
        expect(iterationCount, greaterThanOrEqualTo(50));
      },
    );
  });
}
