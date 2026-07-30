import 'package:flutter/material.dart';
import '../config.dart';
import '../services/auth_service.dart';
import '../services/currency_service.dart';
import '../theme.dart';
import '../widgets/velvet.dart';
import 'tools_hub_screen.dart' show velvetToolsTheme;

const Color _gold = Color(0xFFE3A92C);

class UpgradeScreen extends StatefulWidget {
  const UpgradeScreen({super.key});

  @override
  State<UpgradeScreen> createState() => _UpgradeScreenState();
}

class _UpgradeScreenState extends State<UpgradeScreen> {
  final _auth = AuthService();
  bool _annual = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    CurrencyService.instance.ensureLoaded().then((_) {
      if (mounted) setState(() {});
    });
  }

  static const _perks = [
    'Every lesson & category — all 23+ units',
    'All 62 Adinkra symbols + detail sheets',
    '400 AI credits / month — translate, Lens scans & audio',
    'Top up anytime with pedis',
    'Unlimited quizzes & hearts',
    'League seasons & full leaderboard',
    'Premium Ananse avatar + rare skins',
    'No ads',
  ];

  Future<void> _subscribe() async {
    if (!kBillingEnabled) return; // stubbed until a payment gateway is wired
    setState(() => _busy = true);
    // TODO: launch in_app_purchase, verify the receipt server-side, THEN:
    await _auth.setPremium(true);
    if (!mounted) return;
    setState(() => _busy = false);
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final cur = CurrencyService.instance;
    final price = cur.format(_annual ? 59.99 : 6.99);
    final per = _annual ? '/year' : '/month';
    final sub = _annual
        ? 'save ~28%  ·  ${cur.format(59.99 / 12)} / month'
        : 'billed monthly';

    return Theme(
      data: velvetToolsTheme(context),
      child: Scaffold(
      appBar: AppBar(title: const Text('Go Premium')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Container(
              width: 84,
              height: 84,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: charcoal,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _gold, width: 3),
              ),
              child: const Text('✦', style: TextStyle(color: _gold, fontSize: 40)),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Sankofa Premium',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 24, color: kVelvetInk)),
          const SizedBox(height: 4),
          const Text('Unlock the full journey to fluency.',
              textAlign: TextAlign.center,
              style: TextStyle(color: kVelvetMuted, fontSize: 14)),
          const SizedBox(height: 18),

          // 7-day trial banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2113),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _gold.withValues(alpha: 0.4)),
            ),
            child: const Row(
              children: [
                Text('🎁', style: TextStyle(fontSize: 18)),
                SizedBox(width: 10),
                Expanded(
                  child: Text('Start with a 7-day free trial — cancel anytime.',
                      style: TextStyle(
                          color: _gold,
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Plan toggle
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('Annual')),
              ButtonSegment(value: false, label: Text('Monthly')),
            ],
            selected: {_annual},
            onSelectionChanged: (s) => setState(() => _annual = s.first),
          ),
          const SizedBox(height: 16),

          // Premium price card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF211B17),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _gold, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(price,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 30,
                            color: kVelvetInk)),
                    const SizedBox(width: 4),
                    Text(per,
                        style: const TextStyle(color: kVelvetMuted, fontSize: 15)),
                    const Spacer(),
                    if (_annual)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                            color: const Color(0xFF17281C),
                            borderRadius: BorderRadius.circular(8)),
                        child: const Text('Best value',
                            style: TextStyle(
                                color: Color(0xFF63C583),
                                fontWeight: FontWeight.w800,
                                fontSize: 11)),
                      ),
                  ],
                ),
                Text(sub, style: const TextStyle(color: kVelvetMuted, fontSize: 12)),
                const SizedBox(height: 14),
                for (final p in _perks)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle,
                            color: Color(0xFF2E6B3B), size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                            child: Text(p,
                                style: const TextStyle(
                                    color: kVelvetInk, fontSize: 13.5, height: 1.35))),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: (kBillingEnabled && !_busy) ? _subscribe : null,
              child: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text(kBillingEnabled
                      ? 'Start 7-day free trial'
                      : 'Subscriptions coming soon'),
            ),
          ),
          if (!kBillingEnabled) ...[
            const SizedBox(height: 8),
            const Center(
              child: Text('Payment plans launch soon — check back shortly.',
                  style: TextStyle(color: kVelvetMuted, fontSize: 12)),
            ),
          ],
          const SizedBox(height: 10),
          Center(
            child: TextButton(
              onPressed: () {},
              child: const Text('Restore purchases'),
            ),
          ),
          const SizedBox(height: 8),
          Text(
              'Prices shown for your region (${CurrencyService.instance.code}); '
              'the final charge is made in your app-store currency. After the '
              '7-day trial, your subscription renews automatically until '
              'cancelled — manage anytime in your app-store account settings.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: kVelvetMuted, fontSize: 11, height: 1.4)),
          const SizedBox(height: 24),
        ],
      ),
    ));
  }
}
