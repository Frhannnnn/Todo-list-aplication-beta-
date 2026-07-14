// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'services/task_provider.dart';
import 'utils/app_theme.dart';
import 'screens/dashboard_screen.dart';
import 'screens/task_list_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/priority_screen.dart';
import 'screens/schedule_screen.dart';
import 'screens/settings_screen.dart';

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
    return ChangeNotifierProvider(
      create: (_) => TaskProvider(),
      child: MaterialApp(
        title: 'TugasKu',
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

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation>
    with WidgetsBindingObserver {
  final List<Widget> _screens = const [
    DashboardScreen(),
    TaskListScreen(),
    ScheduleScreen(),
    CalendarScreen(),
    PriorityScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    MainNavigation.tabIndex.addListener(_onTabIndexChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    MainNavigation.tabIndex.removeListener(_onTabIndexChanged);
    super.dispose();
  }

  void _onTabIndexChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<TaskProvider>().refreshUrgensi();
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
            _navItem(2, Icons.schedule_outlined, Icons.schedule, 'Jadwal'),
            _navItem(3, Icons.calendar_month_outlined, Icons.calendar_month, 'Kalender'),
            _navItem(4, Icons.psychology_outlined, Icons.psychology, 'Prioritas'),
            _navItem(5, Icons.person_outline_rounded, Icons.person_rounded, 'Profil'),
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
