// lib/utils/focus_recommendation.dart

/// Rekomendasi jumlah sesi & durasi fokus (menit) berdasarkan label prioritas
/// hasil SAW. Hanya MEMBACA label prioritas (mis. dari
/// `AppTheme.getPrioritasLabel`), tidak mengubah algoritma SAW.
///
/// Pengguna tetap bebas mengubah hasil ini di UI.
({int sessions, int minutes}) focusRecommendation(String priorityLabel) {
  switch (priorityLabel) {
    case 'Sangat Tinggi':
      return (sessions: 4, minutes: 50);
    case 'Tinggi':
      return (sessions: 3, minutes: 45);
    case 'Sedang':
      return (sessions: 2, minutes: 30);
    case 'Rendah':
      return (sessions: 1, minutes: 25);
    default:
      return (sessions: 2, minutes: 30);
  }
}
