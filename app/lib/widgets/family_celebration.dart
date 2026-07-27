import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/avatar.dart';
import '../services/sound_service.dart';
import '../theme.dart';
import 'animations.dart' show celebrateBurst;
import 'avatar_badge.dart';
import 'tappable_scale.dart';
import 'velvet.dart';

/// The family-avatar "Stage Clear" celebration (recreates the promo reel's hero
/// beat): the equipped character drops onto a glowing gold kente podium with a
/// confetti burst and an "Ayɛkoo!" headline, then waits on a Continue tap.
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
  late final AnimationController _drop; // avatar drop + podium bloom
  late final AnimationController _breathe; // idle bob + Continue pulse
  bool _landed = false;

  @override
  void initState() {
    super.initState();
    _drop = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1150))
      ..addListener(_onDrop);
    _breathe = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2400))
      ..repeat(reverse: true);
    HapticFeedback.selectionClick();
    _drop.forward();
  }

  void _onDrop() {
    // Fire confetti + "ta-da" the instant the character lands.
    if (!_landed && _drop.value >= 0.52) {
      _landed = true;
      SoundService.instance.complete();
      HapticFeedback.mediumImpact();
      celebrateBurst(context, particles: 36);
    }
    setState(() {});
  }

  @override
  void dispose() {
    _drop.dispose();
    _breathe.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = _drop.value;
    // Drop: bounce-settle from above; scrim + podium bloom track the fall.
    final fall = Curves.bounceOut.transform(t);
    final dropY = -340 * (1 - fall);
    final bob = _landed ? 4.0 * math.sin(_breathe.value * math.pi * 2) : 0.0;
    final avatarY = dropY - bob;
    final appear = Curves.easeOut.transform((t / 0.2).clamp(0.0, 1.0));
    final podium = Curves.easeOutBack.transform((t / 0.6).clamp(0.0, 1.0));
    final showContinue = t > 0.9;

    return Stack(
      children: [
        // Velvet backdrop + warm focal glow.
        Positioned.fill(
          child: Opacity(
            opacity: appear,
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
              // Hero: podium + dropping avatar.
              SizedBox(
                height: 260,
                width: 240,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  clipBehavior: Clip.none,
                  children: [
                    // Gold podium (blooms up under the character).
                    Positioned(
                      bottom: 6,
                      child: Transform.scale(
                        scale: podium.clamp(0.0, 1.2),
                        child: Container(
                          width: 172,
                          height: 46,
                          decoration: const BoxDecoration(
                            gradient: RadialGradient(
                              radius: 0.95,
                              colors: [Color(0xFFFFE7A6), Color(0xFFE3A92C)],
                            ),
                            borderRadius:
                                BorderRadius.all(Radius.elliptical(86, 23)),
                            boxShadow: [
                              BoxShadow(
                                  color: Color(0x88E3A92C),
                                  blurRadius: 44,
                                  spreadRadius: 8),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Contact shadow.
                    Positioned(
                      bottom: 16,
                      child: Container(
                        width: 96,
                        height: 16,
                        decoration: const BoxDecoration(
                          color: Color(0x55000000),
                          borderRadius:
                              BorderRadius.all(Radius.elliptical(48, 8)),
                        ),
                      ),
                    ),
                    // The equipped family character.
                    Positioned(
                      bottom: 22,
                      child: Opacity(
                        opacity: appear,
                        child: Transform.translate(
                          offset: Offset(0, avatarY),
                          child: Image.asset(
                            widget.avatar.assetReference,
                            height: 236,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => AvatarBadge(
                                avatar: widget.avatar,
                                size: 150,
                                selected: true),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text('Ayɛkoo!',
                  style: displayFont(
                      fontSize: 40,
                      fontWeight: FontWeight.w700,
                      color: kVelvetInk)),
              const SizedBox(height: 4),
              Text('WELL DONE · STAGE CLEAR',
                  style: microLabel(color: kOchre)),
              const SizedBox(height: 26),
              AnimatedOpacity(
                opacity: showContinue ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 260),
                child: AnimatedBuilder(
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
              ),
            ],
          ),
        ),
      ],
    );
  }
}
