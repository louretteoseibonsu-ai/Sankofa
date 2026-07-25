import 'package:flutter/material.dart';
import '../theme.dart';
import 'velvet.dart';

/// A centred, on-brand message for the non-happy states — empty lists, load
/// failures, offline. Replaces bare spinners / blank screens with something
/// designed and, when it makes sense, a way out.
class StateMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color accent;
  final bool dark; // light-on-dark for velvet surfaces

  const StateMessage({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
    this.accent = terracotta,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 46, color: accent),
            const SizedBox(height: 14),
            Text(title,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    color: dark ? kVelvetInk : ink)),
            const SizedBox(height: 6),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: dark ? kVelvetMuted : slate,
                    fontSize: 13.5,
                    height: 1.5)),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 18),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
