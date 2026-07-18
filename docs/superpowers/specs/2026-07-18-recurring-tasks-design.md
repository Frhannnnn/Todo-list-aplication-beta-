# Tugas Berulang (Recurring Tasks)

## Tujuan

Memungkinkan sebuah tugas berulang otomatis menurut pola (harian, mingguan,
bulanan, tahunan, hari kerja, atau custom), sehingga tugas rutin (mis. laporan
praktikum mingguan) tidak perlu dibuat manual tiap kali. Occurrence yang selesai
tetap tersimpan sebagai riwayat agar streak, statistik, dan titik kalender tetap
akurat.

Batasan lintas-fitur: **UI wajib senada** dengan desain yang ada (AppTheme ungu,
kartu rounded-20 border tipis, `showModalBottomSheet`, font Inter). Lihat pola di
`add_edit_task_screen.dart` (`_buildSection`, `_buildDeadlinePicker`).

## Model data

Enum baru (kode Inggris, label ditampilkan Indonesia):

```dart
enum RecurrenceType { none, daily, weekly, monthly, yearly, weekday, custom }
enum RecurrenceUnit { day, week, month, year } // hanya dipakai saat type == custom
```

Field baru di `Task` — semua defaulted/nullable supaya migrasi JSON aman (tugas
lama otomatis `recurrence = none`):

| Field | Tipe | Default | Keterangan |
|---|---|---|---|
| `recurrence` | `RecurrenceType` | `none` | Pola pengulangan |
| `recurrenceInterval` | `int` | `1` | "tiap N" untuk custom |
| `recurrenceUnit` | `RecurrenceUnit?` | `null` | Unit untuk custom |
| `recurrenceEndDate` | `DateTime?` | `null` | Kondisi berakhir: pada tanggal |
| `recurrenceCount` | `int?` | `null` | Kondisi berakhir: setelah N kali (total) |
| `recurrenceIndex` | `int` | `1` | Occurrence ke-berapa dalam seri |
| `seriesId` | `String?` | `null` | Pengelompok occurrence satu seri (statistik & "edit semua" di masa depan) |

`toJson`/`fromJson`/`copyWith` diperbarui. `fromJson` membaca field baru dengan
fallback aman (tidak ada → `none`/default). Ekspor-impor otomatis ikut karena
memakai `toJson`/`fromJson`.

## Label dinamis (Indonesia)

Yang **disimpan hanya enum + param**, bukan string label. Label selalu
di-generate ulang dari tanggal terpilih via helper di `lib/utils/recurrence.dart`,
memakai `DateFormat('EEEE'/'MMMM','id_ID')` (locale sudah di-`initializeDateFormatting`
di `main`):

1. `none` → "Tidak berulang"
2. `daily` → "Setiap hari"
3. `weekly` → "Setiap minggu di hari [EEEE]" — mis. "Setiap minggu di hari Minggu"
4. `monthly` → "Setiap bulan di [nama hari] ke-[N]" — mis. "Setiap bulan di Minggu ke-2" (pola hari-ke-N-dalam-bulan, dihitung dari tanggal terpilih)
5. `yearly` → "Setiap tahun di [d] [MMMM]" — mis. "Setiap tahun di 12 Juli"
6. `weekday` → "Setiap hari kerja (Senin–Jumat)"
7. `custom` → "Ulangi setiap [N] [hari/minggu/bulan/tahun]" + info berakhir

Helper: `int mingguKeBerapa(DateTime)` (1–5, dihitung `((day - 1) ~/ 7) + 1`),
output diterjemahkan ke Indonesia.

## Mesin pengulangan — `lib/utils/recurrence.dart`

`DateTime? nextOccurrenceDate(Task task)` — menghitung deadline berikutnya SETELAH
`task.deadline` berdasar rule; mengembalikan `null` bila seri berakhir.

Aturan hitung (mempertahankan jam/menit deadline asli):
- `daily`: +1 hari
- `weekly`: +7 hari (hari sama)
- `weekday`: hari kerja berikutnya (lewati Sabtu & Minggu)
- `monthly`: hari-ke-N-minggu yang sama di bulan berikutnya (mis. "Minggu ke-2 berikutnya"); bila bulan target tak punya minggu ke-N, clamp ke kemunculan terakhir bulan itu
- `yearly`: +1 tahun (29 Feb → clamp ke 28 Feb pada tahun non-kabisat)
- `custom`: +`interval` × `unit` (day/week/month/year), dengan penanganan overflow bulan/tahun

Cek berakhir (dievaluasi setelah menghitung tanggal berikutnya):
- Bila `recurrenceEndDate != null` dan tanggal berikutnya > `recurrenceEndDate` → `null`
- Bila `recurrenceCount != null` dan `recurrenceIndex + 1 > recurrenceCount` → `null`

## Generasi occurrence — LAZY (on-demand)

**Keputusan: lazy / on-demand**, dengan invariant **"tepat satu occurrence
terbuka (non-`selesai`) per seri aktif"**. Occurrence berikutnya dibuat **tepat
saat occurrence sekarang ditandai `selesai`**.

Kontras dengan alternatif **batch** (generate semua di depan sampai
endDate/count), yang DITOLAK karena:
- Tidak bisa merepresentasikan seri tak terbatas ("setiap hari" selamanya).
- Membanjiri daftar aktif + matriks Eisenhower + ranking SAW dengan banyak item
  masa depan berurgensi rendah (noise).
- Berisiko menembus limit notifikasi terjadwal OS.
- Edit rule berarti harus regenerate tumpukan tugas masa depan.

Lazy menjaga himpunan aktif minimal, urgensi bermakna, notifikasi terbatas, dan
edit rule sepele. Trade-off: occurrence masa depan tidak materialize jadi tugas
nyata. Untuk tetap memberi visibilitas perencanaan, occurrence mendatang
ditampilkan sebagai **preview read-only** di kalender (lihat bagian "Preview
occurrence di kalender") — tanpa mengotori daftar aktif/SAW/notifikasi.

### Titik implementasi

Di `TaskProvider.editTugas`, pada transisi status ke `selesai` (deteksi
`oldStatus != selesai && status == selesai` yang sudah ada untuk `completedAt`):

1. Instance yang selesai tetap tersimpan: `status = selesai`, `completedAt = now`,
   field recurrence tetap (untuk riwayat). Notifnya otomatis dibatalkan oleh
   `scheduleTaskNotifications` (early-return saat `selesai`).
2. Jika `task.recurrence != none`: hitung `nextOccurrenceDate`. Bila ada,
   buat **Task baru** (id baru dari `_uuid`) menyalin semua field + rule +
   `seriesId` (dibuat saat occurrence pertama bila masih null), dengan
   `deadline` = tanggal berikutnya, `status = belumDikerjakan`,
   `completedAt = null`, `recurrenceIndex = index + 1`, `createdAt = now`.
   Tambahkan lewat jalur bersama `_addTaskObject` (dipakai juga oleh
   `tambahTugas`): `_recalculateSAW()`, `_runScheduler()`, `_saveTasks()`,
   `scheduleTaskNotifications(baru)`, dan reschedule daily reminder.

### Occurrence terlewat

Bila occurrence terbuka lewat deadline tanpa diselesaikan: **dibiarkan overdue**
(seri menunggu). TIDAK ada auto-spawn saat deadline lewat — invariant "satu
occurrence terbuka" terjaga, tanpa tumpukan. Menyelesaikan occurrence yang telat
tetap men-spawn berikutnya (dari `nextOccurrenceDate` relatif deadline occurrence
tersebut).

## Dampak SAW & Eisenhower

- **Pewarisan**: `tingkatKepentingan`, `estimasiWaktu`, lingkup, kategori,
  konfigurasi notif, dan rule diwariskan otomatis dari occurrence yang selesai —
  user set sekali saat membuat.
- **Urgensi tidak diwariskan** — selalu dihitung dari deadline occurrence
  (`hitungUrgensiDariDeadline`). Occurrence baru lahir dengan deadline masa depan
  → urgensi rendah, lalu naik sendiri saat mendekat.
- **SAW & Eisenhower** dihitung ulang otomatis via `_recalculateSAW()` saat
  occurrence lahir; occurrence adalah tugas aktif biasa.

## Notifikasi

Sistem lama sudah menangani ini:
- ID notif diturunkan dari `task.id.hashCode` → tiap occurrence (id baru) punya
  slot unik, tidak bentrok antar-occurrence.
- `scheduleTaskNotifications` selalu cancel-lalu-jadwalkan dan berhenti bila
  status `selesai`. Menyelesaikan occurrence membatalkan notifnya; occurrence
  baru menjadwalkan notif segar lewat jalur `tambahTugas`.
- Tidak ada penumpukan (dobel) maupun notif yang hilang, selama spawn dirutekan
  lewat `_addTaskObject` (yang memanggil penjadwalan notif + reschedule daily
  reminder). Ini syarat implementasi yang wajib.

## UI (senada)

### Add/Edit — section "Pengulangan"

Section baru `_buildSection('Pengulangan', [...])` tepat setelah "Deadline"
(karena label bergantung tanggal deadline terpilih). Isinya baris tappable
bergaya seperti `_buildDeadlinePicker`: menampilkan label sekarang (default
"Tidak berulang") + chevron. Tap → `showModalBottomSheet` berisi 7 opsi dengan
label dinamis dari `_deadline`.

Memilih **"Custom…"** → bottom sheet kedua:
- Stepper "Ulangi setiap [N]" (N ≥ 1)
- Dropdown unit: hari / minggu / bulan / tahun
- "Berakhir": pilihan **Tidak pernah** / **Pada tanggal…** (date picker) /
  **Setelah [N] kali** (stepper)

State di `_AddEditTaskScreenState`: `_recurrence`, `_recurrenceInterval`,
`_recurrenceUnit`, `_recurrenceEndDate`, `_recurrenceCount`. Diteruskan ke
`tambahTugas`/`editTugas` (parameter baru). Saat edit tugas lama, state diisi
dari task.

Karena label bergantung `_deadline`, mengganti deadline setelah memilih
weekly/monthly/yearly otomatis memperbarui label (label selalu di-generate ulang).

### Kartu tugas — badge berulang

Di `task_card_widget.dart`, bila `task.recurrence != none`, tampilkan badge kecil
`Icons.repeat_rounded` bergaya pill rounded (`AppTheme.primary` alpha 0.1 + border
alpha 0.3), senada dengan chip kategori/status yang ada.

## Preview occurrence di kalender (read-only)

Occurrence mendatang TIDAK dimaterialize, tapi ditampilkan sebagai titik preview
di layar Kalender (`calendar_screen.dart`) dan mini-kalender Dashboard
(`dashboard_screen.dart`), supaya user tetap melihat pola ke depan tanpa mengotori
daftar aktif / SAW / notifikasi.

**Perhitungan (on-the-fly, tanpa disimpan)** — helper baru di `recurrence.dart`:
`List<DateTime> upcomingOccurrences(Task task, {required DateTime until, int maxCount = 60})`
yang, untuk sebuah occurrence terbuka (`recurrence != none && status != selesai`),
menghasilkan tanggal occurrence berikutnya secara berturut (memakai
`nextOccurrenceDate` sambil menaikkan index bayangan), berhenti pada
`until`/`maxCount`/`endDate`/`count`. Untuk bulan yang tampil, kumpulkan tanggal
preview dari SEMUA seri aktif.

**Gaya titik (senada):**
- Titik preview = **cincin berongga** (`Border.all(color: AppTheme.primary, width: 1.2)`,
  center transparan), diameter ~6px, TANPA latar sel — terbaca "tentatif/direncanakan".
- **Precedence**: bila suatu hari sudah punya tugas nyata, tampilkan titik solid
  yang sudah ada (tugas nyata menang); cincin preview hanya muncul di hari yang
  belum ada tugas nyata.
- Styling `today`/`selected` yang sudah ada tidak diubah.

Batas aman: `maxCount` mencegah loop tak berujung untuk seri tak terbatas; preview
hanya dihitung untuk rentang bulan yang sedang ditampilkan.

## Keputusan lain (v1)

- **Edit**: hanya mengubah instance saat ini; rule terbawa ke occurrence
  berikutnya. Dialog "occurrence ini vs semua" ditunda ke v2.
- **Hapus**: menghapus instance itu saja. Karena spawn hanya terjadi saat
  selesai, menghapus satu-satunya occurrence terbuka menghentikan seri. Untuk
  v1 ini perilaku yang diterima; opsi "lewati occurrence ini" eksplisit bisa
  ditambah nanti.
- **Menghentikan seri**: hapus occurrence terbuka, set `recurrence = none` lewat
  edit, atau kondisi `endDate`/`count` tercapai.

## Testing

Sesuai preferensi: penulisan test ditunda ke sesi akhir. Implementasi tetap
diverifikasi dengan `flutter analyze` + uji fungsional di HP (buat tugas berulang,
selesaikan, pastikan occurrence berikutnya lahir dengan deadline benar, badge
muncul, notif tidak dobel). Baseline test suite saat ini +360/-40 (40 gagal
pre-existing) — perubahan tidak boleh menambah kegagalan.

## Berkas yang tersentuh

- `lib/models/task_model.dart` — enum + field + json/copyWith
- `lib/utils/recurrence.dart` (baru) — mesin hitung + label + `upcomingOccurrences`
- `lib/services/task_provider.dart` — `_addTaskObject`, spawn di `editTugas`,
  parameter recurrence di `tambahTugas`/`editTugas`
- `lib/screens/add_edit_task_screen.dart` — section "Pengulangan" + bottom sheet custom
- `lib/widgets/task_card_widget.dart` — badge berulang
- `lib/screens/calendar_screen.dart` — titik preview cincin berongga
- `lib/screens/dashboard_screen.dart` — titik preview di mini-kalender
