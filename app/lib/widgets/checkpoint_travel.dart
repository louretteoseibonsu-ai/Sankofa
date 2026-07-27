import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../data/avatar.dart';
import '../data/landmark.dart';
import '../theme.dart';
import 'avatar_badge.dart';
import 'tappable_scale.dart';
import 'velvet.dart';

/// The checkpoint-travel cinematic. Plays your driver's tro tro cruising across
/// a stylized Kente-Modernist map toward the next landmark, then reveals a
/// velvet-dark "new landmark" arrival card. Resolves when the learner taps
/// Continue (i.e. when the map should flip `isTraveling` back to false).
///
/// ```dart
/// await CheckpointTravel.play(context,
///   destination: journey.nextLandmark!, avatar: myAvatar);
/// ```
class CheckpointTravel {
  const CheckpointTravel._();

  static Future<void> play(
    BuildContext context, {
    required Landmark destination,
    required Avatar avatar,
  }) {
    final overlay = Overlay.of(context);
    final completer = Completer<void>();
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _CheckpointTravelView(
        destination: destination,
        avatar: avatar,
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
  final VoidCallback onDone;

  const _CheckpointTravelView({
    required this.destination,
    required this.avatar,
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

  // The equipped character's looping celebration clip — travels as the hero and
  // reappears on the arrival card.
  VideoPlayerController? _clip;
  bool _clipReady = false;

  @override
  void initState() {
    super.initState();
    _initClip();
  }

  Future<void> _initClip() async {
    final c = VideoPlayerController.asset(
        'assets/celebrations/celebrate_${widget.avatar.id}.mp4');
    _clip = c;
    try {
      await c.initialize();
      await c.setLooping(true);
      await c.setVolume(0);
      await c.play();
      if (mounted) setState(() => _clipReady = true);
    } catch (_) {
      if (mounted) setState(() {});
    }
  }

  /// The clip in a gold-glow rounded frame, sized to fit within [maxW]×[maxH]
  /// (falls back to the sculpted portrait if the clip can't load).
  Widget _clipFrame(double maxW, double maxH) {
    final v = _clip;
    final aspect = (_clipReady && v != null) ? v.value.aspectRatio : (480 / 556);
    double w = maxW, h = w / aspect;
    if (h > maxH) {
      h = maxH;
      w = h * aspect;
    }
    return SizedBox(
      width: w,
      height: h,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(18)),
          boxShadow: [
            BoxShadow(
                color: Color(0x55E3A92C), blurRadius: 36, spreadRadius: 2),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: (_clipReady && v != null)
              ? FittedBox(
                  fit: BoxFit.cover,
                  clipBehavior: Clip.hardEdge,
                  child: SizedBox(
                    width: v.value.size.width,
                    height: v.value.size.height,
                    child: VideoPlayer(v),
                  ),
                )
              : ColoredBox(
                  color: const Color(0xFF1B1613),
                  child: Center(
                    child: Image.asset(
                      widget.avatar.assetReference,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => AvatarBadge(
                          avatar: widget.avatar,
                          size: maxH * 0.7,
                          selected: true),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _clip?.dispose();
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
          // The chosen family member celebrates as they travel (world scrolls;
          // the hero bobs centre-stage).
          AnimatedBuilder(
            animation: _scroll,
            builder: (_, __) {
              final bob = 6.0 * math.sin(2 * math.pi * _scroll.value);
              return Transform.translate(
                offset: Offset(0, -bob),
                child: _clipFrame(210, 250),
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
                // The character celebrating the arrival.
                _clipFrame(240, 96),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: SizedBox(
                    height: 124,
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
                const SizedBox(height: 14),
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
