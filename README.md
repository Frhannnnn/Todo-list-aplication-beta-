# Priora - Aplikasi Manajemen Tugas Mahasiswa

Aplikasi Flutter untuk membantu mahasiswa mengelola tugas secara terstruktur. Prioritas ditentukan otomatis dengan metode **SAW (Simple Additive Weighting)**, dilengkapi **Sesi Fokus**, **tugas berulang**, dan notifikasi deadline.

[![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

---

## Daftar Isi

- [Tentang Aplikasi](#tentang-aplikasi)
- [Fitur Utama](#fitur-utama)
- [Sesi Fokus](#sesi-fokus)
- [Tugas Berulang](#tugas-berulang)
- [Metode SAW](#metode-saw)
- [Technology Stack](#technology-stack)
- [Arsitektur Project](#arsitektur-project)
- [Penyimpanan Data](#penyimpanan-data)
- [API Reference](#api-reference)
- [Setup Project](#setup-project)
- [Cara Menjalankan](#cara-menjalankan)
- [Testing](#testing)
- [Desain UI](#desain-ui)
- [Privasi Data](#privasi-data)

---

## Tentang Aplikasi

**Priora** adalah aplikasi manajemen tugas untuk mahasiswa. Namanya berasal dari *priority* — inti aplikasinya adalah menjawab satu pertanyaan: **tugas mana yang harus dikerjakan lebih dulu?**

Nilai utama:

- **Prioritas otomatis** — metode SAW memberi peringkat tugas tanpa perlu diurutkan manual
- **Sesi Fokus** — timer terstruktur dengan mode, preset, target, dan riwayat
- **Tugas berulang** — tugas rutin dibuat sekali, occurrence berikutnya lahir otomatis
- **Notifikasi deadline** — pengingat berjenjang (H-3, H-1, 3 jam, saat deadline)
- **Offline penuh** — semua data tersimpan lokal di perangkat
- **Cadangan manual** — ekspor & impor seluruh data lewat file JSON

### Navigasi

Aplikasi punya 5 tab utama:

| Tab | Isi |
|-----|-----|
| **Dashboard** | Ringkasan mingguan, progres, streak fokus, kalender mingguan, Prioritas Teratas |
| **Tugas** | Daftar lengkap tugas — cari, filter, swipe untuk selesai/hapus |
| **Kalender** | Deadline per tanggal dalam tampilan bulanan |
| **Prioritas** | Peringkat SAW & matriks Eisenhower |
| **Profil** | Statistik, notifikasi, ekspor/impor, riwayat fokus, kelola data |

---

## Fitur Utama

### Dashboard

- Header brand dengan tombol tambah tugas cepat
- Ringkasan Minggu Ini (jumlah tugas pada lingkup aktif)
- Progres `selesai/total` + **streak fokus** (jumlah hari berturut-turut menjalankan sesi fokus)
- **Kalender mingguan** (7 hari berjalan) dengan penanda hari ini dan pintasan ke tab Kalender
- **Fokus Sekarang** — satu ketuk untuk langsung mengerjakan tugas prioritas teratas
- **Prioritas Teratas** — 3 tugas dengan peringkat SAW tertinggi
- Kartu penuntun khusus pengguna baru (belum punya tugas sama sekali)

### Manajemen Tugas

- **Tambah / Ubah / Hapus** tugas, dengan **Urungkan** lewat snackbar setelah menghapus
- **Preset deadline** cepat: Hari ini, Besok, 3 hari, Minggu depan (otomatis pukul 23:59)
- **Opsi lanjutan dilipat** secara default — input wajib hanya nama tugas & deadline
- **Swipe** pada kartu: geser kanan untuk tandai selesai, geser kiri untuk hapus
- **Guard perubahan** — konfirmasi sebelum keluar bila form belum disimpan
- **Guard tugas ganda** — tombol simpan terkunci saat proses penyimpanan berjalan
- **Kolom Mata Kuliah** muncul otomatis saat lingkup = *Perkuliahan*
- Cari & filter (status, lingkup, kategori) dalam satu baris ringkas
- Tarik-untuk-menyegarkan (pull to refresh)
- Perayaan singkat saat tugas ditandai selesai

### Lingkup & Kategori

- **Lingkup** (mis. Perkuliahan, Tugas Rumah, Pekerjaan) — tambah, ganti nama (cascade ke semua tugas), hapus dengan pemindahan tugas
- **Kategori independen per lingkup** — tiap lingkup punya daftar kategorinya sendiri
- Kelola langsung dari form tambah/ubah tugas lewat ikon `+` dan `Kelola`

### Prioritas

- Peringkat otomatis dengan SAW — 3 kriteria: Urgensi (40%), Kepentingan (40%), Estimasi Waktu (20%)
- Skor SAW terlihat per tugas
- Matriks Eisenhower (Penting/Mendesak) sebagai pembanding visual
- Urgensi dihitung ulang berkala (tiap 5 menit) selama aplikasi terbuka

### Kalender

- Tampilan bulanan dengan penanda tugas per tanggal
- Sorotan tugas terlambat & mendekati deadline
- Pratinjau occurrence tugas berulang

### Notifikasi

- Sakelar **global** dan sakelar **per tugas** (hierarki jelas: global mati = semua mati)
- Jadwal berjenjang: H-3, H-1, 3 jam sebelum, dan saat deadline
- Pengingat harian dengan jam yang bisa diatur
- Notifikasi berjalan saat sesi fokus aktif
- Fallback otomatis ke *inexact alarm* bila izin *exact alarm* tidak tersedia

### Profil & Data

- Statistik total, aktif, selesai, terlambat
- **Ekspor & Impor** seluruh data ke/dari file JSON, dengan validasi format
- **Pengingat cadangan** — menampilkan kapan terakhir kali data dicadangkan
- **Riwayat Fokus** — daftar sesi fokus yang pernah dijalankan
- Hapus semua tugas (dengan konfirmasi)

---

## Sesi Fokus

Menekan **Mulai** pada tugas (atau **Fokus Sekarang** di Dashboard) membuka alur sesi fokus.

### Alur

```
Pilih Mode & Preset  ->  Tetapkan Target  ->  Persiapan  ->  Timer
                                                              |
                                       Istirahat  <-----------+
                                                              |
                                                    Sesi Selesai (ringkasan)
```

### Mode

| Mode | Perilaku |
|------|----------|
| **Fokus** | Navigasi terkunci — tidak bisa berpindah tab selama sesi |
| **Fleksibel** | Bebas berpindah layar sambil timer berjalan |
| **Kustom** | Atur sendiri durasi, istirahat, jumlah siklus, dan auto-lanjut |

### Preset

| Preset | Fokus | Istirahat |
|--------|-------|-----------|
| Pomodoro | 25 menit | 5 menit |
| Belajar | 45 menit | 15 menit |
| Flow | 50 menit | 10 menit |
| Deep Work | 90 menit | 20 menit |

### Perilaku

- Timer berbasis **timestamp** (`endAt`), bukan hitungan tick — tetap akurat meski aplikasi masuk background
- **Pemulihan sesi** — bila aplikasi tertutup saat sesi berjalan, saat dibuka lagi muncul tawaran melanjutkan pada sisa waktu yang benar
- Layar tetap menyala selama sesi (`wakelock_plus`) dan getaran saat fase berganti
- Setiap sesi fokus yang selesai menambah `totalFocusMinutes` pada tugas
- **Streak fokus** bertambah untuk tiap hari yang punya minimal satu sesi
- Target sesi bisa ditandai *tercapai / sebagian / belum* di akhir sesi
- Status tugas **tidak** pernah diubah otomatis oleh timer — "Selesai" tetap manual

Preset didefinisikan pada `kFocusPresets` di `lib/models/focus_session_model.dart`.

---

## Tugas Berulang

Tugas rutin cukup dibuat sekali. Saat sebuah occurrence ditandai selesai, occurrence berikutnya lahir otomatis.

### Tipe Pengulangan

| Tipe | Keterangan |
|------|-----------|
| `none` | Tidak berulang (default) |
| `daily` | Setiap hari |
| `weekly` | Setiap minggu |
| `monthly` | Setiap bulan |
| `yearly` | Setiap tahun |
| `weekday` | Setiap hari kerja (Senin-Jumat) |
| `custom` | Tiap `N` hari/minggu/bulan/tahun |

### Batas Seri

Seri dapat dihentikan dengan salah satu dari:

- **Tanggal akhir** (`recurrenceEndDate`)
- **Jumlah occurrence** (`recurrenceCount`)
- Tanpa batas (default)

Setiap occurrence menyimpan `seriesId` (pengelompok) dan `recurrenceIndex` (urutan ke-berapa). Logika ada di `lib/utils/recurrence.dart`.

---

## Metode SAW

SAW (*Simple Additive Weighting*) adalah metode Multi-Criteria Decision Making untuk memberi peringkat tugas.

### Kriteria & Bobot

| Kriteria | Bobot | Tipe | Keterangan |
|----------|-------|------|-----------|
| **Tingkat Kepentingan** | 40% | Benefit | Seberapa penting (1-5, input manual) |
| **Tingkat Urgensi** | 40% | Benefit | Seberapa mendesak (1-5, otomatis dari deadline) |
| **Estimasi Waktu** | 20% | Benefit | Jam yang dibutuhkan (lebih lama = prioritas lebih tinggi) |

### Formula

**1. Normalisasi** (benefit criteria):

```
Rij = Xij / max(Xij)
```

**2. Nilai Preferensi**:

```
Vi = (0.40 x R_kepentingan) + (0.40 x R_urgensi) + (0.20 x R_estimasi)
```

**3. Ranking**: Vi tertinggi = peringkat 1.

### Contoh Perhitungan

Data tugas:

- Task A: Kepentingan=5, Urgensi=5, Estimasi=3 jam
- Task B: Kepentingan=3, Urgensi=2, Estimasi=1 jam
- Task C: Kepentingan=4, Urgensi=4, Estimasi=2 jam

Normalisasi (max: Kepentingan=5, Urgensi=5, Estimasi=3):

```
Task A: [5/5, 5/5, 3/3] = [1.00, 1.00, 1.00]
Task B: [3/5, 2/5, 1/3] = [0.60, 0.40, 0.33]
Task C: [4/5, 4/5, 2/3] = [0.80, 0.80, 0.67]
```

Nilai preferensi:

```
Task A: V = (0.40x1.00) + (0.40x1.00) + (0.20x1.00) = 1.00
Task B: V = (0.40x0.60) + (0.40x0.40) + (0.20x0.33) = 0.47
Task C: V = (0.40x0.80) + (0.40x0.80) + (0.20x0.67) = 0.77
```

Ranking: **A (1) > C (2) > B (3)**

### Urgensi Otomatis

Urgensi dihitung dari sisa waktu ke deadline — bukan input pengguna:

| Sisa Waktu | Urgensi | Label |
|------------|---------|-------|
| <= 3 jam | 5 | Sangat Mendesak |
| <= 24 jam | 4 | Mendesak |
| <= 3 hari | 3 | Cukup Mendesak |
| <= 7 hari | 2 | Kurang Mendesak |
| > 7 hari | 1 | Tidak Mendesak |

---

## Technology Stack

### Framework & Bahasa

- **Flutter** 3.0+ — framework lintas platform
- **Dart** 3.0+ — bahasa pemrograman

### State Management

- **provider** ^6.1.2 — pola `ChangeNotifier`

### Penyimpanan

- **shared_preferences** ^2.2.2 — key-value lokal
- Serialisasi JSON bawaan

### Notifikasi

- **flutter_local_notifications** ^17.1.2
- **timezone** ^0.9.4

### Sesi Fokus

- **wakelock_plus** ^1.2.5 — menjaga layar tetap menyala
- **vibration** ^2.0.0 — getaran saat fase berganti

### Cadangan Data

- **share_plus** ^10.0.0 — berbagi file cadangan
- **file_picker** ^8.1.2 — memilih file untuk diimpor

### UI & Utilitas

- **google_fonts** ^6.2.1
- **intl** ^0.19.0 — format tanggal
- **uuid** ^4.3.3
- **cupertino_icons** ^1.0.6

### Testing & Tooling

- **flutter_test** (SDK)
- **flutter_lints** ^3.0.0
- **flutter_launcher_icons** ^0.13.1 — ikon launcher

---

## Arsitektur Project

### Pola

```
UI Layer (screens/, widgets/)
    |
Provider (TaskProvider, FocusSessionProvider)
    |
Services (SAWService, NotificationService, FocusTimerService, ...)
    |
Repository (FocusSessionRepository)
    |
Models (Task, FocusSession, TimeBlock, ...)
    |
Storage (SharedPreferences)
```

Logika bisnis tidak ditempatkan di widget — widget hanya menampilkan state dan meneruskan aksi ke provider.

### Struktur Folder

```
lib/
├── main.dart                             # Entry point, MainNavigation (5 tab)
├── models/
│   ├── task_model.dart                   # Task, TaskStatus, RecurrenceType/Unit
│   ├── focus_session_model.dart          # FocusSession, FocusMode, preset, snapshot
│   ├── time_block_model.dart             # Blok waktu (internal scheduler)
│   ├── schedule_config_model.dart        # Konfigurasi penjadwalan
│   └── schedule_result_model.dart        # Hasil & konflik penjadwalan
├── services/
│   ├── task_provider.dart                # State utama tugas, lingkup, kategori
│   ├── saw_service.dart                  # Algoritma SAW
│   ├── notification_service.dart         # Penjadwalan notifikasi
│   ├── focus_session_provider.dart       # State sesi fokus & streak
│   ├── focus_session_repository.dart     # Persistensi sesi & riwayat
│   ├── focus_timer_service.dart          # Timer berbasis timestamp
│   ├── smart_scheduler_service.dart      # Penjadwalan blok waktu (internal)
│   └── ai_task_creator_service.dart      # Bantuan pembuatan tugas
├── screens/
│   ├── dashboard_screen.dart             # Tab 1 - ringkasan & prioritas teratas
│   ├── task_list_screen.dart             # Tab 2 - daftar tugas
│   ├── calendar_screen.dart              # Tab 3 - kalender bulanan
│   ├── priority_screen.dart              # Tab 4 - peringkat SAW & Eisenhower
│   ├── settings_screen.dart              # Tab 5 - Profil, data, ekspor/impor
│   ├── add_edit_task_screen.dart         # Form tambah/ubah tugas
│   ├── ai_task_creator_screen.dart       # Pembuat tugas terbantu
│   ├── notification_settings_screen.dart # Pengaturan notifikasi
│   └── focus/                            # Alur Sesi Fokus
│       ├── focus_mode_sheet.dart         # Pilih mode & preset
│       ├── focus_custom_sheet.dart       # Konfigurasi mode Kustom
│       ├── focus_intent_dialog.dart      # Tetapkan target sesi
│       ├── focus_preparation_screen.dart # Hitung mundur persiapan
│       ├── focus_timer_screen.dart       # Timer utama
│       ├── focus_break_screen.dart       # Layar istirahat
│       ├── focus_complete_screen.dart    # Ringkasan sesi selesai
│       ├── focus_history_screen.dart     # Riwayat sesi
│       ├── focus_screen.dart             # Kerangka layar fokus
│       └── widgets/focus_info_row.dart
├── widgets/
│   ├── task_card_widget.dart             # Kartu tugas
│   ├── rename_dialog.dart                # Dialog ganti nama
│   └── conflict_notification_banner.dart
└── utils/
    ├── app_theme.dart                    # Tema, warna, transisi halaman
    ├── app_assets.dart                   # Path aset
    ├── recurrence.dart                   # Mesin tugas berulang
    ├── focus_recommendation.dart         # Rekomendasi sesi dari skor SAW
    ├── celebration.dart                  # Overlay perayaan tugas selesai
    └── task_status_actions.dart          # Helper aksi ubah status

assets/
├── images/    logo.png, empty_tasks.png, empty_calendar.png, empty_priority.png
└── icons/     category_kuliah.png, category_praktikum.png,
              category_project.png, category_lainnya.png
```

> **Catatan:** `smart_scheduler_service.dart` beserta model `TimeBlock`/`ScheduleConfig` masih ada di kode dan diuji, tetapi layar Jadwal sudah dihapus dari navigasi demi menyederhanakan UX. Kode ini dipertahankan agar data lama tetap terbaca dan fitur dapat dihidupkan kembali bila diperlukan.

### Konvensi Penamaan

| Elemen | Gaya | Contoh |
|--------|------|--------|
| File | `snake_case` | `task_provider.dart` |
| Class | `PascalCase` | `TaskProvider` |
| Variabel | `camelCase` | `taskProvider` |
| Konstanta | `kPascalCase` | `kDefaultScopes` |
| Privat | `_leadingUnderscore` | `_init()` |

Teks antarmuka memakai **bahasa Indonesia**, sedangkan identifier kode memakai **bahasa Inggris**.

---

## Penyimpanan Data

Seluruh data disimpan lokal memakai `SharedPreferences`.

### Daftar Key

| Key | Tipe | Isi |
|-----|------|-----|
| `tugasku_tasks` | JSON String | Daftar seluruh tugas |
| `tugasku_tasks_backup` | JSON String | Salinan untuk pemulihan bila data utama rusak |
| `custom_scopes` | List\<String\> | Lingkup buatan pengguna |
| `categories_by_scope` | JSON String | Kategori per lingkup |
| `custom_categories` | List\<String\> | *(legacy)* kategori global, dimigrasi otomatis |
| `notif_enabled` | bool | Sakelar notifikasi global |
| `daily_reminder_enabled` | bool | Pengingat harian aktif |
| `daily_reminder_hour` | int | Jam pengingat harian (0-23) |
| `daily_reminder_minute` | int | Menit pengingat harian (0-59) |
| `last_backup_at` | String | Waktu terakhir ekspor data (ISO8601) |
| `focus_active_session` | JSON String | Snapshot sesi fokus berjalan (untuk pemulihan) |
| `focus_history` | JSON String | Riwayat sesi fokus |
| `focus_streak` | int | Streak fokus saat ini |
| `focus_streak_date` | String | Tanggal terakhir sesi fokus |
| `tugasku_schedule_blocks` | JSON String | Blok waktu (internal) |
| `tugasku_schedule_config` | JSON String | Konfigurasi penjadwalan (internal) |

### Model Task

| Field | Tipe | Keterangan | Wajib |
|-------|------|-----------|:-----:|
| `id` | String | UUID v4 | Ya |
| `namaTugas` | String | Nama tugas | Ya |
| `lingkupTugas` | String | Lingkup (mis. Perkuliahan) | Ya |
| `mataKuliah` | String? | Hanya untuk lingkup Perkuliahan | Tidak |
| `deadline` | DateTime | Batas waktu | Ya |
| `tingkatKepentingan` | int (1-5) | Input manual | Ya |
| `tingkatUrgensi` | int (1-5) | Otomatis dari deadline | Ya |
| `estimasiWaktu` | int | Perkiraan jam pengerjaan | Ya |
| `status` | TaskStatus | belumDikerjakan / sedangDikerjakan / selesai | Ya |
| `category` | String | Kategori (per lingkup) | Ya |
| `catatan` | String? | Catatan bebas | Tidak |
| `createdAt` | DateTime | Waktu dibuat | Ya |
| `completedAt` | DateTime? | Waktu ditandai selesai (untuk streak) | Tidak |
| `totalFocusMinutes` | int | Akumulasi menit sesi fokus | Ya |
| `notifEnabled` | bool | Notifikasi tugas ini aktif | Ya |
| `notifSchedule` | List\<String\> | `'h-3'`, `'h-1'`, `'3jam'`, `'deadline'` | Ya |
| `sawScore` | double | Hasil perhitungan SAW | Ya |
| `ranking` | int | Peringkat (1 = tertinggi) | Ya |
| `recurrence` | RecurrenceType | Tipe pengulangan | Ya |
| `recurrenceInterval` | int | "tiap N" untuk tipe custom | Ya |
| `recurrenceUnit` | RecurrenceUnit? | Unit untuk tipe custom | Tidak |
| `recurrenceEndDate` | DateTime? | Seri berakhir pada tanggal | Tidak |
| `recurrenceCount` | int? | Seri berakhir setelah N occurrence | Tidak |
| `recurrenceIndex` | int | Occurrence ke-berapa dalam seri | Ya |
| `seriesId` | String? | Pengelompok occurrence satu seri | Tidak |

### Nilai Default

- Lingkup: `['Perkuliahan', 'Tugas Rumah', 'Pekerjaan']`
- Kategori tiap lingkup: `['Tugas', 'Ujian', 'Proyek', 'Lainnya']`
- Jadwal notifikasi: `['h-1', '3jam', 'deadline']`

> **Migrasi:** data lama dengan key `custom_categories` (kategori global tunggal) dimigrasi sekali-jalan — daftar lama disalin ke setiap lingkup yang ada saat pertama kali dimuat.

### Format File Ekspor

```json
{
  "formatVersion": 1,
  "exportedAt": "ISO8601 DateTime",
  "tasks": [ /* array Task */ ],
  "customScopes": ["String"],
  "categoriesByScope": { "Scope": ["Kategori"] },
  "scheduleConfig": { /* ScheduleConfig */ },
  "notifSettings": {
    "notifEnabled": true,
    "dailyReminderEnabled": true,
    "dailyReminderHour": 8,
    "dailyReminderMinute": 0
  }
}
```

Nama file cadangan: `priora_backup_<timestamp>.json`

---

## API Reference

### TaskProvider

Operasi tulis mengembalikan `Future<bool>` (`true` = tersimpan) supaya UI dapat menampilkan pesan gagal, bukan diam-diam.

#### CRUD Tugas

```dart
Future<bool> tambahTugas({
  required String namaTugas,
  required String lingkupTugas,
  String? mataKuliah,
  required DateTime deadline,
  required int tingkatKepentingan,   // 1-5
  required int estimasiWaktu,        // jam
  String category = 'Tugas',
  String? catatan,
  bool notifEnabled = true,
  List<String>? notifSchedule,
  RecurrenceType recurrence = RecurrenceType.none,
  int recurrenceInterval = 1,
  RecurrenceUnit? recurrenceUnit,
  DateTime? recurrenceEndDate,
  int? recurrenceCount,
});

Future<bool> editTugas(String id, { /* field opsional */ });
Future<bool> hapusTugas(String id);
Future<bool> restoreTugas(Task task);   // untuk fitur "Urungkan"
Future<bool> clearAllTasks();
Future<void> updateStatus(String id, TaskStatus status);
Future<void> addFocusMinutes(String taskId, int minutes);
void refreshUrgensi();                  // hitung ulang urgensi & peringkat
Future<void> refresh();                 // muat ulang (pull to refresh)
```

#### Getter Kueri

```dart
List<Task> get tasks;
List<Task> get activeTasks;
List<Task> get completedTasks;
List<Task> get overdueTasks;
List<Task> get dueSoonTasks;         // dalam 3 hari
List<Task> get prioritizedTasks;     // urut peringkat SAW
List<Task> getTasksByScope(String scope);
List<String> get usedScopes;

int get totalTugas;
int get tugasAktif;
int get tugasSelesai;
double get persentaseSelesai;
```

#### Lingkup & Kategori

```dart
Future<void> addScope(String scope);
Future<bool> renameScope(String oldName, String newName);   // cascade ke tugas
List<String> get customScopes;

// Bila lingkup masih dipakai tugas dan reassignTasksTo == null,
// penghapusan dibatalkan (success: false) agar UI meminta konfirmasi dulu.
Future<({bool success, int affectedTasks})> removeScope(
  String scope, {
  String? reassignTasksTo,
});

List<String> categoriesForScope(String scope);
Future<void> addCategoryToScope(String scope, String category);
Future<void> removeCategoryFromScope(String scope, String category);
Future<bool> renameCategoryInScope(String scope, String oldCat, String newCat);
```

#### Notifikasi

```dart
Future<void> setNotifEnabled(bool value);
bool get notifEnabled;

Future<void> setDailyReminder({required bool enabled, int hour = 8, int minute = 0});
bool get dailyReminderEnabled;
int get dailyReminderHour;
int get dailyReminderMinute;

Future<List<dynamic>> getPendingNotifications();
Future<bool> requestNotificationPermission();
```

#### Ekspor & Impor

```dart
Map<String, dynamic> exportData();

// Parsing dilakukan ke variabel lokal dulu — bila ada yang tidak valid,
// seluruh proses dibatalkan dan data berjalan tidak tersentuh.
Future<({bool success, String? error})> importData(Map<String, dynamic> json);

Future<void> markBackupDone();       // catat waktu cadangan terakhir
DateTime? get lastBackupAt;
```

### SAWService

```dart
static List<Task> hitungPrioritas(List<Task> tasks);

static const double bobotKepentingan = 0.40;
static const double bobotUrgensi     = 0.40;
static const double bobotEstimasi    = 0.20;
```

### FocusSessionProvider

```dart
void attachTaskProvider(TaskProvider tp);

void startSession({
  required Task task,
  required FocusMode mode,
  required FocusPreset preset,
  String? targetText,
  required int recommendedSessions,
  required int totalSessions,
  required bool autoAdvance,
  required FocusOptions options,
});
void pauseResume();
void startBreak();
void skipBreak();
void startNextSession();
void syncFromBackground();

// Pemulihan sesi yang terputus
Future<void> checkForRestorableSession();
FocusSession? get restorableSession;
Future<void> resumeRestorableSession();
Future<void> discardRestorableSession();

Future<List<FocusHistoryEntry>> loadHistory();

bool get isRunning;
bool get isPaused;
bool get isBreak;
bool get isFinished;
bool get hasActiveSession;
bool get hasNextSession;
int  get currentSession;
int  get focusStreak;
```

### NotificationService

```dart
Future<void> initialize();
Future<void> scheduleTaskNotifications(Task task);
Future<void> cancelTaskNotifications(String taskId);
Future<void> cancelAllNotifications();

Future<void> scheduleDailyReminder({
  required int hour,
  required int minute,
  required int activeTasks,
});
Future<void> cancelDailyReminder();

Future<List<dynamic>> getPendingNotifications();
Future<bool> requestPermission();
```

### Recurrence

```dart
// Label pengulangan untuk ditampilkan di UI
String recurrenceLabel(RecurrenceType type, DateTime date, {...});

// Deadline occurrence berikutnya setelah task.deadline;
// null bila seri sudah berakhir
DateTime? nextOccurrenceDate(Task task);

// Pratinjau occurrence mendatang tanpa membuat tugas baru
// (dipakai Kalender & Dashboard)
List<DateTime> upcomingOccurrences(
  Task task, {
  required DateTime until,
  int maxCount = 60,
});

// Minggu ke-berapa dalam bulan (untuk aturan bulanan)
int mingguKeBerapa(DateTime date);
```

---

## Setup Project

### Prasyarat

- **Flutter SDK** >= 3.0.0
- **Dart SDK** >= 3.0.0
- **IDE**: Android Studio / VS Code dengan plugin Flutter
- **Android**: API Level 21+ (Android 5.0+)
- **iOS**: iOS 12.0+

### Langkah Instalasi

1. Klon repositori:

```bash
git clone https://github.com/Frhannnnn/Todo-list-aplication-beta-.git
```

2. Masuk ke direktori project:

```bash
cd Todo-list-aplication-beta-
```

3. Pasang dependensi:

```bash
flutter pub get
```

4. Periksa kesiapan environment:

```bash
flutter doctor
```

5. Lihat perangkat yang tersedia:

```bash
flutter devices
```

### Ikon Launcher

Ikon dihasilkan dari `assets/images/logo.png` melalui `flutter_launcher_icons`:

```bash
dart run flutter_launcher_icons
```

---

## Cara Menjalankan

### Mode Pengembangan

```bash
flutter run
```

Menjalankan pada perangkat tertentu:

```bash
flutter run -d <device-id>
```

Mode rilis:

```bash
flutter run --release
```

### Build APK

Debug:

```bash
flutter build apk --debug
```

Rilis:

```bash
flutter build apk --release
```

Terpisah per ABI (ukuran lebih kecil):

```bash
flutter build apk --split-per-abi
```

Hasil build ada di `build/app/outputs/flutter-apk/`.

### Build App Bundle

```bash
flutter build appbundle --release
```

### Analisis Statis

```bash
flutter analyze
```

---

## Testing

### Menjalankan Tes

Seluruh tes:

```bash
flutter test
```

Satu berkas tes:

```bash
flutter test test/services/task_provider_crud_test.dart
```

Dengan laporan cakupan:

```bash
flutter test --coverage
```

Menyaring berdasarkan nama grup:

```bash
flutter test --name "tambahTugas"
```

### Cakupan Tes

```
test/
├── services/
│   ├── task_provider_crud_test.dart               # CRUD tugas
│   ├── task_provider_scope_category_test.dart     # Lingkup & kategori
│   ├── task_provider_notification_test.dart       # Notifikasi
│   ├── task_provider_persistence_test.dart        # Persistensi data
│   ├── task_provider_edge_cases_test.dart         # Kasus tepi
│   ├── task_provider_schedule_test.dart           # Penjadwalan
│   ├── task_provider_scheduling_*_test.dart       # Integrasi & property
│   ├── smart_scheduler_*_test.dart                # Algoritma penjadwalan
│   ├── reschedule_all_test.dart
│   ├── resolve_conflicts_test.dart
│   └── ai_task_creator_service_test.dart
├── models/                                        # Model & property test
├── property/                                      # Property-based test UI
├── screens/                                       # Widget test
├── mocks/mock_notification_service.dart
└── widget_test.dart
```

> **Catatan:** sebagian tes lama masih mengacu pada layar Jadwal yang sudah dihapus dari navigasi, sehingga belum semuanya hijau. Pembersihan suite tes dikerjakan terpisah agar tidak bercampur dengan perubahan fitur.

---

## Desain UI

### Palet Warna

Didefinisikan pada `lib/utils/app_theme.dart`.

**Warna Utama**

| Nama | Hex | Penggunaan |
|------|-----|-----------|
| Primary | `#6C5CE7` | Warna merek, tombol utama, aksen aktif |
| Primary Light | `#9B8FEF` | Latar lembut, state terpilih |
| Primary Dark | `#4A3DB8` | Tekanan tombol, kontras |
| Secondary | `#7C3AED` | Gradien bersama primary |
| Accent | `#06B6D4` | Aksen sekunder |

**Warna Status**

| Nama | Hex |
|------|-----|
| Success | `#10B981` |
| Warning | `#F59E0B` |
| Danger | `#EF4444` |

**Warna Netral**

| Nama | Hex |
|------|-----|
| Background | `#F9FAFB` |
| Surface | `#FFFFFF` |
| Text Primary | `#1F2937` |
| Text Secondary | `#6B7280` |
| Border | `#E5E7EB` |

**Indikator Prioritas**

| Level | Hex |
|-------|-----|
| Rendah | `#10B981` |
| Sedang | `#F59E0B` |
| Tinggi | `#EF4444` |

### Prinsip Desain

- **Minimalis** — tanpa emotikon pada antarmuka; label dan ikon dibuat cukup jelas dengan sendirinya
- **Deskripsi seperlunya** — teks penjelas dihapus bila fungsi tombol sudah jelas
- **Konsisten** — kartu bersudut 20, border tipis, latar putih di atas background abu lembut
- **Empty state berilustrasi** dengan ajakan aksi yang jelas
- Transisi halaman *fade forwards* (Android) / *cupertino* (iOS)
- Tipografi memakai Google Fonts

---

## Privasi Data

- **Penyimpanan lokal saja** — seluruh data berada di perangkat
- **Tanpa sinkronisasi cloud** — tidak ada data yang dikirim ke server mana pun
- **Tanpa analitik** — tidak ada pelacakan
- **Offline penuh** — seluruh fitur berjalan tanpa internet
- **Cadangan manual** — ekspor/impor JSON sepenuhnya dikendalikan pengguna

---

## Lisensi

Project ini menggunakan Lisensi MIT — lihat berkas [LICENSE](LICENSE).

---

## Kontributor

- **Muhamad Farhan** — pengembang utama — [@Frhannnnn](https://github.com/Frhannnnn)

---

## Kontak

- **GitHub**: [Frhannnnn/Todo-list-aplication-beta-](https://github.com/Frhannnnn/Todo-list-aplication-beta-)
- **Laporan bug**: [Issues](https://github.com/Frhannnnn/Todo-list-aplication-beta-/issues)

---

Dibangun dengan Flutter.
