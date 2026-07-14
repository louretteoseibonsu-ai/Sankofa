import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Wrap any tappable widget for a "juicy" press: it squashes to [pressedScale]
/// on tap-down (fast, easeOut), then springs back with a tiny overshoot on
/// release (easeOutBack) — squash-and-stretch. Fires a selection haptic on tap.
class TappableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;
  final bool haptic;

  const TappableScale({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.96,
    this.haptic = true,
  });

  @override
  State<TappableScale> createState() => _TappableScaleState();
}

class _TappableScaleState extends State<TappableScale> {
  double _scale = 1.0;
  Curve _curve = Curves.easeOut;
  Duration _duration = const Duration(milliseconds: 120);

  void _press() => setState(() {
        _scale = widget.pressedScale;
        _curve = Curves.easeOut;
        _duration = const Duration(milliseconds: 120);
      });

  void _release() => setState(() {
        _scale = 1.0;
        _curve = Curves.easeOutBack; // the tiny overshoot on the way back
        _duration = const Duration(milliseconds: 220);
      });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _press(),
      onTapCancel: _release,
      onTapUp: (_) {
        _release();
        if (widget.haptic) HapticFeedback.selectionClick();
        widget.onTap?.call();
      },
      child: AnimatedScale(
        scale: _scale,
        duration: _duration,
        curve: _curve,
        child: widget.child,
      ),
    );
  }
}
