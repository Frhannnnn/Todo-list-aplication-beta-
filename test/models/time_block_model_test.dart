import 'package:flutter_test/flutter_test.dart';
import 'package:tugasku/models/time_block_model.dart';

void main() {
  group('TimeBlockStatus', () {
    test('has correct values', () {
      expect(TimeBlockStatus.values.length, 3);
      expect(TimeBlockStatus.active.index, 0);
      expect(TimeBlockStatus.missed.index, 1);
      expect(TimeBlockStatus.manuallyMoved.index, 2);
    });
  });

  group('TimeBlock', () {
    final validStartTime = DateTime(2024, 1, 15, 8, 0, 0);
    final validEndTime = DateTime(2024, 1, 15, 9, 0, 0);

    test('creates with valid hour-boundary startTime', () {
      final block = TimeBlock(
        id: 'block-1',
        taskId: 'task-1',
        startTime: validStartTime,
        endTime: validEndTime,
      );

      expect(block.id, 'block-1');
      expect(block.taskId, 'task-1');
      expect(block.startTime, validStartTime);
      expect(block.endTime, validEndTime);
      expect(block.status, TimeBlockStatus.active);
      expect(block.isManuallyPlaced, false);
    });

    test('defaults status to active and isManuallyPlaced to false', () {
      final block = TimeBlock(
        id: 'block-1',
        taskId: 'task-1',
        startTime: validStartTime,
        endTime: validEndTime,
      );

      expect(block.status, TimeBlockStatus.active);
      expect(block.isManuallyPlaced, false);
    });

    test('accepts custom status and isManuallyPlaced', () {
      final block = TimeBlock(
        id: 'block-1',
        taskId: 'task-1',
        startTime: validStartTime,
        endTime: validEndTime,
        status: TimeBlockStatus.missed,
        isManuallyPlaced: true,
      );

      expect(block.status, TimeBlockStatus.missed);
      expect(block.isManuallyPlaced, true);
    });

    test('asserts startTime on hour boundary', () {
      expect(
        () => TimeBlock(
          id: 'block-1',
          taskId: 'task-1',
          startTime: DateTime(2024, 1, 15, 8, 30, 0),
          endTime: DateTime(2024, 1, 15, 9, 30, 0),
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('asserts endTime equals startTime + 1 hour', () {
      expect(
        () => TimeBlock(
          id: 'block-1',
          taskId: 'task-1',
          startTime: validStartTime,
          endTime: DateTime(2024, 1, 15, 10, 0, 0), // 2 hours later
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    group('toJson', () {
      test('serializes correctly', () {
        final block = TimeBlock(
          id: 'block-1',
          taskId: 'task-1',
          startTime: validStartTime,
          endTime: validEndTime,
          status: TimeBlockStatus.active,
          isManuallyPlaced: false,
        );

        final json = block.toJson();

        expect(json['id'], 'block-1');
        expect(json['taskId'], 'task-1');
        expect(json['startTime'], '2024-01-15T08:00:00.000');
        expect(json['endTime'], '2024-01-15T09:00:00.000');
        expect(json['status'], 0);
        expect(json['isManuallyPlaced'], false);
      });

      test('serializes status as int index', () {
        final block = TimeBlock(
          id: 'block-1',
          taskId: 'task-1',
          startTime: validStartTime,
          endTime: validEndTime,
          status: TimeBlockStatus.manuallyMoved,
          isManuallyPlaced: true,
        );

        final json = block.toJson();
        expect(json['status'], 2);
        expect(json['isManuallyPlaced'], true);
      });
    });

    group('fromJson', () {
      test('deserializes correctly', () {
        final json = {
          'id': 'block-1',
          'taskId': 'task-1',
          'startTime': '2024-01-15T08:00:00.000',
          'endTime': '2024-01-15T09:00:00.000',
          'status': 0,
          'isManuallyPlaced': false,
        };

        final block = TimeBlock.fromJson(json);

        expect(block.id, 'block-1');
        expect(block.taskId, 'task-1');
        expect(block.startTime, DateTime(2024, 1, 15, 8, 0, 0));
        expect(block.endTime, DateTime(2024, 1, 15, 9, 0, 0));
        expect(block.status, TimeBlockStatus.active);
        expect(block.isManuallyPlaced, false);
      });

      test('handles missing isManuallyPlaced (defaults to false)', () {
        final json = {
          'id': 'block-1',
          'taskId': 'task-1',
          'startTime': '2024-01-15T08:00:00.000',
          'endTime': '2024-01-15T09:00:00.000',
          'status': 1,
        };

        final block = TimeBlock.fromJson(json);
        expect(block.isManuallyPlaced, false);
        expect(block.status, TimeBlockStatus.missed);
      });
    });

    group('copyWith', () {
      test('copies with no changes', () {
        final block = TimeBlock(
          id: 'block-1',
          taskId: 'task-1',
          startTime: validStartTime,
          endTime: validEndTime,
          status: TimeBlockStatus.active,
          isManuallyPlaced: false,
        );

        final copy = block.copyWith();

        expect(copy.id, block.id);
        expect(copy.taskId, block.taskId);
        expect(copy.startTime, block.startTime);
        expect(copy.endTime, block.endTime);
        expect(copy.status, block.status);
        expect(copy.isManuallyPlaced, block.isManuallyPlaced);
      });

      test('copies with changed status', () {
        final block = TimeBlock(
          id: 'block-1',
          taskId: 'task-1',
          startTime: validStartTime,
          endTime: validEndTime,
        );

        final copy = block.copyWith(status: TimeBlockStatus.missed);

        expect(copy.status, TimeBlockStatus.missed);
        expect(copy.id, block.id);
        expect(copy.startTime, block.startTime);
      });

      test('copies with new startTime auto-adjusts endTime', () {
        final block = TimeBlock(
          id: 'block-1',
          taskId: 'task-1',
          startTime: validStartTime,
          endTime: validEndTime,
        );

        final newStart = DateTime(2024, 1, 15, 14, 0, 0);
        final copy = block.copyWith(startTime: newStart);

        expect(copy.startTime, newStart);
        expect(copy.endTime, DateTime(2024, 1, 15, 15, 0, 0));
      });

      test('copies with isManuallyPlaced changed', () {
        final block = TimeBlock(
          id: 'block-1',
          taskId: 'task-1',
          startTime: validStartTime,
          endTime: validEndTime,
        );

        final copy = block.copyWith(isManuallyPlaced: true);
        expect(copy.isManuallyPlaced, true);
      });
    });

    group('round-trip serialization', () {
      test('toJson then fromJson produces equivalent object', () {
        final original = TimeBlock(
          id: 'block-abc',
          taskId: 'task-xyz',
          startTime: DateTime(2024, 3, 20, 14, 0, 0),
          endTime: DateTime(2024, 3, 20, 15, 0, 0),
          status: TimeBlockStatus.manuallyMoved,
          isManuallyPlaced: true,
        );

        final json = original.toJson();
        final restored = TimeBlock.fromJson(json);

        expect(restored.id, original.id);
        expect(restored.taskId, original.taskId);
        expect(restored.startTime, original.startTime);
        expect(restored.endTime, original.endTime);
        expect(restored.status, original.status);
        expect(restored.isManuallyPlaced, original.isManuallyPlaced);
      });
    });
  });
}
