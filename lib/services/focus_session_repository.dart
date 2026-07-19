// lib/services/focus_session_repository.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/focus_session_model.dart';

/// Persistensi snapshot sesi fokus aktif lewat SharedPreferences. Hanya membaca
/// & menulis data (tanpa business logic). Dipakai untuk memulihkan sesi saat
/// aplikasi dibuka kembali. History & Focus Streak ditambahkan pada fase
/// berikutnya (belum dibuat di sini).
class FocusSessionRepository {
  static const String _activeKey = 'focus_active_session';
  static const String _historyKey = 'focus_history';
  static const String _streakKey = 'focus_streak';
  static const String _streakDateKey = 'focus_streak_date';
  static const int _maxHistory = 100;

  Future<void> saveActive(ActiveSessionSnapshot snapshot) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeKey, jsonEncode(snapshot.toJson()));
  }

  Future<ActiveSessionSnapshot?> loadActive() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_activeKey);
    if (raw == null) return null;
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      return ActiveSessionSnapshot.fromJson(data);
    } catch (_) {
      await prefs.remove(_activeKey);
      return null;
    }
  }

  Future<void> clearActive() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activeKey);
  }

  // ── Riwayat ──────────────────────────────────────────────────────────────

  Future<void> addHistory(FocusHistoryEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_historyKey) ?? <String>[];
    list.insert(0, jsonEncode(entry.toJson()));
    if (list.length > _maxHistory) {
      list.removeRange(_maxHistory, list.length);
    }
    await prefs.setStringList(_historyKey, list);
  }

  Future<List<FocusHistoryEntry>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_historyKey) ?? <String>[];
    final result = <FocusHistoryEntry>[];
    for (final raw in list) {
      try {
        result.add(
            FocusHistoryEntry.fromJson(jsonDecode(raw) as Map<String, dynamic>));
      } catch (_) {
        // lewati entri rusak
      }
    }
    return result;
  }

  // ── Focus Streak ─────────────────────────────────────────────────────────

  Future<({int streak, String? lastDate})> loadStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return (
      streak: prefs.getInt(_streakKey) ?? 0,
      lastDate: prefs.getString(_streakDateKey),
    );
  }

  Future<void> saveStreak(int streak, String lastDate) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_streakKey, streak);
    await prefs.setString(_streakDateKey, lastDate);
  }
}
