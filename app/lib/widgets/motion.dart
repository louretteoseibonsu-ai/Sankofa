import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

/// ── Spring presets — the app's motion vocabulary ─────────────────────────────
/// Real physics (mass / stiffness / damping ratio) instead of fixed-duration
/// tweens, so interactions carry weight, momentum and settle naturally.

/// Snappy press-down: quick, critically damped, no bounce.
final SpringDescription kSpringPress =
    SpringDescription.withDampingRatio(mass: 0.5, stiffness: 520, ratio: 1.0);

/// Bouncy release: overshoots and settles — the "juice" on let-go.
final SpringDescription kSpringRelease =
    SpringDescription.withDampingRatio(mass: 0.5, stiffness: 400, ratio: 0.5);

/// Weighty travel for position/size changes: momentum, minimal bounce.
final SpringDescription kSpringMove =
    SpringDescription.withDampingRatio(mass: 1.0, stiffness: 170, ratio: 0.9);

/// Animates a single value toward [target] with spring physics, carrying the
/// current velocity when the target changes mid-flight (so retargets feel
/// continuous, never restarted). The [builder] receives the live value.
///
/// Usage — spring an x-offset:
/// ```dart
/// SpringBuilder(
///   target: x,
///   builder: (_, v, child) => Transform.translate(offset: Offset(v, 0), child: child),
///   child: mascot,
/// )
/// ```
class SpringBuilder extends StatefulWidget {
  final double target;
  final SpringDescription? spring;
  final Widget Function(BuildContext context, double value, Widget? child)
      builder;
  final Widget? child;

  const SpringBuilder({
    super.key,
    required this.target,
    required this.builder,
    this.child,
    this.spring,
  });

  @override
  State<SpringBuilder> createState() => _SpringBuilderState();
}

class _SpringBuilderState extends State<SpringBuilder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController.unbounded(vsync: this)..value = widget.target;

  SpringDescription get _spring => widget.spring ?? kSpringMove;

  @override
  void didUpdateWidget(covariant SpringBuilder old) {
    super.didUpdateWidget(old);
    if (old.target != widget.target) {
      _c.animateWith(
          SpringSimulation(_spring, _c.value, widget.target, _c.velocity));
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (context, child) => widget.builder(context, _c.value, child),
        child: widget.child,
      );
}
