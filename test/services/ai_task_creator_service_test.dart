import 'package:flutter_test/flutter_test.dart';
import 'package:tugasku/services/ai_task_creator_service.dart';

void main() {
  late AITaskCreatorService service;

  setUp(() {
    service = AITaskCreatorService();
  });

  group('AITaskCreatorService - extractTasks', () {
    group('Input validation', () {
      test('throws AIExtractionException when input is too short (< 50 chars)',
          () async {
        expect(
          () => service.extractTasks('Short input'),
          throwsA(
            isA<AIExtractionException>().having(
              (e) => e.reason,
              'reason',
              AIExtractionFailureReason.inputTooShort,
            ),
          ),
        );
      });

      test('throws AIExtractionException when input is too long (> 10000 chars)',
          () async {
        final longInput = 'a' * 10001;
        expect(
          () => service.extractTasks(longInput),
          throwsA(
            isA<AIExtractionException>().having(
              (e) => e.reason,
              'reason',
              AIExtractionFailureReason.inputTooLong,
            ),
          ),
        );
      });

      test('accepts input at minimum length (50 chars)', () async {
        // 50 chars of meaningful content on one line
        const input = 'Mengerjakan tugas pemrograman web semester genap ok';
        expect(input.length, greaterThanOrEqualTo(50));

        final result = await service.extractTasks(input);
        expect(result, isNotEmpty);
      });

      test('accepts input at maximum length (10000 chars)', () async {
        // Create valid input close to 10000 chars
        const line = 'Tugas pemrograman dasar\n';
        final repeatCount = 9900 ~/ line.length;
        final input = line * repeatCount;
        // Ensure it's within bounds
        expect(input.length, greaterThanOrEqualTo(50));
        expect(input.length, lessThanOrEqualTo(10000));

        final result = await service.extractTasks(input);
        expect(result, isNotEmpty);
      });
    });

    group('Task extraction', () {
      test('extracts tasks from newline-separated text', () async {
        const input = '''Tugas-tugas semester ini yang harus dikerjakan segera:
- Membuat laporan praktikum basis data
- Mengerjakan tugas pemrograman web
- Presentasi project akhir mata kuliah
- Quiz algoritma dan struktur data''';

        final result = await service.extractTasks(input);
        expect(result.length, equals(5)); // header line + 4 items
      });

      test('removes list markers (-, *, •, numbered) from task names', () async {
        const input = '''Daftar tugas yang perlu diselesaikan minggu ini:
- Tugas pertama yang harus dikerjakan
* Tugas kedua yang harus dikerjakan
• Tugas ketiga yang harus dikerjakan
1. Tugas keempat yang harus dikerjakan
2) Tugas kelima yang harus dikerjakan''';

        final result = await service.extractTasks(input);
        // Verify markers are removed
        for (final suggestion in result) {
          expect(suggestion.namaTugas, isNot(startsWith('- ')));
          expect(suggestion.namaTugas, isNot(startsWith('* ')));
          expect(suggestion.namaTugas, isNot(startsWith('• ')));
          expect(
            suggestion.namaTugas,
            isNot(matches(RegExp(r'^\d+[.)]\s'))),
          );
        }
      });

      test('skips empty lines', () async {
        const input = '''Tugas semester ini yang harus segera dikerjakan:

Membuat laporan praktikum basis data

Mengerjakan tugas pemrograman web minggu ini''';

        final result = await service.extractTasks(input);
        // Only non-empty lines should be extracted
        expect(result.length, equals(3));
      });

      test('limits extraction to maximum 50 tasks', () async {
        final lines = List.generate(
          60,
          (i) => '- Tugas nomor ${i + 1} yang harus dikerjakan',
        );
        final input = lines.join('\n');

        final result = await service.extractTasks(input);
        expect(result.length, equals(50));
      });
    });

    group('TaskSuggestion defaults', () {
      test('assigns default values for extracted tasks', () async {
        const input =
            'Mengerjakan tugas biasa yang tidak memiliki keyword khusus apapun di dalamnya';

        final result = await service.extractTasks(input);
        expect(result, isNotEmpty);

        final suggestion = result.first;
        expect(suggestion.deadline, isNull);
        expect(suggestion.estimasiWaktu, inInclusiveRange(1, 10));
        expect(suggestion.tingkatKepentingan, inInclusiveRange(1, 5));
        expect(suggestion.tingkatUrgensi, inInclusiveRange(1, 5));
        expect(suggestion.isSelected, isTrue);
      });

      test('assigns higher importance for exam-related keywords', () async {
        const input =
            'Belajar untuk UAS mata kuliah pemrograman dasar semester ini';

        final result = await service.extractTasks(input);
        expect(result, isNotEmpty);
        expect(result.first.tingkatKepentingan, equals(5));
      });

      test('assigns higher urgency for time-sensitive keywords', () async {
        const input =
            'Mengerjakan tugas yang harus dikumpulkan besok pagi jam delapan';

        final result = await service.extractTasks(input);
        expect(result, isNotEmpty);
        expect(result.first.tingkatUrgensi, equals(5));
      });

      test('assigns higher estimation for large project keywords', () async {
        const input =
            'Menyelesaikan tugas besar pemrograman web semester genap ini';

        final result = await service.extractTasks(input);
        expect(result, isNotEmpty);
        expect(result.first.estimasiWaktu, equals(5));
      });
    });

    group('Error handling', () {
      test('throws when no tasks can be extracted from input', () async {
        // Input with only whitespace/empty lines but meeting min length
        final input = ' ' * 50 + '\n' * 10;
        expect(
          () => service.extractTasks(input),
          throwsA(
            isA<AIExtractionException>().having(
              (e) => e.reason,
              'reason',
              AIExtractionFailureReason.extractionFailed,
            ),
          ),
        );
      });

      test('AIExtractionException has descriptive message', () async {
        try {
          await service.extractTasks('too short');
        } on AIExtractionException catch (e) {
          expect(e.message, contains('minimum'));
          expect(e.toString(), contains('AIExtractionException'));
        }
      });
    });

    group('Timeout handling', () {
      test('service has 30-second timeout configured', () {
        expect(
          AITaskCreatorService.extractionTimeout,
          equals(const Duration(seconds: 30)),
        );
      });

      test('service has max 50 tasks per extraction configured', () {
        expect(AITaskCreatorService.maxTasksPerExtraction, equals(50));
      });
    });
  });
}
