import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/stats_notifier.dart';
import '../theme.dart';
import 'tappable_scale.dart';

const Color _track = Color(0xFFE7E9EC);
const Color _low = Color(0xFFC0492E);
const Color _high = Color(0xFF2E6B3B);

// Luminance matrix — desaturates the "broken down" gauge to grayscale.
const ColorFilter _grayscale = ColorFilter.matrix(<double>[
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0, 0, 0, 1, 0, //
]);

/// Live fuel gauge for the daily streak. It sweeps up (with a little overshoot)
/// the instant a lesson is recorded — driven by [streakNotifier], no reload.
///
/// At zero fuel the tro tro is "broken down": the gauge desaturates to
/// grayscale, but a bright terracotta **Refuel** button stays in colour as a
/// friendly, positive invitation to jump back in (never a punishment).
class FuelGauge extends StatelessWidget {
  final int fullTankDays;
  final VoidCallback? onRefuel;
  const FuelGauge({super.key, this.fullTankDays = 7, this.onRefuel});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: streakNotifier,
      builder: (context, streak, _) {
        final target = (streak / fullTankDays).clamp(0.0, 1.0);
        final broken = streak <= 0;

        final gauge = TweenAnimationBuilder<double>(
          tween: Tween<double>(end: target),
          duration: const Duration(milliseconds: 650),
          curve: Curves.easeOutBack, // overshoot then settle
          builder: (context, v, __) {
            final vv = v.clamp(0.0, 1.0);
            final col = Color.lerp(_low, _high, vv)!;
            return SizedBox(
              width: 150,
              height: 86,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                      size: const Size(150, 86),
                      painter: _FuelArcPainter(vv, col)),
                  Positioned(
                    top: 30,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                            broken
                                ? Icons.car_repair
                                : Icons.local_gas_station_rounded,
                            size: 16,
                            color: broken ? slate : col),
                        Text('$streak',
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: ink)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // The gauge desaturates when broken; the CTA below stays vibrant.
            broken
                ? ColorFiltered(colorFilter: _grayscale, child: gauge)
                : gauge,
            const SizedBox(height: 4),
            if (broken)
              TappableScale(
                onTap: onRefuel,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: terracottaDeep,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.local_gas_station_rounded,
                          color: Colors.white, size: 15),
                      SizedBox(width: 6),
                      Text('Refuel',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 13)),
                    ],
                  ),
                ),
              )
            else
              const Text('fuel · day streak',
                  style: TextStyle(fontSize: 12, color: slate)),
          ],
        );
      },
    );
  }
}

class _FuelArcPainter extends CustomPainter {
  final double value;
  final Color color;
  const _FuelArcPainter(this.value, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height - 10;
    final r = size.width / 2 - 14;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);
    final v = value.clamp(0.0, 1.0);

    canvas.drawArc(
        rect,
        math.pi,
        math.pi,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 12
          ..color = _track);
    canvas.drawArc(
        rect,
        math.pi,
        math.pi * v,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 12
          ..color = color);

    final ang = math.pi + math.pi * v;
    final end = Offset(cx + (r - 6) * math.cos(ang), cy + (r - 6) * math.sin(ang));
    canvas.drawLine(
        Offset(cx, cy),
        end,
        Paint()
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 4
          ..color = charcoal);
    canvas.drawCircle(Offset(cx, cy), 6, Paint()..color = charcoal);
  }

  @override
  bool shouldRepaint(covariant _FuelArcPainter old) =>
      old.value != value || old.color != color;
}
