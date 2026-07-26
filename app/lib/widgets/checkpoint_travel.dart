import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/avatar.dart';
import '../data/landmark.dart';
import '../theme.dart';
import 'avatar_badge.dart';
import 'mascot.dart';
import 'tappable_scale.dart';
import 'velvet.dart';

/// The checkpoint-travel cinematic. Plays your driver's tro tro cruising across
/// a stylized Kente-Modernist map toward the next landmark, then reveals a
/// velvet-dark "new landmark" arrival card. Resolves when the learner taps
/// Continue (i.e. when the map should flip `isTraveling` back to false).
///
/// ```dart
/// await CheckpointTravel.play(context,
///   destination: journey.nextLandmark!, avatar: myAvatar,
///   bodyColor: myColor, equipped: myEquipped);
/// ```
class CheckpointTravel {
  const CheckpointTravel._();

  static Future<void> play(
    BuildContext context, {
    required Landmark destination,
    required Avatar avatar,
    required Color bodyColor,
    Map<String, String> equipped = const {},
  }) {
    final overlay = Overlay.of(context);
    final completer = Completer<void>();
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _CheckpointTravelView(
        destination: destination,
        avatar: avatar,
        bodyColor: bodyColor,
        equipped: equipped,
        onDone: () {
          entry.remove();
          if (!completer.isCompleted) completer.complete();
        },
      ),
    );
    overlay.insert(entry);
    return completer.future;
  }
}

class _CheckpointTravelView extends StatefulWidget {
  final Landmark destination;
  final Avatar avatar;
  final Color bodyColor;
  final Map<String, String> equipped;
  final VoidCallback onDone;

  const _CheckpointTravelView({
    required this.destination,
    required this.avatar,
    required this.bodyColor,
    required this.equipped,
    required this.onDone,
  });

  @override
  State<_CheckpointTravelView> createState() => _CheckpointTravelViewState();
}

class _CheckpointTravelViewState extends State<_CheckpointTravelView>
    with TickerProviderStateMixin {
  late final AnimationController _scroll = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1400))
    ..repeat();
  late final AnimationController _drive = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2300))
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        HapticFeedback.mediumImpact();
        setState(() => _arrived = true);
      }
    })
    ..forward();
  late final AnimationController _breathe = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2200))
    ..repeat(reverse: true);
  bool _arrived = false;

  @override
  void dispose() {
    _scroll.dispose();
    _drive.dispose();
    _breathe.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.destination.accent;
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [kVelvetTop, kVelvetBottom],
                ),
              ),
            ),
          ),
          Positioned.fill(child: IgnorePointer(child: FocalGlow(color: accent))),
          // Scrolling stylized-map backdrop.
          Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _scroll,
                  builder: (_, __) => CustomPaint(
                    painter: _TravelBackdrop(phase: _scroll.value, accent: accent),
                  ),
                ),
              ),
            ),
          ),
          if (!_arrived) _buildDrive() else _buildArrival(accent),
        ],
      ),
    );
  }

  Widget _buildDrive() {
    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 26),
          Text('TRAVELLING TO', style: microLabel(color: kOchre)),
          const SizedBox(height: 6),
          Text(widget.destination.name,
              textAlign: TextAlign.center,
              style: displayFont(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: kVelvetInk)),
          const Spacer(),
          // The tro tro cruising (world scrolls; bus bobs centre-stage).
          AnimatedBuilder(
            animation: Listenable.merge([_scroll, _drive]),
            builder: (_, __) {
              final bob = 5.0 * math.sin(2 * math.pi * _scroll.value);
              return Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Mascot(
                    bodyColor: widget.bodyColor,
                    equipped: widget.equipped,
                    width: 190,
                    pose: MascotPose(bob: bob, tilt: -0.03),
                  ),
                  Positioned(
                    top: 20,
                    right: 40,
                    child: AvatarBadge(
                        avatar: widget.avatar, size: 40, selected: true),
                  ),
                ],
              );
            },
          ),
          const Spacer(),
          // Progress rail.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: AnimatedBuilder(
              animation: _drive,
              builder: (_, __) => ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: _drive.value,
                  minHeight: 5,
                  backgroundColor: Colors.white12,
                  valueColor: const AlwaysStoppedAnimation(kOchre),
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildArrival(Color accent) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.6, end: 1.0),
          duration: const Duration(milliseconds: 520),
          curve: Curves.elasticOut,
          builder: (_, s, child) => Transform.scale(scale: s, child: child),
          child: AtmosphericPanel(
            glow: accent,
            radius: 26,
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: SizedBox(
                    height: 150,
                    width: double.infinity,
                    child: Image.asset(
                      widget.destination.imageAsset,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => DecoratedBox(
                        decoration: BoxDecoration(color: accent.withValues(alpha: 0.25)),
                        child: Icon(Icons.place_rounded,
                            size: 56, color: Colors.white.withValues(alpha: 0.9)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('NEW LANDMARK', style: microLabel(color: kOchre)),
                const SizedBox(height: 6),
                Text(widget.destination.name,
                    textAlign: TextAlign.center,
                    style: displayFont(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: kVelvetInk,
                        height: 1.05)),
                const SizedBox(height: 4),
                Text(widget.destination.region.toUpperCase(),
                    style: microLabel(color: kVelvetMuted)),
                const SizedBox(height: 22),
                AnimatedBuilder(
                  animation: _breathe,
                  builder: (_, child) => Transform.scale(
                      scale: 1.0 + 0.04 * _breathe.value, child: child),
                  child: TappableScale(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      widget.onDone();
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: terracottaDeep,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Text('Continue',
                          style: displayFont(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Velvet map backdrop: a scrolling dashed road + drifting kente diamonds for
/// parallax depth. [phase] 0..1 loops.
class _TravelBackdrop extends CustomPainter {
  final double phase;
  final Color accent;
  _TravelBackdrop({required this.phase, required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final roadY = h * 0.66;

    // Road band.
    canvas.drawRect(
      Rect.fromLTWH(0, roadY, w, h - roadY),
      Paint()..color = Colors.black.withValues(alpha: 0.25),
    );
    // Scrolling centre dashes.
    const dashW = 46.0, gap = 34.0, step = dashW + gap;
    final off = -phase * step;
    final dash = Paint()..color = kOchre.withValues(alpha: 0.55);
    for (double x = off; x < w; x += step) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(x, roadY + (h - roadY) * 0.5 - 2, dashW, 4),
            const Radius.circular(2)),
        dash,
      );
    }
    // Drifting kente diamonds (two parallax layers) above the road.
    void diamonds(double speed, double y, double s, double alpha, Color c) {
      final o = -(phase * speed) % 1.0;
      for (int i = -1; i < 8; i++) {
        final x = ((i + o) / 7) * w;
        final path = Path()
          ..moveTo(x, y - s)
          ..lineTo(x + s, y)
          ..lineTo(x, y + s)
          ..lineTo(x - s, y)
          ..close();
        canvas.drawPath(path, Paint()..color = c.withValues(alpha: alpha));
      }
    }
    diamonds(1.4, h * 0.30, 10, 0.10, accent);
    diamonds(2.4, h * 0.44, 6, 0.08, kOchre);
  }

  @override
  bool shouldRepaint(covariant _TravelBackdrop old) =>
      old.phase != phase || old.accent != accent;
}
