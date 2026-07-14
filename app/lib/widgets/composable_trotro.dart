import 'package:flutter/material.dart';

// Palette (kept local so the mascot renders identically anywhere).
const Color _cream = Color(0xFFF3ECDD);
const Color _char = Color(0xFF2B2B2D);
const Color _terraDeep = Color(0xFFBE5235);
const Color _gold = Color(0xFFE3A92C);
const Color _red = Color(0xFF9B2D2A);
const Color _green = Color(0xFF2E6B3B);
const Color _terra = Color(0xFFE2725B);
const Color _glass = Color(0xFFBFE0EA);
const Color _silver = Color(0xFFC9CCD1);
const Color _slate = Color(0xFF5A5E63);

enum KenteStyle { classic, goldGreen, redBlack }

List<Color> _kente(KenteStyle s) {
  switch (s) {
    case KenteStyle.goldGreen:
      return const [_gold, _green, _gold, _green, _char];
    case KenteStyle.redBlack:
      return const [_red, _char, _red, _char, _gold];
    case KenteStyle.classic:
      return const [_gold, _red, _green, _char, _terra];
  }
}

/// A cosmetic configuration for the tro tro.
class TroTroSkin {
  final Color rim;
  final KenteStyle kente;
  final bool roofRack;
  final String horn;
  final Color body; // paintwork colour of the bus

  const TroTroSkin({
    this.rim = _silver,
    this.kente = KenteStyle.classic,
    this.roofRack = false,
    this.horn = 'horn_vroom',
    this.body = _cream,
  });

  /// Resolve a skin from the user's equipped cosmetic ids.
  factory TroTroSkin.fromEquipped(Map<String, String> e) {
    Color rim;
    switch (e['rim']) {
      case 'rim_gold':
        rim = _gold;
        break;
      case 'rim_terracotta':
        rim = _terra;
        break;
      case 'rim_charcoal':
        rim = _char;
        break;
      default:
        rim = _silver;
    }
    KenteStyle kente;
    switch (e['kente']) {
      case 'kente_goldgreen':
        kente = KenteStyle.goldGreen;
        break;
      case 'kente_redblack':
        kente = KenteStyle.redBlack;
        break;
      default:
        kente = KenteStyle.classic;
    }
    return TroTroSkin(
      rim: rim,
      kente: kente,
      roofRack: e['roof'] == 'roof_rack',
      horn: e['horn'] ?? 'horn_vroom',
    );
  }
}

/// A fully vector, recolourable tro tro (idle pose) drawn from parts so
/// cosmetics — rims, kente trim, roof rack — actually change what's on screen.
class ComposableTroTro extends StatelessWidget {
  final TroTroSkin skin;
  final double width;
  const ComposableTroTro({super.key, required this.skin, this.width = 200});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: width * 250 / 380,
      child: CustomPaint(painter: _TroTroPainter(skin)),
    );
  }
}

class _TroTroPainter extends CustomPainter {
  final TroTroSkin skin;
  const _TroTroPainter(this.skin);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 380.0;
    Rect r(double a, double b, double c, double d) =>
        Rect.fromLTRB(a * s, b * s, c * s, d * s);
    RRect rr(double a, double b, double c, double d, double rad) =>
        RRect.fromRectAndRadius(r(a, b, c, d), Radius.circular(rad * s));
    Offset o(double x, double y) => Offset(x * s, y * s);
    Paint fill(Color c) => Paint()..color = c;
    Paint stroke(Color c, double w) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * s
      ..strokeCap = StrokeCap.round
      ..color = c;
    void sq(double x, double y, Color c) =>
        canvas.drawRect(r(x, y, x + 10, y + 10), fill(c));

    final k = _kente(skin.kente);

    // Shadow
    canvas.drawOval(
        Rect.fromCenter(
            center: o(200, 222), width: 300 * s, height: 26 * s),
        fill(_char.withValues(alpha: 0.10)));

    // Wheels + rims
    for (final cx in [112.0, 300.0]) {
      canvas.drawCircle(o(cx, 202), 30 * s, fill(_char));
      canvas.drawCircle(o(cx, 202), 12 * s, fill(skin.rim));
    }

    // Roof rack (drawn under the cap so the cap frames it)
    if (skin.roofRack) {
      canvas.drawRRect(rr(120, 46, 260, 64, 4), stroke(_slate, 3));
      for (final x in [150.0, 190.0, 230.0]) {
        canvas.drawLine(o(x, 48), o(x, 62), stroke(_slate, 3));
      }
    }

    // Roof cap + kente
    canvas.drawRRect(rr(46, 63, 350, 80, 9), fill(_terraDeep));
    const List<double> roofXs = [58, 82, 106, 252, 276, 300, 324];
    for (int i = 0; i < roofXs.length; i++) {
      sq(roofXs[i], 67, k[i % k.length]);
    }

    // Body
    canvas.drawRRect(rr(46, 70, 350, 188, 26), fill(skin.body));
    canvas.drawRRect(rr(46, 70, 350, 188, 26), stroke(_char, 5));

    // Windows
    for (final wx in [60.0, 196.0]) {
      canvas.drawRRect(rr(wx, 106, wx + 120, 148, 8), fill(_glass));
      canvas.drawRRect(rr(wx, 106, wx + 120, 148, 8), stroke(_char, 4));
      canvas.drawLine(o(wx + 60, 106), o(wx + 60, 148), stroke(_char, 3));
    }

    // Bumper + kente
    canvas.drawRRect(rr(50, 176, 346, 189, 6), fill(_char));
    const List<double> bumpXs = [58, 68, 78, 88, 298, 308, 318];
    for (int i = 0; i < bumpXs.length; i++) {
      sq(bumpXs[i], 177, k[i % k.length]);
    }

    // Headlight
    canvas.drawCircle(o(342, 140), 9 * s, fill(_gold));
    canvas.drawCircle(o(342, 140), 9 * s, stroke(_char, 3));
  }

  @override
  bool shouldRepaint(covariant _TroTroPainter old) => old.skin != skin;
}
