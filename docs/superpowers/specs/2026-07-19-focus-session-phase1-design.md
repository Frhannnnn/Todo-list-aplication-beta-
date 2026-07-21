# Focus Session — Fase 1 (Core Loop)

## Tujuan

Menambahkan sistem **Focus Session** yang menggantikan alur "Mulai" (yang kini
langsung membuka Pomodoro) menjadi: pilih mode → tentukan target → persiapan →
timer → sesi selesai. Fase 1 mencakup **core loop** untuk mode **Fokus** &
**Fleksibel** dengan preset dasar; fase lain menyusul.

Batasan (dari user):
- Hanya MENAMBAH fitur; jangan ubah fitur existing kecuali untuk integrasi.
- Pertahankan struktur project & Material Design 3.
- Warna utama tetap `AppTheme.primary` (#6C5CE7).
- Teks UI Bahasa Indonesia; kode/komentar/logic Bahasa Inggris.
- Clean code, hindari duplikasi, **business logic timer TIDAK di widget**.
- Jangan ubah algoritma SAW (hanya baca skornya sebagai rekomendasi).

## Arsitektur (pemisahan lapisan)

- **Model** — `focus_session_model.dart`
- **Service** — `focus_timer_service.dart` (mesin timer murni)
- **Repository** — `focus_session_repository.dart` (SharedPreferences)
- **State** — `focus_session_provider.dart` (`ChangeNotifier`, orkestrasi)
- **UI** — `screens/focus/*` (hanya render + panggil provider)
- **Util** — `focus_recommendation.dart` (mapping SAW → rekomendasi)

### Model — `lib/models/focus_session_model.dart`

```
enum FocusMode { focus, flexible, custom }        // custom belum aktif di F1
enum SessionTargetStatus { achieved, partial, notAchieved }

class FocusPreset {
  final String name;            // "Pomodoro", "Belajar", "Flow", "Deep Work"
  final int focusMinutes;
  final int breakMinutes;
  const FocusPreset(...);
}
const kFocusPresets = [ Pomodoro 25/5, Belajar 45/15, Flow 50/10, DeepWork 90/20 ];

class FocusSession {
  final String id;
  final String taskId;
  final FocusMode mode;
  final String presetName;
  final String? targetText;         // "Menyelesaikan Bab II" (opsional)
  final int focusMinutes;
  final int recommendedSessions;    // dari SAW (informasi)
  final DateTime startedAt;
  final DateTime? endedAt;
  final SessionTargetStatus? targetStatus;
  // toJson/fromJson untuk persistensi
}
```

Label Indonesia untuk mode/status dibuat di UI/util (bukan disimpan).

### Service — `lib/services/focus_timer_service.dart`

Mesin timer murni, tanpa Flutter UI. Berbasis **timestamp** supaya akurat &
siap untuk restore (Fase 3):
- `void start(Duration total)` — set `endTarget = now + total`.
- `Duration get remaining` — dihitung dari `endTarget - now` (bukan decrement manual).
- `void pause()` / `void resume()` — simpan sisa saat pause.
- `Stream<Duration>` atau callback tick per detik (via `Timer.periodic`) untuk UI.
- `bool get isFinished`.
- Tidak menyentuh SharedPreferences (itu tugas repository).

### Repository — `lib/services/focus_session_repository.dart`

- `Future<void> saveActive(FocusSession, {remainingSeconds})` — snapshot sesi aktif.
- `Future<FocusSession?> loadActive()` / `Future<void> clearActive()`.
- Key SharedPreferences khusus (mis. `focus_active_session`).
- History & streak: method-nya ditambah di Fase 4 (tidak dibuat sekarang → YAGNI).

### State — `lib/providers/focus_session_provider.dart`

`ChangeNotifier` yang memegang state sesi aktif & menggerakkan UI:
- `FocusSession? active`, `Duration remaining`, `bool isRunning`, `int currentSession`.
- `startSession({Task, FocusMode, FocusPreset, targetText})` → buat FocusSession,
  mulai `FocusTimerService`, simpan via repository.
- `pause()`, `resume()`, `end()` (batalkan), `complete(SessionTargetStatus)`.
- Meng-expose tick ke UI via `notifyListeners()`.
- **Semua logika di sini**, screen hanya memanggil.
- Didaftarkan di `main.dart` lewat `MultiProvider` (di samping `TaskProvider`).

### Util — `lib/utils/focus_recommendation.dart`

Mapping prioritas → rekomendasi (murni), sesuai spec:
```
Prioritas Sangat Tinggi → 4 sesi, 50 menit
Prioritas Tinggi        → 3 sesi, 45 menit
Prioritas Sedang        → 2 sesi, 30 menit
Prioritas Rendah        → 1 sesi, 25 menit
```
Prioritas diturunkan dari `AppTheme.getPrioritasLabel(task.ranking, totalActive)`
yang SUDAH ADA (tak mengubah SAW). Mengembalikan `(sessions, minutes)`.

## Alur UI (Fase 1)

1. **Kartu tugas → "Mulai"** (`task_status_actions.dart`): set status
   `sedangDikerjakan` (perilaku existing dipertahankan) lalu tampilkan
   **`FocusModeSheet`** (bottom sheet), bukan `PomodoroTimerScreen`.
2. **FocusModeSheet**: pilih **Mode** (Fokus / Fleksibel; *Kustom* tampil tapi
   dinonaktifkan "segera hadir" di F1) + pilih **Preset** (Pomodoro/Belajar/
   Flow/Deep Work). Lanjut → intent dialog.
3. **FocusIntentDialog**: "Apa target sesi ini?" input teks opsional
   (placeholder "Menyelesaikan Bab II"). Lanjut → preparation.
4. **FocusPreparationScreen**: judul "Siapkan Fokus"; tampilkan Nama tugas,
   Kategori, Prioritas, Durasi sesi, Jumlah sesi rekomendasi, Estimasi selesai;
   **countdown 5→1** lalu timer mulai otomatis; tombol **"Mulai Sekarang"**
   untuk lewati.
5. **FocusTimerScreen**: reuse desain ring countdown; tampilkan Nama tugas,
   Kategori, Prioritas, Target sesi, Nomor sesi ("Sesi 1 dari N"), Estimasi
   selesai, progress. Tombol **Jeda** & **Akhiri**.
   - **Mode Fokus**: `PopScope(canPop:false)` (cegah back Android & swipe),
     Akhiri → dialog konfirmasi "Akhiri sesi fokus?" ("Progres sesi fokus akan
     dihentikan." / Batal / Ya, Akhiri). Karena route full-screen di atas nav,
     bottom nav & pindah halaman otomatis terkunci.
   - **Mode Fleksibel**: `PopScope(canPop:true)`; user boleh keluar/menjelajah,
     timer tetap jalan (di F1 selama app foreground; background di F3).
6. **Saat timer selesai**: ring beralih warna (ungu→hijau) + ikon centang
   (animasi sederhana; getaran ditunda ke F3 karena butuh package `vibration`).
7. **FocusCompleteScreen**: "Sesi Fokus Selesai"; tampilkan Durasi sesi, Nama
   tugas, Target sesi; tanya "Apakah target sesi tercapai?" (Ya / Sebagian /
   Belum) → simpan `targetStatus` ke sesi (riwayat penuh di F4). Tombol **Selesai**
   (kembali). ("Mulai Sesi Berikutnya" & "Mulai Istirahat" menyusul di F2 saat
   multi-sesi/Break ada.)

## Yang TIDAK termasuk Fase 1 (ditunda, jangan dibuat sekarang)

Mode Kustom + toggle, multi-sesi & Break screen, background timestamp-restore +
foreground notification, Layar Fokus/OLED + wakelock, Strict Mode, Focus Streak,
Riwayat Focus Session, integrasi Profil, package `wakelock_plus`/`vibration`.

## Dampak ke fitur existing

- `task_status_actions.dart`: `handleStatusChange` untuk transisi ke
  `sedangDikerjakan` kini membuka `FocusModeSheet` alih-alih push
  `PomodoroTimerScreen`. Transisi status lain tak berubah. `addFocusMinutes`
  tetap dipakai (dipanggil saat sesi fokus selesai penuh).
- `main.dart`: `ChangeNotifierProvider(TaskProvider)` → `MultiProvider`
  [TaskProvider, FocusSessionProvider]. Tak ada perubahan UI lain.
- `PomodoroTimerScreen` menjadi tak terpakai (dead route) setelah F1 — dibiarkan
  sampai Focus Session lengkap, lalu dihapus.
- Tidak ada perubahan pada model `Task`, SAW, notifikasi existing, atau layar lain.

## Integrasi subtask (catatan masa depan)

`targetText` di F1 adalah teks bebas. Saat fitur subtask dibangun, target sesi
bisa di-upgrade untuk memilih subtask tertentu (dan menandainya selesai dari
Session Complete). Titik integrasi: `FocusIntentDialog` & `FocusCompleteScreen`.

## Testing

Unit test ditunda ke sesi testing akhir (preferensi user). Verifikasi tiap
langkah: `flutter analyze` bersih + uji fungsional (user cek di localhost:8080).
Baseline suite +360/-40 pre-existing; jangan menambah kegagalan.
