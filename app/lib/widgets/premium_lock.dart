import 'package:flutter/material.dart';
import '../screens/upgrade_screen.dart';
import '../theme.dart';

const Color _gold = Color(0xFFE3A92C);

/// Full-screen "this is premium" gate with an upgrade call-to-action.
class PremiumLock extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  const PremiumLock({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.lock,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
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
                color: charcoal,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: _gold, width: 3),
              ),
              child: Icon(icon, color: _gold, size: 34),
            ),
            const SizedBox(height: 18),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 20, color: ink)),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: slate, height: 1.5, fontSize: 14)),
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
  }
}
