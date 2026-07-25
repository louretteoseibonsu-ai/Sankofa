import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/blind_box_data.dart';
import '../services/sound_service.dart';
import '../theme.dart';
import 'kente_shard.dart';
import 'mascot.dart';
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
/// reveals the reward. For a bus cosmetic the reveal composites the drop straight
/// onto the canonical [Mascot] via `equipped`, so the reveal IS a live equip
/// preview. Tap during the shake to skip ahead.
///
/// Presented over the current screen via an [OverlayEntry] (see [show]); resolves
/// when the learner taps Equip or Keep.
class BlindBoxOpening extends StatefulWidget {
  final UnboxResult result;
  final Color bodyColor; // player's current body colour (for the preview)
  final Map<String, String> equipped; // current cosmetics (drop layers on top)
  final VoidCallback onEquip; // equip the reward + close
  final VoidCallback onKeep; // keep in collection + close

  const BlindBoxOpening({
    super.key,
    required this.result,
    required this.bodyColor,
    this.equipped = const {},
    required this.onEquip,
    required this.onKeep,
  });

  /// Plays the unboxing over the current screen via an [OverlayEntry].
  /// Resolves to `true` if the learner tapped Equip, `false` if they kept it —
  /// the caller then persists the equip and refreshes. Doing the equip after
  /// this resolves (rather than in a callback) avoids racing the reload.
  static Future<bool> show(
    BuildContext context, {
    required UnboxResult result,
    required Color bodyColor,
    Map<String, String> equipped = const {},
  }) {
    final overlay = Overlay.of(context);
    final completer = Completer<bool>();
    late OverlayEntry entry;
    void finish(bool equip) {
      entry.remove();
      if (!completer.isCompleted) completer.complete(equip);
    }

    entry = OverlayEntry(
      builder: (_) => BlindBoxOpening(
        result: result,
        bodyColor: bodyColor,
        equipped: equipped,
        onEquip: () => finish(true),
        onKeep: () => finish(false),
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
  static const double _burstAt = 0.55;
  static const double _revealAt = 0.72;

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
            child: _revealed ? _buildReveal(accent) : _buildBox(p, accent),
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

  Widget _buildBox(double p, Color accent) {
    final coil = (p / _shakeStart).clamp(0.0, 1.0); // anticipation dip
    final shakeP = ((p - _shakeStart) / (_burstAt - _shakeStart)).clamp(0.0, 1.0);
    final burst = ((p - _burstAt) / 0.17).clamp(0.0, 1.0);
    final anticip = p < _shakeStart;
    final scaleCoil = anticip ? 1.0 - 0.10 * Curves.easeOut.transform(coil) : 1.0;
    final dy = anticip ? 8.0 * Curves.easeOut.transform(coil) : 0.0;
    final dx = math.sin(p * 90) * 6 * shakeP * (1 - burst);
    final rot = math.sin(p * 78) * 0.06 * shakeP * (1 - burst);
    return Opacity(
      opacity: 1.0 - burst,
      child: Transform.translate(
        offset: Offset(dx, dy),
        child: Transform.rotate(
          angle: rot,
          child: Transform.scale(
            scale: scaleCoil * (1.0 + 0.5 * burst),
            child: _Calabash(accent: accent),
          ),
        ),
      ),
    );
  }

  Widget _buildReveal(Color accent) {
    final dup = widget.result.duplicate;
    final canEquip = _reward.isBusCosmetic && !dup;

    // The reward, scaling in — with a gentle continuous sway for legendaries.
    Widget reward = _RewardPreview(
      reward: _reward,
      bodyColor: widget.bodyColor,
      equipped: widget.equipped,
      accent: accent,
    );
    if (_isLegendary) {
      final inner = reward;
      reward = AnimatedBuilder(
        animation: _spin,
        builder: (_, child) => Transform.rotate(
            angle: math.sin(_spin.value * 2 * math.pi) * 0.06, child: child),
        child: inner,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _RarityChip(rarity: _rarity, color: accent),
          const SizedBox(height: 24),
          SizedBox(
            width: 300,
            height: 196,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // Legendary: slow gold rays behind the reward.
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
                // Grounding glow disc — anchors the reward on the black stage.
                AnimatedBuilder(
                  animation: _glow,
                  builder: (_, __) => _groundGlow(accent, _glow.value),
                ),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.4, end: 1.0),
                  duration: const Duration(milliseconds: 520),
                  curve: Curves.elasticOut,
                  builder: (_, s, child) =>
                      Transform.scale(scale: s, child: child),
                  child: reward,
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Text(
            _reward.name,
            textAlign: TextAlign.center,
            style: displayFont(
                fontSize: 25, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          const SizedBox(height: 6),
          if (dup)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Duplicate — refunded ${widget.result.refund}',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 13)),
                const SizedBox(width: 5),
                const KenteShard(size: 14),
              ],
            )
          else
            Text('Added to your collection',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7), fontSize: 13)),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (canEquip) ...[
                _PillButton(
                  label: 'Equip Now',
                  filled: true,
                  color: accent,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    SoundService.instance.tap();
                    widget.onEquip();
                  },
                ),
                const SizedBox(width: 12),
              ],
              _PillButton(
                label: canEquip ? 'Keep' : 'Collect',
                filled: !canEquip,
                color: accent,
                onTap: () {
                  SoundService.instance.tap();
                  widget.onKeep();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// A soft elliptical glow beneath the reward — the "pedestal".
  Widget _groundGlow(Color accent, double pulse) => Transform.translate(
        offset: const Offset(0, 64),
        child: Transform.scale(
          scaleY: 0.34,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  accent.withValues(alpha: 0.34 + 0.14 * pulse),
                  accent.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
      );
}

/// The reward preview. Bus cosmetics composite onto the canonical Mascot via
/// `equipped` (a live equip preview); figurines show a collectible card.
class _RewardPreview extends StatelessWidget {
  final BoxReward reward;
  final Color bodyColor;
  final Map<String, String> equipped;
  final Color accent;
  const _RewardPreview({
    required this.reward,
    required this.bodyColor,
    required this.equipped,
    required this.accent,
  });

  /// True if the layered cosmetic PNG is actually bundled yet.
  static Future<bool> _hasArt(BuildContext context, String path) async {
    try {
      await DefaultAssetBundle.of(context).load(path);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Figurine collectible (dashboard trophy — art TBD, styled placeholder).
    if (!reward.isBusCosmetic) {
      return Container(
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: accent, width: 2),
        ),
        child: Icon(Icons.auto_awesome, color: accent, size: 64),
      );
    }
    // Bus cosmetic: if the layer is bundled, show it live on the canonical
    // Mascot (an instant equip preview). Until the art ships, fall back to a
    // clean procedural kente swatch so the reward always reads.
    final path =
        'assets/mascot/trotro_gameplay/${reward.category}/${reward.id}.png';
    return FutureBuilder<bool>(
      future: _hasArt(context, path),
      builder: (context, snap) {
        if (snap.data == true) {
          return Mascot(
            bodyColor: bodyColor,
            equipped: {...equipped, reward.category: reward.id},
            width: 220,
          );
        }
        return _KenteSwatch(accent: accent);
      },
    );
  }
}

/// A procedurally woven kente tile — the graceful stand-in for a bus cosmetic
/// whose final layered art hasn't shipped yet. Reads clearly as "you won a
/// cloth" and needs no assets.
class _KenteSwatch extends StatelessWidget {
  final Color accent;
  const _KenteSwatch({required this.accent});

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: CustomPaint(
            size: const Size(190, 150), painter: _KentePainter(accent)),
      );
}

class _KentePainter extends CustomPainter {
  final Color accent;
  _KentePainter(this.accent);

  static const Color _dark = Color(0xFF2B2B2D);
  static const Color _gold = Color(0xFFE3A92C);
  static const Color _cream = Color(0xFFF4F1EC);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = _dark);
    const cols = 6, rows = 5;
    final cw = size.width / cols, ch = size.height / rows;
    final palette = [accent, _gold, _cream, _dark];
    for (var y = 0; y < rows; y++) {
      for (var x = 0; x < cols; x++) {
        final block = Rect.fromLTWH(x * cw, y * ch, cw, ch).deflate(1.5);
        canvas.drawRect(
            block, Paint()..color = palette[(x + y) % palette.length]);
        // A woven weft stripe across the middle of each block.
        canvas.drawRect(
          Rect.fromLTWH(x * cw, y * ch + ch * 0.4, cw, ch * 0.2).deflate(1.5),
          Paint()..color = _gold.withValues(alpha: 0.5),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _KentePainter old) => old.accent != accent;
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

/// A kente-wrapped calabash (gourd): a warm body, a woven band across the middle,
/// and a mystery glyph.
class _Calabash extends StatelessWidget {
  final Color accent;
  const _Calabash({required this.accent});

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: const Size(150, 168), painter: _CalabashPainter(accent));
}

class _CalabashPainter extends CustomPainter {
  final Color accent;
  _CalabashPainter(this.accent);

  static const Color _gourd = Color(0xFF9A5B33);
  static const Color _gourdDark = Color(0xFF7A4526);
  static const Color _gold = Color(0xFFE3A92C);
  static const Color _cream = Color(0xFFF4F1EC);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final cx = w / 2;

    // Neck.
    final neck = RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - 14, h * 0.02, 28, h * 0.20),
        const Radius.circular(8));
    canvas.drawRRect(neck, Paint()..color = _gourdDark);

    // Body (rounded gourd).
    final body = Rect.fromCenter(
        center: Offset(cx, h * 0.60), width: w * 0.86, height: h * 0.74);
    canvas.drawOval(body, Paint()..color = _gourd);
    // Soft top-light.
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx - w * 0.10, h * 0.46),
          width: w * 0.4,
          height: h * 0.3),
      Paint()..color = Colors.white.withValues(alpha: 0.10),
    );

    // Woven kente band — thin alternating warp threads over a dark weft base.
    canvas.save();
    canvas.clipPath(Path()..addOval(body));
    final bandTop = h * 0.50;
    const bandH = 30.0;
    canvas.drawRect(
        Rect.fromLTWH(0, bandTop, w, bandH), Paint()..color = _gourdDark);
    const step = 9.0;
    final threads = [accent, _gold, _cream];
    for (var i = 0; i * step < w; i++) {
      canvas.drawRect(
        Rect.fromLTWH(i * step, bandTop + 2, step - 2.0, bandH - 4),
        Paint()..color = threads[i % threads.length],
      );
    }
    // Two horizontal weft lines binding the band.
    final weft = Paint()
      ..color = _gourdDark
      ..strokeWidth = 2;
    canvas.drawLine(
        Offset(0, bandTop + bandH * 0.5), Offset(w, bandTop + bandH * 0.5), weft);
    final edge = Paint()
      ..color = _gold
      ..strokeWidth = 2;
    canvas.drawLine(Offset(0, bandTop - 3), Offset(w, bandTop - 3), edge);
    canvas.drawLine(
        Offset(0, bandTop + bandH + 3), Offset(w, bandTop + bandH + 3), edge);
    canvas.restore();

    // Mystery glyph (in the display face).
    final tp = TextPainter(
      text: TextSpan(
        text: '?',
        style: displayFont(
            fontSize: 30, fontWeight: FontWeight.w800, color: Colors.white),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, h * 0.66));
  }

  @override
  bool shouldRepaint(covariant _CalabashPainter old) => old.accent != accent;
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
