import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'mascot.dart';
import 'motion.dart';

/// A "living" stage for the canonical [Mascot] (the dumb renderer). It keeps the
/// bus subtly alive with a continuous soft idle bob, and on tap gives it a
/// spring-damped tilt wobble — momentum, not a static state swap. The [Mascot]
/// itself stays stateless; this wrapper just computes a live [MascotPose].
class MascotStage extends StatefulWidget {
  final Color bodyColor;
  final Map<String, String> equipped;
  final double width;
  final VoidCallback? onTap;

  const MascotStage({
    super.key,
    required this.bodyColor,
    this.equipped = const {},
    this.width = 240,
    this.onTap,
  });

  @override
  State<MascotStage> createState() => _MascotStageState();
}

class _MascotStageState extends State<MascotStage>
    with TickerProviderStateMixin {
  late final AnimationController _idle = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2600))
    ..repeat();
  // Unbounded so the tilt can overshoot through zero (a wobble) before settling.
  late final AnimationController _tilt =
      AnimationController.unbounded(vsync: this)..value = 0.0;

  void _poke() {
    HapticFeedback.selectionClick();
    // Kick the tilt and let a bouncy spring carry it back through zero.
    _tilt.animateWith(SpringSimulation(kSpringRelease, 0.16, 0.0, 1.5));
    widget.onTap?.call();
  }

  @override
  void dispose() {
    _idle.dispose();
    _tilt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _poke,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // Grounding contact shadow — a static floor pool so the bus reads as
          // sculpted/planted rather than floating (deepens on velvet-dark).
          Padding(
            padding: EdgeInsets.only(bottom: widget.width * 0.03),
            child: Transform.scale(
              scaleY: 0.26,
              child: Container(
                width: widget.width * 0.60,
                height: widget.width * 0.60,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Color(0x80000000), Color(0x00000000)],
                  ),
                ),
              ),
            ),
          ),
          AnimatedBuilder(
            animation: Listenable.merge([_idle, _tilt]),
            builder: (_, __) {
              final bob = 4.0 * math.sin(2 * math.pi * _idle.value);
              final pose = MascotPose(bob: bob, tilt: _tilt.value);
              return Mascot(
                bodyColor: widget.bodyColor,
                equipped: widget.equipped,
                width: widget.width,
                pose: pose,
              );
            },
          ),
        ],
      ),
    );
  }
}
