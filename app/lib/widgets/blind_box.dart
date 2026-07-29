import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/blind_box_data.dart';
import '../services/sound_service.dart';
import '../theme.dart';
import 'kente_shard.dart';
import 'velvet.dart';
import 'tappable_scale.dart';

/// The accent colour for each rarity tier (kept in the UI layer).
Color rarityColor(Rarity r) {
  switch (r) {
    case Rarity.common:
      return const Color(0xFF9AA0A6);
    case Rarity.rare:
      return const Color(0xFF2E86C1);
    case Rarity.legendary:
      return const Color(0xFFE3A92C);
  }
}

/// Ananse's Folklore Blind Box — a tactile calabash unboxing.
///
/// One controller drives the whole timeline: the kente-wrapped calabash coils,
/// shakes with rising intensity, bursts in a rarity-tinted particle bloom, then
/// reveals the functional prize (streak freezes or a shard haul), already
/// credited to the balance by the service. Tap during the shake to skip ahead.
///
/// Presented over the current screen via an [OverlayEntry] (see [show]); resolves
/// when the learner taps Collect.
class BlindBoxOpening extends StatefulWidget {
  final UnboxResult result;
  final VoidCallback onKeep; // acknowledge the prize + close

  const BlindBoxOpening({
    super.key,
    required this.result,
    required this.onKeep,
  });

  /// Plays the unboxing over the current screen via an [OverlayEntry].
  /// Resolves when the learner taps Collect (the payout is already credited by
  /// the service before this shows).
  static Future<void> show(
    BuildContext context, {
    required UnboxResult result,
  }) {
    final overlay = Overlay.of(context);
    final completer = Completer<void>();
    late OverlayEntry entry;
    void finish() {
      entry.remove();
      if (!completer.isCompleted) completer.complete();
    }

    entry = OverlayEntry(
      builder: (_) => BlindBoxOpening(
        result: result,
        onKeep: finish,
      ),
    );
    overlay.insert(entry);
    return completer.future;
  }

  @override
  State<BlindBoxOpening> createState() => _BlindBoxOpeningState();
}

class _BlindBoxOpeningState extends State<BlindBoxOpening>
    with TickerProviderStateMixin {
  late final AnimationController _c; // coil → shake → burst → reveal
  late final AnimationController _glow; // bloom + ground-glow pulse
  late final AnimationController _spin; // legendary rays + reward sway
  bool _revealed = false;
  final Set<String> _fired = {};

  BoxReward get _reward => widget.result.reward;
  Rarity get _rarity => _reward.rarity;
  bool get _isLegendary => _rarity == Rarity.legendary;

  // Timeline beats.
  static const double _shakeStart = 0.10; // after the anticipation coil
  static const double _burstAt = 0.55; // seal breaks — cut to the split render
  static const double _glowAt = 0.64; // cut to the top-down glowing interior
  static const double _revealAt = 0.72; // reward card lands

  // The four premium unboxing render beats.
  static const String _kBoxDir = 'assets/blindbox';

  /// The render for the current unboxing phase (pre-reveal).
  String _beatAsset(double p) {
    if (p < _burstAt) return '$_kBoxDir/sealed.png';
    if (p < _glowAt) return '$_kBoxDir/crack.png';
    return '$_kBoxDir/glow.png';
  }

  @override
  void initState() {
    super.initState();
    _glow = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);
    _spin = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 9000))
      ..repeat();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2600))
      ..addListener(_onTick)
      ..forward();
  }

  void _onTick() {
    final p = _c.value;
    if (p >= _shakeStart && p < _burstAt) {
      // rising shake — a haptic tick per beat, faster as it builds
      final beat = (p * 16).floor();
      if (_fired.add('s$beat')) HapticFeedback.selectionClick();
    }
    if (p >= _burstAt && _fired.add('burst')) {
      HapticFeedback.heavyImpact();
      SoundService.instance.complete();
    }
    if (p >= _revealAt && !_revealed) {
      HapticFeedback.mediumImpact(); // the reward "lands"
      setState(() => _revealed = true);
    } else {
      setState(() {});
    }
  }

  // Tap during the shake to fast-forward to the burst.
  void _skip() {
    if (!_revealed && _c.value < _burstAt) _c.forward(from: _burstAt);
  }

  @override
  void dispose() {
    _c.dispose();
    _glow.dispose();
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = _c.value;
    final accent = rarityColor(_rarity);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _skip,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    kVelvetTop.withValues(alpha: 0.94),
                    kVelvetBottom.withValues(alpha: 0.96),
                  ],
                ),
              ),
            ),
          ),
          // Rarity bloom (from the burst onward) — stronger + held for legendary.
          if (p >= _burstAt)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _glow,
                  builder: (_, __) {
                    final base = _isLegendary ? 0.30 : 0.18;
                    return DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          radius: 0.95,
                          colors: [
                            accent.withValues(
                                alpha: _revealed
                                    ? base + 0.10 * _glow.value
                                    : 0.34),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          Center(
            child: _revealed ? _buildReveal(accent) : _buildUnbox(p),
          ),
          // Particle bloom.
          if (p >= _burstAt && p < 0.92)
            Positioned.fill(
              child: IgnorePointer(
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: _BurstPainter(
                      t: ((p - _burstAt) / 0.37).clamp(0.0, 1.0),
                      color: accent,
                      seed: _reward.id.hashCode,
                      dense: _isLegendary,
                    ),
                  ),
                ),
              ),
            ),
          // One-frame white flash at the crack for punch.
          if (p >= _burstAt && p < 0.63)
            Positioned.fill(
              child: IgnorePointer(
                child: Opacity(
                  opacity: (1 - (p - _burstAt) / 0.08).clamp(0.0, 1.0),
                  child: const ColoredBox(color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// The pre-reveal unboxing: cross-fades the sealed → split → glow renders on
  /// the timeline, with an anticipation coil and a rising shake while sealed.
  Widget _buildUnbox(double p) {
    final coil = (p / _shakeStart).clamp(0.0, 1.0); // anticipation dip
    final shakeP =
        ((p - _shakeStart) / (_burstAt - _shakeStart)).clamp(0.0, 1.0);
    final anticip = p < _shakeStart;
    final sealed = p < _burstAt; // only the sealed gourd shakes
    final scaleCoil =
        anticip ? 1.0 - 0.06 * Curves.easeOut.transform(coil) : 1.0;
    final dy = anticip ? 8.0 * Curves.easeOut.transform(coil) : 0.0;
    final dx = sealed ? math.sin(p * 90) * 6 * shakeP : 0.0;
    final rot = sealed ? math.sin(p * 78) * 0.05 * shakeP : 0.0;
    final asset = _beatAsset(p);
    return Transform.translate(
      offset: Offset(dx, dy),
      child: Transform.rotate(
        angle: rot,
        child: Transform.scale(
          scale: scaleCoil,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            child: Image.asset(
              asset,
              key: ValueKey(asset),
              width: 300,
              height: 300,
              fit: BoxFit.contain,
              gaplessPlayback: true,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReveal(Color accent) {
    final isFreeze = _reward.kind == RewardKind.freeze;
    // The opened calabash + golden stool hero render, scaling in — with a gentle
    // continuous sway for legendaries.
    Widget hero = Image.asset('$_kBoxDir/reward.png',
        width: 268, height: 268, fit: BoxFit.contain);
    if (_isLegendary) {
      final inner = hero;
      hero = AnimatedBuilder(
        animation: _spin,
        builder: (_, child) => Transform.rotate(
            angle: math.sin(_spin.value * 2 * math.pi) * 0.05, child: child),
        child: inner,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _RarityChip(rarity: _rarity, color: accent),
          const SizedBox(height: 12),
          SizedBox(
            width: 300,
            height: 250,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // Legendary: slow gold rays behind the hero.
                if (_isLegendary)
                  AnimatedBuilder(
                    animation: _spin,
                    builder: (_, __) => Transform.rotate(
                      angle: _spin.value * 2 * math.pi,
                      child: CustomPaint(
                          size: const Size(300, 300),
                          painter: _RayPainter(accent)),
                    ),
                  ),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.5, end: 1.0),
                  duration: const Duration(milliseconds: 520),
                  curve: Curves.elasticOut,
                  builder: (_, s, child) =>
                      Transform.scale(scale: s, child: child),
                  child: hero,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // The real prize — a payout badge over the golden-stool hero.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: accent, width: 1.4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isFreeze)
                  const Icon(Icons.ac_unit_rounded,
                      color: Color(0xFF6FA8DC), size: 22)
                else
                  const KenteShard(size: 22),
                const SizedBox(width: 10),
                Text(
                  isFreeze
                      ? '${_reward.name}  ×${_reward.freezeAmount}'
                      : '+${_reward.shardAmount} Golden Shards',
                  style: displayFont(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
              isFreeze
                  ? 'Added to your streak freezes'
                  : 'Added to your shard balance',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7), fontSize: 13)),
          const SizedBox(height: 22),
          _PillButton(
            label: 'Collect',
            filled: true,
            color: accent,
            onTap: () {
              HapticFeedback.mediumImpact();
              SoundService.instance.tap();
              widget.onKeep();
            },
          ),
        ],
      ),
    );
  }
}

class _RarityChip extends StatelessWidget {
  final Rarity rarity;
  final Color color;
  const _RarityChip({required this.rarity, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Text(
        rarity.label.toUpperCase(),
        style: displayFont(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 1.6,
            height: 1.0),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final String label;
  final bool filled;
  final Color color;
  final VoidCallback onTap;
  const _PillButton({
    required this.label,
    required this.filled,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TappableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
        decoration: BoxDecoration(
          color: filled ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: color, width: 1.6),
        ),
        child: Text(
          label,
          style: displayFont(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: filled ? Colors.white : color,
              letterSpacing: -0.2),
        ),
      ),
    );
  }
}

/// Slow radiating rays behind a legendary reward. Static shape; the caller
/// rotates it with a [Transform].
class _RayPainter extends CustomPainter {
  final Color color;
  _RayPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.shortestSide / 2;
    const n = 12;
    final paint = Paint()..color = color.withValues(alpha: 0.13);
    for (var i = 0; i < n; i++) {
      final a = i * 2 * math.pi / n;
      final path = Path()
        ..moveTo(c.dx, c.dy)
        ..lineTo(c.dx + math.cos(a - 0.05) * r, c.dy + math.sin(a - 0.05) * r)
        ..lineTo(c.dx + math.cos(a + 0.05) * r, c.dy + math.sin(a + 0.05) * r)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RayPainter old) => old.color != color;
}

/// A one-shot particle bloom from centre. [t] 0→1 drives expansion + fade.
class _BurstPainter extends CustomPainter {
  final double t;
  final Color color;
  final int seed;
  final bool dense;
  _BurstPainter({
    required this.t,
    required this.color,
    required this.seed,
    required this.dense,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.5);
    final rng = math.Random(seed);
    final count = dense ? 46 : 28;
    final maxR = size.shortestSide * 0.55;
    for (var i = 0; i < count; i++) {
      final ang = rng.nextDouble() * math.pi * 2;
      final speed = 0.5 + rng.nextDouble() * 0.5;
      final dist = maxR * speed * Curves.easeOut.transform(t);
      final pos = center + Offset(math.cos(ang), math.sin(ang)) * dist;
      final life = (1 - t).clamp(0.0, 1.0);
      final r = (2.0 + rng.nextDouble() * 4.0) * life;
      final c = rng.nextDouble() < 0.3
          ? const Color(0xFFE3A92C)
          : (rng.nextDouble() < 0.5 ? Colors.white : color);
      canvas.drawCircle(
          pos, r, Paint()..color = c.withValues(alpha: 0.9 * life));
    }
  }

  @override
  bool shouldRepaint(covariant _BurstPainter old) => old.t != t;
}
