import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/blind_box_data.dart';
import '../services/sound_service.dart';
import 'mascot.dart';
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
/// One controller drives the whole timeline: the kente-wrapped calabash shakes
/// with rising intensity, bursts in a rarity-tinted particle bloom, then reveals
/// the reward. For a bus cosmetic the reveal composites the drop straight onto
/// the canonical [Mascot] via `equipped`, so the reveal IS a live equip preview.
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
  late final AnimationController _c; // shake → burst → reveal
  late final AnimationController _glow; // reveal glow pulse
  bool _revealed = false;
  final Set<String> _fired = {};

  BoxReward get _reward => widget.result.reward;
  Rarity get _rarity => _reward.rarity;

  @override
  void initState() {
    super.initState();
    _glow = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2600))
      ..addListener(_onTick)
      ..forward();
  }

  void _onTick() {
    final p = _c.value;
    if (p < 0.55) {
      // rising shake — a haptic tick per beat, faster as it builds
      final beat = (p * 16).floor();
      if (_fired.add('s$beat')) HapticFeedback.selectionClick();
    }
    if (p >= 0.55 && _fired.add('burst')) {
      HapticFeedback.heavyImpact();
      SoundService.instance.complete();
    }
    if (p >= 0.72 && !_revealed) {
      setState(() => _revealed = true);
    } else {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _c.dispose();
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = _c.value;
    final accent = rarityColor(_rarity);
    return Stack(
      children: [
        Positioned.fill(
          child: Container(color: Colors.black.withValues(alpha: 0.86)),
        ),
        // Rarity glow bloom (from the burst onward).
        if (p >= 0.55)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _glow,
                builder: (_, __) => DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      radius: 0.95,
                      colors: [
                        accent.withValues(
                            alpha: _revealed ? 0.20 + 0.08 * _glow.value : 0.32),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        Center(
          child: _revealed ? _buildReveal(accent) : _buildBox(p, accent),
        ),
        // Particle burst overlay.
        if (p >= 0.55 && p < 0.92)
          Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _BurstPainter(
                    t: ((p - 0.55) / 0.37).clamp(0.0, 1.0),
                    color: accent,
                    seed: _reward.id.hashCode,
                    dense: _rarity == Rarity.legendary,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBox(double p, Color accent) {
    final shake = (p / 0.55).clamp(0.0, 1.0);
    final burst = ((p - 0.55) / 0.17).clamp(0.0, 1.0);
    final dx = math.sin(p * 90) * 6 * shake * (1 - burst);
    final rot = math.sin(p * 78) * 0.06 * shake * (1 - burst);
    return Opacity(
      opacity: 1.0 - burst,
      child: Transform.translate(
        offset: Offset(dx, 0),
        child: Transform.rotate(
          angle: rot,
          child: Transform.scale(
            scale: 1.0 + 0.5 * burst,
            child: _Calabash(accent: accent),
          ),
        ),
      ),
    );
  }

  Widget _buildReveal(Color accent) {
    final dup = widget.result.duplicate;
    final canEquip = _reward.isBusCosmetic && !dup;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _RarityChip(rarity: _rarity, color: accent),
          const SizedBox(height: 22),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.4, end: 1.0),
            duration: const Duration(milliseconds: 520),
            curve: Curves.elasticOut,
            builder: (_, s, child) => Transform.scale(scale: s, child: child),
            child: _RewardPreview(
              reward: _reward,
              bodyColor: widget.bodyColor,
              equipped: widget.equipped,
              accent: accent,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _reward.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20),
          ),
          const SizedBox(height: 6),
          Text(
            dup
                ? 'Duplicate — refunded ${widget.result.refund} shards'
                : 'Added to your collection',
            style:
                TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
          ),
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
        style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 12,
            letterSpacing: 1.5),
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
          style: TextStyle(
              color: filled ? Colors.white : color,
              fontWeight: FontWeight.w700,
              fontSize: 15),
        ),
      ),
    );
  }
}

/// A kente-wrapped calabash (gourd): a warm body, a woven band across the middle
/// with alternating accent/gold blocks, and a mystery glyph.
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

    // Kente band across the middle: alternating accent / gold blocks.
    canvas.save();
    canvas.clipPath(Path()..addOval(body));
    final bandTop = h * 0.52;
    const bandH = 26.0;
    const blocks = 7;
    final bw = w / blocks;
    for (var i = 0; i < blocks; i++) {
      canvas.drawRect(
        Rect.fromLTWH(i * bw, bandTop, bw, bandH),
        Paint()..color = i.isEven ? accent : _gold,
      );
    }
    // Thin weave lines above/below the band.
    final line = Paint()
      ..color = _gold
      ..strokeWidth = 2;
    canvas.drawLine(Offset(0, bandTop - 4), Offset(w, bandTop - 4), line);
    canvas.drawLine(
        Offset(0, bandTop + bandH + 4), Offset(w, bandTop + bandH + 4), line);
    canvas.restore();

    // Mystery glyph.
    final tp = TextPainter(
      text: const TextSpan(
        text: '?',
        style: TextStyle(
            color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, h * 0.66));
  }

  @override
  bool shouldRepaint(covariant _CalabashPainter old) => old.accent != accent;
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
