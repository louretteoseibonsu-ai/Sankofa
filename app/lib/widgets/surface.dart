import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'motion.dart';

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

/// A stronger lift for elements that should feel raised off the page — also the
/// target shadow an interactive [AppCard] springs to while pressed.
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
///
/// Pass [onTap] to make it interactive: it springs a slight scale-down AND
/// elevates its shadow ([shadow] → [pressedShadow]) in real time while pressed,
/// then springs back — tactile, physical lift. Non-interactive cards keep the
/// original flat static path.
class AppCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final Color color;
  final Color? borderColor;
  final double borderWidth;
  final List<BoxShadow> shadow;
  final double? width;
  final VoidCallback? onTap;
  final List<BoxShadow> pressedShadow;
  final bool haptic;

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
    this.width,
    this.onTap,
    this.pressedShadow = kRaisedShadow,
    this.haptic = true,
  });

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard>
    with SingleTickerProviderStateMixin {
  // 0 = at rest, 1 = fully pressed. Unbounded so the release can overshoot.
  late final AnimationController _p =
      AnimationController.unbounded(vsync: this)..value = 0.0;

  void _spring(double target, SpringDescription s) =>
      _p.animateWith(SpringSimulation(s, _p.value, target, _p.velocity));

  @override
  void dispose() {
    _p.dispose();
    super.dispose();
  }

  Widget _decorated(List<BoxShadow> shadow, Widget? child) {
    // A faint top-lit sheen: lighten the base at the top, settle to it below.
    final sheen =
        Color.alphaBlend(Colors.white.withValues(alpha: 0.35), widget.color);
    return Container(
      width: widget.width,
      margin: widget.margin,
      padding: widget.padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.radius),
        boxShadow: shadow,
        border: widget.borderColor != null
            ? Border.all(color: widget.borderColor!, width: widget.borderWidth)
            : null,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [sheen, widget.color],
          stops: const [0.0, 0.6],
        ),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onTap == null) return _decorated(widget.shadow, widget.child);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _spring(1.0, kSpringPress),
      onTapCancel: () => _spring(0.0, kSpringRelease),
      onTapUp: (_) {
        _spring(0.0, kSpringRelease);
        if (widget.haptic) HapticFeedback.selectionClick();
        widget.onTap!();
      },
      child: AnimatedBuilder(
        animation: _p,
        child: widget.child,
        builder: (_, child) {
          final e = _p.value.clamp(0.0, 1.0);
          final shadow =
              BoxShadow.lerpList(widget.shadow, widget.pressedShadow, e)!;
          return Transform.scale(
            scale: 1 - 0.02 * e,
            child: _decorated(shadow, child),
          );
        },
      ),
    );
  }
}
