import 'package:flutter/material.dart';
import '../services/credits_service.dart';
import '../theme.dart';
import 'velvet.dart';

/// Compact monthly-credits indicator with a top-up shortcut. Shared by the
/// metered features (AI Translate, Sankofa Lens) so the UX stays consistent.
/// Pass [dark] to match the velvet hub.
class CreditsBar extends StatelessWidget {
  final CreditStatus status;
  final String unit; // e.g. 'translate credits', 'Lens scans'
  final Future<void> Function() onBuy;
  final bool dark;
  const CreditsBar({
    super.key,
    required this.status,
    required this.unit,
    required this.onBuy,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    final low = status.remaining <= 3;
    final okAccent = dark ? const Color(0xFF63C583) : plantainGreen;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF211B17) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: low
                ? accentCoral
                : (dark ? Colors.white10 : silverLight),
            width: low ? 1.4 : 1),
      ),
      child: Row(
        children: [
          Icon(Icons.bolt, size: 18, color: low ? accentCoral : okAccent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${status.remaining} $unit left this month'
              '${status.extra > 0 ? ' (+${status.extra} bought)' : ''}',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                  color: dark ? kVelvetInk : ink),
            ),
          ),
          TextButton(
            onPressed: () => onBuy(),
            style: dark
                ? TextButton.styleFrom(foregroundColor: kOchre)
                : null,
            child: const Text('Buy more'),
          ),
        ],
      ),
    );
  }
}
