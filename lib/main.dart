// lib/main.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'services/task_provider.dart';
import 'services/focus_session_provider.dart';
import 'models/task_model.dart';
import 'models/focus_session_model.dart';
import 'utils/app_theme.dart';
import 'screens/dashboard_screen.dart';
import 'screens/task_list_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/priority_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/focus/focus_timer_screen.dart';

/// Kunci global supaya SnackBar bisa ditampilkan dari layar mana pun,
/// termasuk setelah Navigator.pop() berpindah ke layar lain (mis. setelah
/// simpan/hapus tugas dari AddEditTaskScreen kembali ke tab Data Tugas).
final rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const TugasKuApp());
}

class TugasKuApp extends StatelessWidget {
  const TugasKuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => FocusSessionProvider()),
      ],
      child: MaterialApp(
        title: 'Priora',
        debugShowCheckedModeBanner: false,
        scaffoldMessengerKey: rootScaffoldMessengerKey,
        theme: AppTheme.theme,
        home: const MainNavigation(),
      ),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  /// Tab aktif di IndexedStack. Layar lain (mis. AddEditTaskScreen) bisa
  /// memaksa pindah tab sebelum pop, tanpa perlu named routes.
  static final ValueNotifier<int> tabIndex = ValueNotifier<int>(0);

  static const int dashboardTab = 0;
  static const int taskListTab = 1;
  static const int calendarTab = 2;

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation>
    with WidgetsBindingObserver {
  final List<Widget> _screens = const [
    DashboardScreen(),
    TaskListScreen(),
    CalendarScreen(),
    PriorityScreen(),
    SettingsScreen(),
  ];

  Timer? _refreshUrgensiTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    MainNavigation.tabIndex.addListener(_onTabIndexChanged);
    // Issue #10: refresh urgensi/ranking berkala selama app terbuka, supaya
    // label seperti "Masih Aman" tidak basi kalau app dibiarkan terbuka
    // lama. Sengaja jadi tanggung jawab layar (bukan TaskProvider) supaya
    // unit/widget test yang membuat TaskProvider() langsung tanpa memount
    // MainNavigation tidak ikut kena timer yang tidak pernah di-cancel.
    _refreshUrgensiTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => context.read<TaskProvider>().refreshUrgensi(),
    );
    // Hubungkan FocusSessionProvider ke TaskProvider (untuk aksi notifikasi &
    // akumulasi menit fokus tanpa BuildContext), lalu tawarkan melanjutkan
    // sesi fokus yang mungkin terputus.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final focus = context.read<FocusSessionProvider>();
      focus.attachTaskProvider(context.read<TaskProvider>());
      await focus.checkForRestorableSession();
      if (!mounted) return;
      final session = focus.restorableSession;
      if (session != null) _promptResumeFocus(focus, session);
    });
  }

  Future<void> _promptResumeFocus(
      FocusSessionProvider focus, FocusSession session) async {
    // Saat startup, TaskProvider mungkin belum selesai memuat tugas dari
    // penyimpanan. Tunggu hingga tugas terkait muncul (maks ~3 dtk) sebelum
    // memutuskan — kalau tidak, tugas dianggap "hilang" dan sesi terbuang.
    Task? task;
    for (var i = 0; i < 30; i++) {
      for (final t in context.read<TaskProvider>().tasks) {
        if (t.id == session.taskId) {
          task = t;
          break;
        }
      }
      if (task != null) break;
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
    }
    // Tugas benar-benar sudah tidak ada → buang sesi tanpa menawarkan.
    if (task == null) {
      focus.discardRestorableSession();
      return;
    }
    if (!mounted) return;
    final resumeTask = task;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Lanjutkan sesi fokus?'),
        content: Text(
            'Kamu punya sesi fokus yang belum selesai untuk "${resumeTask.namaTugas}".'),
        actions: [
          TextButton(
            onPressed: () {
              focus.discardRestorableSession();
              Navigator.pop(ctx);
            },
            child: const Text('Akhiri'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              focus.resumeRestorableSession();
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => FocusTimerScreen(task: resumeTask)),
              );
            },
            child: const Text('Lanjutkan'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    MainNavigation.tabIndex.removeListener(_onTabIndexChanged);
    _refreshUrgensiTimer?.cancel();
    super.dispose();
  }

  void _onTabIndexChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<TaskProvider>().refreshUrgensi();
      context.read<FocusSessionProvider>().syncFromBackground();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: MainNavigation.tabIndex.value, children: _screens),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppTheme.border.withValues(alpha: 0.5)),
        ),
      ),
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(0, Icons.grid_view_rounded, Icons.grid_view_rounded, 'Dashboard'),
            _navItem(1, Icons.assignment_outlined, Icons.assignment, 'Tugas'),
            _navItem(2, Icons.calendar_month_outlined, Icons.calendar_month, 'Kalender'),
            _navItem(3, Icons.psychology_outlined, Icons.psychology, 'Prioritas'),
            _navItem(4, Icons.person_outline_rounded, Icons.person_rounded, 'Profil'),
          ],
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, IconData activeIcon, String label) {
    final isActive = MainNavigation.tabIndex.value == index;
    return GestureDetector(
      onTap: () => MainNavigation.tabIndex.value = index,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 16 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              size: 22,
              color: isActive ? AppTheme.primary : AppTheme.textSecondary,
            ),
            if (isActive) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
