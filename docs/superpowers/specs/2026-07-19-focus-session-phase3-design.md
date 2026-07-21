# Focus Session — Fase 3 (Background, Notifikasi, Layar Fokus, Strict Mode)

## Tujuan

Membuat sesi fokus tetap akurat di background dan menambah fitur native:
foreground notification, Layar Fokus (OLED + wakelock), Strict Mode, Getaran,
Alarm. **Verifikasi di HP Infinix** (fitur native tidak jalan di web).

Batasan sama seperti fase sebelumnya. Package baru: `wakelock_plus`, `vibration`
(sudah ditambah). `flutter_local_notifications` sudah ada.

Karena besar, dikerjakan bertahap:

## Fase 3a — Foreground notification + sinkronisasi background

- **Timestamp-sync**: `FocusTimerService` sudah berbasis `_endAt`. Tambah
  lifecycle observer di `FocusSessionProvider` (via widget di root) → saat app
  kembali foreground, `syncFromBackground()`: jika `remaining<=0` picu
  `onFinished` (blok yang selesai saat app di background tetap dihitung); jika
  masih berjalan, pastikan ticker & UI sinkron (waktu dihitung dari `_endAt`,
  jadi selalu akurat walau Dart sempat dijeda OS).
- **Snapshot** diperluas: simpan `state` & `endAtEpochMs` (siap restore penuh).
- **Foreground notification** (`notification_service.dart`): notifikasi
  *ongoing* saat sesi fokus berjalan — judul "🎯 Sedang Fokus", body nama tugas,
  hitung mundur native (`usesChronometer` + `chronometerCountDown` + `when`).
  Aksi **Jeda** & **Akhiri** (`AndroidNotificationAction`). Ditampilkan saat
  running, di-update saat pause/resume, dibatalkan saat selesai/akhiri.
- **Routing aksi notifikasi**: `NotificationService` meneruskan actionId ke
  callback yang didaftarkan `FocusSessionProvider` (pause/end). Ditangani saat
  app foreground/resumed (background-isolate penuh di luar lingkup 3a).

## Fase 3b — Layar Fokus (OLED) + toggle Kustom native

- Field flag di `FocusSession`: `keepScreenOn`, `vibrate`, `alarmOnFinish`,
  `lockNavigation`, `strictMode` (dari toggle Kustom; default per mode).
- **Layar Fokus**: layar hitam penuh minimalis (countdown, tugas, target, sesi,
  estimasi, Jeda/Akhiri). Tombol "Layar Fokus" di timer. `wakelock_plus` aktif
  di layar ini & saat `keepScreenOn`.
- **Getaran** (`vibration`) & **Alarm** singkat saat sesi selesai (bila toggle).
- Toggle Kustom "Segera hadir" diaktifkan sesuai flag.

## Fase 3c — Strict Mode

- Bila `strictMode`/`lockNavigation`: deteksi app ke background saat sesi
  berjalan → saat kembali, dialog "Kamu meninggalkan sesi fokus" (Lanjut Fokus /
  Akhiri Sesi). `lockNavigation` juga memaksa PopScope terkunci di mode non-Fokus.

## Restore penuh (opsional, akhir Fase 3)

Saat app dibuka ulang & ada snapshot aktif: tampilkan prompt "Lanjutkan sesi
fokus?" di dashboard → kembali ke timer/break sesuai `state` & `endAtEpochMs`.

## Dampak fitur existing

Menambah channel notifikasi baru; tidak mengubah notifikasi tugas existing.
`Task`, SAW, layar lain tak tersentuh.

## Testing

Diverifikasi di HP Infinix (adb): notifikasi muncul & hitung mundur, aksi Jeda/
Akhiri, background akurat, wakelock, getaran, strict. `flutter analyze` bersih.
