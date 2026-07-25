import 'package:flutter/material.dart';
import '../theme.dart';

/// ── Velvet-dark premium system ───────────────────────────────────────────────
/// A high-end "velvet-dark atmosphere" layer for focal / showcase surfaces,
/// keeping the Kente-Modernist identity (terracotta accent, Space Grotesk) but
/// on deep espresso rather than white. Additive — screens opt in.

// Surfaces: a deep-charcoal → dark-espresso vertical mesh (restrained / moody).
const Color kVelvetTop = Color(0xFF131211); // deep charcoal (top)
const Color kVelvetBottom = Color(0xFF1E1A17); // dark espresso (base)
const Color kVelvetInk = Color(0xFFF3ECE4); // warm off-white text
const Color kVelvetMuted = Color(0xFF9B8F86); // muted warm grey

/// The refined secondary accent — a muted, premium ochre/gold for special
/// status highlights and currency tags, striking against the espresso ground.
const Color kOchre = Color(0xFFD4A373);

/// A velvet-dark surface: a subtle vertical mesh gradient, an inner top-edge
/// highlight (the "sculpted" lip), deep ambient drop, and an optional radial
/// focal glow bleeding up behind the content.
class AtmosphericPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? glow; // focal glow colour (e.g. terracotta behind the bus)

  const AtmosphericPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = 24,
    this.glow,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [kVelvetTop, kVelvetBottom],
        ),
        boxShadow: const [
          BoxShadow(
              color: Color(0x66000000),
              blurRadius: 44,
              spreadRadius: -10,
              offset: Offset(0, 26)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          children: [
            if (glow != null)
              Positioned.fill(child: FocalGlow(color: glow!)),
            // Inner top-edge highlight — the sculpted lip that catches light.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: radius * 1.9,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x14FFFFFF), Color(0x00FFFFFF)],
                  ),
                ),
              ),
            ),
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
  }
}

/// A soft, low-opacity radial glow to sit behind a focal point (the mascot,
/// a legendary reward). Bleeds from just above centre.
class FocalGlow extends StatelessWidget {
  final Color color;
  final double intensity;
  const FocalGlow({super.key, required this.color, this.intensity = 0.20});

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.15),
            radius: 0.95,
            colors: [
              color.withValues(alpha: intensity),
              color.withValues(alpha: 0.0),
            ],
          ),
        ),
      );
}

/// Editorial type — a massive, tight-tracked display number (for hero counts).
TextStyle editorialNumber({double fontSize = 44, Color color = kVelvetInk}) =>
    displayFont(
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      color: color,
      letterSpacing: -1.5,
      height: 0.95,
    );

/// Editorial micro-label — ultra-clean, wide-spaced uppercase (Space Grotesk).
TextStyle microLabel({Color color = kVelvetMuted}) => displayFont(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: color,
      letterSpacing: 2.2,
      height: 1.0,
    );
