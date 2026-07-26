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
        // The Kente warp-stripe weave spans the full header (Version 3).
        flexibleSpace: const KenteHeaderBackground(),
        // Home (Journey) greets the user by name; other tabs show their label.
        // A dark pill lifts the text off the busy weave for legibility.
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xE6120E0C),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0x59D4A373)),
          ),
          child: _index == 0
              ? const GreetingTitle()
              : Text(
                  _dest[_index].label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                      color: Color(0xFFF3ECE4)),
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
                        color: Color(0xFFD4A373), shape: BoxShape.circle),
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
