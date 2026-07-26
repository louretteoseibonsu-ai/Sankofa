import 'package:flutter/material.dart';
import '../theme.dart';
import 'surface.dart';
import 'tappable_scale.dart';

/// Apple-style squircle card — now with layered ambient depth and a spring
/// press (via [TappableScale]) instead of a flat drop shadow + Material ripple,
/// so every card that uses it feels elevated and tactile.
class FloatingCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  const FloatingCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(18),
  });

  @override
  Widget build(BuildContext context) {
    // Brightness-aware: under a dark theme (e.g. the velvet Tools destinations)
    // the card flips to a velvet surface with a hairline; light usages elsewhere
    // are untouched.
    final dark = Theme.of(context).brightness == Brightness.dark;
    final card = DecoratedBox(
      decoration: ShapeDecoration(
        color: dark ? const Color(0xFF211B17) : surfaceCard,
        shape: dark
            ? const ContinuousRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(30)),
                side: BorderSide(color: Colors.white10),
              )
            : kSquircleCard,
        shadows: kAmbientShadow,
      ),
      child: Padding(padding: padding, child: child),
    );
    if (onTap == null) return card;
    return TappableScale(onTap: onTap, child: card);
  }
}
