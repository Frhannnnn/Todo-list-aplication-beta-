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
}
