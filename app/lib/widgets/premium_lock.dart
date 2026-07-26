import 'package:flutter/material.dart';
import '../screens/upgrade_screen.dart';
import '../theme.dart';
import 'velvet.dart';

const Color _gold = Color(0xFFE3A92C);

/// Full-screen "this is premium" gate with an upgrade call-to-action.
/// Pass [dark] to sit seamlessly inside the velvet hub.
class PremiumLock extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final bool dark;
  const PremiumLock({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.lock,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    final gate = Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: dark ? const Color(0xFF211B17) : charcoal,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: _gold, width: 3),
              ),
              child: Icon(icon, color: _gold, size: 34),
            ),
            const SizedBox(height: 18),
            Text(title,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    color: dark ? kVelvetInk : ink)),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: dark ? kVelvetMuted : slate,
                    height: 1.5,
                    fontSize: 14)),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const UpgradeScreen())),
                icon: const Icon(Icons.workspace_premium, size: 18),
                label: const Text('Go Premium'),
              ),
            ),
          ],
        ),
      ),
    );
    if (!dark) return gate;
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF17130F), Color(0xFF1E1A17)],
        ),
      ),
      child: gate,
    );
  }
}
