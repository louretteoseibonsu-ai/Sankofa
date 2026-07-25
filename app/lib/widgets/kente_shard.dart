import 'package:flutter/material.dart';

/// The "Golden Kente shard" — the app's soft currency, drawn as a crisp flat
/// vector (no asset needed, scales to any size). A gold kite-cut shard with a
/// woven terracotta/ink thread across the middle and a single facet highlight —
/// on-brand with the Kente-Modernist palette, unlike a glossy stock gem.
///
/// Pass [muted] for the "can't afford" state (renders in greys).
class KenteShard extends StatelessWidget {
  final double size;
  final bool muted;
  const KenteShard({super.key, this.size = 18, this.muted = false});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _KenteShardPainter(muted)),
      );
}

class _KenteShardPainter extends CustomPainter {
  final bool muted;
  _KenteShardPainter(this.muted);

  static const Color _gold = Color(0xFFE3A92C);
  static const Color _goldLight = Color(0xFFF2CE7A);
  static const Color _terra = Color(0xFFBE5235);
  static const Color _ink = Color(0xFF2B2B2D);

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    final cx = w / 2;

    final base = muted ? const Color(0xFFC2C6CB) : _gold;
    final facetC = muted ? const Color(0xFFDADDE1) : _goldLight;
    final bandC = muted ? const Color(0xFF9AA0A6) : _terra;
    final lineC = muted ? const Color(0xFF7C8085) : _ink;

    // Kite-cut shard: pointed top + bottom, widest just above centre.
    final path = Path()
      ..moveTo(cx, 0)
      ..lineTo(w * 0.92, h * 0.40)
      ..lineTo(cx, h)
      ..lineTo(w * 0.08, h * 0.40)
      ..close();
    canvas.drawPath(path, Paint()..color = base);

    // Left facet highlight.
    canvas.drawPath(
      Path()
        ..moveTo(cx, 0)
        ..lineTo(w * 0.08, h * 0.40)
        ..lineTo(cx, h)
        ..close(),
      Paint()..color = facetC,
    );

    // Woven kente threads across the widest band (clipped to the shard).
    canvas.save();
    canvas.clipPath(path);
    canvas.drawRect(
        Rect.fromLTWH(0, h * 0.33, w, h * 0.06), Paint()..color = bandC);
    canvas.drawRect(
        Rect.fromLTWH(0, h * 0.42, w, h * 0.03), Paint()..color = lineC);
    canvas.restore();

    // Outline.
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = (w * 0.06).clamp(1.0, 3.0)
        ..strokeJoin = StrokeJoin.round
        ..color = lineC,
    );
  }

  @override
  bool shouldRepaint(covariant _KenteShardPainter old) => old.muted != muted;
}
