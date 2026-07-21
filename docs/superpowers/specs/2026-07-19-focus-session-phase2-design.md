# Focus Session — Fase 2 (Multi-sesi, Break, Mode Kustom)

## Tujuan

Melanjutkan Focus Session Fase 1 dengan: **siklus multi-sesi** (fokus →
istirahat → fokus), **Break screen**, dan **Mode Kustom** (durasi/istirahat/
siklus). Tidak menyentuh fitur existing selain integrasi; tidak
mengimplementasikan Fase 3/4.

Batasan sama seperti Fase 1: UI Indonesia, kode/identifier Inggris (komentar
Indonesia mengikuti codebase), warna `AppTheme.primary` (#6C5CE7), MD3, business
logic di service/provider (bukan widget), SAW tak diubah, clean code, hindari
duplikasi.

Keputusan yang disepakati:
- Perpindahan antar-sesi: **manual + opsi auto** (toggle "Mulai sesi berikutnya otomatis").
- Toggle milik Fase 3 (Pertahankan layar/wakelock, Strict Mode, Getaran):
  **ditampilkan nonaktif "Segera hadir"**, tidak difungsikan.

## Model (`focus_session_model.dart`)

Tambah field ke `FocusSession` (defaulted → aman untuk snapshot lama):
- `int totalSessions` (jumlah siklus fokus; default 1)
- `int breakMinutes` (durasi istirahat; default 0)
- `bool autoAdvance` (default false)

Update `toJson`/`fromJson`/`copyWith`. `recommendedSessions` tetap (hint SAW).
`totalSessions` = nilai yang benar-benar dijalankan (default = `recommendedSessions`
untuk preset; = "Jumlah Siklus" untuk Kustom).

Custom config memakai `FocusPreset` (name `'Kustom'`, focusMinutes, breakMinutes)
+ `cycles` terpisah. Pilihan durasi fokus: `const kCustomFocusOptions = [15,25,30,45,50,60,90,120]`.

## Provider (`focus_session_provider.dart`)

State siklus (business logic penuh di sini):
- `int _currentSession = 1;` → getter `currentSession`.
- `bool get hasNextSession => _active != null && _currentSession < _active!.totalSessions;`
- `int _accumulatedFocusMinutes = 0;` (akumulasi menit fokus dari blok yang selesai).

Transisi (satu `FocusTimerService`, dibedakan lewat `state`):
- `startSession(...)`: `_currentSession=1`, `_accumulatedFocusMinutes=0`, state=`running`, mulai timer fokus.
- `onFinished` saat state=`running` (blok fokus selesai): `_accumulatedFocusMinutes += focusMinutes`, state=`completed`. Jika `autoAdvance && hasNextSession`: langsung `startBreak()` (atau `startNextSession()` bila breakMinutes==0).
- `startBreak()`: state=`breakTime`, mulai timer `breakMinutes`.
- `onFinished` saat state=`breakTime`: `startNextSession()` (istirahat selalu lanjut kerja).
- `startNextSession()`: `_currentSession++`, state=`running`, mulai timer fokus.
- `skipBreak()`: hentikan timer break → `startNextSession()`.
- `completeSession(status, taskProvider)`: tambah `_accumulatedFocusMinutes` ke tugas (sekali), reset ke idle, clearActive.
- `endSession(taskProvider)`: tambah `_accumulatedFocusMinutes` yang sudah terkumpul (blok yang sudah selesai tetap dihitung), reset idle, clearActive.

Snapshot (`ActiveSessionSnapshot`) diperluas menyertakan `currentSession` &
`accumulatedFocusMinutes` (siap restore Fase 3). Repository tetap murni I/O.

## Mode Kustom

`FocusModeSheet`: opsi **Kustom** kini aktif. Memilih Kustom → tombol "Atur
Kustom" membuka `FocusCustomSheet`:
- **Durasi Fokus**: pilihan dari `kCustomFocusOptions` (chip/dropdown).
- **Durasi Istirahat**: stepper (0–30 menit).
- **Jumlah Siklus**: stepper (1–8).
- **Toggle aktif Fase 2**: "Mulai sesi berikutnya otomatis" (autoAdvance).
- **Toggle "Segera hadir" (nonaktif)**: Pertahankan layar tetap menyala, Strict
  Mode, Getaran, Alarm selesai, Kunci navigasi (ditampilkan disabled — Fase 3).

Hasil: `FocusPreset('Kustom', focus, break)` + cycles + autoAdvance → dialir ke
`FocusPreparationScreen` seperti preset biasa.

Untuk preset non-Kustom (Fokus/Fleksibel): `totalSessions = recommendedSessions`,
`autoAdvance = false`, `breakMinutes = preset.breakMinutes`.

## Break Screen (baru — `screens/focus/focus_break_screen.dart`)

Ditampilkan saat state=`breakTime`. Isi:
- Judul "Waktunya Istirahat".
- Ring/teks countdown istirahat (reuse gaya ring, warna `success` untuk
  membedakan dari fokus).
- Tips acak: "Minum air putih", "Berdiri sebentar", "Istirahatkan mata",
  "Peregangan ringan".
- Tombol **"Lewati Istirahat"** → `provider.skipBreak()`.
- Info: "Berikutnya: Sesi X dari N".

Navigasi break: dari Complete screen "Mulai Istirahat" → push Break screen.
Saat break selesai/skip → provider `startNextSession()`; Break screen mendengar
state, saat kembali `running` → `pushReplacement` ke `FocusTimerScreen`.

## Complete Screen (multi-sesi)

`FocusCompleteScreen` jadi sadar siklus:
- Judul: "Sesi Fokus Selesai" (per blok) bila `hasNextSession`, atau "Semua Sesi
  Selesai" bila sesi terakhir.
- Info + pertanyaan target (Ya/Sebagian/Belum) tetap.
- Tombol dinamis:
  - `hasNextSession` & `breakMinutes>0`: **"Mulai Istirahat"** (→ Break screen) + **"Mulai Sesi Berikutnya"** (→ skip break, `startNextSession` + push Timer) + **"Selesai"**.
  - `hasNextSession` & `breakMinutes==0`: **"Mulai Sesi Berikutnya"** + **"Selesai"**.
  - sesi terakhir: **"Selesai"** saja.
- "Selesai" → `completeSession(status, taskProvider)` → `popUntil` root.

Bila `autoAdvance` ON, blok fokus non-terakhir tidak menampilkan Complete screen
(provider langsung `startBreak`/`startNextSession`); target ditanyakan hanya pada
Complete screen sesi terakhir.

## Timer Screen

`FocusTimerScreen`: "Sesi 1 dari N" → pakai `provider.currentSession` &
`session.totalSessions` (bukan hardcode 1). Sisanya sama.

## Alur

Mulai → mode sheet (Kustom → custom sheet) → intent → preparation →
[Fokus → Complete → (Istirahat → Break →) Sesi berikutnya] ×N → Complete akhir →
Selesai.

## Yang TIDAK termasuk Fase 2

Wakelock/Layar Fokus, Strict Mode, Getaran, Alarm suara, background/foreground
notif (semua Fase 3); Streak nyata, Riwayat, Profil (Fase 4). Toggle Fase 3
hanya tampil nonaktif.

## Dampak fitur existing

Tidak ada perubahan di luar file Focus Session. `Task`, SAW, notifikasi, layar
lain tak tersentuh. `addFocusMinutes` tetap dipakai (akumulasi per sesi).

## Testing

Unit test ditunda ke sesi akhir. Verifikasi: `flutter analyze` bersih + boot web
bersih + uji fungsional. Baseline suite +360/-40; jangan menambah kegagalan.

## Berkas

- `lib/models/focus_session_model.dart` — field siklus + kCustomFocusOptions + snapshot
- `lib/services/focus_session_provider.dart` — logika siklus/break
- `lib/services/focus_session_repository.dart` — (snapshot field baru; tetap I/O)
- `lib/screens/focus/focus_mode_sheet.dart` — aktifkan Kustom
- `lib/screens/focus/focus_custom_sheet.dart` (baru) — konfigurasi kustom + toggle
- `lib/screens/focus/focus_break_screen.dart` (baru) — Break screen
- `lib/screens/focus/focus_complete_screen.dart` — aksi multi-sesi
- `lib/screens/focus/focus_timer_screen.dart` — "Sesi X dari N"
- `lib/utils/task_status_actions.dart` — teruskan cycles/autoAdvance
- `lib/screens/focus/focus_preparation_screen.dart` — teruskan cycles/autoAdvance
