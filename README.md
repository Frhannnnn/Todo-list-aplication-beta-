# 📚 TugasKu - Aplikasi Manajemen Tugas Mahasiswa

Aplikasi Flutter untuk membantu mahasiswa mengelola tugas secara terstruktur menggunakan metode **SAW (Simple Additive Weighting)** untuk penentuan prioritas otomatis, dilengkapi dengan **Smart Scheduler** dan notifikasi.

[![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

---

## 📖 Daftar Isi

- [Tentang Aplikasi](#-tentang-aplikasi)
- [Fitur Utama](#-fitur-utama)
- [Technology Stack](#-technology-stack)
- [Arsitektur Project](#-arsitektur-project)
- [Database Schema](#-database-schema)
- [API Reference](#-api-reference)
- [Setup Project](#-setup-project)
- [Cara Menjalankan](#-cara-menjalankan)
- [Testing](#-testing)
- [Metode SAW](#-metode-saw)

---

## 🎯 Tentang Aplikasi

**TugasKu** adalah aplikasi manajemen tugas yang dirancang khusus untuk mahasiswa dengan fitur:
- **Smart Prioritization**: Menggunakan metode SAW untuk ranking otomatis
- **Intelligent Scheduling**: AI-powered task scheduling dengan conflict detection
- **Custom Notifications**: Notifikasi per-task yang dapat dikustomisasi
- **Eisenhower Matrix**: Visualisasi prioritas dengan matriks Eisenhower
- **Calendar Integration**: Integrasi kalender untuk deadline tracking

---

## ✨ Fitur Utama

### 1. 📊 Dashboard
- Statistik real-time (total, aktif, selesai, terlambat)
- Quick stats dengan persentase completion
- Tugas dengan deadline terdekat
- Tugas dengan prioritas tertinggi (SAW ranking)
- Indikator visual untuk overdue tasks

### 2. 📋 Manajemen Tugas (CRUD)
- **Create**: Tambah tugas dengan form lengkap
- **Read**: List view dengan search dan filter
- **Update**: Edit tugas dengan validation
- **Delete**: Hapus tugas dengan cascade cleanup
- **Status Management**: Update status (Belum/Sedang/Selesai)
- Custom scope & category management
- Notification scheduling per-task

### 3. 🧠 Prioritas (SAW Method)
- Automatic ranking dengan algoritma SAW
- 3 kriteria: Urgensi (40%), Kepentingan (40%), Estimasi Waktu (20%)
- Visualisasi skor SAW untuk setiap tugas
- Filter dan sort berdasarkan prioritas
- Badge prioritas (Tinggi/Sedang/Rendah)

### 4. 📅 Smart Scheduler
- Automatic time block generation
- Conflict detection & resolution
- Manual time block adjustment
- Schedule configuration (work hours, max hours/day)
- Backward scheduling dari deadline
- Visual schedule display

### 5. 📆 Calendar View
- Month/week/day view
- Task deadline visualization
- Overdue task highlighting
- Due soon indicators
- Empty state untuk tanggal tanpa task

### 6. 🔔 Notification System
- Per-task notification settings
- Custom notification schedule (H-3, H-1, 3jam sebelum, deadline)
- Daily reminder dengan custom time
- Global notification toggle
- Persistent notification preferences

### 7. ⚙️ Settings
- Scope management (Perkuliahan, Tugas Rumah, dll)
- Category management (Tugas, Ujian, Proyek, dll)
- Notification settings (enable/disable, daily reminder)
- Schedule settings (work hours, buffer time)
- Statistics dashboard
- Data management (clear all, backup info)

---

## 🛠️ Technology Stack

### Framework & Language
- **Flutter**: 3.0+ (Cross-platform mobile framework)
- **Dart**: 3.0+ (Programming language)

### State Management
- **Provider**: ^6.1.2 (State management pattern)

### Storage
- **SharedPreferences**: ^2.2.2 (Local key-value storage)
- **JSON Encoding**: Built-in serialization

### Notifications
- **flutter_local_notifications**: ^17.1.2 (Local push notifications)
- **timezone**: ^0.9.4 (Timezone handling for notifications)

### UI & Utilities
- **google_fonts**: ^6.2.1 (Custom fonts)
- **intl**: ^0.19.0 (Internationalization, date formatting)
- **uuid**: ^4.3.3 (Unique ID generation)
- **cupertino_icons**: ^1.0.6 (iOS-style icons)

### Testing
- **flutter_test**: SDK (Unit & widget testing)
- **flutter_lints**: ^3.0.0 (Linting rules)

---

## 📁 Arsitektur Project

### Struktur Folder

```
lib/
├── main.dart                           # Entry point & app initialization
├── models/                             # Data models
│   ├── task_model.dart                 # Task entity & enum
│   ├── time_block_model.dart           # Time block for scheduling
│   ├── schedule_config_model.dart      # Schedule configuration
│   └── schedule_result_model.dart      # Schedule result & conflicts
├── services/                           # Business logic layer
│   ├── task_provider.dart              # Main state management (Provider)
│   ├── saw_service.dart                # SAW algorithm implementation
│   ├── smart_scheduler_service.dart    # AI scheduling algorithm
│   ├── notification_service.dart       # Notification management
│   └── ai_task_creator_service.dart    # AI task creation helper
├── screens/                            # UI screens
│   ├── dashboard_screen.dart           # Main dashboard
│   ├── task_list_screen.dart           # Task list view
│   ├── add_edit_task_screen.dart       # Task form
│   ├── priority_screen.dart            # SAW ranking view
│   ├── calendar_screen.dart            # Calendar view
│   ├── schedule_screen.dart            # Schedule view
│   ├── schedule_settings_screen.dart   # Schedule config
│   ├── ai_task_creator_screen.dart     # AI task creator
│   ├── notification_settings_screen.dart # Notification settings
│   └── settings_screen.dart            # App settings
├── widgets/                            # Reusable widgets
│   ├── task_card_widget.dart           # Task card component
│   └── conflict_notification_banner.dart # Conflict alert banner
└── utils/                              # Utilities
    ├── app_theme.dart                  # Theme & colors
    └── app_assets.dart                 # Asset paths

test/                                   # Test files
├── services/                           # Service tests
│   ├── task_provider_crud_test.dart
│   ├── task_provider_scope_category_test.dart
│   ├── task_provider_notification_test.dart
│   ├── task_provider_schedule_test.dart
│   ├── task_provider_persistence_test.dart
│   └── task_provider_edge_cases_test.dart
├── mocks/                              # Mock objects
│   └── mock_notification_service.dart
└── UNIT_TEST_DOCUMENTATION.md          # Test documentation

assets/
├── images/                             # Image assets
│   ├── logo.png
│   ├── empty_tasks.png
│   ├── empty_calendar.png
│   └── empty_priority.png
└── icons/                              # Icon assets
    ├── category_kuliah.png
    ├── category_praktikum.png
    ├── category_project.png
    └── category_lainnya.png
```

### Naming Convention

**Files**: `snake_case` (e.g., `task_provider.dart`)
**Classes**: `PascalCase` (e.g., `TaskProvider`)
**Variables**: `camelCase` (e.g., `taskProvider`)
**Constants**: `kPascalCase` or `UPPER_SNAKE_CASE` (e.g., `kDefaultScopes`)
**Private**: `_leadingUnderscore` (e.g., `_init()`)

### Architecture Pattern

**Provider Pattern (State Management)**:
```
UI Layer (Screens) 
    ↓
Provider (TaskProvider) 
    ↓
Services (SAWService, NotificationService, etc)
    ↓
Models (Task, TimeBlock, etc)
    ↓
Storage (SharedPreferences)
```

---

## 🗄️ Database Schema

### Storage: SharedPreferences (Key-Value Store)

#### Task Data
**Key**: `tugasku_tasks`
**Type**: JSON String (List of Task objects)

```json
[
  {
    "id": "uuid-v4",
    "namaTugas": "String",
    "lingkupTugas": "String",
    "deadline": "ISO8601 DateTime",
    "tingkatKepentingan": "int (1-5)",
    "tingkatUrgensi": "int (1-5, auto-calculated)",
    "estimasiWaktu": "int (hours)",
    "status": "String (pending/inProgress/selesai)",
    "category": "String",
    "catatan": "String?",
    "createdAt": "ISO8601 DateTime",
    "notifEnabled": "bool",
    "notifSchedule": ["String array"],
    "sawScore": "double",
    "ranking": "int"
  }
]
```

**Backup Key**: `tugasku_tasks_backup` (Same structure for corruption recovery)

#### Task Model Fields

| Field | Type | Description | Required |
|-------|------|-------------|----------|
| `id` | String | UUID v4 unique identifier | ✅ |
| `namaTugas` | String | Task name/title | ✅ |
| `lingkupTugas` | String | Task scope (e.g., Perkuliahan) | ✅ |
| `deadline` | DateTime | Task deadline | ✅ |
| `tingkatKepentingan` | int (1-5) | Importance level (manual) | ✅ |
| `tingkatUrgensi` | int (1-5) | Urgency level (auto from deadline) | ✅ |
| `estimasiWaktu` | int | Estimated hours to complete | ✅ |
| `status` | TaskStatus | belumDikerjakan/sedangDikerjakan/selesai | ✅ |
| `category` | String | Custom category | ✅ |
| `catatan` | String? | Optional notes | ❌ |
| `createdAt` | DateTime | Creation timestamp | ✅ |
| `notifEnabled` | bool | Notification enabled | ✅ |
| `notifSchedule` | List<String> | Schedule: ['h-1', '3jam', 'deadline'] | ✅ |
| `sawScore` | double | SAW calculation result | ✅ |
| `ranking` | int | Task ranking (1 = highest priority) | ✅ |

#### Schedule Data

**Key**: `tugasku_schedule_blocks`
**Type**: JSON String (List of TimeBlock objects)

```json
[
  {
    "id": "uuid-v4",
    "taskId": "String (task reference)",
    "startTime": "ISO8601 DateTime",
    "endTime": "ISO8601 DateTime",
    "status": "String (pending/completed/missed/manuallyMoved)",
    "isManuallyPlaced": "bool"
  }
]
```

**Schedule Config Key**: `tugasku_schedule_config`

```json
{
  "maxHoursPerDay": "int",
  "workStartHour": "int (0-23)",
  "workEndHour": "int (0-23)",
  "bufferBetweenTasks": "int (minutes)"
}
```

#### Notification Settings

**Keys**:
- `notif_enabled`: bool - Global notification toggle
- `daily_reminder_enabled`: bool - Daily reminder enabled
- `daily_reminder_hour`: int - Daily reminder hour (0-23)
- `daily_reminder_minute`: int - Daily reminder minute (0-59)

#### Custom Data

**Keys**:
- `custom_scopes`: List<String> - User-defined scopes
- `custom_categories`: List<String> - User-defined categories

**Default Values**:
- Scopes: ['Perkuliahan', 'Tugas Rumah', 'Pekerjaan']
- Categories: ['Tugas', 'Ujian', 'Proyek', 'Lainnya']

---

## 🔌 API Reference

### TaskProvider API

#### Task CRUD Operations

**`tambahTugas()`** - Add New Task
```dart
Future<void> tambahTugas({
  required String namaTugas,
  required String lingkupTugas,
  required DateTime deadline,
  required int tingkatKepentingan,  // 1-5
  required int estimasiWaktu,       // hours
  String category = 'Tugas',
  String? catatan,
  bool notifEnabled = true,
  List<String>? notifSchedule,
});
```

**`editTugas()`** - Update Existing Task
```dart
Future<void> editTugas(
  String id, {
  String? namaTugas,
  String? lingkupTugas,
  DateTime? deadline,
  int? tingkatKepentingan,
  int? estimasiWaktu,
  TaskStatus? status,
  String? category,
  String? catatan,
  bool? notifEnabled,
  List<String>? notifSchedule,
});
```

**`hapusTugas()`** - Delete Task
```dart
Future<void> hapusTugas(String id);
```

**`updateStatus()`** - Update Task Status
```dart
Future<void> updateStatus(String id, TaskStatus status);
```

**`clearAllTasks()`** - Clear All Tasks
```dart
Future<void> clearAllTasks();
```

#### Query Methods (Getters)

```dart
// Get all tasks
List<Task> get tasks

// Get active tasks (not completed)
List<Task> get activeTasks

// Get completed tasks
List<Task> get completedTasks

// Get overdue tasks
List<Task> get overdueTasks

// Get tasks due soon (within 3 days)
List<Task> get dueSoonTasks

// Get tasks sorted by SAW ranking
List<Task> get prioritizedTasks

// Get tasks by scope
List<Task> getTasksByScope(String scope)

// Get unique scopes used in tasks
List<String> get usedScopes

// Statistics
int get totalTugas
int get tugasSelesai
int get tugasAktif
double get persentaseSelesai
```

#### Scope & Category Management

```dart
// Scope operations
Future<void> addScope(String scope)
Future<void> removeScope(String scope)
List<String> get customScopes

// Category operations
Future<void> addCategory(String category)
Future<void> removeCategory(String category)
List<String> get customCategories
```

#### Notification Management

```dart
// Global notification toggle
Future<void> setNotifEnabled(bool value)
bool get notifEnabled

// Daily reminder
Future<void> setDailyReminder({
  required bool enabled,
  int hour = 8,
  int minute = 0,
})
bool get dailyReminderEnabled
int get dailyReminderHour
int get dailyReminderMinute

// Get pending notifications
Future<List<dynamic>> getPendingNotifications()

// Request permission
Future<bool> requestNotificationPermission()
```

#### Schedule Management

```dart
// Time block operations
Future<({bool success, String? error})> moveTimeBlock(
  String blockId,
  DateTime newSlot,
)
Future<void> deleteTimeBlock(String blockId)

// Schedule config
Future<void> updateScheduleConfig(ScheduleConfig config)
ScheduleConfig get scheduleConfig

// Query time blocks
List<TimeBlock> get timeBlocks
List<TimeBlock> getTimeBlocksForDate(DateTime date)
List<TimeBlock> getTimeBlocksForTask(String taskId)

// Conflict management
List<ScheduleConflict> get latestConflicts
DateTime? get conflictsDetectedAt
bool get hasConflicts
void dismissConflicts()
```

### SAWService API

**Static Methods**:

```dart
// Calculate priority for all tasks
static List<Task> hitungPrioritas(List<Task> tasks)

// Weights (constants)
static const double bobotKepentingan = 0.40;  // 40%
static const double bobotUrgensi = 0.40;      // 40%
static const double bobotEstimasi = 0.20;     // 20%
```

### NotificationService API

```dart
// Initialize notification service
Future<void> initialize()

// Schedule task notifications
Future<void> scheduleTaskNotifications(Task task)

// Cancel task notifications
Future<void> cancelTaskNotifications(String taskId)

// Cancel all notifications
Future<void> cancelAllNotifications()

// Daily reminder
Future<void> scheduleDailyReminder({
  required int hour,
  required int minute,
  required int activeTasks,
})
Future<void> cancelDailyReminder()

// Pending notifications
Future<List<dynamic>> getPendingNotifications()

// Permission
Future<bool> requestPermission()
```

### SmartSchedulerService API

```dart
// Reschedule all tasks
ScheduleResult rescheduleAll({
  required List<Task> tasks,
  required List<TimeBlock> manualBlocks,
  required ScheduleConfig config,
  required DateTime now,
})

// Resolve conflicts
List<TimeBlock> resolveConflicts({
  required List<Task> tasks,
  required List<TimeBlock> blocks,
  required ScheduleConfig config,
})
```

---

## 🚀 Setup Project

### Prerequisites

- **Flutter SDK**: >= 3.0.0
- **Dart SDK**: >= 3.0.0
- **IDE**: Android Studio / VS Code with Flutter plugin
- **Device**: Android Emulator / iOS Simulator / Physical device
- **Android SDK**: API Level 21+ (Android 5.0+)
- **iOS**: iOS 12.0+

### Installation Steps

1. **Clone Repository**
```bash
git clone https://github.com/Frhannnnn/Todo-list-aplication-beta-.git
cd Todo-list-aplication-beta-
```

2. **Install Dependencies**
```bash
flutter pub get
```

3. **Verify Installation**
```bash
flutter doctor
```

4. **Check Devices**
```bash
flutter devices
```

### Configuration (Optional)

**Android Notification Icon**:
- Place icon in `android/app/src/main/res/drawable/`
- Update `android/app/src/main/AndroidManifest.xml` if needed

**iOS Permissions**:
- Update `ios/Runner/Info.plist` for notification permissions

---

## 🏃 Cara Menjalankan

### Development Mode

**Run on Connected Device**:
```bash
flutter run
```

**Run on Specific Device**:
```bash
flutter run -d <device-id>
```

**Run with Hot Reload Enabled**:
```bash
flutter run --debug
```

**Run in Release Mode**:
```bash
flutter run --release
```

### Build APK (Android)

**Debug APK**:
```bash
flutter build apk --debug
```

**Release APK**:
```bash
flutter build apk --release
```

**Split APK per ABI** (smaller size):
```bash
flutter build apk --split-per-abi
```

Output: `build/app/outputs/flutter-apk/`

### Build App Bundle (Android)

```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/`

### Build iOS

```bash
flutter build ios --release
```

---

## 🧪 Testing

### Run All Tests

```bash
flutter test
```

### Run Specific Test File

```bash
flutter test test/services/task_provider_crud_test.dart
```

### Run with Coverage

```bash
flutter test --coverage
```

### View Coverage Report

```bash
# Install lcov (Linux/Mac)
sudo apt-get install lcov  # Linux
brew install lcov           # Mac

# Generate HTML report
genhtml coverage/lcov.info -o coverage/html

# Open report
open coverage/html/index.html  # Mac
xdg-open coverage/html/index.html  # Linux
```

### Test Structure

**Test Files** (131 test scenarios):
- `task_provider_crud_test.dart` - CRUD operations (28 scenarios)
- `task_provider_scope_category_test.dart` - Scope & category (18 scenarios)
- `task_provider_notification_test.dart` - Notifications (16 scenarios)
- `task_provider_schedule_test.dart` - Scheduling (18 scenarios)
- `task_provider_persistence_test.dart` - Data persistence (15 scenarios)
- `task_provider_edge_cases_test.dart` - Edge cases (28 scenarios)
- `mock_notification_service.dart` - Mock objects

**Documentation**: `test/UNIT_TEST_DOCUMENTATION.md`

### Verbose Test Output

```bash
flutter test -v
```

### Run Specific Test Group

```bash
flutter test --name "tambahTugas"
```

---

## 🧮 Metode SAW (Simple Additive Weighting)

### Konsep

SAW adalah metode Multi-Criteria Decision Making (MCDM) yang digunakan untuk menentukan ranking prioritas tugas berdasarkan beberapa kriteria.

### Kriteria & Bobot

| Kriteria | Bobot | Tipe | Keterangan |
|----------|-------|------|-----------|
| **Tingkat Kepentingan** | 40% | Benefit | Seberapa penting tugas (1-5, input manual) |
| **Tingkat Urgensi** | 40% | Benefit | Seberapa mendesak (1-5, auto dari deadline) |
| **Estimasi Waktu** | 20% | Benefit | Jam yang dibutuhkan (lebih lama = prioritas tinggi) |

### Formula

**1. Matriks Keputusan**:
```
     Kepentingan  Urgensi  Estimasi
T1   [    4         5         3    ]
T2   [    3         2         2    ]
T3   [    5         4         5    ]
```

**2. Normalisasi** (untuk benefit criteria):
```
Rij = Xij / max(Xij)
```

**3. Nilai Preferensi**:
```
Vi = Σ (Wj × Rij)
Vi = (W1 × R1) + (W2 × R2) + (W3 × R3)
Vi = (0.40 × R_kepentingan) + (0.40 × R_urgensi) + (0.20 × R_estimasi)
```

**4. Ranking**:
- Task dengan Vi tertinggi = Ranking 1 (prioritas tertinggi)
- Task dengan Vi terendah = Ranking terakhir

### Contoh Perhitungan

**Data Tugas**:
- Task A: Kepentingan=5, Urgensi=5, Estimasi=3 jam
- Task B: Kepentingan=3, Urgensi=2, Estimasi=1 jam
- Task C: Kepentingan=4, Urgensi=4, Estimasi=2 jam

**Normalisasi**:
```
Max values: Kepentingan=5, Urgensi=5, Estimasi=3

Task A: R = [5/5, 5/5, 3/3] = [1.00, 1.00, 1.00]
Task B: R = [3/5, 2/5, 1/3] = [0.60, 0.40, 0.33]
Task C: R = [4/5, 4/5, 2/3] = [0.80, 0.80, 0.67]
```

**Nilai Preferensi**:
```
Task A: V = (0.40×1.00) + (0.40×1.00) + (0.20×1.00) = 1.00
Task B: V = (0.40×0.60) + (0.40×0.40) + (0.20×0.33) = 0.47
Task C: V = (0.40×0.80) + (0.40×0.80) + (0.20×0.67) = 0.77
```

**Ranking**: A (1st) > C (2nd) > B (3rd)

### Urgency Auto-Calculation

Tingkat urgensi dihitung otomatis dari sisa waktu ke deadline:

| Sisa Waktu | Urgensi | Level |
|------------|---------|-------|
| ≤ 3 jam | 5 | 🔴 Sangat Mendesak |
| ≤ 24 jam | 4 | 🟠 Mendesak |
| ≤ 3 hari | 3 | 🟡 Cukup Mendesak |
| ≤ 7 hari | 2 | 🟢 Kurang Mendesak |
| > 7 hari | 1 | ⚪ Tidak Mendesak |

---

## 📊 Smart Scheduler

### Fitur

1. **Automatic Scheduling**: Generate time blocks based on task priority
2. **Backward Scheduling**: Schedule from deadline backward
3. **Conflict Detection**: Detect overlapping schedules
4. **Manual Override**: User can manually move time blocks
5. **Configuration**: Customize work hours, max hours/day, buffer time

### Algorithm

1. Sort tasks by SAW ranking (highest priority first)
2. For each task, calculate required time blocks
3. Find available slots within work hours
4. Schedule backward from deadline
5. Add buffer time between tasks
6. Detect and report conflicts
7. Allow manual adjustment with validation

---

## 🎨 UI Design

### Color Scheme

**Primary Colors**:
- Primary: `#2563EB` (Blue)
- Secondary: `#7C3AED` (Purple)
- Accent: `#10B981` (Green)

**Status Colors**:
- Success: `#10B981` (Green)
- Warning: `#F59E0B` (Orange)
- Error: `#EF4444` (Red)
- Info: `#3B82F6` (Blue)

**Priority Indicators**:
- High: 🔴 Red (`#EF4444`)
- Medium: 🟡 Yellow (`#F59E0B`)
- Low: 🟢 Green (`#10B981`)

### Typography

- **Font Family**: Google Fonts (Poppins, Inter)
- **Heading**: Poppins Bold
- **Body**: Inter Regular
- **Caption**: Inter Light

---

## 🔐 Data Privacy

- **Local Storage Only**: All data stored locally on device
- **No Cloud Sync**: No data sent to external servers
- **No Analytics**: No tracking or analytics
- **Offline First**: Fully functional without internet

---

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 👥 Contributors

- **Farhan** - Initial work - [@Frhannnnn](https://github.com/Frhannnnn)

---

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Provider package for state management
- Community for inspiration and support

---

## 📞 Contact & Support

- **GitHub**: [Frhannnnn/Todo-list-aplication-beta-](https://github.com/Frhannnnn/Todo-list-aplication-beta-)
- **Issues**: [Report Bug](https://github.com/Frhannnnn/Todo-list-aplication-beta-/issues)

---

**Made with ❤️ using Flutter**
