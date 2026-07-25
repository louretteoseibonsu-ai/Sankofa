import 'package:flutter/material.dart';

/// ── Depth system ─────────────────────────────────────────────────────────────
/// Multi-layer ambient elevation: a tight contact shadow, a soft ambient bloom,
/// and a faint wide halo — atmospheric depth instead of one hard drop shadow.
const List<BoxShadow> kAmbientShadow = [
  BoxShadow(color: Color(0x0F000000), blurRadius: 2, offset: Offset(0, 1)),
  BoxShadow(
      color: Color(0x14000000),
      blurRadius: 16,
      spreadRadius: -2,
      offset: Offset(0, 8)),
  BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 40,
      spreadRadius: -4,
      offset: Offset(0, 20)),
];

/// A stronger lift for elements that should feel raised off the page.
const List<BoxShadow> kRaisedShadow = [
  BoxShadow(color: Color(0x14000000), blurRadius: 3, offset: Offset(0, 1)),
  BoxShadow(
      color: Color(0x1F000000),
      blurRadius: 28,
      spreadRadius: -4,
      offset: Offset(0, 14)),
  BoxShadow(
      color: Color(0x12000000),
      blurRadius: 60,
      spreadRadius: -8,
      offset: Offset(0, 34)),
];

/// A soft, elevated surface: rounded, layered ambient shadow, a barely-there top
/// sheen (top→base gradient) for tactility, and an optional hairline accent
/// instead of a hard border. The modern default for cards across the app.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final Color color;
  final Color? borderColor;
  final double borderWidth;
  final List<BoxShadow> shadow;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.radius = 20,
    this.color = Colors.white,
    this.borderColor,
    this.borderWidth = 1.5,
    this.shadow = kAmbientShadow,
  });

  @override
  Widget build(BuildContext context) {
    // A faint top-lit sheen: lighten the base at the top, settle to it at the
    // bottom. Using a gradient (not a flat color) is what reads as "surface".
    final sheen = Color.alphaBlend(Colors.white.withValues(alpha: 0.35), color);
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: shadow,
        border: borderColor != null
            ? Border.all(color: borderColor!, width: borderWidth)
            : null,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [sheen, color],
          stops: const [0.0, 0.6],
        ),
      ),
      child: child,
    );
  }
}
