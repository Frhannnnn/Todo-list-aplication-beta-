// lib/utils/recurrence.dart

import 'package:intl/intl.dart';
import '../models/task_model.dart';

/// Minggu ke-berapa suatu tanggal dalam bulannya (1..5).
int mingguKeBerapa(DateTime date) => ((date.day - 1) ~/ 7) + 1;

String _unitLabel(RecurrenceUnit u) {
  switch (u) {
    case RecurrenceUnit.day:
      return 'hari';
    case RecurrenceUnit.week:
      return 'minggu';
    case RecurrenceUnit.month:
      return 'bulan';
    case RecurrenceUnit.year:
      return 'tahun';
  }
}

/// Label Indonesia dinamis (dibentuk ulang dari tanggal terpilih).
String recurrenceLabel(RecurrenceType type, DateTime date,
    {int interval = 1, RecurrenceUnit? unit}) {
  switch (type) {
    case RecurrenceType.none:
      return 'Tidak berulang';
    case RecurrenceType.daily:
      return 'Setiap hari';
    case RecurrenceType.weekly:
      return 'Setiap minggu di hari ${DateFormat('EEEE', 'id_ID').format(date)}';
    case RecurrenceType.monthly:
      return 'Setiap bulan di ${DateFormat('EEEE', 'id_ID').format(date)} ke-${mingguKeBerapa(date)}';
    case RecurrenceType.yearly:
      return 'Setiap tahun di ${DateFormat('d MMMM', 'id_ID').format(date)}';
    case RecurrenceType.weekday:
      return 'Setiap hari kerja (Senin–Jumat)';
    case RecurrenceType.custom:
      return 'Ulangi setiap $interval ${_unitLabel(unit ?? RecurrenceUnit.day)}';
  }
}

DateTime _addDays(DateTime d, int n) =>
    DateTime(d.year, d.month, d.day + n, d.hour, d.minute);

DateTime _addMonths(DateTime d, int n) {
  final total = d.month - 1 + n;
  final year = d.year + (total ~/ 12);
  final month = (total % 12) + 1;
  final lastDay = DateTime(year, month + 1, 0).day;
  final day = d.day <= lastDay ? d.day : lastDay;
  return DateTime(year, month, day, d.hour, d.minute);
}

DateTime _addYears(DateTime d, int n) {
  final year = d.year + n;
  final lastDay = DateTime(year, d.month + 1, 0).day; // handle 29 Feb
  final day = d.day <= lastDay ? d.day : lastDay;
  return DateTime(year, d.month, day, d.hour, d.minute);
}

DateTime _nextWeekday(DateTime d) {
  var next = _addDays(d, 1);
  while (next.weekday == DateTime.saturday || next.weekday == DateTime.sunday) {
    next = _addDays(next, 1);
  }
  return next;
}

/// Hari-ke-N-minggu yang sama di bulan berikutnya (mis. "Minggu ke-2 berikutnya").
DateTime _nextNthWeekday(DateTime d) {
  final n = mingguKeBerapa(d);
  final weekday = d.weekday;
  final firstNext = DateTime(d.year, d.month + 1, 1, d.hour, d.minute);
  var offset = (weekday - firstNext.weekday) % 7;
  if (offset < 0) offset += 7;
  var day = 1 + offset + (n - 1) * 7;
  final lastDay = DateTime(firstNext.year, firstNext.month + 1, 0).day;
  if (day > lastDay) day -= 7; // clamp ke kemunculan terakhir
  return DateTime(firstNext.year, firstNext.month, day, d.hour, d.minute);
}

DateTime? _rawNext(DateTime d, Task t) {
  switch (t.recurrence) {
    case RecurrenceType.none:
      return null;
    case RecurrenceType.daily:
      return _addDays(d, 1);
    case RecurrenceType.weekly:
      return _addDays(d, 7);
    case RecurrenceType.weekday:
      return _nextWeekday(d);
    case RecurrenceType.monthly:
      return _nextNthWeekday(d);
    case RecurrenceType.yearly:
      return _addYears(d, 1);
    case RecurrenceType.custom:
      final n = t.recurrenceInterval;
      switch (t.recurrenceUnit ?? RecurrenceUnit.day) {
        case RecurrenceUnit.day:
          return _addDays(d, n);
        case RecurrenceUnit.week:
          return _addDays(d, 7 * n);
        case RecurrenceUnit.month:
          return _addMonths(d, n);
        case RecurrenceUnit.year:
          return _addYears(d, n);
      }
  }
}

bool _seriesEnded(Task t, DateTime candidate, int candidateIndex) {
  if (t.recurrenceEndDate != null && candidate.isAfter(t.recurrenceEndDate!)) {
    return true;
  }
  if (t.recurrenceCount != null && candidateIndex > t.recurrenceCount!) {
    return true;
  }
  return false;
}

/// Deadline occurrence berikutnya SETELAH task.deadline; null bila seri berakhir.
DateTime? nextOccurrenceDate(Task task) {
  final next = _rawNext(task.deadline, task);
  if (next == null) return null;
  if (_seriesEnded(task, next, task.recurrenceIndex + 1)) return null;
  return next;
}

/// Tanggal occurrence mendatang (setelah deadline) sampai [until] / [maxCount].
/// Dipakai untuk preview kalender (tidak memateralize tugas).
List<DateTime> upcomingOccurrences(Task task,
    {required DateTime until, int maxCount = 60}) {
  if (task.recurrence == RecurrenceType.none) return const [];
  final result = <DateTime>[];
  var cursor = task.deadline;
  var index = task.recurrenceIndex;
  for (var i = 0; i < maxCount; i++) {
    final next = _rawNext(cursor, task);
    if (next == null) break;
    final nextIndex = index + 1;
    if (_seriesEnded(task, next, nextIndex)) break;
    if (next.isAfter(until)) break;
    result.add(next);
    cursor = next;
    index = nextIndex;
  }
  return result;
}
