// Smoke test: memastikan aplikasi bisa dirakit dan dirender tanpa exception,
// lalu menampilkan Dashboard sebagai tab awal.

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tugasku/main.dart';

void main() {
  testWidgets('Priora app smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await initializeDateFormatting('id_ID', null);

    await tester.pumpWidget(const TugasKuApp());
    await tester.pump();

    // Label tab hanya dirender saat tab itu aktif, dan saat boot tab aktifnya
    // adalah Dashboard — jadi 'Tugas' memang belum tampil di sini.
    expect(find.text('Dashboard'), findsOneWidget);

    // Header brand pada Dashboard.
    expect(find.text('Priora'), findsOneWidget);
  });
}
