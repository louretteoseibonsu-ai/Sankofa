import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/sound_service.dart';
import 'animations.dart' show celebrateBurst;
import 'composable_trotro.dart' show TroTroSkin;
import '../theme.dart';
import 'mascot.dart';
import 'tappable_scale.dart';
import 'velvet.dart';

// High-saturation cartoon palette (Terracotta + grayscale Kente).
const Color _ink = Color(0xFF2B2B2D);
const Color _terra = Color(0xFFE8551F);
const Color _terraDark = Color(0xFFB23C12);
const Color _gold = Color(0xFFFFC02E);
const Color _kenteLight = Color(0xFFF4F1EC);
const Color _kenteGrey = Color(0xFF8B8E93);
const Color _window = Color(0xFFBFE6F0);
const Color _hub = Color(0xFFC9CCD1);

/// The "Stage Clear" celebration: a cheeky, rubber-hose tro tro slingshots
/// across the screen, boings on each star it collects, then looks back, gives a
/// thumbs-up and peels out. Driven entirely by the storyboard Character Flow.
///
/// Plays over the current screen via an [OverlayEntry] and completes when done.
class StageClear {
  const StageClear._();

  /// Runs the sequence. [stars] (1–3) sets how many star-boings play.
  static Future<void> run(
    BuildContext context, {
    required int stars,
    TroTroSkin skin = const TroTroSkin(),
    VoidCallback? onDone,
  }) {
    final overlay = Overlay.of(context);
    final completer = Completer<void>();
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _StageClearView(
        stars: stars.clamp(1, 3),
        skin: skin,
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

class _StageClearView extends StatefulWidget {
  final int stars;
  final TroTroSkin skin;
  final VoidCallback onFinished;
  const _StageClearView({
    required this.stars,
    required this.skin,
    required this.onFinished,
  });

  @override
  State<_StageClearView> createState() => _StageClearViewState();
}

class _StageClearViewState extends State<_StageClearView>
    with TickerProviderStateMixin {
  late final AnimationController _c;
  late final AnimationController _breathe; // Act III Continue-button pulse
  bool _showVictory = false; // Act III reached — waiting for Continue tap
  final Set<String> _fired = {};
  final List<_Puff> _puffs = [];
  final math.Random _rng = math.Random();
  double _lastV = 0;

  // ── Illustrated (Midjourney) sprite frames ──────────────────────────────
  // Transparent PNGs, character facing RIGHT (direction of travel). If they are
  // absent the sequence falls back to the vector tro tro, so the app always
  // runs. Drop the four frames in and register the folder in pubspec to enable.
  static const String _spriteDir = 'assets/mascot/stageclear/';
  static const String _fWink = '${_spriteDir}trotro_wink.png'; // rev-up
  static const String _fDrive = '${_spriteDir}trotro_drive.png'; // squint
  static const String _fTada = '${_spriteDir}trotro_tada.png'; // brake Ta-Da
  static const String _fLook = '${_spriteDir}trotro_lookback.png'; // thumbs-up
  bool _spritesReady = false;

  Future<void> _checkSprites() async {
    try {
      // If the first frame loads, assume the set is present.
      await rootBundle.load(_fWink);
      if (mounted) setState(() => _spritesReady = true);
    } catch (_) {
      // Frames not added yet — stay on the vector fallback.
    }
  }

  String _frameFor(double p) {
    if (p < 0.17) return _fWink;
    if (p < 0.73) return _fDrive;
    if (p < 0.83) return _fTada;
    return _fLook;
  }

  /// Normalised speed 0..1 from the position curve (for stretch + blur).
  double _speedNorm(double p) {
    const e = 0.004;
    final a = _busXFrac((p - e).clamp(0.0, 1.0));
    final b = _busXFrac((p + e).clamp(0.0, 1.0));
    return (((b - a) / (2 * e)).abs() / 2.2).clamp(0.0, 1.0);
  }

  // Column fractions the bus "collects" — depends on star count.
  late final List<double> _cols;
  final List<double> _hopStart = []; // controller-time each boing started
  int _collected = 0;

  @override
  void initState() {
    super.initState();
    switch (widget.stars) {
      case 1:
        _cols = [0.50];
        break;
      case 2:
        _cols = [0.36, 0.64];
        break;
      default:
        _cols = [0.30, 0.50, 0.70];
    }
    for (var i = 0; i < _cols.length; i++) {
      _hopStart.add(-1);
    }
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..addListener(_tick)
      ..addStatusListener((s) {
        // Act II done → hold on the black Victory screen until Continue is tapped
        // (the Future resolves on the tap, never auto-advancing).
        if (s == AnimationStatus.completed && mounted) {
          setState(() => _showVictory = true);
        }
      });
    _breathe = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2400))
      ..repeat(reverse: true);
    _checkSprites();
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    _breathe.dispose();
    super.dispose();
  }

  static double _eo3(double t) => 1 - math.pow(1 - t, 3).toDouble();

  /// Bus centre X as a fraction of screen width, across the 5 storyboard beats.
  static double _busXFrac(double p) {
    if (p < 0.17) {
      final l = p / 0.17;
      return -0.15 + 0.23 * (l * l); // coil at left edge
    }
    if (p < 0.73) {
      final l = (p - 0.17) / 0.56;
      return 0.08 + 0.74 * _eo3(l); // slingshot + star run
    }
    if (p < 0.83) {
      final l = (p - 0.73) / 0.10;
      return 0.82 + 0.02 * math.sin(l * math.pi); // brake hover
    }
    if (p < 0.92) {
      return 0.84; // look-back + thumbs-up hold
    }
    final l = (p - 0.92) / 0.08;
    return 0.84 + 0.5 * (l * l); // peel out
  }

  void _tick() {
    final p = _c.value;
    // Character-beat sound + haptic cues (each fires once).
    if (p >= 0.10 && _fired.add('wink')) HapticFeedback.selectionClick();
    if (p >= 0.17 && _fired.add('launch')) {
      SoundService.instance.horn(widget.skin.horn);
      HapticFeedback.mediumImpact();
      celebrateBurst(context, particles: 34); // confetti at launch
    }
    if (p >= 0.73 && _fired.add('brake')) {
      SoundService.instance.complete(); // "Ta-Da!"
      HapticFeedback.mediumImpact();
    }
    if (p >= 0.85 && _fired.add('thumb')) HapticFeedback.selectionClick();

    // Star boings — trigger as the bus centre passes each column.
    final xf = _busXFrac(p);
    for (var i = 0; i < _cols.length; i++) {
      if (_hopStart[i] < 0 && xf >= _cols[i]) {
        _hopStart[i] = p;
        _collected = i + 1;
        HapticFeedback.lightImpact();
      }
    }

    // Age dust puffs; spawn behind the bus while it's moving fast.
    final v = (xf - _lastV).abs();
    _lastV = xf;
    for (final puff in _puffs) {
      puff.life -= 0.03;
    }
    _puffs.removeWhere((p) => p.life <= 0);
    if (v > 0.012 && _puffs.length < 40) {
      final r = math.Random();
      for (var k = 0; k < 2; k++) {
        _puffs.add(_Puff(
          xf: xf - 0.03 - r.nextDouble() * 0.03,
          dy: r.nextDouble() * 10,
          size: 4 + r.nextDouble() * 6,
          gold: r.nextDouble() < 0.22,
          life: 1.0,
        ));
      }
    }
    setState(() {});
  }

  double _hopOffset(double p) {
    double off = 0;
    for (final start in _hopStart) {
      if (start < 0) continue;
      final k = (p - start) / 0.06; // ~180ms boing
      if (k >= 0 && k <= 1) off += 26 * math.sin(math.pi * k);
    }
    return off;
  }

  @override
  Widget build(BuildContext context) {
    final p = _c.value;
    // Act I: sharp cut to full black over the first ~0.4s, then hold black
    // through the drive (Act II) and the victory screen (Act III).
    final blackIn = (p / 0.13).clamp(0.0, 1.0);
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            color: Colors.black.withValues(alpha: _showVictory ? 1.0 : blackIn),
          ),
        ),
        // Velvet warmth + a focal glow for the victory screen.
        if (_showVictory)
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
        if (_showVictory)
          Positioned.fill(
            child: IgnorePointer(child: FocalGlow(color: _terra)),
          ),
        // ── Act II: the tro tro drives across the black stage ──────────────
        if (!_showVictory)
          IgnorePointer(
            child: Stack(
              children: [
                Positioned(
                  top: MediaQuery.of(context).padding.top + 24,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < widget.stars; i++)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: AnimatedScale(
                            scale: i < _collected ? 1.0 : 0.55,
                            duration: const Duration(milliseconds: 260),
                            curve: Curves.elasticOut,
                            child: Icon(Icons.star_rounded,
                                size: 34,
                                color: i < _collected
                                    ? _gold
                                    : Colors.white.withValues(alpha: 0.4)),
                          ),
                        ),
                    ],
                  ),
                ),
                Positioned.fill(
                  child: CustomPaint(
                    painter: _TroTroCharacterPainter(
                      p: p,
                      xFrac: _busXFrac(p),
                      hopOffset: _hopOffset(p),
                      puffs: _puffs,
                      drawBus: !_spritesReady,
                    ),
                  ),
                ),
                if (_spritesReady) _buildSprite(context, p),
              ],
            ),
          ),
        // ── Act III: victory screen (interactive Continue) ─────────────────
        if (_showVictory) _buildVictory(context),
      ],
    );
  }

  /// The black victory card: earned stars, headline, and a breathing terracotta
  /// Continue button — the only thing on screen. Tapping it resolves the
  /// sequence (removes the overlay, hands control back to the lesson).
  Widget _buildVictory(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < widget.stars; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.4, end: 1.0),
                    duration: Duration(milliseconds: 380 + i * 160),
                    curve: Curves.elasticOut,
                    builder: (_, s, child) =>
                        Transform.scale(scale: s, child: child),
                    child: Icon(Icons.star_rounded,
                        size: i == 1 ? 58 : 46, color: _gold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text('STAGE CLEAR',
              style: displayFont(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: kVelvetInk,
                  letterSpacing: 2.5)),
          const SizedBox(height: 36),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 54, vertical: 15),
                decoration: BoxDecoration(
                  color: _terra,
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
    );
  }

  Widget _buildSprite(BuildContext context, double p) {
    final size = MediaQuery.of(context).size;
    const w = 156.0, h = 112.0;
    final cx = size.width * _busXFrac(p);
    final baseY = size.height * 0.60;
    final hop = _hopOffset(p);
    final sp = _speedNorm(p);

    final coil = p < 0.17;
    final brake = p >= 0.73 && p < 0.83;
    double sX, sY;
    if (coil) {
      final c = p / 0.17;
      sX = 1 - 0.30 * c;
      sY = 1 + 0.22 * c;
    } else if (brake) {
      sX = 1.14;
      sY = 0.80;
    } else {
      sX = 1 + sp * 0.75;
      sY = 1 - sp * 0.42;
    }

    // Vibration on rev, kick on launch + brake.
    double jx = 0, jy = 0;
    if (coil || (p >= 0.17 && p < 0.21) || brake) {
      jx = (_rng.nextDouble() - 0.5) * (coil ? 3 : 6);
      jy = (_rng.nextDouble() - 0.5) * (coil ? 3 : 6);
    }
    final blur = sp > 0.5 ? (sp - 0.5) * 6 : 0.0;

    return Positioned(
      left: cx - w / 2 + jx,
      top: baseY - h - hop + jy,
      width: w,
      height: h,
      child: Transform.scale(
        scaleX: sX,
        scaleY: sY,
        alignment: Alignment.bottomCenter,
        child: ImageFiltered(
          imageFilter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: 0.001),
          // The finish-line hero frames now render through the shared Mascot
          // celebration seam: its internal AnimatedSwitcher cross-fades between
          // wink → drive → Ta-Da → look-back as the beat (frame path) changes.
          // If a frame is missing, Mascot fails silent and the vector painter
          // (drawBus) is still underneath.
          child: Mascot(
            bodyColor: _terra, // ignored in celebration mode (branded hero pose)
            width: w,
            mode: MascotMode.celebrating,
            celebrationFrame: _frameFor(p),
          ),
        ),
      ),
    );
  }
}

class _Puff {
  double xf;
  double dy;
  double size;
  bool gold;
  double life;
  _Puff({
    required this.xf,
    required this.dy,
    required this.size,
    required this.gold,
    required this.life,
  });
}

/// Draws the rubber-hose tro tro from parts so it can squash, stretch, wink and
/// look in any direction — plus its kente-dust wake and motion streaks.
class _TroTroCharacterPainter extends CustomPainter {
  final double p; // 0..1 sequence progress
  final double xFrac; // bus centre X fraction
  final double hopOffset; // upward boing offset (px)
  final List<_Puff> puffs;
  final bool drawBus; // false once illustrated sprite frames take over

  _TroTroCharacterPainter({
    required this.p,
    required this.xFrac,
    required this.hopOffset,
    required this.puffs,
    this.drawBus = true,
  });

  double get _speed {
    const eps = 0.004;
    final a = _StageClearViewState._busXFrac((p - eps).clamp(0.0, 1.0));
    final b = _StageClearViewState._busXFrac((p + eps).clamp(0.0, 1.0));
    return ((b - a) / (2 * eps)).abs().clamp(0.0, 3.0);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final baseY = size.height * 0.60;
    final cx = size.width * xFrac;
    final sp = (_speed / 2.2).clamp(0.0, 1.0); // normalised 0..1

    final coil = p < 0.17;
    final brake = p >= 0.73 && p < 0.83;
    final lookBack = p >= 0.83 && p < 0.92;

    // ── Dust wake + speed streaks (behind the bus) ──
    for (final puff in puffs) {
      final paint = Paint()
        ..color =
            (puff.gold ? _gold : _kenteGrey).withValues(alpha: puff.life * 0.8);
      canvas.drawCircle(
        Offset(size.width * puff.xf, baseY + puff.dy),
        puff.size * puff.life,
        paint,
      );
    }
    if (sp > 0.35) {
      final streak = Paint()
        ..color = _ink.withValues(alpha: 0.20)
        ..strokeWidth = 2;
      final r = math.Random(p.hashCode);
      for (var k = 0; k < 4; k++) {
        final ly = baseY - 46 + r.nextDouble() * 44;
        canvas.drawLine(Offset(cx - 12 - r.nextDouble() * 30, ly),
            Offset(cx - 46 - sp * 34, ly), streak);
      }
    }

    // Dust wake is shared; the vector bus below is the FALLBACK only. Once the
    // illustrated sprite frames are present, the sprite widget draws the bus.
    if (!drawBus) return;

    // ── Squash & stretch (bottom-anchored) ──
    double sX, sY;
    if (coil) {
      final c = p / 0.17;
      sX = 1 - 0.30 * c;
      sY = 1 + 0.22 * c;
    } else if (brake) {
      sX = 1.14;
      sY = 0.80;
    } else {
      sX = 1 + sp * 0.75; // slingshot stretch
      sY = 1 - sp * 0.42;
    }

    canvas.save();
    canvas.translate(cx, baseY - hopOffset);
    canvas.scale(sX, sY);

    // Wheel geometry: ovals at speed, wide "rectangles" on coil/brake.
    double wrx = 13, wry = 13;
    if (coil) {
      wrx = 17;
      wry = 8;
    } else if (brake) {
      wrx = 19;
      wry = 6;
    } else if (sp > 0.25) {
      wrx = 13 + 7 * sp;
      wry = 13 - 6 * sp;
    }

    // Eye state: direction (-1 back, 0 at-user, 1 forward) + lid closure L/R.
    double eyeDir;
    double lidL, lidR;
    if (p < 0.10) {
      eyeDir = 0;
      lidL = lidR = 0; // wide, looking at user
    } else if (p < 0.17) {
      eyeDir = 0;
      lidL = 0;
      lidR = 1; // WINK (right eye)
    } else if (brake) {
      eyeDir = 0;
      lidL = lidR = 0; // "Ta-Da!" wide & happy
    } else if (lookBack) {
      eyeDir = -1;
      lidL = lidR = 0; // look back at user
    } else {
      eyeDir = 1;
      lidL = lidR = (sp * 0.6).clamp(0.0, 0.6); // squint forward
    }

    _drawBus(canvas, wrx, wry, eyeDir, lidL, lidR,
        showWink: p >= 0.10 && p < 0.16, lookBack: lookBack);

    canvas.restore();
  }

  void _drawBus(Canvas canvas, double wrx, double wry, double eyeDir,
      double lidL, double lidR,
      {required bool showWink, required bool lookBack}) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = _ink
      ..strokeJoin = StrokeJoin.round;

    // Wheels (rounded rects so ovals ↔ flat rectangles is one primitive).
    for (final wx in [-32.0, 32.0]) {
      final rr = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(wx, -12), width: wrx * 2, height: wry * 2),
        Radius.circular(math.min(wrx, wry)),
      );
      canvas.drawRRect(rr, Paint()..color = _ink);
      canvas.drawCircle(Offset(wx, -12), math.min(5, wry * 0.6),
          Paint()..color = _hub);
    }

    // Thumbs-up arm (behind body, swings up on the look-back).
    if (lookBack) {
      canvas.save();
      canvas.translate(60, -22);
      canvas.rotate(-0.9);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(-3, -18, 6, 18), const Radius.circular(3)),
        Paint()..color = _terraDark,
      );
      canvas.drawCircle(const Offset(0, -20), 6, Paint()..color = _gold);
      canvas.drawCircle(const Offset(0, -20), 6, stroke);
      canvas.restore();
    }

    // Roof rack.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(-40, -70, 70, 12), const Radius.circular(6)),
      Paint()..color = _terraDark,
    );

    // Body.
    final body = RRect.fromRectAndRadius(
        const Rect.fromLTWH(-58, -58, 116, 40), const Radius.circular(18));
    canvas.drawRRect(body, Paint()..color = _terra);
    canvas.drawRRect(body, stroke);

    // Grayscale kente band across the flank.
    canvas.save();
    canvas.clipRRect(body);
    canvas.drawRect(const Rect.fromLTWH(-58, -40, 116, 9),
        Paint()..color = _kenteLight);
    final zig = Path();
    for (double x = -58; x <= 58; x += 12) {
      zig.moveTo(x, -40);
      zig.lineTo(x + 6, -31);
      zig.lineTo(x + 12, -40);
    }
    canvas.drawPath(
        zig,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = _kenteGrey);
    canvas.restore();

    // Rear window.
    final win = RRect.fromRectAndRadius(
        const Rect.fromLTWH(-52, -52, 20, 15), const Radius.circular(4));
    canvas.drawRRect(win, Paint()..color = _window);
    canvas.drawRRect(win, stroke);

    // Headlight.
    canvas.drawCircle(const Offset(58, -30), 5, Paint()..color = _gold);
    canvas.drawCircle(const Offset(58, -30), 5, stroke);

    // Eyes (layered: sclera → pupil → highlight → eyelid).
    _drawEye(canvas, const Offset(28, -48), eyeDir, lidL, stroke);
    _drawEye(canvas, const Offset(47, -48), eyeDir, lidR, stroke);

    // Wink sparkle.
    if (showWink) {
      final s = Paint()..color = _gold;
      const c = Offset(58, -60);
      canvas.drawCircle(c, 2.4, s);
      canvas.drawRect(Rect.fromCenter(center: c, width: 10, height: 1.6), s);
      canvas.drawRect(Rect.fromCenter(center: c, width: 1.6, height: 10), s);
    }
  }

  void _drawEye(
      Canvas canvas, Offset c, double dir, double lid, Paint stroke) {
    const r = 10.0;
    canvas.drawCircle(c, r, Paint()..color = Colors.white);
    canvas.drawCircle(c, r, stroke);
    final pupil = Offset(c.dx + dir * 4, c.dy + 1);
    canvas.drawCircle(pupil, 4.8, Paint()..color = _ink);
    canvas.drawCircle(Offset(pupil.dx + 1.6, pupil.dy - 2.2), 1.7,
        Paint()..color = Colors.white);
    if (lid > 0.01) {
      canvas.save();
      canvas.clipPath(Path()..addOval(Rect.fromCircle(center: c, radius: r)));
      canvas.drawRect(
        Rect.fromLTWH(c.dx - r, c.dy - r, r * 2, r * 2 * lid),
        Paint()..color = _terra,
      );
      canvas.drawLine(Offset(c.dx - r, c.dy - r + r * 2 * lid),
          Offset(c.dx + r, c.dy - r + r * 2 * lid), stroke);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _TroTroCharacterPainter old) => true;
}
