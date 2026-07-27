import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../data/avatar.dart';
import '../services/sound_service.dart';
import '../theme.dart';
import 'animations.dart' show celebrateBurst;
import 'avatar_badge.dart';
import 'tappable_scale.dart';
import 'velvet.dart';

/// The family-avatar "Stage Clear" celebration. Plays the equipped character's
/// looping celebration video clip (assets/celebrations/celebrate_<id>.mp4 —
/// sliced from the promo reel) over a velvet stage with a confetti burst, an
/// "Ayɛkoo!" headline and a Continue button. If the clip can't load it falls
/// back to the sculpted avatar portrait so the flow never blocks.
///
/// Plays over the current screen via an [OverlayEntry] and completes when done.
class FamilyCelebration {
  const FamilyCelebration._();

  static Future<void> play(
    BuildContext context, {
    required Avatar avatar,
    int stars = 1,
    VoidCallback? onDone,
  }) {
    final overlay = Overlay.of(context);
    final completer = Completer<void>();
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _FamilyCelebrationView(
        avatar: avatar,
        stars: stars.clamp(1, 3),
        onFinished: () {
          entry.remove();
          onDone?.call();
          if (!completer.isCompleted) completer.complete();
        },
      ),
    );
    overlay.insert(entry);
    return completer.future;
  }
}

class _FamilyCelebrationView extends StatefulWidget {
  final Avatar avatar;
  final int stars;
  final VoidCallback onFinished;
  const _FamilyCelebrationView({
    required this.avatar,
    required this.stars,
    required this.onFinished,
  });

  @override
  State<_FamilyCelebrationView> createState() => _FamilyCelebrationViewState();
}

class _FamilyCelebrationViewState extends State<_FamilyCelebrationView>
    with TickerProviderStateMixin {
  late final AnimationController _intro; // scrim + frame bloom
  late final AnimationController _breathe; // Continue-button pulse
  VideoPlayerController? _video;
  bool _videoReady = false;
  bool _burst = false;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 620))
      ..addListener(() {
        if (mounted) setState(() {});
      })
      ..forward();
    _breathe = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2400))
      ..repeat(reverse: true);
    HapticFeedback.selectionClick();
    _initVideo();
    // Celebrate immediately — don't wait on the video decoder.
    WidgetsBinding.instance.addPostFrameCallback((_) => _celebrate());
  }

  Future<void> _initVideo() async {
    final clip = 'assets/celebrations/celebrate_${widget.avatar.id}.mp4';
    final c = VideoPlayerController.asset(clip);
    _video = c;
    try {
      await c.initialize();
      await c.setLooping(true);
      await c.setVolume(0); // the app's own SFX carry the moment
      await c.play();
      if (mounted) setState(() => _videoReady = true);
    } catch (_) {
      // Plugin/asset unavailable — the portrait fallback renders instead.
      if (mounted) setState(() {});
    }
  }

  void _celebrate() {
    if (_burst || !mounted) return;
    _burst = true;
    SoundService.instance.complete();
    HapticFeedback.mediumImpact();
    celebrateBurst(context, particles: 36);
  }

  @override
  void dispose() {
    _video?.dispose();
    _intro.dispose();
    _breathe.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Curves.easeOut.transform(_intro.value);
    final bloom = Curves.easeOutBack.transform(_intro.value);
    final v = _video;
    final aspect =
        (_videoReady && v != null) ? v.value.aspectRatio : (480 / 556);

    return Stack(
      children: [
        Positioned.fill(
          child: Opacity(
            opacity: t,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [kVelvetTop, kVelvetBottom],
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(child: FocalGlow(color: kOchre)),
        ),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Stars earned.
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < widget.stars; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.3, end: 1.0),
                        duration: Duration(milliseconds: 420 + i * 170),
                        curve: Curves.elasticOut,
                        builder: (_, s, child) =>
                            Transform.scale(scale: s, child: child),
                        child: Icon(Icons.star_rounded,
                            size: i == 1 ? 56 : 44,
                            color: const Color(0xFFFFC02E)),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              // Celebration clip (or portrait fallback) in a glowing frame.
              Transform.scale(
                scale: 0.7 + 0.3 * bloom.clamp(0.0, 1.2),
                child: SizedBox(
                  width: 300,
                  child: AspectRatio(
                    aspectRatio: aspect,
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(22)),
                        boxShadow: [
                          BoxShadow(
                              color: Color(0x66E3A92C),
                              blurRadius: 48,
                              spreadRadius: 4),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: (_videoReady && v != null)
                            ? VideoPlayer(v)
                            : ColoredBox(
                                color: const Color(0xFF1B1613),
                                child: Center(
                                  child: Image.asset(
                                    widget.avatar.assetReference,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => AvatarBadge(
                                        avatar: widget.avatar,
                                        size: 150,
                                        selected: true),
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Ayɛkoo!',
                  style: displayFont(
                      fontSize: 40,
                      fontWeight: FontWeight.w700,
                      color: kVelvetInk)),
              const SizedBox(height: 4),
              Text('WELL DONE · STAGE CLEAR',
                  style: microLabel(color: kOchre)),
              const SizedBox(height: 26),
              AnimatedBuilder(
                animation: _breathe,
                builder: (_, child) => Transform.scale(
                    scale: 1.0 + 0.05 * _breathe.value, child: child),
                child: TappableScale(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    SoundService.instance.tap();
                    widget.onFinished();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 54, vertical: 15),
                    decoration: BoxDecoration(
                      color: terracotta,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: const Text('Continue',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 17)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
