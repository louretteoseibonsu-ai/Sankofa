import 'package:flutter/material.dart';
import '../config.dart';
import '../data/pedi_packs.dart';
import '../services/currency_service.dart';
import '../services/progress_service.dart';
import '../theme.dart';
import 'velvet.dart';

const Color _gold = Color(0xFFE3A92C);

/// Opens the pedis store. Returns the number of pedis purchased (0 if none).
Future<int> showPedisStore(BuildContext context, {int currentPedis = 0}) async {
  return await showModalBottomSheet<int>(
        context: context,
        isScrollControlled: true,
        backgroundColor: const Color(0xFF1E1A17),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) => _PedisStoreSheet(currentPedis: currentPedis),
      ) ??
      0;
}

class _PedisStoreSheet extends StatefulWidget {
  final int currentPedis;
  const _PedisStoreSheet({required this.currentPedis});

  @override
  State<_PedisStoreSheet> createState() => _PedisStoreSheetState();
}

class _PedisStoreSheetState extends State<_PedisStoreSheet> {
  bool _busy = false;

  Future<void> _buy(PediPack pack) async {
    if (!kBillingEnabled) return; // stubbed until a payment gateway is wired
    setState(() => _busy = true);
    // TODO: launch in_app_purchase, verify the receipt server-side, THEN:
    await ProgressService().addPedis(pack.pedis);
    if (!mounted) return;
    setState(() => _busy = false);
    Navigator.of(context).pop(pack.pedis);
  }

  @override
  Widget build(BuildContext context) {
    final cur = CurrencyService.instance;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('🌿', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                const Text('Get pedis',
                    style: TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 20, color: kVelvetInk)),
                const Spacer(),
                Text('Balance: ${widget.currentPedis}',
                    style: const TextStyle(
                        color: kVelvetMuted, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 12),
            for (final pack in kPediPacks)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF211B17),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: pack.tag == 'Best value' ? _gold : Colors.white10,
                        width: pack.tag == 'Best value' ? 2 : 1),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.spa, color: plantainGreen, size: 22),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${pack.pedis} pedis',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: kVelvetInk)),
                          if (pack.tag != null)
                            Text(pack.tag!,
                                style: const TextStyle(
                                    color: Color(0xFF63C583),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11)),
                        ],
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed:
                            (kBillingEnabled && !_busy) ? () => _buy(pack) : null,
                        child: Text(cur.format(pack.eur)),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
            const Text('Spend pedis on:',
                style: TextStyle(
                    color: kVelvetMuted, fontWeight: FontWeight.w700, fontSize: 12)),
            const SizedBox(height: 6),
            for (final use in kPediUses)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('· ', style: TextStyle(color: kVelvetMuted)),
                    Expanded(
                        child: Text(use,
                            style: const TextStyle(
                                color: kVelvetMuted, fontSize: 12.5, height: 1.3))),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            if (!kBillingEnabled)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: const Color(0xFF2A2113),
                    borderRadius: BorderRadius.circular(12)),
                child: const Text(
                    'Buying pedis launches with paid plans — coming soon. '
                    'For now, earn pedis through lessons, streaks and Lens finds.',
                    style: TextStyle(
                        color: Color(0xFFE3C77A),
                        fontSize: 12,
                        height: 1.4,
                        fontWeight: FontWeight.w600)),
              ),
            const SizedBox(height: 8),
            Text(
                'Prices shown for your region (${cur.code}); charged in your '
                'app-store currency. Pedis are virtual items with no cash value.',
                style: const TextStyle(color: kVelvetMuted, fontSize: 11, height: 1.4)),
          ],
        ),
      ),
    );
  }
}
