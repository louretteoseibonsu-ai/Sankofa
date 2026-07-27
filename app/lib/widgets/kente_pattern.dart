import 'package:flutter/material.dart';

/// The signature Kente accent line — a thin multi-colour block rule in the
/// canonical sequence: bright yellow · rich red · deep green · matte black ·
/// warm orange (as on the Sankofa raffle page). Used as the top accent token
/// beneath the header across the velvet-dark shell.
class KenteAccentLine extends StatelessWidget {
  final double height;
  final double blockWidth;
  const KenteAccentLine({super.key, this.height = 3, this.blockWidth = 13});

  /// Canonical block sequence.
  static const List<Color> kSequence = [
    Color(0xFFF4B400), // bright yellow
    Color(0xFF9B2D2A), // rich red
    Color(0xFF2E6B3B), // deep green
    Color(0xFF1A1512), // matte black
    Color(0xFFE07A3E), // warm orange
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: _KenteLinePainter(blockWidth)),
    );
  }
}

class _KenteLinePainter extends CustomPainter {
  final double block;
  const _KenteLinePainter(this.block);

  @override
  void paint(Canvas canvas, Size size) {
    final seq = KenteAccentLine.kSequence;
    int i = 0;
    for (double x = 0; x < size.width; x += block) {
      canvas.drawRect(
        Rect.fromLTWH(x, 0, block + 0.5, size.height),
        Paint()..color = seq[i % seq.length],
      );
      i++;
    }
  }

  @override
  bool shouldRepaint(covariant _KenteLinePainter old) => old.block != block;
}

/// Kente header weave — "warp stripes" (Version 3, matches the design preview):
/// a green field woven with vertical gold/red bars, fine black weave-lines and
/// cream hairlines. Used as the app-wide header strip behind the greeting.
class KenteStrip extends StatelessWidget {
  final double height;
  const KenteStrip({super.key, this.height = 16});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: _KentePainter()),
    );
  }
}

/// Fills its parent with the Kente weave — used as an AppBar `flexibleSpace`
/// so the header band spans the full top area and the avatar rests in front.
/// Rounds its bottom corners and lays a soft base shadow + ochre thread so it
/// reads as a sculpted band against the velvet body below.
class KenteHeaderBackground extends StatelessWidget {
  const KenteHeaderBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(painter: _KentePainter(), size: Size.infinite),
          // Grounding: darken the base so the greeting pill + avatar lift off it.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x14000000), Color(0x59000000)],
                stops: [0.55, 1.0],
              ),
            ),
          ),
          // A single ochre thread finishes the bottom edge.
          const Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              height: 1.5,
              child: DecoratedBox(
                  decoration: BoxDecoration(color: Color(0x66D4A373))),
            ),
          ),
        ],
      ),
    );
  }
}

class _KentePainter extends CustomPainter {
  // Warp-stripe palette (matches the preview swatches).
  static const _green = Color(0xFF3B6D11);
  static const _gold = Color(0xFFD99A16);
  static const _red = Color(0xFF9B2D2A);
  static const _cream = Color(0xFFEFDCA6);
  static const _black = Color(0xFF17130F);

  // One repeating warp unit, left→right: green · cream · gold · black · red ·
  // cream · gold · black (then green again). Each entry is (colour, width).
  static const _unit = 60.0;
  static const List<(Color, double)> _bands = [
    (_green, 13),
    (_cream, 2),
    (_gold, 10),
    (_black, 3),
    (_red, 12),
    (_cream, 2),
    (_gold, 10),
    (_black, 3),
    (_green, 5),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    canvas.drawRect(Offset.zero & size, Paint()..color = _green);

    for (double ox = 0; ox < size.width; ox += _unit) {
      double x = ox;
      for (final (color, w) in _bands) {
        canvas.drawRect(
            Rect.fromLTWH(x, 0, w + 0.5, h), Paint()..color = color);
        x += w;
      }
    }

    // Fine horizontal weave-lines give the warp its woven texture.
    final hatch = Paint()
      ..color = const Color(0x22000000)
      ..strokeWidth = 1;
    for (final f in const [0.22, 0.46, 0.70, 0.92]) {
      final y = h * f;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), hatch);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
