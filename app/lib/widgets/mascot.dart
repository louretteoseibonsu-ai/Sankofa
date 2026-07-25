import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'tintable_trotro.dart';

/// Which visual register the mascot is in.
enum MascotMode {
  /// The canonical, recolourable layered bus — used for ALL continuous motion
  /// (map drive, rally lanes, garage preview, Ananse pull-up). Reflects the
  /// player's body colour + equipped cosmetics.
  driving,

  /// A discrete Midjourney "hero" frame, reserved for the finish-line / ta-da
  /// beat only. A branded victory pose — by design it does NOT reflect body
  /// colour, keeping that distinct celebration energy without the masking
  /// pipeline. Continuous surfaces never use this register.
  celebrating,
}

/// Per-frame motion for the canonical bus, applied as a SINGLE RIGID SPRITE:
/// whole-body translate / rotate / squash (never part-cutting — that's the
/// "wheel-arch saga" trap). All defaults are identity, i.e. a still bus.
@immutable
class MascotPose {
  /// Lean, in radians (+ tilts nose-up / into acceleration).
  final double tilt;

  /// Upward bob, in logical pixels (bottom-anchored, so the wheels stay planted).
  final double bob;

  /// Horizontal / vertical squash-and-stretch (1.0 = neutral).
  final double squashX;
  final double squashY;

  /// Motion-blur sigma (0 = crisp).
  final double blur;

  const MascotPose({
    this.tilt = 0,
    this.bob = 0,
    this.squashX = 1,
    this.squashY = 1,
    this.blur = 0,
  });

  /// A still, upright bus — the default for every continuous surface until real
  /// drive motion is fed in (Commit 4).
  static const MascotPose idle = MascotPose();
}

/// The one mascot the whole app renders.
///
/// Continuous surfaces pass [MascotMode.driving] — the recolourable layered bus
/// ([TintableTroTro]) transformed by a [MascotPose]. The finish line passes
/// [MascotMode.celebrating] with a [celebrationFrame] (a Midjourney hero PNG).
///
/// An [AnimatedSwitcher] cross-fades the two registers — and successive
/// celebration frames — on a KEY change, while the heavy, cacheable layer stack
/// stays parked in the switcher's child slot (built once, animated cheaply).
/// A steady [pose] never changes the child key, so per-frame drive motion just
/// updates the wrapping [Transform] with no image re-decode and no transition.
class Mascot extends StatelessWidget {
  final Color bodyColor;

  /// Equipped cosmetic ids by category (e.g. {'kente': 'kente_goldgreen'}).
  final Map<String, String> equipped;
  final double width;

  final MascotMode mode;
  final MascotPose pose;

  /// The illustrated hero frame to show in [MascotMode.celebrating]
  /// (e.g. 'assets/mascot/stageclear/trotro_tada.png'). Ignored while driving.
  final String? celebrationFrame;

  const Mascot({
    super.key,
    required this.bodyColor,
    this.equipped = const {},
    this.width = 160,
    this.mode = MascotMode.driving,
    this.pose = MascotPose.idle,
    this.celebrationFrame,
  });

  // Midjourney celebration frame source aspect (560×420).
  static const double _celebAspect = 560 / 420;

  @override
  Widget build(BuildContext context) {
    final celebrating =
        mode == MascotMode.celebrating && celebrationFrame != null;

    final Widget child = celebrating
        ? SizedBox(
            key: ValueKey<String>('celeb:$celebrationFrame'),
            width: width,
            height: width / _celebAspect,
            child: Image.asset(
              celebrationFrame!,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
              // If a frame is missing, fail silent rather than throw.
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          )
        : _canonical();

    return RepaintBoundary(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: child,
      ),
    );
  }

  /// The canonical recolourable bus wrapped in the pose transform. A constant
  /// ValueKey('canonical') means every pose update is treated as the SAME child
  /// by the [AnimatedSwitcher] — so only the [Transform] changes per frame, the
  /// layer stack is never rebuilt, and there's no re-decode.
  Widget _canonical() {
    Widget bus = TintableTroTro(
      bodyColor: bodyColor,
      equipped: equipped,
      width: width,
    );
    if (pose.blur > 0) {
      bus = ImageFiltered(
        imageFilter: ui.ImageFilter.blur(sigmaX: pose.blur, sigmaY: 0.001),
        child: bus,
      );
    }
    return Transform(
      key: const ValueKey<String>('canonical'),
      alignment: Alignment.bottomCenter,
      transform: Matrix4.identity()
        ..translate(0.0, -pose.bob)
        ..rotateZ(pose.tilt)
        ..scale(pose.squashX, pose.squashY),
      child: bus,
    );
  }
}
