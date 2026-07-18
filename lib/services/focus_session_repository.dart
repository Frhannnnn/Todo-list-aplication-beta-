// lib/services/focus_session_repository.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/focus_session_model.dart';

/// Persistensi snapshot sesi fokus yang sedang aktif lewat SharedPreferences.
/// Dipakai untuk memulihkan sesi saat aplikasi dibuka kembali. History &
/// Focus Streak ditambahkan pada fase berikutnya (belum dibuat di sini).
class FocusSessionRepository {
  static const String _activeKey = 'focus_active_session';

  Future<void> saveActive(FocusSession session, int remainingSeconds) async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'session': session.toJson(),
      'remainingSeconds': remainingSeconds,
    };
    await prefs.setString(_activeKey, jsonEncode(data));
  }

  Future<({FocusSession session, int remainingSeconds})?> loadActive() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_activeKey);
    if (raw == null) return null;
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final session =
          FocusSession.fromJson(data['session'] as Map<String, dynamic>);
      final remaining = data['remainingSeconds'] as int? ?? 0;
      return (session: session, remainingSeconds: remaining);
    } catch (_) {
      await prefs.remove(_activeKey);
      return null;
    }
  }

  Future<void> clearActive() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activeKey);
  }
}
