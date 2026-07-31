import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/currency_service.dart';
import '../theme.dart';
import '../widgets/velvet.dart';
import 'tools_hub_screen.dart' show velvetToolsTheme;
import 'upgrade_screen.dart';

const Color _gold = Color(0xFFE3A92C);

/// One-time post-sign-up step: choose Free or view Premium plans.
class PlanPickerScreen extends StatelessWidget {
  final VoidCallback onDone;
  const PlanPickerScreen({super.key, required this.onDone});

  Future<void> _continueFree(BuildContext context) async {
    await AuthService().markPlanChosen();
    onDone();
  }

  Future<void> _viewPremium(BuildContext context) async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const UpgradeScreen()));
    // Whatever they chose, they've now seen plans — let them into the app.
    await AuthService().markPlanChosen();
    onDone();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: velvetToolsTheme(context),
      child: Scaffold(
      backgroundColor: const Color(0xFF17130F),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 12),
            Text('Akwaaba! 🎉',
                textAlign: TextAlign.center,
                style: displayFont(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: kVelvetInk)),
            const SizedBox(height: 4),
            const Text('Choose how you’d like to begin.',
                textAlign: TextAlign.center,
                style: TextStyle(color: kVelvetMuted, fontSize: 14)),
            const SizedBox(height: 22),

            // Premium card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: charcoal,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _gold, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('✦',
                          style: TextStyle(color: _gold, fontSize: 22)),
                      const SizedBox(width: 8),
                      const Text('Premium',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 18)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                            color: _gold,
                            borderRadius: BorderRadius.circular(8)),
                        child: const Text('7-day free trial',
                            style: TextStyle(
                                color: Color(0xFF2B2B2D),
                                fontWeight: FontWeight.w800,
                                fontSize: 11)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                      'Everything: all lessons, 400 AI credits monthly '
                      '(translate, Lens scans & audio — top up with pedis), all '
                      'symbols, no ads. ${CurrencyService.instance.format(6.99)}'
                      '/mo or ${CurrencyService.instance.format(59.99)}/yr.',
                      style: const TextStyle(
                          color: Color(0xFFC9CCD1), height: 1.45)),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                          backgroundColor: _gold,
                          foregroundColor: const Color(0xFF2B2B2D)),
                      onPressed: () => _viewPremium(context),
                      child: const Text('See Premium plans'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Free card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF211B17),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white10, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Free',
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: kVelvetInk)),
                  const SizedBox(height: 6),
                  const Text(
                      'Foundations + Numbers lessons, first 10 Adinkra symbols, '
                      'streaks, and daily quests. Upgrade anytime.',
                      style: TextStyle(color: kVelvetMuted, height: 1.45)),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => _continueFree(context),
                      child: const Text('Start learning — Free'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text('You can switch plans anytime in your profile.',
                  style: TextStyle(color: kVelvetMuted, fontSize: 12)),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
