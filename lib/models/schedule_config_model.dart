// lib/models/schedule_config_model.dart

class ScheduleConfig {
  final int workStartHour; // Default: 8
  final int workStartMinute; // Default: 0
  final int workEndHour; // Default: 17
  final int workEndMinute; // Default: 0

  ScheduleConfig({
    this.workStartHour = 8,
    this.workStartMinute = 0,
    this.workEndHour = 17,
    this.workEndMinute = 0,
  });

  /// Apakah konfigurasi lintas tengah malam (e.g., 22:00-06:00)
  bool get isCrossMidnight =>
      workStartHour > workEndHour ||
      (workStartHour == workEndHour && workStartMinute > workEndMinute);

  /// Apakah slot tertentu berada dalam Primary Work Hours.
  ///
  /// Slot mewakili periode [slotStart, slotStart + 1 jam).
  /// Slot dianggap dalam work hours jika slotStart >= workStart
  /// dan slotStart < workEnd (menggunakan perbandingan jam dan menit).
  ///
  /// Mendukung konfigurasi lintas tengah malam (e.g., 22:00-06:00):
  /// - Untuk 22:00-06:00, slot 22:00, 23:00, 0:00, ..., 5:00 termasuk work hours
  /// - Slot 06:00 TIDAK termasuk karena mewakili periode 06:00-07:00 yang sudah di luar
  bool isWithinWorkHours(DateTime slotStart) {
    final slotMinutes = slotStart.hour * 60 + slotStart.minute;
    final startMinutes = workStartHour * 60 + workStartMinute;
    final endMinutes = workEndHour * 60 + workEndMinute;

    if (isCrossMidnight) {
      // Cross-midnight: e.g., 22:00-06:00
      // Valid if slot >= start OR slot < end
      return slotMinutes >= startMinutes || slotMinutes < endMinutes;
    } else {
      // Normal: e.g., 08:00-17:00
      // Valid if slot >= start AND slot < end
      return slotMinutes >= startMinutes && slotMinutes < endMinutes;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'workStartHour': workStartHour,
      'workStartMinute': workStartMinute,
      'workEndHour': workEndHour,
      'workEndMinute': workEndMinute,
    };
  }

  factory ScheduleConfig.fromJson(Map<String, dynamic> json) {
    return ScheduleConfig(
      workStartHour: json['workStartHour'] as int,
      workStartMinute: json['workStartMinute'] as int,
      workEndHour: json['workEndHour'] as int,
      workEndMinute: json['workEndMinute'] as int,
    );
  }
}
