# Focus Session Fase 1 — Rencana Implementasi

Spec: `docs/superpowers/specs/2026-07-19-focus-session-phase1-design.md`
Branch: `feature/focus-session`. Verifikasi: `flutter analyze` bersih tiap task + uji fungsional di browser. Test unit ditunda.

Urutan: A→D (fondasi non-UI) dulu, lalu E→H (UI + wiring). Tiap task = 1 commit.

## Task A — Models + rekomendasi SAW
**Files:** create `lib/models/focus_session_model.dart`, `lib/utils/focus_recommendation.dart`
- `enum FocusMode { focus, flexible, custom }`
- `enum SessionTargetStatus { achieved, partial, notAchieved }`
- `class FocusPreset { final String name; final int focusMinutes; final int breakMinutes; const FocusPreset(...); }`
- `const List<FocusPreset> kFocusPresets` = Pomodoro 25/5, Belajar 45/15, Flow 50/10, Deep Work 90/20
- `class FocusSession { id, taskId, mode, presetName, targetText?, focusMinutes, recommendedSessions, startedAt, endedAt?, targetStatus?; toJson/fromJson; copyWith }`
- `focus_recommendation.dart`: `({int sessions, int minutes}) focusRecommendation(String priorityLabel)` — map "Tinggi"/"Sedang"/"Rendah" (+ "Sangat Tinggi") → (4,50)/(3,45)/(2,30)/(1,25). Baca label via `AppTheme.getPrioritasLabel` di pemanggil.
**Gate:** analyze.

## Task B — Timer service
**Files:** create `lib/services/focus_timer_service.dart`
- Berbasis timestamp: `start(Duration total)` set `_endAt = now+total`; `Duration get remaining` = `_endAt - now` (clamp ≥ 0); `pause()`/`resume()` simpan sisa; `bool get isFinished`; `void dispose()`.
- Tick: `void Function(Duration)? onTick` dipanggil tiap detik via `Timer.periodic`; panggil `onFinished` saat habis.
- Tanpa SharedPreferences, tanpa Flutter UI.
**Gate:** analyze.

## Task C — Repository
**Files:** create `lib/services/focus_session_repository.dart`
- Key `focus_active_session`. `Future<void> saveActive(FocusSession session, int remainingSeconds)`, `Future<({FocusSession session, int remainingSeconds})?> loadActive()`, `Future<void> clearActive()`.
- JSON via `FocusSession.toJson`. (History/streak: Fase 4 — jangan dibuat.)
**Gate:** analyze.

## Task D — Provider + registrasi
**Files:** create `lib/providers/focus_session_provider.dart`; modify `lib/main.dart`
- `FocusSessionProvider extends ChangeNotifier` memegang: `FocusSession? active`, `Duration remaining`, `bool isRunning`, `bool isFinished`.
- API: `void startSession({required Task task, required FocusMode mode, required FocusPreset preset, String? targetText, required int recommendedSessions})`, `void pauseResume()`, `Future<void> endSession()` (batal; clearActive), `Future<void> completeSession(SessionTargetStatus status, {TaskProvider? taskProvider})` (set targetStatus, `addFocusMinutes` bila penuh, clearActive).
- Gunakan `FocusTimerService` (tick → `notifyListeners`) + `FocusSessionRepository`.
- `main.dart`: ganti `ChangeNotifierProvider(create: TaskProvider())` → `MultiProvider(providers:[ChangeNotifierProvider(TaskProvider), ChangeNotifierProvider(FocusSessionProvider)])`. Tak ada perubahan UI lain.
**Gate:** analyze + app boot bersih.

## Task E — Mode sheet + Intent dialog + wiring "Mulai"
**Files:** create `lib/screens/focus/focus_mode_sheet.dart`, `lib/screens/focus/focus_intent_dialog.dart`; modify `lib/utils/task_status_actions.dart`
- `FocusModeSheet`: bottom sheet MD3 senada. Pilih Mode (Fokus / Fleksibel aktif; **Kustom** disabled + label "Segera hadir"), pilih Preset (4 preset, default Pomodoro). Tombol "Lanjut" → tutup sheet → tampilkan `FocusIntentDialog`.
- `FocusIntentDialog`: judul "Apa target sesi ini?", `TextField` opsional (placeholder "Menyelesaikan Bab II"), tombol "Lanjut". Return target text (bisa kosong).
- `task_status_actions.dart`: pada transisi ke `sedangDikerjakan`, panggil `showFocusModeSheet(context, task)` alih-alih push `PomodoroTimerScreen`. Fungsi baru mengorkestrasi sheet→dialog→push `FocusPreparationScreen`. (Perilaku status lain tetap.)
**Gate:** analyze.

## Task F — Preparation screen
**Files:** create `lib/screens/focus/focus_preparation_screen.dart`
- Judul "Siapkan Fokus". Info: Nama tugas, Kategori, Prioritas (via `AppTheme.getPrioritasLabel`), Durasi sesi (preset.focusMinutes), Jumlah sesi rekomendasi (`focusRecommendation`), Estimasi selesai (now + durasi).
- Countdown 5→1 (`Timer.periodic`), lalu otomatis `Navigator.pushReplacement` ke `FocusTimerScreen`. Tombol "Mulai Sekarang" untuk lewati.
- Memanggil `provider.startSession(...)` saat timer mulai (atau saat pindah ke timer screen — sekali saja).
**Gate:** analyze.

## Task G — Timer screen
**Files:** create `lib/screens/focus/focus_timer_screen.dart`
- Reuse desain ring countdown (pola dari `pomodoro_timer_screen.dart`: `CircularProgressIndicator` + `Stack` + waktu). Konsumsi `FocusSessionProvider` (remaining, isRunning).
- Info: Nama tugas, Kategori, Prioritas, Target sesi, Nomor sesi ("Sesi 1 dari N"), Estimasi selesai.
- Tombol **Jeda** (toggle pause/resume) & **Akhiri**.
- **Mode Fokus**: `PopScope(canPop:false, onPopInvokedWithResult)`; Akhiri → dialog "Akhiri sesi fokus?" ("Progres sesi fokus akan dihentikan." / Batal / Ya, Akhiri) → `provider.endSession()` + pop.
- **Mode Fleksibel**: `PopScope(canPop:true)`.
- Saat `isFinished`: ring animasi ungu→hijau + ikon centang (`AnimatedSwitcher`/warna), lalu `Navigator.pushReplacement` ke `FocusCompleteScreen`. (Getaran: Fase 3.)
**Gate:** analyze.

## Task H — Complete screen + rangkai end-to-end
**Files:** create `lib/screens/focus/focus_complete_screen.dart`
- Judul "Sesi Fokus Selesai". Info: Durasi sesi, Nama tugas, Target sesi.
- "Apakah target sesi tercapai?" → 3 tombol (Ya/Sebagian/Belum) → `provider.completeSession(status, taskProvider: ...)`.
- Tombol **Selesai** → `Navigator.popUntil` ke root (kembali ke app). ("Mulai Sesi Berikutnya"/"Mulai Istirahat": Fase 2.)
**Gate:** analyze + uji end-to-end di browser (Mulai → mode → target → preparation → timer → complete), pastikan fitur existing (nav, kartu tugas) tetap normal.

## Catatan
- Warna: `AppTheme.primary` (#6C5CE7), kartu rounded-20 senada.
- `PomodoroTimerScreen` jadi tak terpakai setelah Task E; dibiarkan (dihapus saat Focus Session lengkap).
- Tidak menyentuh model `Task`, SAW, notifikasi, atau layar existing lain.
