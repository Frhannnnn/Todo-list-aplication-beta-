import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tugasku/models/task_model.dart';
import 'package:tugasku/services/task_provider.dart';

import '../mocks/mock_notification_service.dart';

/// Tes persistensi: memastikan data yang disimpan TaskProvider benar-benar
/// bisa dimuat kembali oleh instance baru (mensimulasikan aplikasi ditutup
/// lalu dibuka lagi), dan data rusak tidak membuat aplikasi crash.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Buat provider baru yang membaca ulang dari penyimpanan — mensimulasikan
  /// aplikasi dijalankan ulang.
  Future<TaskProvider> reload() async {
    final provider = TaskProvider(notifService: MockNotificationService());
    await provider.init();
    return provider;
  }

  group('TaskProvider - Persistensi Data', () {
    late TaskProvider provider;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      provider = TaskProvider(notifService: MockNotificationService());
      await provider.init();
    });

    group('Persistensi Tugas', () {
      test('tugas yang disimpan terbaca kembali oleh instance baru', () async {
        await provider.tambahTugas(
          namaTugas: 'Tugas Persisten',
          lingkupTugas: 'Perkuliahan',
          deadline: DateTime.now().add(const Duration(days: 1)),
          tingkatKepentingan: 3,
          estimasiWaktu: 2,
        );
        final id = provider.tasks.first.id;

        final reloaded = await reload();

        expect(reloaded.totalTugas, 1);
        expect(reloaded.tasks.first.id, id);
        expect(reloaded.tasks.first.namaTugas, 'Tugas Persisten');
        expect(reloaded.tasks.first.lingkupTugas, 'Perkuliahan');
      });

      test('banyak tugas tersimpan tanpa ada yang hilang', () async {
        const jumlah = 15;
        for (var i = 0; i < jumlah; i++) {
          await provider.tambahTugas(
            namaTugas: 'Tugas $i',
            lingkupTugas: 'Perkuliahan',
            deadline: DateTime.now().add(Duration(days: i + 1)),
            tingkatKepentingan: (i % 5) + 1,
            estimasiWaktu: (i % 4) + 1,
          );
        }

        final reloaded = await reload();

        expect(reloaded.totalTugas, jumlah);
        final nama = reloaded.tasks.map((t) => t.namaTugas).toSet();
        for (var i = 0; i < jumlah; i++) {
          expect(nama, contains('Tugas $i'));
        }
      });

      test('penyimpanan kosong menghasilkan daftar kosong', () async {
        final reloaded = await reload();
        expect(reloaded.totalTugas, 0);
        expect(reloaded.tasks, isEmpty);
      });

      test('menghapus tugas juga terhapus di penyimpanan', () async {
        await provider.tambahTugas(
          namaTugas: 'Akan Dihapus',
          lingkupTugas: 'Perkuliahan',
          deadline: DateTime.now().add(const Duration(days: 1)),
          tingkatKepentingan: 3,
          estimasiWaktu: 2,
        );
        await provider.hapusTugas(provider.tasks.first.id);

        final reloaded = await reload();
        expect(reloaded.totalTugas, 0);
      });

      test('perubahan status ikut tersimpan', () async {
        await provider.tambahTugas(
          namaTugas: 'Tugas Status',
          lingkupTugas: 'Perkuliahan',
          deadline: DateTime.now().add(const Duration(days: 2)),
          tingkatKepentingan: 3,
          estimasiWaktu: 2,
        );
        await provider.updateStatus(
            provider.tasks.first.id, TaskStatus.selesai);

        final reloaded = await reload();
        expect(reloaded.tasks.first.status, TaskStatus.selesai);
      });

      test('field pengulangan bertahan setelah dimuat ulang', () async {
        await provider.tambahTugas(
          namaTugas: 'Tugas Berulang',
          lingkupTugas: 'Perkuliahan',
          deadline: DateTime.now().add(const Duration(days: 1)),
          tingkatKepentingan: 3,
          estimasiWaktu: 2,
          recurrence: RecurrenceType.weekly,
        );

        final reloaded = await reload();
        expect(reloaded.tasks.first.recurrence, RecurrenceType.weekly);
      });

      test('clearAllTasks mengosongkan penyimpanan secara permanen', () async {
        await provider.tambahTugas(
          namaTugas: 'Tugas A',
          lingkupTugas: 'Perkuliahan',
          deadline: DateTime.now().add(const Duration(days: 1)),
          tingkatKepentingan: 3,
          estimasiWaktu: 2,
        );

        final berhasil = await provider.clearAllTasks();
        expect(berhasil, isTrue);

        final reloaded = await reload();
        expect(reloaded.totalTugas, 0);
      });
    });

    group('Persistensi Lingkup & Kategori', () {
      test('lingkup buatan pengguna tersimpan', () async {
        await provider.addScope('Organisasi');

        final reloaded = await reload();
        expect(reloaded.customScopes, contains('Organisasi'));
      });

      test('kategori tersimpan pada lingkupnya sendiri', () async {
        await provider.addScope('Organisasi');
        await provider.addCategoryToScope('Organisasi', 'Rapat');

        final reloaded = await reload();
        expect(reloaded.categoriesForScope('Organisasi'), contains('Rapat'));
      });

      test('kategori satu lingkup tidak bocor ke lingkup lain', () async {
        await provider.addScope('Organisasi');
        await provider.addCategoryToScope('Organisasi', 'Rapat');

        final reloaded = await reload();
        expect(
          reloaded.categoriesForScope('Perkuliahan'),
          isNot(contains('Rapat')),
        );
      });
    });

    group('Persistensi Pengaturan Notifikasi', () {
      test('sakelar notifikasi global tersimpan', () async {
        await provider.setNotifEnabled(false);

        final reloaded = await reload();
        expect(reloaded.notifEnabled, isFalse);
      });

      test('pengingat harian beserta jamnya tersimpan', () async {
        await provider.setDailyReminder(enabled: true, hour: 21, minute: 30);

        final reloaded = await reload();
        expect(reloaded.dailyReminderEnabled, isTrue);
        expect(reloaded.dailyReminderHour, 21);
        expect(reloaded.dailyReminderMinute, 30);
      });
    });

    group('Persistensi Waktu Cadangan', () {
      test('belum pernah dicadangkan bernilai null', () async {
        expect(provider.lastBackupAt, isNull);
      });

      test('markBackupDone tersimpan dan terbaca kembali', () async {
        await provider.markBackupDone();
        expect(provider.lastBackupAt, isNotNull);

        final reloaded = await reload();
        expect(reloaded.lastBackupAt, isNotNull);
      });
    });

    group('Ketahanan Terhadap Data Rusak', () {
      test('JSON rusak tanpa cadangan menghasilkan daftar kosong, bukan crash',
          () async {
        SharedPreferences.setMockInitialValues({
          'tugasku_tasks': 'ini bukan json }{',
        });

        final reloaded = await reload();
        expect(reloaded.totalTugas, 0);
      });

      test('JSON rusak dipulihkan dari cadangan bila tersedia', () async {
        final cadangan = jsonEncode([
          Task(
            id: 'task-cadangan',
            namaTugas: 'Tugas Dari Cadangan',
            lingkupTugas: 'Perkuliahan',
            deadline: DateTime.now().add(const Duration(days: 3)),
            tingkatKepentingan: 4,
            estimasiWaktu: 2,
            createdAt: DateTime.now(),
          ).toJson(),
        ]);

        SharedPreferences.setMockInitialValues({
          'tugasku_tasks': 'rusak }{',
          'tugasku_tasks_backup': cadangan,
        });

        final reloaded = await reload();
        expect(reloaded.totalTugas, 1);
        expect(reloaded.tasks.first.namaTugas, 'Tugas Dari Cadangan');
      });

      test('data jadwal rusak tidak menggagalkan pemuatan tugas', () async {
        SharedPreferences.setMockInitialValues({
          'tugasku_schedule_blocks': 'rusak }{',
          'tugasku_schedule_config': 'rusak }{',
        });

        final reloaded = await reload();
        expect(reloaded.totalTugas, 0);
        expect(reloaded.timeBlocks, isEmpty);
      });
    });
  });
}
