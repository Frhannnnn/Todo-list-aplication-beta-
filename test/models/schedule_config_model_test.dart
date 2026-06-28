import 'package:flutter_test/flutter_test.dart';
import 'package:tugasku/models/schedule_config_model.dart';

void main() {
  group('ScheduleConfig', () {
    group('default values', () {
      test('should have default work hours 08:00-17:00', () {
        final config = ScheduleConfig();
        expect(config.workStartHour, 8);
        expect(config.workStartMinute, 0);
        expect(config.workEndHour, 17);
        expect(config.workEndMinute, 0);
      });
    });

    group('isCrossMidnight', () {
      test('should return false for normal hours (08:00-17:00)', () {
        final config = ScheduleConfig();
        expect(config.isCrossMidnight, false);
      });

      test('should return true for cross-midnight (22:00-06:00)', () {
        final config = ScheduleConfig(workStartHour: 22, workEndHour: 6);
        expect(config.isCrossMidnight, true);
      });

      test('should return true when start equals end with higher start minute',
          () {
        final config = ScheduleConfig(
          workStartHour: 10,
          workStartMinute: 30,
          workEndHour: 10,
          workEndMinute: 0,
        );
        expect(config.isCrossMidnight, true);
      });

      test('should return false when start equals end with same minutes', () {
        final config = ScheduleConfig(
          workStartHour: 10,
          workStartMinute: 0,
          workEndHour: 10,
          workEndMinute: 0,
        );
        expect(config.isCrossMidnight, false);
      });
    });

    group('isWithinWorkHours - normal hours', () {
      final config = ScheduleConfig(); // 08:00-17:00

      test('slot at 08:00 is within work hours', () {
        final slot = DateTime(2024, 1, 15, 8, 0);
        expect(config.isWithinWorkHours(slot), true);
      });

      test('slot at 16:00 is within work hours', () {
        final slot = DateTime(2024, 1, 15, 16, 0);
        expect(config.isWithinWorkHours(slot), true);
      });

      test('slot at 17:00 is NOT within work hours (represents 17:00-18:00)',
          () {
        final slot = DateTime(2024, 1, 15, 17, 0);
        expect(config.isWithinWorkHours(slot), false);
      });

      test('slot at 07:00 is NOT within work hours', () {
        final slot = DateTime(2024, 1, 15, 7, 0);
        expect(config.isWithinWorkHours(slot), false);
      });

      test('slot at 00:00 is NOT within work hours', () {
        final slot = DateTime(2024, 1, 15, 0, 0);
        expect(config.isWithinWorkHours(slot), false);
      });

      test('slot at 23:00 is NOT within work hours', () {
        final slot = DateTime(2024, 1, 15, 23, 0);
        expect(config.isWithinWorkHours(slot), false);
      });
    });

    group('isWithinWorkHours - cross-midnight', () {
      final config =
          ScheduleConfig(workStartHour: 22, workEndHour: 6); // 22:00-06:00

      test('slot at 22:00 is within work hours', () {
        final slot = DateTime(2024, 1, 15, 22, 0);
        expect(config.isWithinWorkHours(slot), true);
      });

      test('slot at 23:00 is within work hours', () {
        final slot = DateTime(2024, 1, 15, 23, 0);
        expect(config.isWithinWorkHours(slot), true);
      });

      test('slot at 00:00 is within work hours', () {
        final slot = DateTime(2024, 1, 15, 0, 0);
        expect(config.isWithinWorkHours(slot), true);
      });

      test('slot at 05:00 is within work hours', () {
        final slot = DateTime(2024, 1, 15, 5, 0);
        expect(config.isWithinWorkHours(slot), true);
      });

      test('slot at 06:00 is NOT within work hours (represents 06:00-07:00)',
          () {
        final slot = DateTime(2024, 1, 15, 6, 0);
        expect(config.isWithinWorkHours(slot), false);
      });

      test('slot at 12:00 is NOT within work hours', () {
        final slot = DateTime(2024, 1, 15, 12, 0);
        expect(config.isWithinWorkHours(slot), false);
      });

      test('slot at 21:00 is NOT within work hours', () {
        final slot = DateTime(2024, 1, 15, 21, 0);
        expect(config.isWithinWorkHours(slot), false);
      });
    });

    group('isWithinWorkHours - with minutes precision', () {
      final config = ScheduleConfig(
        workStartHour: 8,
        workStartMinute: 30,
        workEndHour: 17,
        workEndMinute: 30,
      ); // 08:30-17:30

      test('slot at 08:00 is NOT within work hours (before 08:30)', () {
        final slot = DateTime(2024, 1, 15, 8, 0);
        expect(config.isWithinWorkHours(slot), false);
      });

      test('slot at 08:30 is within work hours', () {
        final slot = DateTime(2024, 1, 15, 8, 30);
        expect(config.isWithinWorkHours(slot), true);
      });

      test('slot at 17:00 is within work hours (before 17:30)', () {
        final slot = DateTime(2024, 1, 15, 17, 0);
        expect(config.isWithinWorkHours(slot), true);
      });

      test('slot at 17:30 is NOT within work hours', () {
        final slot = DateTime(2024, 1, 15, 17, 30);
        expect(config.isWithinWorkHours(slot), false);
      });
    });

    group('toJson', () {
      test('should serialize default config correctly', () {
        final config = ScheduleConfig();
        final json = config.toJson();
        expect(json, {
          'workStartHour': 8,
          'workStartMinute': 0,
          'workEndHour': 17,
          'workEndMinute': 0,
        });
      });

      test('should serialize custom config correctly', () {
        final config = ScheduleConfig(
          workStartHour: 22,
          workStartMinute: 30,
          workEndHour: 6,
          workEndMinute: 15,
        );
        final json = config.toJson();
        expect(json, {
          'workStartHour': 22,
          'workStartMinute': 30,
          'workEndHour': 6,
          'workEndMinute': 15,
        });
      });
    });

    group('fromJson', () {
      test('should deserialize correctly', () {
        final json = {
          'workStartHour': 9,
          'workStartMinute': 15,
          'workEndHour': 18,
          'workEndMinute': 45,
        };
        final config = ScheduleConfig.fromJson(json);
        expect(config.workStartHour, 9);
        expect(config.workStartMinute, 15);
        expect(config.workEndHour, 18);
        expect(config.workEndMinute, 45);
      });
    });

    group('serialization round trip', () {
      test('toJson then fromJson produces equivalent object', () {
        final original = ScheduleConfig(
          workStartHour: 22,
          workStartMinute: 30,
          workEndHour: 6,
          workEndMinute: 15,
        );
        final restored = ScheduleConfig.fromJson(original.toJson());
        expect(restored.workStartHour, original.workStartHour);
        expect(restored.workStartMinute, original.workStartMinute);
        expect(restored.workEndHour, original.workEndHour);
        expect(restored.workEndMinute, original.workEndMinute);
        expect(restored.isCrossMidnight, original.isCrossMidnight);
      });
    });
  });
}
