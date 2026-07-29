import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Reusable "Overlay Snapshot" flight: animate a clone of any widget across the
/// screen along an arc, from one on-screen element to a target point/element,
/// then clean itself up. Not tied to the tro tro — pass any [builder].
///
/// Uses:
///  • the family avatar flying home into the Compound,
///  • the tro tro "driving" to a newly unlocked map stop,
///  • a reward icon flying into a counter, etc.
class OverlayFlight {
  const OverlayFlight._();

  /// Flies a clone (produced by [builder], given its current width) from
  /// [fromKey]'s rect to either [toKey]'s centre or [toCenter], with an upward
  /// [arcHeight] parabola and a size lerp to [endScale]. Completes when done.
  static Future<void> run({
    required BuildContext context,
    required TickerProvider vsync,
    required GlobalKey fromKey,
    required Widget Function(double width) builder,
    GlobalKey? toKey,
    Offset? toCenter,
    Duration duration = const Duration(milliseconds: 640),
    Curve curve = Curves.easeInOutCubic,
    double arcHeight = 90,
    double endScale = 1.0,
    VoidCallback? onStart,
  }) async {
    final fromCtx = fromKey.currentContext;
    if (fromCtx == null) return;
    final overlayState = Overlay.of(context);
    final fromBox = fromCtx.findRenderObject() as RenderBox;
    final startCenter = fromBox.localToGlobal(fromBox.size.center(Offset.zero));
    final startW = fromBox.size.width;
    final startH = fromBox.size.height;

    Offset endCenter = toCenter ?? startCenter;
    final toCtx = toKey?.currentContext;
    if (toCtx != null) {
      final toBox = toCtx.findRenderObject() as RenderBox;
      endCenter = toBox.localToGlobal(toBox.size.center(Offset.zero));
    }

    final controller = AnimationController(vsync: vsync, duration: duration);
    final anim = CurvedAnimation(parent: controller, curve: curve);

    onStart?.call();

    final entry = OverlayEntry(builder: (context) {
      return AnimatedBuilder(
        animation: anim,
        builder: (context, _) {
          final t = anim.value;
          final dx = ui.lerpDouble(startCenter.dx, endCenter.dx, t)!;
          final dyBase = ui.lerpDouble(startCenter.dy, endCenter.dy, t)!;
          final arc = -arcHeight * 4 * t * (1 - t); // upward, peaks mid-flight
          final scale = ui.lerpDouble(1.0, endScale, t)!;
          final w = startW * scale;
          final h = startH * scale;
          return Positioned(
            left: dx - w / 2,
            top: dyBase + arc - h / 2,
            width: w,
            height: h,
            child: IgnorePointer(child: builder(w)),
          );
        },
      );
    });

    overlayState.insert(entry);
    await controller.forward();
    entry.remove();
    controller.dispose();
  }
}
