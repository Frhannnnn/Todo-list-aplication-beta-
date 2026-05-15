// test/property/app_theme_property_test.dart
//
// Property-Based Tests untuk AppTheme helper functions.
//
// **Property 1: Label Slider Selalu Valid untuk Semua Nilai**
// **Validates: Requirements 1.2, 2.2**
//
// **Property 2: Label Kuadran Eisenhower Selalu Valid untuk Semua Kombinasi**
// **Validates: Requirements 2.4**

import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:tugasku/utils/app_theme.dart';

void main() {
  group('Property 1: Label Slider Selalu Valid untuk Semua Nilai', () {
    const validLabels = {
      'Sangat Rendah',
      'Rendah',
      'Sedang',
      'Tinggi',
      'Sangat Tinggi',
    };

    // Generator: nilai acak dalam rentang [1, 5]
    Iterable<int> generateRandomValues({int count = 100, int seed = 42}) sync* {
      final rng = Random(seed);
      for (var i = 0; i < count; i++) {
        // nextInt(5) menghasilkan 0–4, tambah 1 → rentang [1, 5]
        yield rng.nextInt(5) + 1;
      }
    }

    test(
      'getLabelSlider() selalu mengembalikan string non-kosong untuk nilai acak dalam [1,5]',
      () {
        var iterationCount = 0;
        for (final value in generateRandomValues(count: 100)) {
          final result = AppTheme.getLabelSlider(value);

          expect(
            result.isNotEmpty,
            isTrue,
            reason:
                'getLabelSlider($value) mengembalikan string kosong, seharusnya non-kosong',
          );

          iterationCount++;
        }
        // Pastikan minimal 100 iterasi dijalankan
        expect(iterationCount, greaterThanOrEqualTo(100));
      },
    );

    test(
      'getLabelSlider() selalu mengembalikan salah satu dari 5 label valid untuk nilai acak dalam [1,5]',
      () {
        var iterationCount = 0;
        for (final value in generateRandomValues(count: 100, seed: 123)) {
          final result = AppTheme.getLabelSlider(value);

          expect(
            validLabels.contains(result),
            isTrue,
            reason:
                'getLabelSlider($value) = "$result" bukan salah satu dari label valid: $validLabels',
          );

          iterationCount++;
        }
        expect(iterationCount, greaterThanOrEqualTo(100));
      },
    );

    test(
      'getLabelSlider() mencakup semua 5 label valid dalam distribusi acak yang cukup besar',
      () {
        // Dengan 500 iterasi acak dalam [1,5], semua 5 label harus muncul setidaknya sekali
        final foundLabels = <String>{};
        for (final value in generateRandomValues(count: 500, seed: 999)) {
          foundLabels.add(AppTheme.getLabelSlider(value));
        }

        expect(
          foundLabels,
          equals(validLabels),
          reason:
              'Tidak semua label valid ditemukan. Ditemukan: $foundLabels, Diharapkan: $validLabels',
        );
      },
    );

    test(
      'getLabelSlider() konsisten — nilai yang sama selalu menghasilkan label yang sama',
      () {
        final rng = Random(77);
        var iterationCount = 0;
        for (var i = 0; i < 100; i++) {
          final value = rng.nextInt(5) + 1;
          final result1 = AppTheme.getLabelSlider(value);
          final result2 = AppTheme.getLabelSlider(value);

          expect(
            result1,
            equals(result2),
            reason:
                'getLabelSlider($value) tidak konsisten: "$result1" != "$result2"',
          );

          iterationCount++;
        }
        expect(iterationCount, greaterThanOrEqualTo(100));
      },
    );
  });

  group('Property 2: Label Kuadran Eisenhower Selalu Valid untuk Semua Kombinasi', () {
    const validQuadrantLabels = {
      'Penting & Mendesak → Kerjakan Sekarang',
      'Penting, Tidak Mendesak → Jadwalkan',
      'Mendesak, Kurang Penting → Delegasikan',
      'Kurang Penting & Tidak Mendesak → Eliminasi',
    };

    // Generator: pasangan acak (kepentingan, urgensi) masing-masing dalam [1, 5]
    Iterable<(int, int)> generateRandomPairs({int count = 100, int seed = 42}) sync* {
      final rng = Random(seed);
      for (var i = 0; i < count; i++) {
        final kepentingan = rng.nextInt(5) + 1; // [1, 5]
        final urgensi = rng.nextInt(5) + 1;     // [1, 5]
        yield (kepentingan, urgensi);
      }
    }

    test(
      'getEisenhowerLabel() selalu mengembalikan string non-kosong untuk pasangan acak dalam [1,5]×[1,5]',
      () {
        var iterationCount = 0;
        for (final (kepentingan, urgensi) in generateRandomPairs(count: 100)) {
          final result = AppTheme.getEisenhowerLabel(kepentingan, urgensi);

          expect(
            result.isNotEmpty,
            isTrue,
            reason:
                'getEisenhowerLabel($kepentingan, $urgensi) mengembalikan string kosong, seharusnya non-kosong',
          );

          iterationCount++;
        }
        // Pastikan minimal 100 iterasi dijalankan
        expect(iterationCount, greaterThanOrEqualTo(100));
      },
    );

    test(
      'getEisenhowerLabel() selalu mengembalikan salah satu dari 4 label kuadran yang valid untuk pasangan acak dalam [1,5]×[1,5]',
      () {
        var iterationCount = 0;
        for (final (kepentingan, urgensi) in generateRandomPairs(count: 100, seed: 123)) {
          final result = AppTheme.getEisenhowerLabel(kepentingan, urgensi);

          expect(
            validQuadrantLabels.contains(result),
            isTrue,
            reason:
                'getEisenhowerLabel($kepentingan, $urgensi) = "$result" bukan salah satu dari label kuadran valid: $validQuadrantLabels',
          );

          iterationCount++;
        }
        expect(iterationCount, greaterThanOrEqualTo(100));
      },
    );

    test(
      'getEisenhowerLabel() mencakup semua 4 label kuadran dalam distribusi acak yang cukup besar',
      () {
        // Dengan 500 iterasi acak dalam [1,5]×[1,5], semua 4 kuadran harus muncul setidaknya sekali
        final foundLabels = <String>{};
        for (final (kepentingan, urgensi) in generateRandomPairs(count: 500, seed: 999)) {
          foundLabels.add(AppTheme.getEisenhowerLabel(kepentingan, urgensi));
        }

        expect(
          foundLabels,
          equals(validQuadrantLabels),
          reason:
              'Tidak semua label kuadran ditemukan. Ditemukan: $foundLabels, Diharapkan: $validQuadrantLabels',
        );
      },
    );

    test(
      'getEisenhowerLabel() konsisten — pasangan yang sama selalu menghasilkan label yang sama',
      () {
        final rng = Random(77);
        var iterationCount = 0;
        for (var i = 0; i < 100; i++) {
          final kepentingan = rng.nextInt(5) + 1;
          final urgensi = rng.nextInt(5) + 1;
          final result1 = AppTheme.getEisenhowerLabel(kepentingan, urgensi);
          final result2 = AppTheme.getEisenhowerLabel(kepentingan, urgensi);

          expect(
            result1,
            equals(result2),
            reason:
                'getEisenhowerLabel($kepentingan, $urgensi) tidak konsisten: "$result1" != "$result2"',
          );

          iterationCount++;
        }
        expect(iterationCount, greaterThanOrEqualTo(100));
      },
    );

    test(
      'getEisenhowerLabel() memetakan kuadran dengan benar berdasarkan threshold >= 4',
      () {
        // Verifikasi logika threshold secara eksplisit dengan 100 pasangan acak
        final rng = Random(55);
        var iterationCount = 0;
        for (var i = 0; i < 100; i++) {
          final kepentingan = rng.nextInt(5) + 1;
          final urgensi = rng.nextInt(5) + 1;
          final result = AppTheme.getEisenhowerLabel(kepentingan, urgensi);

          final isImportant = kepentingan >= 4;
          final isUrgent = urgensi >= 4;

          if (isImportant && isUrgent) {
            expect(
              result,
              equals('Penting & Mendesak → Kerjakan Sekarang'),
              reason:
                  'kepentingan=$kepentingan, urgensi=$urgensi (keduanya tinggi) harus → "Kerjakan Sekarang"',
            );
          } else if (isImportant && !isUrgent) {
            expect(
              result,
              equals('Penting, Tidak Mendesak → Jadwalkan'),
              reason:
                  'kepentingan=$kepentingan, urgensi=$urgensi (penting, tidak mendesak) harus → "Jadwalkan"',
            );
          } else if (!isImportant && isUrgent) {
            expect(
              result,
              equals('Mendesak, Kurang Penting → Delegasikan'),
              reason:
                  'kepentingan=$kepentingan, urgensi=$urgensi (mendesak, kurang penting) harus → "Delegasikan"',
            );
          } else {
            expect(
              result,
              equals('Kurang Penting & Tidak Mendesak → Eliminasi'),
              reason:
                  'kepentingan=$kepentingan, urgensi=$urgensi (keduanya rendah) harus → "Eliminasi"',
            );
          }

          iterationCount++;
        }
        expect(iterationCount, greaterThanOrEqualTo(100));
      },
    );
  });
}
