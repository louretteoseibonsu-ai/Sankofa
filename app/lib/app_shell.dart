import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'widgets/app_avatar.dart';
import 'widgets/greeting.dart';
import 'widgets/kente_pattern.dart';
import 'screens/profile_screen.dart';
import 'screens/journey_screen.dart';
import 'screens/translate_screen.dart';
import 'screens/lens_screen.dart';
import 'screens/progress_dashboard_screen.dart';
import 'screens/tools_hub_screen.dart';

class _Dest {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  const _Dest(this.label, this.icon, this.selectedIcon);
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0; // land on the Journey — the gamified daily hub

  static const _dest = [
    _Dest('Journey', Icons.route_outlined, Icons.route),
    _Dest('Translate', Icons.translate, Icons.translate),
    _Dest('Lens', Icons.center_focus_strong_outlined,
        Icons.center_focus_strong),
    _Dest('Progress', Icons.insights_outlined, Icons.insights),
    _Dest('Tools', Icons.apps_outlined, Icons.apps),
  ];

  static const _screens = [
    JourneyScreen(),
    TranslateScreen(),
    LensScreen(),
    ProgressDashboardScreen(),
    ToolsHubScreen(),
  ];

  void _select(int i) {
    HapticFeedback.selectionClick();
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 60,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 16,
        flexibleSpace: const KenteHeaderBackground(),
        // Home (Journey) greets the user by name; other tabs show their label.
        // Dark scrim behind the title so white text stays legible over any
        // colour in the kente banner.
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xCC1A1A1A),
            borderRadius: BorderRadius.circular(12),
          ),
          child: _index == 0
              ? const GreetingTitle()
              : Text(
                  _dest[_index].label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                      color: Colors.white),
                ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: StreamBuilder<User?>(
              stream: FirebaseAuth.instance.userChanges(),
              builder: (context, snapshot) {
                return GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                        builder: (_) => const ProfileScreen()),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(2.5),
                    decoration: const BoxDecoration(
                        color: Colors.white, shape: BoxShape.circle),
                    child: AppAvatar(
                        user: FirebaseAuth.instance.currentUser, radius: 16),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: IndexedStack(index: _index, children: _screens),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _select,
        destinations: [
          for (final d in _dest)
            NavigationDestination(
              icon: Icon(d.icon),
              selectedIcon: Icon(d.selectedIcon),
              label: d.label,
            ),
        ],
      ),
    );
  }
}
