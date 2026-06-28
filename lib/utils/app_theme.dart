// lib/utils/app_theme.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Primary palette — ungu lembut sesuai referensi
  static const Color primary = Color(0xFF6C5CE7);
  static const Color primaryLight = Color(0xFF9B8FEF);
  static const Color primaryDark = Color(0xFF4A3DB8);
  static const Color secondary = Color(0xFF7C3AED);
  static const Color accent = Color(0xFF06B6D4);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);

  // Neutral
  static const Color background = Color(0xFFF9FAFB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color border = Color(0xFFE5E7EB);
  static const Color cardBorder = Color(0xFFD1D5DB);

  // Priority colors
  static const Color prioritasRendah = Color(0xFF10B981);
  static const Color prioritasSedang = Color(0xFFF59E0B);
  static const Color prioritasTinggi = Color(0xFFEF4444);

  static ThemeData get theme {
    final textTheme = GoogleFonts.interTextTheme();

    return ThemeData(
      useMaterial3: true,
      textTheme: textTheme,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: border),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF3F4F6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: textSecondary,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }

  /// Mengembalikan label deskriptif untuk nilai slider kepentingan/urgensi (1–5).
  static String getLabelSlider(int value) {
    const labels = {
      1: 'Sangat Rendah',
      2: 'Rendah',
      3: 'Sedang',
      4: 'Tinggi',
      5: 'Sangat Tinggi',
    };
    return labels[value] ?? '-';
  }

  /// Mengembalikan label kuadran Eisenhower berdasarkan kombinasi kepentingan & urgensi.
  static String getEisenhowerLabel(int kepentingan, int urgensi) {
    final isImportant = kepentingan >= 4;
    final isUrgent = urgensi >= 4;
    if (isImportant && isUrgent) return 'Penting & Mendesak → Kerjakan Sekarang';
    if (isImportant && !isUrgent) return 'Penting, Tidak Mendesak → Jadwalkan';
    if (!isImportant && isUrgent) return 'Mendesak, Kurang Penting → Delegasikan';
    return 'Kurang Penting & Tidak Mendesak → Eliminasi';
  }

  static Color getPrioritasColor(int ranking, int total) {
    if (total == 0) return Colors.grey;
    double pct = ranking / total;
    if (pct <= 0.25) return prioritasTinggi;
    if (pct <= 0.60) return prioritasSedang;
    return prioritasRendah;
  }

  static String getPrioritasLabel(int ranking, int total) {
    if (total == 0) return '-';
    double pct = ranking / total;
    if (pct <= 0.25) return 'Tinggi';
    if (pct <= 0.60) return 'Sedang';
    return 'Rendah';
  }

  static Color getStatusColor(dynamic status) {
    switch (status.index) {
      case 0:
        return const Color(0xFF64748B);
      case 1:
        return warning;
      case 2:
        return success;
      default:
        return Colors.grey;
    }
  }
}
