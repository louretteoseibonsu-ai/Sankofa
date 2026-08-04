import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../data/avatar.dart';
import '../data/family_lines.dart';
import '../services/sound_service.dart';
import '../theme.dart';
import 'animations.dart' show celebrateBurst;
import 'avatar_badge.dart';
import 'kente_pattern.dart';
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
  // A rotating in-character line, picked once so it stays put across rebuilds.
  late final String _line = FamilyLines.celebrate(widget.avatar.id);

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
    // Kick off the Afrobeat groove (fades in) + entrance flourish + confetti.
    SoundService.instance.startCelebrationLoop();
    SoundService.instance.celebrationFanfare();
    HapticFeedback.mediumImpact();
    celebrateBurst(context, particles: 36);
    // A bright pop as each star lands (matches the elastic star timings).
    for (var i = 0; i < widget.stars; i++) {
      Future.delayed(Duration(milliseconds: 360 + i * 170), () {
        if (mounted) SoundService.instance.starPop();
      });
    }
  }

  @override
  void dispose() {
    // Fade the music out cleanly as the screen leaves; the singleton keeps the
    // ramp running after this widget is torn down, so it never cuts abruptly.
    SoundService.instance.stopCelebrationLoop();
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

    // Size the clip to fit — cap height so the headline + CTA are never pushed
    // off-screen (portrait clips are tall).
    final screen = MediaQuery.of(context).size;
    final maxH = screen.height * 0.44;
    double vw = 300, vh = vw / aspect;
    if (vh > maxH) {
      vh = maxH;
      vw = vh * aspect;
    }

    // A Material ancestor gives the overlay proper text styling (and removes the
    // debug yellow underline you get from bare Text in an Overlay).
    return Material(
      type: MaterialType.transparency,
      child: Stack(
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
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
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
                                size: i == 1 ? 52 : 40,
                                color: const Color(0xFFFFC02E)),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Headline (Option C): heavy stacked caps underlined with the
                  // signature 5-colour Kente accent rule.
                  Text('AYƐKOO',
                      style: displayFont(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: kVelvetInk,
                          letterSpacing: 1.5)),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 120,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: const KenteAccentLine(height: 3, blockWidth: 24),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // In-character line (rotates per pass) in the guide's voice.
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 300),
                    child: Text(_line,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: kVelvetInk,
                            fontSize: 15,
                            height: 1.35,
                            fontWeight: FontWeight.w500)),
                  ),
                  const SizedBox(height: 16),
                  // Celebration clip (or portrait fallback) in a glowing frame.
                  Transform.scale(
                    scale: 0.72 + 0.28 * bloom.clamp(0.0, 1.2),
                    child: SizedBox(
                      width: vw,
                      height: vh,
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
                                          size: 150,
                                          selected: true),
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Continue — the clear bottom CTA.
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
                                fontSize: 17,
                                decoration: TextDecoration.none)),
                      ),
                    ),
                  ),
                ],
              )),
            ),
          ),
        ],
      ),
    );
  }
}
