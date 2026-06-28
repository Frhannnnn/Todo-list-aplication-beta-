# 📚 TugasKu - Aplikasi Manajemen Tugas Mahasiswa

Aplikasi Flutter untuk membantu mahasiswa mengelola tugas secara terstruktur menggunakan metode **SAW (Simple Additive Weighting)** untuk penentuan prioritas otomatis.

---

## 🚀 Cara Menjalankan

### Prasyarat
- Flutter SDK ≥ 3.0.0
- Dart SDK ≥ 3.0.0
- Android Studio / VS Code
- Android Emulator / Device fisik

### Langkah Setup

```bash
# 1. Clone / ekstrak project
cd tugasku

# 2. Install dependencies
flutter pub get

# 3. Jalankan aplikasi
flutter run
```

---

## 📱 Fitur Aplikasi

### 1. 📊 Dashboard
- Statistik total, aktif, selesai, dan terlambat
- Tugas dengan deadline terdekat
- Tugas dengan prioritas tertinggi
- Indikator tugas terlambat

### 2. 📋 Data Tugas
- Tambah, edit, hapus tugas
- Filter berdasarkan grup (Individu / Kelompok)
- Pencarian tugas
- Update status tugas langsung dari kartu

### 3. 🧠 Prioritas Tugas (SAW)
- Ranking otomatis semua tugas
- Tampilan skor SAW untuk setiap tugas
- Visualisasi prioritas (Tinggi / Sedang / Rendah)

### 4. ⚙️ Pengaturan
- Statistik penggunaan
- Informasi bobot SAW
- Reset data

---

## 🧮 Metode SAW

Aplikasi menggunakan **Simple Additive Weighting** dengan 3 kriteria:

| Kriteria | Bobot | Keterangan |
|----------|-------|-----------|
| Tingkat Urgensi | 40% | Seberapa mendesak tugas |
| Tingkat Kepentingan | 40% | Seberapa penting tugas |
| Estimasi Waktu | 20% | Semakin lama = perlu segera dikerjakan |

### Rumus:
```
Vi = Σ (Wj × Rij)
```
- `Vi` = Nilai preferensi tugas ke-i
- `Wj` = Bobot kriteria ke-j
- `Rij` = Nilai normalisasi tugas ke-i pada kriteria ke-j

---

## 🗂️ Struktur Project

```
lib/
├── main.dart                    # Entry point + navigasi
├── models/
│   └── task_model.dart          # Model data tugas
├── services/
│   ├── task_provider.dart       # State management (Provider)
│   └── saw_service.dart         # Kalkulasi SAW
├── screens/
│   ├── dashboard_screen.dart    # Halaman dashboard
│   ├── task_list_screen.dart    # Daftar tugas
│   ├── add_edit_task_screen.dart # Form tambah/edit
│   ├── priority_screen.dart     # Ranking SAW
│   └── settings_screen.dart     # Pengaturan
├── widgets/
│   └── task_card_widget.dart    # Kartu tugas reusable
└── utils/
    └── app_theme.dart           # Tema & warna
```

---

## 📦 Dependencies

```yaml
provider: ^6.1.2           # State management
shared_preferences: ^2.2.2  # Penyimpanan lokal
intl: ^0.19.0              # Format tanggal (id_ID)
uuid: ^4.3.3               # Generate ID unik
fl_chart: ^0.68.0          # Grafik (opsional)
```

---

## 🎨 Desain

- **Warna Utama**: Biru (#2563EB) + Ungu (#7C3AED)
- **Indikator Prioritas**: Merah (Tinggi) / Kuning (Sedang) / Hijau (Rendah)
- **Penyimpanan**: SharedPreferences (lokal di device)

---

## 👨‍💻 Dikembangkan dengan Flutter & Dart
