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
  late final AnimationController _spin; // gentle legendary reward sway
  // The internal amber glow's "ignition": a fade + subtle scale so it breathes
  // into existence at the seal-break instead of snapping on. Derived from the
  // master controller so it's perfectly locked to the burst beat.
  late final Animation<double> _ignite; // 0→1 opacity ramp across the break
  late final Animation<double> _igniteScale; // 0.82→1.0 gentle swell
  bool _revealed = false;
  final Set<String> _fired = {};

  BoxReward get _reward => widget.result.reward;
  Rarity get _rarity => _reward.rarity;
  bool get _isLegendary => _rarity == Rarity.legendary;

  // Timeline beats — normalized positions on the 2.8s master controller.
  // Re-balanced for a premium, tactile cadence: a longer settle + anticipation,
  // a sharp break, a held glow of suspense, then the reward.
  static const double _shakeStart = 0.12; // after the anticipation settle
  static const double _burstAt = 0.52; // seal breaks — cut to the split render
  static const double _glowAt = 0.62; // cut to the top-down glowing interior
  static const double _revealAt = 0.70; // reward lands

  // A controlled overshoot (easeOutBack) — reads as a critically-damped spring
  // pop, more "tactile toy" than the jelly of elasticOut. Tuned overshoot ~1.5.
  static const Cubic _springPop = Cubic(0.34, 1.56, 0.64, 1.0);

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
        vsync: this, duration: const Duration(milliseconds: 2800))
      ..addListener(_onTick)
      ..forward();

    // Ignition ramp: the amber glow eases in across the break window
    // (_burstAt → just past _glowAt). easeIn gives it weight — it swells slowly
    // then fills, like heat building inside the shell, rather than flicking on.
    _ignite = CurvedAnimation(
      parent: _c,
      curve: const Interval(_burstAt, _glowAt + 0.04, curve: Curves.easeIn),
    );
    _igniteScale = Tween<double>(begin: 0.82, end: 1.0).animate(_ignite);

    // Phase 1 — the box was tapped open: a crisp pickup pop.
    SoundService.instance.boxTap();
  }

  void _onTick() {
    final p = _c.value;
    if (p >= _shakeStart && p < _burstAt) {
      // rising shake — a haptic + audible tick per beat, building in pitch and
      // volume toward the break.
      final beat = (p * 16).floor();
      if (_fired.add('s$beat')) {
        HapticFeedback.selectionClick();
        final intensity =
            ((p - _shakeStart) / (_burstAt - _shakeStart)).clamp(0.0, 1.0);
        SoundService.instance.boxShakeTick(intensity);
      }
    }
    // The warm glow igniting — a sustained riser started just before the break
    // so it swells into the burst.
    if (p >= _burstAt - 0.10 && _fired.add('ignite')) {
      SoundService.instance.boxIgnite();
    }
    if (p >= _burstAt && _fired.add('burst')) {
      HapticFeedback.heavyImpact();
      SoundService.instance.boxBurst(); // Phase 2 — seal cracks
    }
    if (p >= _revealAt && !_revealed) {
      HapticFeedback.mediumImpact(); // Phase 4 — the reward "lands"
      SoundService.instance.boxReveal(grand: _isLegendary);
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
    (_ignite as CurvedAnimation).dispose();
    _c.dispose();
    _glow.dispose();
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = _c.value;
    final accent = rarityColor(_rarity);
    // Wrap in a transparent Material so overlay Text has a Material ancestor
    // (otherwise Flutter paints the debug yellow double-underline).
    return Material(
      type: MaterialType.transparency,
      child: GestureDetector(
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
          // Internal amber glow (from the burst onward) — breathes into being via
          // a fade + subtle scale so it never snaps on; held + pulsing after the
          // reveal, stronger for legendary.
          if (p >= _burstAt)
            Positioned.fill(
              child: IgnorePointer(
                child: FadeTransition(
                  opacity: _ignite,
                  child: ScaleTransition(
                    scale: _igniteScale,
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
          // Warm golden crack-flare — replaces the old white-out. A radial amber
          // bloom that flares from the seam then decays into the charcoal
          // (#141416), so the punch reads as heat/light, never a harsh flash.
          if (p >= _burstAt && p < _revealAt)
            Positioned.fill(
              child: IgnorePointer(
                child: Opacity(
                  opacity: _flareEnvelope(p),
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment(0, -0.12), // over the calabash seam
                        radius: 0.85,
                        colors: [
                          Color(0xFFFBE3A6), // warm cream-gold core
                          Color(0xFFF0A93E), // amber
                          Color(0xFFE07A3E), // ember edge
                          Color(0x00141416), // dissolves into charcoal
                        ],
                        stops: [0.0, 0.28, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
        ),
      ),
    );
  }

  /// Attack-decay envelope for the crack flare: a fast warm swell just after the
  /// seal breaks, then an eased fade before the reward lands. Capped below 1 so
  /// the screen never fully blows out — premium, not blinding.
  double _flareEnvelope(double p) {
    final t = ((p - _burstAt) / (_revealAt - _burstAt)).clamp(0.0, 1.0);
    const attack = 0.22; // quick swell to peak…
    final env = t < attack
        ? Curves.easeOutCubic.transform(t / attack)
        : Curves.easeInOutCubic.transform(1 - (t - attack) / (1 - attack));
    return 0.62 * env;
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

    // 8pt vertical rhythm — generous, consistent gaps so nothing feels crammed.
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Only badge the lucky pulls — a "COMMON" tag on a streak freeze
              // just reads as a letdown now that rewards are functional.
              if (_rarity != Rarity.common) ...[
                _RarityChip(rarity: _rarity, color: accent),
                const SizedBox(height: 28),
              ] else
                const SizedBox(height: 8),
              // Hero — pops in with a spring overshoot.
              SizedBox(
                height: 236,
                child: Center(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.6, end: 1.0),
                    duration: const Duration(milliseconds: 460),
                    curve: _springPop,
                    builder: (_, s, child) =>
                        Transform.scale(scale: s, child: child),
                    child: hero,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              // The real prize — a payout pill, settling in just after the hero.
              _StaggerIn(
                start: 0.28,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(24),
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
              ),
              const SizedBox(height: 12),
              _StaggerIn(
                start: 0.42,
                child: Text(
                    isFreeze
                        ? 'Added to your streak freezes'
                        : 'Added to your shard balance',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 13)),
              ),
              const SizedBox(height: 36),
              // Primary CTA — full-width, generous touch target.
              _StaggerIn(
                start: 0.55,
                child: SizedBox(
                  width: double.infinity,
                  child: _PillButton(
                    label: 'Collect',
                    filled: true,
                    color: accent,
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      SoundService.instance.boxCollect();
                      widget.onKeep();
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
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
        constraints: const BoxConstraints(minHeight: 52), // comfy touch target
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
        decoration: BoxDecoration(
          color: filled ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: color, width: 1.6),
          boxShadow: filled
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: displayFont(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: filled ? Colors.white : color,
              letterSpacing: 0.2),
        ),
      ),
    );
  }
}

/// A small fade + slide-up reveal used to stagger the reward details in after
/// the hero pops. [start] is where this item begins on a shared 620ms curve
/// (0.0–1.0), so the pill, subtitle and CTA cascade rather than snapping in.
class _StaggerIn extends StatelessWidget {
  final double start;
  final Widget child;
  const _StaggerIn({required this.start, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 620),
      curve: Interval(start, 1.0, curve: Curves.easeOutCubic),
      builder: (_, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, (1 - v) * 12), child: child),
      ),
      child: child,
    );
  }
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
