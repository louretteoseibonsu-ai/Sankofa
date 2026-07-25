import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'motion.dart';

/// Wrap any tappable widget for a "juicy" press: it springs down to
/// [pressedScale] on tap-down and springs back with a natural overshoot on
/// release — real spring physics (not a fixed-duration tween), so the velocity
/// carries through and rapid taps feel alive. Fires a selection haptic on tap.
class TappableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;
  final bool haptic;

  const TappableScale({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.96,
    this.haptic = true,
  });

  @override
  State<TappableScale> createState() => _TappableScaleState();
}

class _TappableScaleState extends State<TappableScale>
    with SingleTickerProviderStateMixin {
  // Unbounded so the release can overshoot past 1.0 before settling.
  late final AnimationController _c = AnimationController.unbounded(vsync: this)
    ..value = 1.0;

  void _springTo(double target, SpringDescription spring) {
    _c.animateWith(SpringSimulation(spring, _c.value, target, _c.velocity));
  }

  void _press() => _springTo(widget.pressedScale, kSpringPress);
  void _release() => _springTo(1.0, kSpringRelease);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Disabled (no tap) → no press-scale, so it reads as inactive.
    if (widget.onTap == null) return widget.child;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _press(),
      onTapCancel: _release,
      onTapUp: (_) {
        _release();
        if (widget.haptic) HapticFeedback.selectionClick();
        widget.onTap?.call();
      },
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, child) => Transform.scale(scale: _c.value, child: child),
        child: widget.child,
      ),
    );
  }
}
