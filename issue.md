# Issue: Comprehensive Unit Test Planning

## Deskripsi
Perbarui dan tingkatkan coverage semua unit test untuk semua API yang tersedia di aplikasi. Setiap skenario test harus menghapus data terlebih dahulu agar konsisten. Planning ini untuk junior programmer atau model AI yang lebih murah agar implementasi detail test dapat disesuaikan dengan kemampuan mereka.

## Objective
Membuat skenario test yang lengkap untuk semua API di project ini tanpa terlalu detail dalam implementasinya. Fokus adalah pada skenario apa yang harus di-test, bukan bagaimana cara mengimplementasinya.

---

## 1. Task Provider API - CRUD Operations

### 1.1 Test `tambahTugas()` - Add Task
**Clear data first:** Hapus semua tasks sebelum test dimulai

#### Skenario yang harus di-test:
- [ ] **Skenario Valid**: Tambah task dengan semua parameter wajib dan opsional yang lengkap
  - Verifikasi task berhasil ditambah ke list
  - Verifikasi ID unik ter-generate
  - Verifikasi timestamp `createdAt` ter-set dengan benar
  - Verifikasi default values (category, catatan, notification settings)

- [ ] **Skenario Validation**: Tambah task dengan parameter kosong/invalid
  - Nama task kosong atau whitespace
  - Estimasi waktu 0 atau negative
  - Deadline di masa lalu
  - Tingkat kepentingan di luar range (< 1 atau > 5)

- [ ] **Skenario Multiple Add**: Tambah multiple tasks berurutan
  - Verifikasi semua tasks ter-save
  - Verifikasi order/urutan tasks
  - Verifikasi tidak ada duplicate ID

- [ ] **Skenario Notification**: Tambah task dengan notification settings
  - Verifikasi `notifEnabled` default true
  - Verifikasi `notifSchedule` tersimpan
  - Verifikasi notification service di-call

- [ ] **Skenario Categories**: Tambah task dengan berbagai kategori
  - Custom category yang ada di list
  - Category tidak ada di list (handling)
  - Category kosong/null

### 1.2 Test `editTugas()` - Update Task
**Clear data first:** Hapus semua tasks, tambah task dummy untuk di-edit

#### Skenario yang harus di-test:
- [ ] **Skenario Update Lengkap**: Update semua field sekaligus
  - Verifikasi setiap field ter-update
  - Verifikasi ID tidak berubah
  - Verifikasi updated timestamp/history

- [ ] **Skenario Update Partial**: Update hanya beberapa field
  - Update nama saja
  - Update deadline saja
  - Update priority saja
  - Verifikasi field lain tetap original

- [ ] **Skenario Status Update**: Update task status
  - Dari pending → in_progress
  - Dari in_progress → selesai
  - Verifikasi time blocks dihapus saat status selesai
  - Verifikasi scheduler re-run setelah status change

- [ ] **Skenario Invalid Edit**: Update dengan data invalid
  - Update ID yang tidak ada
  - Update deadline di masa lalu
  - Update dengan parameter invalid
  - Verifikasi task tidak berubah / error handling

- [ ] **Skenario Category Change**: Update kategori task
  - Change ke kategori yang ada
  - Change ke kategori baru
  - Change ke kategori kosong

### 1.3 Test `hapusTugas()` - Delete Task
**Clear data first:** Hapus semua tasks, tambah beberapa task dummy

#### Skenario yang harus di-test:
- [ ] **Skenario Delete Exist**: Hapus task yang ada
  - Verifikasi task dihapus dari list
  - Verifikasi notification di-cancel
  - Verifikasi time blocks terkait ter-delete
  - Verifikasi SAW ranking di-recalculate

- [ ] **Skenario Delete Not Exist**: Hapus task yang tidak ada
  - ID invalid/tidak ditemukan
  - Verifikasi error handling
  - Verifikasi list tetap sama

- [ ] **Skenario Delete Multiple**: Hapus multiple tasks
  - Hapus task 1, verifikasi
  - Hapus task 2, verifikasi
  - Hapus semua tasks
  - Verifikasi list kosong

- [ ] **Skenario Delete Cascade**: Hapus task yang memiliki relasi
  - Task dengan active notifications
  - Task dengan scheduled time blocks
  - Verifikasi semua relasi ter-cleanup

- [ ] **Skenario Delete Completion Impact**: Hapus task mempengaruhi metrics
  - Verifikasi persentaseSelesai ter-recalculate
  - Verifikasi tugasAktif count ter-update

### 1.4 Test `updateStatus()` - Update Task Status
**Clear data first:** Hapus semua tasks, tambah task dengan status pending

#### Skenario yang harus di-test:
- [ ] **Skenario Valid Status Transition**: Update status valid
  - pending → in_progress
  - in_progress → selesai
  - Verifikasi status ter-update
  - Verifikasi related operations ter-trigger

- [ ] **Skenario Selesai Status**: Mark task sebagai selesai
  - Verifikasi time blocks dihapus
  - Verifikasi dari activeTasks di-remove
  - Verifikasi di-move ke completedTasks
  - Verifikasi notifikasi di-cancel

- [ ] **Skenario Invalid Task**: Update status task tidak ada
  - ID tidak ditemukan
  - Verifikasi error handling
  - Verifikasi tidak ada side effects

---

## 2. Task Provider API - Query/Getter Methods

### 2.1 Test Getters & Computed Properties
**Clear data first:** Hapus semua tasks, setup berbagai task dengan berbagai status

#### Skenario yang harus di-test:
- [ ] **Skenario `activeTasks`**: Get tasks yang belum selesai
  - Task dengan status pending/in_progress ter-include
  - Task dengan status selesai ter-exclude
  - Order/urutan correct

- [ ] **Skenario `completedTasks`**: Get tasks yang selesai
  - Task dengan status selesai ter-include
  - Task dengan status lain ter-exclude

- [ ] **Skenario `overdueTasks`**: Get tasks yang overdue
  - Deadline sudah lewat ter-include
  - Task masih active (tidak selesai) ter-check
  - Deadline belum lewat ter-exclude

- [ ] **Skenario `dueSoonTasks`**: Get tasks due dalam X hari
  - Setup tasks dengan deadline beragam
  - Verifikasi yang ter-include (due soon tapi tidak overdue)
  - Verifikasi yang ter-exclude (sudah selesai, overdue)

- [ ] **Skenario `prioritizedTasks`**: Get tasks diurutkan by SAW ranking
  - Verifikasi urutan berdasarkan ranking
  - Verifikasi hanya active tasks
  - Verifikasi di-sort ascending/descending

- [ ] **Skenario `getTasksByScope()`**: Get tasks by lingkupTugas
  - Setup tasks dengan berbagai scope
  - Query scope yang ada
  - Query scope yang tidak ada (empty list)
  - Verifikasi result akurat

- [ ] **Skenario Metrics**: Get calculated metrics
  - `totalTugas` count correct
  - `tugasSelesai` count correct
  - `tugasAktif` count correct
  - `persentaseSelesai` calculation correct (0%, 50%, 100%)

---

## 3. Scope & Category Management

### 3.1 Test `addScope()` & `removeScope()`
**Clear data first:** Hapus custom scopes, reset ke default

#### Skenario yang harus di-test:
- [ ] **Skenario Add Valid Scope**: Tambah scope baru
  - Scope ter-add ke list
  - Trim whitespace
  - Reject duplicate scope
  - Verifikasi persistent di SharedPreferences

- [ ] **Skenario Add Invalid Scope**: Tambah scope invalid
  - Empty string / whitespace only
  - Already exists
  - Null handling

- [ ] **Skenario Remove Scope**: Hapus scope
  - Scope exist ter-remove
  - Scope tidak exist (no error)
  - Verifikasi persistent di SharedPreferences
  - Verifikasi tasks menggunakan scope tersebut handling

- [ ] **Skenario Multiple Scopes**: Manage multiple scopes
  - Add multiple scopes
  - Remove some
  - Verify list integrity

### 3.2 Test `addCategory()` & `removeCategory()`
**Clear data first:** Hapus custom categories, reset ke default

#### Skenario yang harus di-test:
- [ ] **Skenario Add Valid Category**: Tambah category baru
  - Category ter-add
  - Trim whitespace
  - Reject duplicate
  - Verifikasi persistent

- [ ] **Skenario Add Invalid Category**: Category invalid
  - Empty string
  - Already exists
  - Null handling

- [ ] **Skenario Remove Category**: Hapus category
  - Exist ter-remove
  - Not exist (safe)
  - Verify tasks dengan category tersebut handling

---

## 4. Notification Settings Management

### 4.1 Test `setNotifEnabled()` & `setDailyReminder()`
**Clear data first:** Reset notification settings ke default

#### Skenario yang harus di-test:
- [ ] **Skenario Enable/Disable Notification**: Toggle global notification
  - Enable notification
  - Disable notification
  - Verifikasi NotificationService di-call
  - Verifikasi persistent di SharedPreferences
  - Verifikasi all pending notifications di-cancel saat disable

- [ ] **Skenario Daily Reminder Setup**: Set daily reminder
  - Set reminder dengan custom hour/minute
  - Enable/disable reminder
  - Verifikasi schedule di-update di NotificationService
  - Verify persistent di SharedPreferences

- [ ] **Skenario Invalid Time**: Set invalid time values
  - Hour > 23 atau < 0
  - Minute > 59 atau < 0
  - Handling/validation

- [ ] **Skenario Notification Reschedule**: Ubah settings memicu reschedule
  - Enable notification harus re-schedule semua task notifications
  - Change reminder time harus update
  - Verify NotificationService interaction

### 4.2 Test `getPendingNotifications()`
**Setup:** Setup tasks dengan notifications

#### Skenario yang harus di-test:
- [ ] **Skenario Get Pending**: Retrieve pending notifications
  - Verifikasi return list dari NotificationService
  - Verifikasi include active task notifications
  - Verifikasi include daily reminder jika enabled

---

## 5. Schedule/Time Block Management

### 5.1 Test `moveTimeBlock()`
**Clear data first:** Hapus semua tasks dan time blocks, setup task dengan time blocks

#### Skenario yang harus di-test:
- [ ] **Skenario Valid Move**: Pindah time block ke slot valid
  - Move ke slot yang available
  - Verify new slot ter-set
  - Verify `isManuallyPlaced` = true
  - Verify status = TimeBlockStatus.manuallyMoved
  - Verify persistent di SharedPreferences

- [ ] **Skenario Invalid Move**: Pindah ke slot invalid
  - Move ke slot yang sudah ada task lain
  - Move ke slot di masa lalu
  - Move beyond task deadline
  - Verify error message
  - Verify original slot tidak berubah

- [ ] **Skenario Non-Exist Block**: Move block tidak ada
  - ID tidak ditemukan
  - Verify error handling
  - Verify no side effects

- [ ] **Skenario Conflict Check**: Move yang menyebabkan conflict
  - Verify conflict detection
  - Verify prevent move atau show warning

### 5.2 Test `deleteTimeBlock()`
**Setup:** Setup tasks dengan time blocks

#### Skenario yang harus di-test:
- [ ] **Skenario Delete Exist Block**: Hapus time block exist
  - Block ter-delete dari list
  - Verify persistent di SharedPreferences

- [ ] **Skenario Delete Non-Exist Block**: Hapus block tidak ada
  - ID tidak ditemukan
  - Safe operation (no error)

### 5.3 Test `updateScheduleConfig()`
**Setup:** Reset schedule config

#### Skenario yang harus di-test:
- [ ] **Skenario Update Config**: Update schedule configuration
  - Config ter-update
  - Verify scheduler re-run
  - Verify new time blocks generated
  - Verify persistent

- [ ] **Skenario Config Impact**: Config change mempengaruhi scheduling
  - Change max hours per day → re-schedule
  - Change working hours → re-schedule
  - Verify conflicts di-recalculate

---

## 6. Schedule Calculation & Conflict Detection

### 6.1 Test Smart Scheduler Integration
**Setup:** Setup multiple tasks dengan time constraints

#### Skenario yang harus di-test:
- [ ] **Skenario Schedule Generation**: Scheduler generate time blocks
  - Setup tasks
  - Trigger scheduler
  - Verify time blocks generated
  - Verify setiap active task punya time block
  - Verify time blocks fit dalam schedule config constraints

- [ ] **Skenario Conflict Detection**: Detect scheduling conflicts
  - Setup conflicting task requirements
  - Verify conflicts di-detect
  - Verify `latestConflicts` ter-populate
  - Verify `conflictsDetectedAt` set correctly

- [ ] **Skenario Conflict Resolution**: Handle conflicts
  - Setup yang trigger conflicts
  - Verify notification banners shown
  - Verify `dismissConflicts()` clear conflicts
  - Verify manual move override automatic schedule

- [ ] **Skenario Missed Blocks**: Mark missed time blocks
  - Setup time blocks dengan waktu past
  - Load schedule
  - Verify blocks marked as missed
  - Verify selesai tasks tidak di-mark missed

### 6.2 Test SAW Scoring Recalculation
**Setup:** Setup multiple tasks

#### Skenario yang harus di-test:
- [ ] **Skenario SAW Recalculate**: Hitung ulang SAW scores
  - Setup tasks dengan berbagai priority levels
  - Trigger recalculation
  - Verify ranking ter-update
  - Verify prioritizedTasks order correct

- [ ] **Skenario SAW Weights**: Verify SAW weight calculation
  - Kepentingan 40%, Urgensi 40%, Estimasi 20%
  - Verify formula diterapkan correct
  - Verify normalization works

---

## 7. Data Persistence & Storage

### 7.1 Test `_saveTasks()` & `_loadTasks()`
**Setup:** Fresh app state

#### Skenario yang harus di-test:
- [ ] **Skenario Save & Load**: Data persistence
  - Add tasks
  - Save ke SharedPreferences
  - Create new provider instance
  - Load tasks
  - Verify data consistent

- [ ] **Skenario Backup Mechanism**: JSON corruption handling
  - Setup tasks
  - Simulate corrupted JSON
  - Load (attempt)
  - Verify fallback to backup
  - Verify fallback to empty jika keduanya corrupt

- [ ] **Skenario Large Dataset**: Save/load many tasks
  - Add 100+ tasks
  - Save
  - Load
  - Verify performance acceptable
  - Verify data integrity

### 7.2 Test `_saveSchedule()` & `_loadSchedule()`
**Setup:** Fresh schedule state

#### Skenario yang harus di-test:
- [ ] **Skenario Schedule Persistence**: Schedule data saved/loaded
  - Setup time blocks
  - Setup schedule config
  - Save
  - New provider instance
  - Load
  - Verify data consistent

- [ ] **Skenario Corrupt Schedule**: Handle corrupt schedule data
  - Simulate corrupted JSON
  - Load (attempt)
  - Verify fallback to default
  - Verify no crash

---

## 8. Notification Service Integration

### 8.1 Test Notification Scheduling
**Setup:** Setup tasks

#### Skenario yang harus di-test:
- [ ] **Skenario Schedule Task Notification**: Schedule notification untuk task
  - Add task dengan notification enabled
  - Verify NotificationService.scheduleTaskNotifications() di-call
  - Verify notification ID linked to task ID

- [ ] **Skenario Cancel Task Notification**: Cancel notification
  - Delete task
  - Verify NotificationService.cancelTaskNotifications() di-call
  - Verify notification ID ter-cancel

- [ ] **Skenario Cancel All Notification**: Cancel semua
  - Clear all tasks
  - Verify NotificationService.cancelAllNotifications() di-call

- [ ] **Skenario Daily Reminder Scheduling**: Schedule daily reminder
  - Enable daily reminder
  - Verify NotificationService.scheduleDailyReminder() di-call dengan correct params
  - Verify hour/minute correct

---

## 9. Initialization & Lifecycle

### 9.1 Test `_init()` Method
**Setup:** Fresh app

#### Skenario yang harus di-test:
- [ ] **Skenario First Launch**: App first time initialization
  - Provider created
  - Verify NotificationService initialized
  - Verify default notification settings loaded
  - Verify tasks loaded (empty jika first time)
  - Verify schedule loaded (default)

- [ ] **Skenario Subsequent Launch**: App second+ time
  - Setup data first time
  - Create new provider
  - Verify previous data loaded
  - Verify settings preserved

- [ ] **Skenario Init Sequence**: Proper initialization order
  - NotificationService init → Custom data load → Tasks load → Schedule load
  - Verify dependency order correct
  - Verify no race conditions

---

## 10. Edge Cases & Error Handling

### 10.1 General Edge Cases
**Setup:** Various edge case scenarios

#### Skenario yang harus di-test:
- [ ] **Skenario Empty State**: Operasi dengan list kosong
  - Query methods dengan empty tasks
  - Delete dari empty
  - Update metrics dengan empty
  - All should handle gracefully

- [ ] **Skenario Concurrent Operations**: Multiple rapid operations
  - Rapid add/delete sequence
  - Concurrent updates
  - Verify data consistency

- [ ] **Skenario Boundary Values**: Min/max values
  - Priority level boundaries (1-5)
  - Duration boundaries (0 jam, 24+ jam)
  - Date boundaries (past, far future)

- [ ] **Skenario Null/Invalid Input**: Null atau invalid parameters
  - Null task ID
  - Empty strings
  - Invalid dates
  - Verify validation/error handling

### 10.2 State Consistency
**Setup:** Complex state scenarios

#### Skenario yang harus di-test:
- [ ] **Skenario State Sync**: Internal state consistency
  - Tasks vs time blocks sync
  - Tasks vs notifications sync
  - Config vs scheduler state sync
  - Verify no orphaned data

- [ ] **Skenario State Recovery**: Recover dari unexpected state
  - Partial load failure
  - Inconsistent persisted data
  - Verify recovery mechanism works

---

## Implementation Notes untuk Junior / Cheaper AI

1. **Setup Pattern**: Setiap test suite harus:
   - Clear semua data first (hapus tasks, blocks, settings)
   - Setup minimal test data yang dibutuhkan
   - Run test
   - Cleanup after (optional tapi recommended)

2. **Verification Pattern**: Setiap test harus verify:
   - Primary action hasil (data ter-add/update/delete)
   - Side effects ter-trigger (notifications, scheduler, persistence)
   - Data integrity maintained
   - Error handling proper

3. **Mocking Strategy**:
   - Mock SharedPreferences untuk data persistence tests
   - Mock NotificationService untuk notification tests
   - Mock SmartSchedulerService untuk scheduler tests
   - Consider real SharedPreferences vs mock tradeoff

4. **Test Organization**:
   - Group by service/feature
   - Group by CRUD operation
   - Group by data flow scenario
   - Keep tests focused dan readable

5. **Common Test Patterns**:
   - Arrange → Act → Assert pattern
   - Setup helper methods untuk common data
   - Reuse test fixtures
   - Keep test descriptions clear

6. **Priority Implementation Order**:
   - Phase 1: CRUD operations (add, edit, delete, status)
   - Phase 2: Query/getter methods
   - Phase 3: Scope/category management
   - Phase 4: Notifications
   - Phase 5: Schedule/time blocks
   - Phase 6: Persistence & edge cases

---

## Success Criteria

✅ Semua API methods punya test coverage  
✅ Setiap test hapus data first untuk consistency  
✅ Scenario-based test (bukan hanya single happy path)  
✅ Error cases ter-cover (invalid input, not found, etc)  
✅ Side effects di-verify (notifications, persistence, state update)  
✅ Test data consistent dan reusable  
✅ Clear test names describing what/why being tested  

---

## Notes
- Dokumentasi ini fokus pada **WHAT to test**, bukan **HOW to test**
- Junior programmer atau model AI lebih murah dapat customize implementasi detail sesuai kemampuan
- Expected output: Unit test suite dengan 80%+ coverage
- Timeline: Flexible, sesuai kapasitas implementor
