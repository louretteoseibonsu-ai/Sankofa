import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme.dart';
import 'fuel_gauge.dart';

const Color _gold = Color(0xFFE3A92C);
const Color _terra = Color(0xFFBE5235);
const Color _track = Color(0xFFE7E9EC);

/// The tro tro "dashboard" HUD: a speedometer for the current lesson's progress
/// and a fuel gauge for the daily streak, plus token + kente-shard counters.
/// Pure presentation — feed it values from Progress / Stats.
class TroTroDashboard extends StatelessWidget {
  /// 0..1 progress through the current lesson (the speedometer needle).
  final double progress;

  /// Day streak — drives the fuel gauge (full at [fullTankDays]).
  final int streak;

  /// Cultural Tokens (pedis).
  final int tokens;

  /// Golden Kente shards (mastery currency).
  final int shards;

  final int fullTankDays;

  /// Streak exists but today isn't done yet — show a gentle "top up" prompt.
  final bool atRisk;

  /// Tapped when the tank is empty ("broken down") — a positive nudge to learn.
  final VoidCallback? onRefuel;

  const TroTroDashboard({
    super.key,
    required this.progress,
    required this.streak,
    required this.tokens,
    this.shards = 0,
    this.fullTankDays = 7,
    this.atRisk = false,
    this.onRefuel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _track, width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _Gauge(
                  value: progress.clamp(0.0, 1.0),
                  color: _terra,
                  big: '${(progress.clamp(0.0, 1.0) * 100).round()}%',
                  label: 'lesson progress',
                ),
              ),
              Expanded(child: FuelGauge(onRefuel: onRefuel)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _Counter(
                    icon: Icons.monetization_on_rounded,
                    color: _gold,
                    value: tokens,
                    label: 'tokens'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Counter(
                    icon: Icons.diamond_rounded,
                    color: _terra,
                    value: shards,
                    label: 'kente shards'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Gauge extends StatelessWidget {
  final double value;
  final Color color;
  final String big;
  final String label;
  const _Gauge(
      {required this.value,
      required this.color,
      required this.big,
      required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 150,
          height: 86,
          child: Stack(
            children: [
              CustomPaint(
                  size: const Size(150, 86),
                  painter: _GaugePainter(value, color)),
              Positioned(
                left: 0,
                right: 0,
                top: 36,
                child: Center(
                  child: Text(big,
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: ink)),
                ),
              ),
            ],
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: slate)),
      ],
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double value;
  final Color color;
  const _GaugePainter(this.value, this.color);

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
  bool shouldRepaint(covariant _GaugePainter old) =>
      old.value != value || old.color != color;
}

class _Counter extends StatelessWidget {
  final IconData icon;
  final Color color;
  final int value;
  final String label;
  const _Counter(
      {required this.icon,
      required this.color,
      required this.value,
      required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: canvas,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _track, width: 1.5),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$value',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800, color: ink)),
              Text(label, style: const TextStyle(fontSize: 11, color: slate)),
            ],
          ),
        ],
      ),
    );
  }
}
