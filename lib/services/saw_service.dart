// lib/services/saw_service.dart
// Implementasi Metode SAW (Simple Additive Weighting)

import '../models/task_model.dart';

class SAWService {
  // Bobot kriteria (total = 1.0)
  // Kepentingan: 30%, Urgensi: 35%, Deadline: 25%, Estimasi Waktu: 10%
  static const double bobotKepentingan = 0.30;
  static const double bobotUrgensi = 0.35;
  static const double bobotDeadline = 0.25;
  static const double bobotEstimasi = 0.10;

  /// Hitung prioritas semua tugas menggunakan metode SAW
  /// dan kembalikan list yang sudah diurutkan berdasarkan ranking
  static List<Task> hitungPrioritas(List<Task> tasks) {
    if (tasks.isEmpty) return tasks;

    // Filter hanya tugas yang belum selesai
    final activeTasks = tasks.where((t) => t.status != TaskStatus.selesai).toList();
    final doneTasks = tasks.where((t) => t.status == TaskStatus.selesai).toList();

    if (activeTasks.isEmpty) return tasks;

    // Step 1: Buat matriks keputusan
    // Kolom: [kepentingan, urgensi, nilaiDeadline, estimasiWaktu]
    List<List<double>> matriks = activeTasks.map((task) {
      return [
        task.tingkatKepentingan.toDouble(),
        task.tingkatUrgensi.toDouble(),
        _hitungNilaiDeadline(task.sisaHari),
        _hitungNilaiEstimasi(task.estimasiWaktu),
      ];
    }).toList();

    // Step 2: Normalisasi matriks (benefit criteria: nilai max lebih baik)
    List<List<double>> matriksNormalisasi = _normalisasiMatriks(matriks);

    // Step 3: Hitung nilai preferensi (Vi = Σ Wj * Rij)
    List<double> nilaiPreferensi = [];
    for (int i = 0; i < activeTasks.length; i++) {
      double vi = (matriksNormalisasi[i][0] * bobotKepentingan) +
                  (matriksNormalisasi[i][1] * bobotUrgensi) +
                  (matriksNormalisasi[i][2] * bobotDeadline) +
                  (matriksNormalisasi[i][3] * bobotEstimasi);
      nilaiPreferensi.add(vi);
    }

    // Step 4: Assign SAW score ke setiap tugas
    List<Task> updatedTasks = [];
    for (int i = 0; i < activeTasks.length; i++) {
      updatedTasks.add(activeTasks[i].copyWith(sawScore: nilaiPreferensi[i]));
    }

    // Step 5: Urutkan berdasarkan nilai SAW (descending) dan assign ranking
    updatedTasks.sort((a, b) => b.sawScore.compareTo(a.sawScore));
    for (int i = 0; i < updatedTasks.length; i++) {
      updatedTasks[i] = updatedTasks[i].copyWith(ranking: i + 1);
    }

    // Gabungkan tugas aktif (sudah diranking) dengan tugas selesai
    return [...updatedTasks, ...doneTasks];
  }

  /// Konversi sisa hari menjadi nilai 1-5 (semakin dekat deadline, semakin tinggi)
  static double _hitungNilaiDeadline(int sisaHari) {
    if (sisaHari < 0) return 5.0; // Sudah lewat deadline
    if (sisaHari == 0) return 5.0;
    if (sisaHari <= 1) return 4.5;
    if (sisaHari <= 3) return 4.0;
    if (sisaHari <= 7) return 3.0;
    if (sisaHari <= 14) return 2.0;
    return 1.0;
  }

  /// Konversi estimasi waktu menjadi nilai 1-5 (semakin lama, semakin penting dikerjakan segera)
  static double _hitungNilaiEstimasi(int jamEstimasi) {
    if (jamEstimasi >= 8) return 5.0;
    if (jamEstimasi >= 6) return 4.0;
    if (jamEstimasi >= 4) return 3.0;
    if (jamEstimasi >= 2) return 2.0;
    return 1.0;
  }

  /// Normalisasi matriks keputusan
  static List<List<double>> _normalisasiMatriks(List<List<double>> matriks) {
    int jumlahKriteria = matriks[0].length;
    List<List<double>> hasil = List.generate(
      matriks.length, (_) => List.filled(jumlahKriteria, 0.0));

    for (int j = 0; j < jumlahKriteria; j++) {
      double maxVal = matriks.map((row) => row[j]).reduce((a, b) => a > b ? a : b);
      for (int i = 0; i < matriks.length; i++) {
        hasil[i][j] = maxVal == 0 ? 0 : matriks[i][j] / maxVal;
      }
    }
    return hasil;
  }

  /// Dapatkan label prioritas berdasarkan ranking
  static String getLabelPrioritas(int ranking, int totalTasks) {
    if (totalTasks == 0) return 'Tidak ada tugas';
    double persentase = ranking / totalTasks;
    if (persentase <= 0.25) return 'Prioritas Tinggi';
    if (persentase <= 0.60) return 'Prioritas Sedang';
    return 'Prioritas Rendah';
  }

  /// Warna untuk label prioritas
  static String getWarnaPrioritas(int ranking, int totalTasks) {
    if (totalTasks == 0) return 'grey';
    double persentase = ranking / totalTasks;
    if (persentase <= 0.25) return 'red';
    if (persentase <= 0.60) return 'orange';
    return 'green';
  }
}
